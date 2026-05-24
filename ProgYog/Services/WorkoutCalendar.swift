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

import SwiftUI

// MARK: - Color <-> hex (generic, reusable)

extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt64(s, radix: 16) else { return nil }
        self.init(
            .sRGB,
            red: Double((v >> 16) & 0xFF) / 255,
            green: Double((v >> 8) & 0xFF) / 255,
            blue: Double(v & 0xFF) / 255
        )
    }

    var hexString: String {
        #if canImport(UIKit)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X",
                      Int(r * 255), Int(g * 255), Int(b * 255))
        #else
        return "#FF9F0A"
        #endif
    }
}

#if canImport(UIKit)
import UIKit
#endif

#if canImport(EventKit)
import EventKit

/// Generic mirror of timed events into a dedicated, color-configurable system
/// calendar. State (enabled / color / calendar id) lives in `UserDefaults`
/// under public keys so a SwiftUI `@AppStorage` settings screen stays in sync.
@MainActor
enum WorkoutCalendar {
    /// Calendar name shown in Apple Calendar — a shared concept across apps.
    static var calendarTitle = "Workout"
    static let defaultColorHex = "#FF9F0A"

    static let enabledKey    = "workoutCalendarEnabled"
    static let colorKey      = "workoutCalendarColor"
    static let calendarIdKey = "workoutCalendarId"

    static let store = EKEventStore()

    static var isEnabled: Bool { UserDefaults.standard.bool(forKey: enabledKey) }
    static var colorHex: String {
        UserDefaults.standard.string(forKey: colorKey) ?? defaultColorHex
    }
    static var isAuthorized: Bool {
        EKEventStore.authorizationStatus(for: .event) == .fullAccess
    }

    @discardableResult
    static func requestAccess() async -> Bool {
        do { return try await store.requestFullAccessToEvents() }
        catch { print("[WorkoutCalendar] auth error: \(error)"); return false }
    }

    // MARK: Find-or-create the app calendar in a writable source

    private static func appCalendar() -> EKCalendar? {
        if let id = UserDefaults.standard.string(forKey: calendarIdKey),
           let cal = store.calendar(withIdentifier: id) { return cal }
        guard let source = writableSource() else {
            print("[WorkoutCalendar] no writable calendar source"); return nil
        }
        let cal = EKCalendar(for: .event, eventStore: store)
        cal.title = calendarTitle
        cal.source = source
        if let cg = Color(hex: colorHex)?.cgColor { cal.cgColor = cg }
        do {
            try store.saveCalendar(cal, commit: true)
            UserDefaults.standard.set(cal.calendarIdentifier, forKey: calendarIdKey)
            return cal
        } catch { print("[WorkoutCalendar] saveCalendar: \(error)"); return nil }
    }

    private static func writableSource() -> EKSource? {
        store.sources.first { $0.sourceType == .local }
            ?? store.defaultCalendarForNewEvents?.source
            ?? store.sources.first { $0.sourceType == .calDAV || $0.sourceType == .exchange }
    }

    // MARK: Event identity = the deep-link URL (no model storage needed)

    private static func event(matching url: URL, around date: Date) -> EKEvent? {
        guard let cal = appCalendar() else { return nil }
        let cal0 = Calendar.current
        let start = cal0.date(byAdding: .day, value: -1, to: date) ?? date
        let end = cal0.date(byAdding: .day, value: 1, to: date) ?? date
        let pred = store.predicateForEvents(withStart: start, end: end, calendars: [cal])
        return store.events(matching: pred).first { $0.url == url }
    }

    // MARK: Public API

    @discardableResult
    static func upsert(title: String, start: Date, end: Date,
                       url: URL, notes: String?) -> Bool {
        guard isAuthorized, let cal = appCalendar() else { return false }
        let ev = event(matching: url, around: start) ?? EKEvent(eventStore: store)
        ev.calendar = cal
        ev.title = title
        ev.startDate = start
        ev.endDate = max(end, start)
        ev.url = url
        ev.notes = notes
        do { try store.save(ev, span: .thisEvent, commit: true); return true }
        catch { print("[WorkoutCalendar] save event: \(error)"); return false }
    }

    static func remove(url: URL, around date: Date) {
        guard isAuthorized, let ev = event(matching: url, around: date) else { return }
        try? store.remove(ev, span: .thisEvent, commit: true)
    }

    /// Remove every event in the app calendar whose URL starts with `prefix`
    /// AND is not in `keeping`. Scans a ±1y window around `now`. Used to
    /// reconcile a multi-event group (e.g. all segment events for one
    /// session) when the desired set has changed.
    static func reconcile(urlPrefix prefix: String, keeping: Set<URL>) {
        guard isAuthorized, let cal = appCalendar() else { return }
        let now = Date()
        let start = Calendar.current.date(byAdding: .year, value: -1, to: now) ?? now
        let end = Calendar.current.date(byAdding: .year, value: 1, to: now) ?? now
        let pred = store.predicateForEvents(withStart: start, end: end, calendars: [cal])
        for ev in store.events(matching: pred) {
            guard let u = ev.url, u.absoluteString.hasPrefix(prefix),
                  !keeping.contains(u) else { continue }
            try? store.remove(ev, span: .thisEvent, commit: false)
        }
        try? store.commit()
    }

    /// Wipe every event in the app calendar but keep the calendar itself.
    static func removeAllEvents() {
        guard isAuthorized, let cal = appCalendar() else { return }
        let now = Date()
        let start = Calendar.current.date(byAdding: .year, value: -10, to: now) ?? now
        let end = Calendar.current.date(byAdding: .year, value: 1, to: now) ?? now
        let pred = store.predicateForEvents(withStart: start, end: end, calendars: [cal])
        for ev in store.events(matching: pred) {
            try? store.remove(ev, span: .thisEvent, commit: false)
        }
        try? store.commit()
    }

    static func setColor(hex: String) {
        UserDefaults.standard.set(hex, forKey: colorKey)
        guard isAuthorized, let cal = appCalendar(),
              let cg = Color(hex: hex)?.cgColor else { return }
        cal.cgColor = cg
        try? store.saveCalendar(cal, commit: true)
    }

    /// Full teardown: delete the app calendar and forget its id.
    static func disable() {
        if isAuthorized,
           let id = UserDefaults.standard.string(forKey: calendarIdKey),
           let cal = store.calendar(withIdentifier: id) {
            try? store.removeCalendar(cal, commit: true)
        }
        UserDefaults.standard.removeObject(forKey: calendarIdKey)
    }
}
#endif

// MARK: - ProgYog bridge (the only app-specific part)

#if canImport(EventKit) && canImport(CoreData)
import CoreData

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
            let last = b.logs.last!
            let start = first.loggedAt.addingTimeInterval(-TimeInterval(first.durationSec))
            return WorkoutSegment(index: idx, dayStart: b.day,
                                  startedAt: start, endedAt: last.loggedAt,
                                  setLogs: b.logs)
        }
    }
}

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
    static func syncSegments(_ s: Session) {
        guard WorkoutCalendar.isEnabled, WorkoutCalendar.isAuthorized else { return }
        let title = WorkoutLabel.display(for: s)
        var kept = Set<URL>()
        for seg in WorkoutSegmenter.segments(of: s) {
            guard let url = dayURL(for: s, dayStart: seg.dayStart) else { continue }
            WorkoutCalendar.upsert(title: title, start: seg.startedAt, end: seg.endedAt,
                                   url: url, notes: notes(s, segment: seg))
            kept.insert(url)
        }
        WorkoutCalendar.reconcile(urlPrefix: sessionURLPrefix(s), keeping: kept)
    }

    /// Delete every event tied to this session (segments + legacy URL).
    static func removeAll(for s: Session) {
        WorkoutCalendar.reconcile(urlPrefix: sessionURLPrefix(s), keeping: [])
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
