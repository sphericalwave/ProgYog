//
//  DashboardStats.swift
//  ProgYog
//
//  Shared stats infra for the Dashboard AND Workouts tabs — both scan the
//  full session history and both call the expensive `CompletionScorer
//  .sessionPercent` (sorts + faults every family's logs) per session.
//  Computing it twice, once per tab, on the main thread, on every appear/
//  data-change, was the second half of the dashboard-hang bug (see
//  WorkoutStatsStore's doc comment). One background pass now computes the
//  per-session percent map once and derives both tabs' snapshots from it;
//  the result is cached and shared via `AppServices.stats` so switching
//  tabs never re-triggers the scan.
//

import Foundation
import CoreData
import Observation

struct CompletionPoint: Identifiable, Sendable, Codable {
    let id: String
    let code: String
    let last: Double
    let best: Double?
    var label: String { code }
}

struct VolumePoint: Identifiable, Sendable, Codable {
    let id: Date
    let bucketStart: Date
    let count: Int

    init(bucketStart: Date, count: Int) {
        self.id = bucketStart
        self.bucketStart = bucketStart
        self.count = count
    }
}

struct TimePoint: Identifiable, Sendable, Codable {
    let id: String
    let code: String
    let minutes: Int
}

struct DashboardSnapshot: Sendable, Codable {
    var completion: [CompletionPoint] = []
    var weekly: [VolumePoint] = []
    var monthly: [VolumePoint] = []
    var total: [TimePoint] = []
    var avg: [TimePoint] = []
    var hasSessions: Bool = false

    static let empty = DashboardSnapshot()
}

/// Everything the Workouts (first) tab needs per workout code, plus the
/// history/rate-of-change chart series across all codes.
struct WorkoutListSnapshot: Sendable, Codable {
    var historyPoints: [FamilyPercentChart.Point] = []
    var rocPoints: [FamilyPercentChart.Point] = []
    var lastPercentByCode: [String: Double] = [:]
    var bestPercentByCode: [String: Double] = [:]
    var sessionCountByCode: [String: Int] = [:]
    var lastDateByCode: [String: Date] = [:]
    var orderedCodes: [String] = WorkoutPalette.codes

    static let empty = WorkoutListSnapshot()
}

struct WorkoutStatsSnapshot: Sendable, Codable {
    var dashboard: DashboardSnapshot = .empty
    var workoutList: WorkoutListSnapshot = .empty

    static let empty = WorkoutStatsSnapshot()
}

/// Pure aggregation over a background-context session fetch. Runs entirely
/// inside the fetching context's `perform` block, so it's safe to call from
/// any queue; only the plain-value snapshot it returns crosses back out.
enum WorkoutStatsAggregator {
    static func snapshot(from sessions: [Session], now: Date = Date()) -> WorkoutStatsSnapshot {
        // The one expensive pass: sessionPercent sorts + faults each
        // family's logs. Both tabs need it per-session — compute once.
        var pctBySession: [NSManagedObjectID: Double] = [:]
        for s in sessions {
            if let p = CompletionScorer.sessionPercent(s) { pctBySession[s.objectID] = p }
        }

        return WorkoutStatsSnapshot(
            dashboard: DashboardSnapshot(
                completion: completionPoints(sessions, pctBySession: pctBySession),
                weekly: bucketed(sessions, unit: .weekOfYear, now: now, count: 12),
                monthly: bucketed(sessions, unit: .month, now: now, count: 12),
                total: totalTimePoints(sessions),
                avg: avgTimePoints(sessions),
                hasSessions: !sessions.isEmpty
            ),
            workoutList: workoutListSnapshot(sessions, pctBySession: pctBySession)
        )
    }

    // MARK: - Dashboard tab

    private static func completionPoints(_ sessions: [Session],
                                         pctBySession: [NSManagedObjectID: Double]) -> [CompletionPoint] {
        let grouped = Dictionary(grouping: sessions, by: \.workoutCode)
        return WorkoutPalette.codes.compactMap { code in
            let codeSessions = grouped[code] ?? []
            guard let last = codeSessions.first.flatMap({ pctBySession[$0.objectID] }) else {
                return nil
            }
            let best = codeSessions.compactMap { pctBySession[$0.objectID] }.max()
            return CompletionPoint(id: code, code: code, last: last, best: best)
        }
    }

    private static func bucketed(_ sessions: [Session], unit: Calendar.Component,
                                 now: Date, count: Int) -> [VolumePoint] {
        let cal = Calendar.current
        guard let currentStart = cal.dateInterval(of: unit, for: now)?.start else { return [] }
        let buckets: [Date] = (0..<count).reversed().compactMap { i in
            cal.date(byAdding: unit, value: -i, to: currentStart)
        }
        let grouped = Dictionary(grouping: sessions) {
            cal.dateInterval(of: unit, for: $0.startedAt)?.start ?? .distantPast
        }
        return buckets.map { VolumePoint(bucketStart: $0, count: grouped[$0]?.count ?? 0) }
    }

    private static func totalTimePoints(_ sessions: [Session]) -> [TimePoint] {
        WorkoutPalette.codes.map { code in
            let seconds = secondsForCode(code, in: sessions)
            return TimePoint(id: code, code: code, minutes: Int((Double(seconds) / 60).rounded()))
        }
    }

    private static func avgTimePoints(_ sessions: [Session]) -> [TimePoint] {
        WorkoutPalette.codes.map { code in
            let codeSessions = sessions.filter { $0.workoutCode == code }
            guard !codeSessions.isEmpty else {
                return TimePoint(id: code, code: code, minutes: 0)
            }
            let seconds = codeSessions
                .flatMap { $0.orderedSetLogs }
                .reduce(0) { $0 + Int($1.durationSec) }
            let avgSec = Double(seconds) / Double(codeSessions.count)
            return TimePoint(id: code, code: code, minutes: Int((avgSec / 60).rounded()))
        }
    }

    private static func secondsForCode(_ code: String, in sessions: [Session]) -> Int {
        sessions
            .filter { $0.workoutCode == code }
            .flatMap { $0.orderedSetLogs }
            .reduce(0) { $0 + Int($1.durationSec) }
    }

    // MARK: - Workouts tab

    private static func workoutListSnapshot(_ sessions: [Session],
                                            pctBySession: [NSManagedObjectID: Double]) -> WorkoutListSnapshot {
        // `sessions` is sorted newest-first (see WorkoutStatsStore's fetch).
        let codes = WorkoutPalette.codes
        let historyPoints: [FamilyPercentChart.Point] = sessions.reversed().compactMap { s in
            guard let pct = pctBySession[s.objectID] else { return nil }
            return FamilyPercentChart.Point(percent: pct,
                                            barColor: WorkoutPalette.color(for: s.workoutCode),
                                            series: s.workoutCode)
        }
        let rocPoints = rateOfChange(from: historyPoints)

        let grouped = Dictionary(grouping: sessions, by: \.workoutCode)
        var lastPercentByCode: [String: Double] = [:]
        var bestPercentByCode: [String: Double] = [:]
        var sessionCountByCode: [String: Int] = [:]
        var lastDateByCode: [String: Date] = [:]
        for code in codes {
            let codeSessions = grouped[code] ?? []
            lastPercentByCode[code] = codeSessions.first.flatMap { pctBySession[$0.objectID] }
            bestPercentByCode[code] = codeSessions.compactMap { pctBySession[$0.objectID] }.max()
            sessionCountByCode[code] = codeSessions.count
            lastDateByCode[code] = codeSessions.first?.startedAt
        }

        var orderedCodes = codes
        if let last = sessions.first, let idx = codes.firstIndex(of: last.workoutCode) {
            let startIdx = last.endedAt == nil ? idx : (idx + 1) % codes.count
            orderedCodes = Array(codes[startIdx...]) + Array(codes[..<startIdx])
        }

        return WorkoutListSnapshot(
            historyPoints: historyPoints,
            rocPoints: rocPoints,
            lastPercentByCode: lastPercentByCode,
            bestPercentByCode: bestPercentByCode,
            sessionCountByCode: sessionCountByCode,
            lastDateByCode: lastDateByCode,
            orderedCodes: orderedCodes
        )
    }

    private static func rateOfChange(from pts: [FamilyPercentChart.Point]) -> [FamilyPercentChart.Point] {
        var lastPct: [String: Double] = [:]
        var result: [FamilyPercentChart.Point] = []
        for p in pts {
            let key = p.series.isEmpty ? "_" : p.series
            if let prev = lastPct[key] {
                result.append(.init(percent: p.percent - prev, barColor: p.barColor, series: p.series))
            }
            lastPct[key] = p.percent
        }
        return result
    }
}

/// Owned once by `AppServices` so the Dashboard and Workouts tabs share one
/// background scan instead of each running (and re-running) their own.
@MainActor
@Observable
final class WorkoutStatsStore {
    private(set) var snapshot: WorkoutStatsSnapshot = .empty

    private let container: NSPersistentContainer
    private var rebuildTask: Task<Void, Never>?
    // deinit is nonisolated even on a @MainActor class (teardown can run
    // from any thread), so this needs to be readable there.
    private nonisolated(unsafe) var saveObserver: NSObjectProtocol?

    init(container: NSPersistentContainer) {
        self.container = container
        // Show last-known-accurate data instantly instead of an empty/zero
        // state while the first background rebuild is still running.
        if let cached = Self.loadCached() { snapshot = cached }
        saveObserver = NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave, object: nil, queue: nil
        ) { [weak self] _ in
            Task { @MainActor in self?.scheduleRebuild() }
        }
        scheduleRebuild()
    }

    deinit {
        if let saveObserver { NotificationCenter.default.removeObserver(saveObserver) }
    }

    /// Coalesces bursts of saves (e.g. a CloudKit import batch) into one
    /// rebuild instead of one per notification.
    func scheduleRebuild(debounce: Duration = .milliseconds(250)) {
        rebuildTask?.cancel()
        rebuildTask = Task { [weak self] in
            try? await Task.sleep(for: debounce)
            guard !Task.isCancelled else { return }
            await self?.rebuild()
        }
    }

    private func rebuild() async {
        let container = self.container
        let snap = await withCheckedContinuation { (continuation: CheckedContinuation<WorkoutStatsSnapshot, Never>) in
            container.performBackgroundTask { ctx in
                let request = NSFetchRequest<Session>(entityName: "Session")
                request.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: false)]
                let sessions = (try? ctx.fetch(request)) ?? []
                continuation.resume(returning: WorkoutStatsAggregator.snapshot(from: sessions))
            }
        }
        guard !Task.isCancelled else { return }
        snapshot = snap
        Task.detached(priority: .utility) { Self.persist(snap) }
    }

    // MARK: - Disk cache (last-known-good snapshot, shown instantly at launch)

    private nonisolated static let cacheURL: URL = {
        let dir = (try? FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true
        )) ?? URL.applicationSupportDirectory
        return dir.appendingPathComponent("WorkoutStatsCache.json")
    }()

    private nonisolated static func loadCached() -> WorkoutStatsSnapshot? {
        guard let data = try? Data(contentsOf: cacheURL) else { return nil }
        return try? JSONDecoder().decode(WorkoutStatsSnapshot.self, from: data)
    }

    /// Best-effort — a failed write just means the next launch falls back
    /// to the empty/loading state instead of the cache, nothing user-facing
    /// depends on this succeeding.
    private nonisolated static func persist(_ snapshot: WorkoutStatsSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: cacheURL, options: .atomic)
    }
}
