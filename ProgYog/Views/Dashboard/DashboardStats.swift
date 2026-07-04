//
//  DashboardStats.swift
//  ProgYog
//
//  The dashboard used to recompute five full-history aggregations inline in
//  `DashboardView.body` on the main thread, on every render — and every
//  CloudKit remote-change notification triggered a `refreshAllObjects()`
//  that invalidated the underlying @FetchRequest, causing a fresh recompute.
//  During a sync burst that's a feedback loop, and it gets slower as
//  history grows. `DashboardStatsStore` moves the aggregation to a
//  background context, rebuilt only when data actually changes (debounced),
//  and hands the view a plain Sendable snapshot.
//

import Foundation
import CoreData
import Observation

struct CompletionPoint: Identifiable, Sendable {
    let id: String
    let code: String
    let last: Double
    let best: Double?
    var label: String { code }
}

struct VolumePoint: Identifiable, Sendable {
    let id: Date
    let bucketStart: Date
    let count: Int

    init(bucketStart: Date, count: Int) {
        self.id = bucketStart
        self.bucketStart = bucketStart
        self.count = count
    }
}

struct TimePoint: Identifiable, Sendable {
    let id: String
    let code: String
    let minutes: Int
}

struct DashboardSnapshot: Sendable {
    var completion: [CompletionPoint] = []
    var weekly: [VolumePoint] = []
    var monthly: [VolumePoint] = []
    var total: [TimePoint] = []
    var avg: [TimePoint] = []
    var hasSessions: Bool = false

    static let empty = DashboardSnapshot()
}

/// Pure aggregation over a background-context session fetch. Runs entirely
/// inside the fetching context's `perform` block, so it's safe to call from
/// any queue; only the plain-value `DashboardSnapshot` it returns crosses
/// back to the caller.
enum DashboardAggregator {
    static func snapshot(from sessions: [Session], now: Date = Date()) -> DashboardSnapshot {
        DashboardSnapshot(
            completion: completionPoints(sessions),
            weekly: bucketed(sessions, unit: .weekOfYear, now: now, count: 12),
            monthly: bucketed(sessions, unit: .month, now: now, count: 12),
            total: totalTimePoints(sessions),
            avg: avgTimePoints(sessions),
            hasSessions: !sessions.isEmpty
        )
    }

    private static func completionPoints(_ sessions: [Session]) -> [CompletionPoint] {
        let grouped = Dictionary(grouping: sessions, by: \.workoutCode)
        return WorkoutPalette.codes.compactMap { code in
            let codeSessions = grouped[code] ?? []
            guard let last = codeSessions.first.flatMap({ CompletionScorer.sessionPercent($0) }) else {
                return nil
            }
            let best = codeSessions.compactMap { CompletionScorer.sessionPercent($0) }.max()
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
}

@MainActor
@Observable
final class DashboardStatsStore {
    private(set) var snapshot: DashboardSnapshot = .empty

    private let container: NSPersistentContainer
    private var rebuildTask: Task<Void, Never>?
    // deinit is nonisolated even on a @MainActor class (teardown can run
    // from any thread), so this needs to be readable there.
    private nonisolated(unsafe) var saveObserver: NSObjectProtocol?

    init(container: NSPersistentContainer) {
        self.container = container
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
        let snap = await withCheckedContinuation { (continuation: CheckedContinuation<DashboardSnapshot, Never>) in
            container.performBackgroundTask { ctx in
                let request = NSFetchRequest<Session>(entityName: "Session")
                request.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: false)]
                let sessions = (try? ctx.fetch(request)) ?? []
                continuation.resume(returning: DashboardAggregator.snapshot(from: sessions))
            }
        }
        guard !Task.isCancelled else { return }
        snapshot = snap
    }
}
