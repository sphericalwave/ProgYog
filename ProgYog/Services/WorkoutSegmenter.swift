//
//  WorkoutSegmenter.swift
//  ProgYog
//
//  One calendar-day's worth of work within a `Session`. Shared by both the
//  calendar and health bridges — no EventKit or HealthKit dependency.
//

#if canImport(CoreData)
import CoreData
import Foundation

/// One calendar-day's worth of work within a `Session`. Derived by
/// grouping `SetLog.loggedAt` per local-TZ day — see `WorkoutSegmenter`.
/// `dayStart` is the local midnight that keys the segment; `index` is
/// chronological day order within the session.
struct WorkoutSegment {
    let index: Int
    let dayStart: Date
    let startedAt: Date
    let endedAt: Date
    let setLogs: [SetLog]
}

enum WorkoutSegmenter {
    /// Group sets by `Calendar.current.startOfDay(for: loggedAt)` so the
    /// calendar shows exactly one timed bar per workout per day, even when
    /// the work spans many hours. A session that physically crosses
    /// midnight produces two segments (one per day) to keep bars from
    /// drawing across day boundaries.
    static func segments(of session: Session) -> [WorkoutSegment] {
        let logs = session.orderedSetLogs.sorted { $0.loggedAt < $1.loggedAt }
        guard !logs.isEmpty else { return [] }

        let cal = Calendar.current
        var buckets: [(day: Date, logs: [SetLog])] = []
        for log in logs {
            let day = cal.startOfDay(for: log.loggedAt)
            if buckets.last?.day == day {
                buckets[buckets.count - 1].logs.append(log)
            } else {
                buckets.append((day, [log]))
            }
        }

        return buckets.enumerated().map { idx, b in
            let first = b.logs.first!
            let start = first.loggedAt.addingTimeInterval(-TimeInterval(first.durationSec))
            // Use sum of set durations, not wall-clock window, so rest time
            // between sets doesn't inflate workout minutes in Health/Calendar.
            let activeDuration = b.logs.reduce(0) { $0 + TimeInterval($1.durationSec) }
            let end = start.addingTimeInterval(max(activeDuration, 1))
            return WorkoutSegment(index: idx, dayStart: b.day,
                                  startedAt: start, endedAt: end,
                                  setLogs: b.logs)
        }
    }
}
#endif
