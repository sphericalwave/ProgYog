//
//  WorkoutHealth.swift
//  ProgYog
//
//  Drop-in workout → Apple Health mirror.
//
//  `WorkoutHealth` is generic (no app types) so this file can be copied
//  verbatim into any workout app. `WorkoutHealthBridge` is the only
//  app-specific part — it maps this app's `Session` onto the generic API.
//  Workout identity is `HKMetadataKeyExternalUUID`, so no model/CoreData
//  storage is needed to reconcile.
//

// MARK: - ProgYog bridge (the only app-specific part)

#if canImport(HealthKit) && canImport(CoreData)
import WorkoutSyncKit
import CoreData
import HealthKit

@MainActor
enum WorkoutHealthBridge {
    private static let dayKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = .current
        f.timeZone = .current
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyyMMdd"
        return f
    }()

    /// Stable external UUID per (session, calendar day). Cleanup uses
    /// `sessionUUIDPrefix` to sweep stale segments, matching the approach
    /// of `WorkoutCalendarBridge`.
    static func segmentUUID(for session: Session, dayStart: Date) -> String {
        "\(session.id.uuidString)/day/\(dayKeyFormatter.string(from: dayStart))"
    }

    static func sessionUUIDPrefix(_ session: Session) -> String {
        session.id.uuidString
    }

    /// Mirror a session as one HKWorkout per calendar day it was worked on.
    static func syncSegments(_ s: Session) {
        guard WorkoutHealth.isEnabled, WorkoutHealth.isAuthorized else { return }
        Task { await syncAsync(s) }
    }

    /// Delete every HealthKit workout tied to this session.
    static func removeAll(for s: Session) {
        Task { await WorkoutHealth.reconcile(uuidPrefix: sessionUUIDPrefix(s), keeping: []) }
    }

    /// Backfill / reconcile every session that has logged sets.
    /// Runs all sessions sequentially in one task — concurrent HK batch
    /// writes are unreliable and drop entries silently.
    static func syncAll(moc: NSManagedObjectContext) {
        Task { await syncAllAsync(moc: moc) }
    }

    /// Awaitable form used by the settings UI so it can show a spinner
    /// and stamp a last-synced timestamp on completion.
    static func syncAllAsync(moc: NSManagedObjectContext) async {
        guard WorkoutHealth.isEnabled, WorkoutHealth.isAuthorized else { return }
        let fr: NSFetchRequest<Session> = Session.fetchRequest()
        fr.predicate = NSPredicate(format: "setLogs.@count > 0")
        let sessions = (try? moc.fetch(fr)) ?? []
        for s in sessions { await syncAsync(s) }
        UserDefaults.standard.set(
            Date().timeIntervalSince1970,
            forKey: WorkoutHealth.lastSyncedAtKey
        )
    }

    private static func syncAsync(_ s: Session) async {
        let title = WorkoutLabel.display(for: s)
        var kept = Set<String>()
        for seg in WorkoutSegmenter.segments(of: s) {
            let uuid = segmentUUID(for: s, dayStart: seg.dayStart)
            await WorkoutHealth.upsert(
                uuid: uuid,
                activityType: .yoga,
                start: seg.startedAt,
                end: seg.endedAt,
                metadata: [HKMetadataKeyWorkoutBrandName: title],
                heartRate: hrReadings(for: seg)
            )
            kept.insert(uuid)
        }
        await WorkoutHealth.reconcile(uuidPrefix: sessionUUIDPrefix(s), keeping: kept)
    }

    private static func hrReadings(for seg: WorkoutSegment) -> [(date: Date, bpm: Int)] {
        seg.setLogs.flatMap { log in
            let setStart = log.loggedAt.addingTimeInterval(-TimeInterval(log.durationSec))
            return log.orderedHRSamples.map { s in
                (date: setStart.addingTimeInterval(s.t), bpm: Int(s.bpm))
            }
        }
    }

    static func removeAll() {
        Task { await WorkoutHealth.removeAllAppWorkouts() }
    }
}
#endif
