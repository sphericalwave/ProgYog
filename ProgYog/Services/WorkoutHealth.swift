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

#if canImport(HealthKit)
import HealthKit

/// Generic mirror of timed workout sessions into Apple Health.
/// State (enabled) lives in `UserDefaults` under public keys so a SwiftUI
/// `@AppStorage` settings screen stays in sync.
@MainActor
enum WorkoutHealth {
    static let enabledKey        = "workoutHealthEnabled"
    static let lastSyncedAtKey   = "workoutHealthLastSyncedAt"

    static let store = HKHealthStore()

    static var isEnabled: Bool { UserDefaults.standard.bool(forKey: enabledKey) }
    static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }
    static var isAuthorized: Bool {
        store.authorizationStatus(for: .workoutType()) == .sharingAuthorized
    }

    @discardableResult
    static func requestAccess() async -> Bool {
        guard isAvailable else { return false }
        let toShare: Set<HKSampleType> = [.workoutType(), HKQuantityType(.heartRate)]
        do {
            try await store.requestAuthorization(toShare: toShare, read: [])
            return isAuthorized
        } catch {
            print("[WorkoutHealth] auth error: \(error)")
            return false
        }
    }

    // MARK: Identity — HKMetadataKeyExternalUUID

    private static func existing(uuid: String) async -> HKWorkout? {
        guard isAvailable else { return nil }
        let predicate = HKQuery.predicateForObjects(
            withMetadataKey: HKMetadataKeyExternalUUID,
            operatorType: .equalTo,
            value: uuid
        )
        return await withCheckedContinuation { cont in
            store.execute(HKSampleQuery(
                sampleType: .workoutType(),
                predicate: predicate,
                limit: 1,
                sortDescriptors: nil
            ) { _, samples, _ in
                cont.resume(returning: samples?.first as? HKWorkout)
            })
        }
    }

    // MARK: Public API

    @discardableResult
    static func upsert(
        uuid: String,
        activityType: HKWorkoutActivityType,
        start: Date,
        end: Date,
        metadata: [String: Any] = [:]
    ) async -> HKWorkout? {
        guard isAuthorized else { return nil }
        let old = await existing(uuid: uuid)
        var meta = metadata
        meta[HKMetadataKeyExternalUUID] = uuid
        let clampedEnd = max(end, start.addingTimeInterval(1))
        // HKWorkoutBuilder is for live sessions; direct init is correct for
        // retroactive logging and avoids silent failures on batch import.
        let workout = HKWorkout(
            activityType: activityType,
            start: start,
            end: clampedEnd,
            duration: clampedEnd.timeIntervalSince(start),
            totalEnergyBurned: nil,
            totalDistance: nil,
            metadata: meta
        )
        do {
            // Save new first — only delete old after the new one lands safely.
            try await store.save(workout)
            if let old { try? await store.delete(old) }
            return workout
        } catch {
            print("[WorkoutHealth] upsert: \(error)")
            return nil
        }
    }

    static func addHeartRate(_ readings: [(date: Date, bpm: Int)], to workout: HKWorkout) async {
        guard !readings.isEmpty,
              store.authorizationStatus(for: HKQuantityType(.heartRate)) == .sharingAuthorized
        else { return }
        let hrType = HKQuantityType(.heartRate)
        let unit = HKUnit.count().unitDivided(by: .minute())
        let samples = readings.map { r in
            HKQuantitySample(type: hrType,
                             quantity: HKQuantity(unit: unit, doubleValue: Double(r.bpm)),
                             start: r.date, end: r.date)
        }
        do {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                store.add(samples, to: workout) { _, error in
                    if let error { cont.resume(throwing: error) } else { cont.resume() }
                }
            }
        } catch { print("[WorkoutHealth] addHeartRate: \(error)") }
    }

    /// Delete all app workouts whose external UUID starts with `prefix`
    /// and is NOT in `keeping`. Scans only workouts saved by this app.
    static func reconcile(uuidPrefix prefix: String, keeping: Set<String>) async {
        guard isAuthorized, isAvailable else { return }
        let workouts: [HKWorkout] = await withCheckedContinuation { cont in
            store.execute(HKSampleQuery(
                sampleType: .workoutType(),
                predicate: HKQuery.predicateForObjects(from: .default()),
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                cont.resume(returning: (samples as? [HKWorkout]) ?? [])
            })
        }
        let stale = workouts.filter { w in
            guard let id = w.metadata?[HKMetadataKeyExternalUUID] as? String else { return false }
            return id.hasPrefix(prefix) && !keeping.contains(id)
        }
        if !stale.isEmpty { try? await store.delete(stale) }
    }

    /// Wipe all workouts saved by this app.
    static func removeAllAppWorkouts() async {
        guard isAuthorized, isAvailable else { return }
        let workouts: [HKWorkout] = await withCheckedContinuation { cont in
            store.execute(HKSampleQuery(
                sampleType: .workoutType(),
                predicate: HKQuery.predicateForObjects(from: .default()),
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                cont.resume(returning: (samples as? [HKWorkout]) ?? [])
            })
        }
        if !workouts.isEmpty { try? await store.delete(workouts) }
    }
}
#endif

// MARK: - ProgYog bridge (the only app-specific part)

#if canImport(HealthKit) && canImport(CoreData)
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
            if let workout = await WorkoutHealth.upsert(
                uuid: uuid,
                activityType: .yoga,
                start: seg.startedAt,
                end: seg.endedAt,
                metadata: [HKMetadataKeyWorkoutBrandName: title]
            ) {
                await WorkoutHealth.addHeartRate(hrReadings(for: seg), to: workout)
            }
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
