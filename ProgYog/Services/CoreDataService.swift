//
//  CoreDataService.swift
//  ProgYog
//

import CoreData
import UIKit

@MainActor
final class CoreDataService: ObservableObject {
    let container: NSPersistentContainer
    weak var errorLog: ErrorLog?

    @Published private(set) var lastSavedAt: Date?
    @Published var lastSaveError: String?
    @Published private(set) var didBackupOnLaunch: Bool = false
    @Published private(set) var backupURL: URL?

    var moc: NSManagedObjectContext { container.viewContext }

    init(inMemory: Bool = false) {
        let container = NSPersistentContainer(name: "ProgYog")
        if inMemory {
            let desc = NSPersistentStoreDescription()
            desc.url = URL(fileURLWithPath: "/dev/null")
            container.persistentStoreDescriptions = [desc]
        }
        if let desc = container.persistentStoreDescriptions.first {
            desc.shouldMigrateStoreAutomatically = true
            desc.shouldInferMappingModelAutomatically = true
        }

        self.container = container

        var loadErrorCaptured: NSError?
        var backupURLCaptured: URL?

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                loadErrorCaptured = error
                backupURLCaptured = Self.backupAndReset(container: container)
                container.loadPersistentStores { _, retryError in
                    if let retryError = retryError {
                        fatalError("CoreData store unrecoverable after backup: \(retryError)")
                    }
                }
                UserDefaults.standard.removeObject(forKey: "didSeedJSON")
                UserDefaults.standard.removeObject(forKey: "seedVersion")
            }
        }

        if let err = loadErrorCaptured {
            self.didBackupOnLaunch = true
            self.backupURL = backupURLCaptured
            self.lastSaveError = "Store load failed; backed up and rebuilt. \(err.localizedDescription)"
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification, object: nil, queue: nil
        ) { [weak self] _ in
            Task { @MainActor in self?.save() }
        }
    }

    func attach(errorLog: ErrorLog) {
        self.errorLog = errorLog
        if didBackupOnLaunch {
            let path = backupURL?.path ?? "unknown"
            errorLog.record(
                .error,
                source: "CoreData.load",
                message: "Store load failed; previous data backed up.",
                error: NSError(
                    domain: "ProgYog.CoreData",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Backup at \(path)"]
                )
            )
        }
    }

    func save() {
        guard moc.hasChanges else { return }
        do {
            try moc.save()
            lastSavedAt = Date()
            lastSaveError = nil
        } catch {
            let message = (error as NSError).localizedDescription
            lastSaveError = message
            errorLog?.error("CoreData.save", "Save failed: \(message)", error: error)
        }
    }

    /// Deep-copy a Session: new IDs, fresh startedAt; SetLogs and HR samples
    /// duplicated verbatim aside from their UUIDs. Completed sessions
    /// rebase endedAt to now so calendar ordering stays coherent.
    @discardableResult
    func duplicateSession(_ source: Session) -> Session {
        let dup = Session(context: moc)
        dup.id = UUID()
        dup.startedAt = Date()
        dup.endedAt = source.endedAt == nil ? nil : Date()
        dup.workoutCode = source.workoutCode
        dup.notes = source.notes

        for src in source.orderedSetLogs {
            let log = SetLog(context: moc)
            log.id = UUID()
            log.session = dup
            log.absSkill = src.absSkill
            log.roundIndex = src.roundIndex
            log.orderInRound = src.orderInRound
            log.reps = src.reps
            log.rom = src.rom
            log.rpt = src.rpt
            log.rpe = src.rpe
            log.rpd = src.rpd
            log.rptNote = src.rptNote
            log.rpeNote = src.rpeNote
            log.rpdNote = src.rpdNote
            log.notes = src.notes
            log.durationSec = src.durationSec
            log.decision = src.decision
            log.hrAvg = src.hrAvg
            log.hrMin = src.hrMin
            log.hrMax = src.hrMax
            log.loggedAt = src.loggedAt

            for s in src.orderedHRSamples {
                let sample = HRSample(context: moc)
                sample.t = s.t
                sample.bpm = s.bpm
                sample.setLog = log
            }
        }
        save()
        WorkoutCalendarBridge.syncSegments(dup)
        WorkoutHealthBridge.syncSegments(dup)
        return dup
    }

    private static let seedVersionKey = "seedVersion"
    private static let currentSeedVersion = 2

    func seedIfNeeded() {
        let stored = UserDefaults.standard.integer(forKey: Self.seedVersionKey)
        guard stored < Self.currentSeedVersion else { return }

        if stored > 0 {
            wipeCatalog()
        }
        _ = ImportedJSON(moc: moc)
        save()
        UserDefaults.standard.set(Self.currentSeedVersion, forKey: Self.seedVersionKey)
    }

    private static let decisionRenameFlagKey = "didRenameHoldToRepeat"

    func renameHoldToRepeatIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: Self.decisionRenameFlagKey) else { return }
        let fr: NSFetchRequest<SetLog> = SetLog.fetchRequest()
        fr.predicate = NSPredicate(format: "decision == %@", "hold")
        let logs = (try? moc.fetch(fr)) ?? []
        for log in logs { log.decision = "repeat" }
        save()
        UserDefaults.standard.set(true, forKey: Self.decisionRenameFlagKey)
    }

    private static let notesMergeFlagKey = "didMergeSetLogNotes"

    func mergeLegacyNotesIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: Self.notesMergeFlagKey) else { return }

        let fr: NSFetchRequest<SetLog> = SetLog.fetchRequest()
        let logs = (try? moc.fetch(fr)) ?? []
        for log in logs {
            guard (log.notes ?? "").isEmpty else { continue }
            var parts: [String] = []
            if let n = log.rptNote, !n.isEmpty { parts.append("Technique: \(n)") }
            if let n = log.rpeNote, !n.isEmpty { parts.append("Exertion: \(n)") }
            if let n = log.rpdNote, !n.isEmpty { parts.append("Discomfort: \(n)") }
            if !parts.isEmpty {
                log.notes = parts.joined(separator: "\n")
            }
        }
        save()
        UserDefaults.standard.set(true, forKey: Self.notesMergeFlagKey)
    }

    private static let skillPhotoMigrationKey = "didMigrateSkillPhotosV1"

    /// One-time migration: copies bundle images (and any legacy customPhotoData /
    /// customPhotosData) into CDSkillPhoto records with allowsExternalBinaryDataStorage.
    func migrateSkillPhotosIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: Self.skillPhotoMigrationKey) else { return }
        let req = CDAbsSkill.fetchRequest()
        guard let skills = try? moc.fetch(req) else { return }
        for skill in skills {
            var datas: [Data] = []
            // Bundle images (only for skills that haven't been flagged yet)
            if !skill.hideBundleImages {
                datas = skill.posterAssetNames.compactMap {
                    UIImage(named: $0)?.jpegData(compressionQuality: 0.82)
                }
            }
            // Legacy Transformable array
            if datas.isEmpty, let arr = skill.customPhotosData as? [Data] {
                datas = arr
            }
            // Legacy single binary
            if datas.isEmpty, let d = skill.customPhotoData {
                datas = [d]
            }
            if !datas.isEmpty {
                skill.customPhotos = datas
                skill.hideBundleImages = true
            }
            skill.customPhotosData = nil
        }
        save()
        UserDefaults.standard.set(true, forKey: Self.skillPhotoMigrationKey)
    }

    private func wipeCatalog() {
        for entity in ["CDAbsSkill", "CDSkillFamily", "CDYogSeries"] {
            let fr = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            let delete = NSBatchDeleteRequest(fetchRequest: fr)
            _ = try? container.persistentStoreCoordinator.execute(delete, with: moc)
        }
        moc.reset()
    }

    /// Rename existing SQLite to a timestamped .broken file (preserves data),
    /// detaches stores, and returns the backup URL. Safer than rm -rf.
    private static func backupAndReset(container: NSPersistentContainer) -> URL? {
        guard let url = container.persistentStoreDescriptions.first?.url else { return nil }
        let coordinator = container.persistentStoreCoordinator
        for store in coordinator.persistentStores {
            try? coordinator.remove(store)
        }
        let stamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let parent = url.deletingLastPathComponent()
        let stem = url.deletingPathExtension().lastPathComponent
        let backup = parent.appendingPathComponent("\(stem)-broken-\(stamp).sqlite")
        let backupShm = backup.appendingPathExtension("-shm")
        let backupWal = backup.appendingPathExtension("-wal")
        try? FileManager.default.moveItem(at: url, to: backup)
        try? FileManager.default.moveItem(at: url.appendingPathExtension("-shm"), to: backupShm)
        try? FileManager.default.moveItem(at: url.appendingPathExtension("-wal"), to: backupWal)
        return backup
    }
}
