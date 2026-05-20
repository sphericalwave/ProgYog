//
//  CompletionScorer.swift
//  ProgYog
//
//  Inclusive % completed metric. A set "qualifies" when RPT ≥ 8, RPE ≤ 6,
//  RPD ≤ 1, ROM ≥ 95. A family's contribution to a session is the
//  (depth / family.maxDepth) of its LAST qualifying set in that session,
//  or 0 if the last set didn't qualify, or nil if the family wasn't
//  logged at all (so it's excluded from the session mean — not punished).
//

import Foundation
import CoreData

/// Thresholds backing the % completed metric. Editable in Settings.
/// Reads from `UserDefaults.standard`; falls back to the defaults below
/// when the key is absent or zero (the initial @AppStorage value).
enum CompletionSettings {
    static let rptMinKey = "completion.rptMin"
    static let rpeMaxKey = "completion.rpeMax"
    static let rpdMaxKey = "completion.rpdMax"
    static let romMinKey = "completion.romMin"

    static let defaultRptMin: Int16 = 8
    static let defaultRpeMax: Int16 = 6
    static let defaultRpdMax: Int16 = 1
    static let defaultRomMin: Int16 = 95

    private static func read(_ key: String, fallback: Int16) -> Int16 {
        let stored = UserDefaults.standard.integer(forKey: key)
        return stored == 0 ? fallback : Int16(stored)
    }

    static var rptMin: Int16 { read(rptMinKey, fallback: defaultRptMin) }
    static var rpeMax: Int16 { read(rpeMaxKey, fallback: defaultRpeMax) }
    static var rpdMax: Int16 { read(rpdMaxKey, fallback: defaultRpdMax) }
    static var romMin: Int16 { read(romMinKey, fallback: defaultRomMin) }

    static func resetToDefaults() {
        UserDefaults.standard.removeObject(forKey: rptMinKey)
        UserDefaults.standard.removeObject(forKey: rpeMaxKey)
        UserDefaults.standard.removeObject(forKey: rpdMaxKey)
        UserDefaults.standard.removeObject(forKey: romMinKey)
    }
}

enum CompletionScorer {

    // MARK: - Thresholds (forwarded from CompletionSettings)
    static var rptMin: Int16 { CompletionSettings.rptMin }
    static var rpeMax: Int16 { CompletionSettings.rpeMax }
    static var rpdMax: Int16 { CompletionSettings.rpdMax }
    static var romMin: Int16 { CompletionSettings.romMin }

    // MARK: - Per-family per-session

    /// Returns 0...100 for the family's contribution to this session.
    /// `nil` when the family has no logs in the session — caller excludes it
    /// from the session mean so early sessions aren't crushed by untouched
    /// families.
    static func familyPercent(in session: Session,
                              family: CDSkillFamily) -> Double? {
        let logs = session.orderedSetLogs.filter {
            $0.absSkill?.skillFamily == family
        }
        guard let last = logs.last else { return nil }
        guard last.qualifiesForCompletion else { return 0 }
        let maxDepth = Double(family.maxDepth)
        guard maxDepth > 0 else { return 0 }
        let depth = Double(last.absSkill?.depth ?? 0)
        return min(100, (depth / maxDepth) * 100)
    }

    // MARK: - Per-session

    /// Mean of per-family % over the families that appeared in the session.
    /// `nil` when no families logged.
    static func sessionPercent(_ session: Session) -> Double? {
        let logs = session.orderedSetLogs
        guard !logs.isEmpty else { return nil }
        let families = Set(logs.compactMap { $0.absSkill?.skillFamily })
        let percents = families.compactMap { familyPercent(in: session, family: $0) }
        guard !percents.isEmpty else { return nil }
        return percents.reduce(0, +) / Double(percents.count)
    }

    // MARK: - All-time best per family

    /// Best per-session % for this family across every session it appears in.
    static func allTimeBestFamilyPercent(_ family: CDSkillFamily) -> Double? {
        let skills = family.absSkills as? Set<CDAbsSkill> ?? []
        let allLogs = skills.flatMap { ($0.setLogs as? Set<SetLog> ?? []) }
        let sessions = Set(allLogs.compactMap { $0.session })
        var best: Double = 0
        var sawAny = false
        for session in sessions {
            if let p = familyPercent(in: session, family: family) {
                sawAny = true
                if p > best { best = p }
            }
        }
        return sawAny ? best : nil
    }

    // MARK: - Workout-code rollups

    /// Most recent session % for this workout code.
    static func lastSessionPercent(workoutCode: String,
                                   moc: NSManagedObjectContext) -> Double? {
        let fr: NSFetchRequest<Session> = Session.fetchRequest()
        fr.predicate = NSPredicate(format: "workoutCode == %@", workoutCode)
        fr.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: false)]
        fr.fetchLimit = 1
        guard let session = (try? moc.fetch(fr))?.first else { return nil }
        return sessionPercent(session)
    }

    /// All-time best session % across every session of this workout code.
    static func allTimeBestSessionPercent(workoutCode: String,
                                          moc: NSManagedObjectContext) -> Double? {
        let fr: NSFetchRequest<Session> = Session.fetchRequest()
        fr.predicate = NSPredicate(format: "workoutCode == %@", workoutCode)
        let sessions = (try? moc.fetch(fr)) ?? []
        return sessions.compactMap { sessionPercent($0) }.max()
    }
}
