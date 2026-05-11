//
//  CoreDataService.swift
//  ProgYog
//

import CoreData
import UIKit

final class CoreDataService: ObservableObject {
    let container: NSPersistentContainer

    var moc: NSManagedObjectContext { container.viewContext }

    init() {
        let container = NSPersistentContainer(name: "ProgYog")
        if let desc = container.persistentStoreDescriptions.first {
            desc.shouldMigrateStoreAutomatically = true
            desc.shouldInferMappingModelAutomatically = true
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                Self.wipeStore(container: container)
                container.loadPersistentStores { _, retryError in
                    if let retryError = retryError {
                        fatalError("CoreData store unrecoverable: \(retryError)")
                    }
                }
                print("CoreData store was incompatible (\(error.code)); wiped and rebuilt.")
                UserDefaults.standard.removeObject(forKey: "didSeedJSON")
            }
        }

        self.container = container

        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification, object: nil, queue: nil
        ) { [weak self] _ in self?.save() }
    }

    func save() {
        guard moc.hasChanges else { return }
        do { try moc.save() }
        catch { print("CoreData save error: \(error)") }
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

    private func wipeCatalog() {
        for entity in ["CDAbsSkill", "CDSkillFamily", "CDYogSeries"] {
            let fr = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            let delete = NSBatchDeleteRequest(fetchRequest: fr)
            _ = try? container.persistentStoreCoordinator.execute(delete, with: moc)
        }
        moc.reset()
    }

    private static func wipeStore(container: NSPersistentContainer) {
        guard let url = container.persistentStoreDescriptions.first?.url else { return }
        let coordinator = container.persistentStoreCoordinator
        for store in coordinator.persistentStores {
            try? coordinator.remove(store)
        }
        try? FileManager.default.removeItem(at: url)
        try? FileManager.default.removeItem(at: url.appendingPathExtension("-shm"))
        try? FileManager.default.removeItem(at: url.appendingPathExtension("-wal"))
    }
}
