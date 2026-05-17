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

@MainActor
enum WorkoutCalendarBridge {
    static let scheme = "progyog"

    static func url(for session: Session) -> URL? {
        URL(string: "\(scheme)://session/\(session.id.uuidString)")
    }

    /// Parse `progyog://session/<uuid>` from an incoming deep link.
    static func sessionID(from url: URL) -> UUID? {
        guard url.scheme == scheme, url.host == "session",
              let last = url.pathComponents.last else { return nil }
        return UUID(uuidString: last)
    }

    private static func title(_ s: Session) -> String { "Workout \(s.workoutCode)" }

    private static func notes(_ s: Session) -> String? {
        let logs = s.orderedSetLogs
        let rounds = Set(logs.map(\.roundIndex)).count
        var parts = ["\(rounds) round\(rounds == 1 ? "" : "s") · "
            + "\(logs.count) set\(logs.count == 1 ? "" : "s")"]
        if let n = s.notes, !n.isEmpty { parts.append(n) }
        return parts.joined(separator: "\n")
    }

    /// Mirror one finished session. No-op unless enabled + authorized.
    static func syncCompleted(_ s: Session) {
        guard WorkoutCalendar.isEnabled, WorkoutCalendar.isAuthorized,
              let end = s.endedAt, let url = url(for: s) else { return }
        WorkoutCalendar.upsert(title: title(s), start: s.startedAt,
                               end: end, url: url, notes: notes(s))
    }

    static func remove(_ s: Session) {
        guard let url = url(for: s) else { return }
        WorkoutCalendar.remove(url: url, around: s.startedAt)
    }

    /// Backfill / reconcile every completed session.
    static func syncAll(moc: NSManagedObjectContext) {
        guard WorkoutCalendar.isEnabled, WorkoutCalendar.isAuthorized else { return }
        let fr: NSFetchRequest<Session> = Session.fetchRequest()
        fr.predicate = NSPredicate(format: "endedAt != nil")
        for s in (try? moc.fetch(fr)) ?? [] { syncCompleted(s) }
    }

    static func removeAll() { WorkoutCalendar.removeAllEvents() }
}
#endif
