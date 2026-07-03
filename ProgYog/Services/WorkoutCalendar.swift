//
//  WorkoutCalendar.swift
//  ProgYog
//
//  Drop-in workout → Apple Calendar mirror.
//
//  `WorkoutCalendar` is generic (no app types) so this file can be copied
//  verbatim into any workout app. `WorkoutCalendarBridge` is the only
//  app-specific part — it maps this app's `Session` onto the generic API.
//  Event identity is the deep-link URL, so no model/CoreData storage is
//  needed to reconcile.
//

// MARK: - ProgYog bridge (the only app-specific part)

#if canImport(EventKit) && canImport(CoreData)
import WorkoutSyncKit
import CoreData

@MainActor
enum WorkoutCalendarBridge {
    static let scheme = "progyog"

    private static let dayKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = .current
        f.timeZone = .current
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyyMMdd"
        return f
    }()

    /// Stable URL per (session, calendar day). Cleanup uses
    /// `sessionURLPrefix` to sweep stale URLs under the same session —
    /// including legacy `/segment/<n>` forms and the very-legacy
    /// no-suffix URL — so old events get reconciled to the day-keyed
    /// scheme on the next sync.
    static func dayURL(for session: Session, dayStart: Date) -> URL? {
        URL(string: "\(scheme)://session/\(session.id.uuidString)/day/\(dayKeyFormatter.string(from: dayStart))")
    }

    static func sessionURLPrefix(_ session: Session) -> String {
        "\(scheme)://session/\(session.id.uuidString)"
    }

    /// Parse a deep link back to a session id. Handles the no-suffix,
    /// `/segment/<n>`, and `/day/<yyyyMMdd>` URL forms (session id is
    /// always the first path component).
    static func sessionID(from url: URL) -> UUID? {
        guard url.scheme == scheme, url.host == "session" else { return nil }
        let parts = url.pathComponents.filter { $0 != "/" }
        return parts.first.flatMap(UUID.init(uuidString:))
    }

    private static func notes(_ s: Session, segment: WorkoutSegment) -> String? {
        let n = segment.setLogs.count
        var parts = ["\(n) set\(n == 1 ? "" : "s")"]
        if let extra = s.notes, !extra.isEmpty { parts.append(extra) }
        return parts.joined(separator: "\n")
    }

    /// Mirror a session as one timed event per calendar day it was
    /// worked on. Sweeps stale URLs under this session's prefix on the
    /// way out, so day re-bucketing AND upgrades from the older
    /// per-chunk / single-event URL schemes leave no orphans.
    /// Core Data is read on the calling (main) actor; EK work runs on a
    /// background task so the main thread is never blocked.
    static func syncSegments(_ s: Session) {
        guard WorkoutCalendar.isEnabled, WorkoutCalendar.isAuthorized else { return }
        let title = WorkoutLabel.display(for: s)
        let prefix = sessionURLPrefix(s)
        // Extract everything we need from Core Data objects on the main thread.
        let items: [(url: URL, start: Date, end: Date, notes: String?)] =
            WorkoutSegmenter.segments(of: s).compactMap { seg in
                guard let url = dayURL(for: s, dayStart: seg.dayStart) else { return nil }
                return (url, seg.startedAt, seg.endedAt, notes(s, segment: seg))
            }
        let kept = Set(items.map(\.url))
        Task.detached {
            for item in items {
                WorkoutCalendar.upsert(title: title, start: item.start, end: item.end,
                                       url: item.url, notes: item.notes)
            }
            WorkoutCalendar.reconcile(urlPrefix: prefix, keeping: kept)
        }
    }

    /// Delete every event tied to this session (segments + legacy URL).
    static func removeAll(for s: Session) {
        let prefix = sessionURLPrefix(s)
        Task.detached { WorkoutCalendar.reconcile(urlPrefix: prefix, keeping: []) }
    }

    /// Backfill / reconcile every session that has logged sets.
    /// Drops the `endedAt != nil` predicate so in-progress chunked
    /// workouts also appear on the calendar.
    static func syncAll(moc: NSManagedObjectContext) {
        guard WorkoutCalendar.isEnabled, WorkoutCalendar.isAuthorized else { return }
        let fr: NSFetchRequest<Session> = Session.fetchRequest()
        fr.predicate = NSPredicate(format: "setLogs.@count > 0")
        for s in (try? moc.fetch(fr)) ?? [] { syncSegments(s) }
    }

    static func removeAll() { WorkoutCalendar.removeAllEvents() }
}
#endif
