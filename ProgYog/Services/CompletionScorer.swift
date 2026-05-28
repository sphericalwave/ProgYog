//
//  CompletionScorer.swift
//  ProgYog
//
//  Two distinct scores:
//
//  SET SCORE (per-set, shown in SetLogSheet):
//      clamp(rom / romMin, 0...1) × 100
//      Depth-independent — full range at any level = 100%.
//
//  WORKOUT SCORE (per-session/family, shown in lists and summaries):
//      romFraction  = clamp(last.rom / romMin, 0...1)
//      familyPercent = (max(depth − 1, 0) + romFraction) / maxDepth × 100
//      100% requires the highest-depth skill AND full ROM.
//      Uses the LAST set logged for that family in the session.
//
//  RPT / RPE / RPD are advisory (used in qualifiesForCompletion on SetLog)
//  but don't affect either score. Families with no logs return nil and are
//  excluded from the session mean.
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
    /// families. Lower depths are banked; ROM short of `romMin` yields
    /// partial credit toward the current depth's slot.
    static func familyPercent(in session: Session,
                              family: CDSkillFamily) -> Double? {
        let logs = session.orderedSetLogs.filter {
            $0.absSkill?.skillFamily == family
        }
        guard let last = logs.last else { return nil }
        let maxDepth = Double(family.maxDepth)
        guard maxDepth > 0 else { return 0 }
        let depth = Double(last.absSkill?.depth ?? 0)
        let romMin = Double(CompletionScorer.romMin)
        let romFraction = romMin > 0
            ? min(1.0, max(0.0, Double(last.rom) / romMin))
            : 0.0
        let achieved = max(0.0, depth - 1.0) + romFraction
        return min(100, (achieved / maxDepth) * 100)
    }

    /// Per-round contribution for a family in this session. Same formula as
    /// `familyPercent`, restricted to logs whose `roundIndex == round`.
    /// `nil` when the family wasn't logged that round.
    static func roundFamilyPercent(in session: Session,
                                   family: CDSkillFamily,
                                   round: Int16) -> Double? {
        let logs = session.orderedSetLogs.filter {
            $0.absSkill?.skillFamily == family && $0.roundIndex == round
        }
        guard let last = logs.last else { return nil }
        let maxDepth = Double(family.maxDepth)
        guard maxDepth > 0 else { return 0 }
        let depth = Double(last.absSkill?.depth ?? 0)
        let romMin = Double(CompletionScorer.romMin)
        let romFraction = romMin > 0
            ? min(1.0, max(0.0, Double(last.rom) / romMin))
            : 0.0
        let achieved = max(0.0, depth - 1.0) + romFraction
        return min(100, (achieved / maxDepth) * 100)
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
