//
//  CompletionScorerTests.swift
//  ProgYogTests
//
//  Unit tests for the % completed metric.
//  Technique-keyed continuous: familyPercent =
//      (depth × clamp(rpt/rptMin, 0...1)) / maxDepth × 100.
//      Banked depth levels are scaled by the current technique, not assumed
//      perfect. RPE / RPD are advisory — they do not gate the metric.
//      (ROM was retired 2026-07; technique carries the same signal.)
//

import XCTest
import SetLogKit
import CoreData
@testable import ProgYog

@MainActor
final class CompletionScorerTests: XCTestCase {

    // MARK: - Fixture

    private var services: AppServices!
    private var moc: NSManagedObjectContext { services.coreData.moc }

    override func setUpWithError() throws {
        services = AppServices(inMemory: true)
    }

    override func tearDownWithError() throws {
        services = nil
    }

    /// Builds a family with `depths` (e.g. [1,2,3,4,5]) under workout code `code`.
    private func makeFamily(code: String, name: String, depths: [Int16]) -> CDSkillFamily {
        // Reuse a CDYogSeries per `code` so families share a parent.
        let seriesFR: NSFetchRequest<CDYogSeries> = CDYogSeries.fetchRequest()
        seriesFR.predicate = NSPredicate(format: "name == %@", code)
        let series: CDYogSeries
        if let existing = (try? moc.fetch(seriesFR))?.first {
            series = existing
        } else {
            series = CDYogSeries(context: moc)
            series.name = code
            series.url = URL(string: "https://example.com/series/\(code)")!
        }

        let fam = CDSkillFamily(context: moc)
        fam.name = name
        fam.order = 1
        fam.series = code
        fam.yogSeries = series

        for depth in depths {
            let skill = CDAbsSkill(context: moc)
            skill.name = "\(name) L\(depth)"
            skill.depth = depth
            skill.instructions = ""
            skill.symetrical = false
            skill.timeCode = 0
            skill.family = name
            skill.series = code
            skill.url = URL(string: "https://example.com")!
            skill.skillFamily = fam
        }
        return fam
    }

    private func makeSession(code: String, startedAt: Date = Date()) -> Session {
        let s = Session(workoutCode: code, moc: moc)
        s.startedAt = startedAt
        return s
    }

    /// Append a SetLog to `session` for `skill` at the next orderInRound.
    /// `rpt` (technique, 1–10) drives the score; rptMin defaults to 8, so
    /// rpt ≥ 8 is full credit.
    @discardableResult
    private func addLog(
        _ session: Session,
        skill: CDAbsSkill,
        rpt: Int16 = 8, rpe: Int16 = 6, rpd: Int16 = 1,
        round: Int16 = 0
    ) -> SetLog {
        let log = SetLog(context: moc)
        log.id = UUID()
        log.session = session
        log.absSkill = skill
        log.roundIndex = round
        let existingInRound = session.orderedSetLogs.filter { $0.roundIndex == round }.count
        log.orderInRound = Int16(existingInRound)
        log.reps = 10
        log.rpt = rpt
        log.rpe = rpe
        log.rpd = rpd
        log.durationSec = 60
        log.decision = "repeat"
        log.loggedAt = Date()
        return log
    }

    // MARK: - Qualifying boundaries

    func testFullTechniqueAtTopDepthIsFull() {
        let fam = makeFamily(code: "A", name: "Fam", depths: [1, 2, 3, 4, 5])
        let session = makeSession(code: "A")
        // rpt 8 exactly meets rptMin → full technique fraction.
        addLog(session, skill: fam.orderedAbsSkills.last!, rpt: 8, rpe: 6, rpd: 1)
        XCTAssertEqual(CompletionScorer.familyPercent(in: session, family: fam), 100)
    }

    // Technique below target docks credit proportionally (rpt now DRIVES the
    // score — it is no longer advisory). depth 3/3, rpt 7 → 7/8 × 100 = 87.5.
    func testTechniqueBelowTargetDocksCredit() throws {
        let fam = makeFamily(code: "A", name: "Fam", depths: [1, 2, 3])
        let session = makeSession(code: "A")
        addLog(session, skill: fam.orderedAbsSkills.last!, rpt: 7, rpe: 6, rpd: 1)
        let p = try XCTUnwrap(CompletionScorer.familyPercent(in: session, family: fam))
        XCTAssertEqual(p, (3.0 * (7.0/8.0)) / 3.0 * 100.0, accuracy: 0.0001)
    }

    // RPE and RPD remain advisory: a fail on either with full technique still
    // yields full credit at the logged depth.
    func testRPEFailWithFullTechniqueStillFull() {
        let fam = makeFamily(code: "A", name: "Fam", depths: [1, 2, 3])
        let session = makeSession(code: "A")
        addLog(session, skill: fam.orderedAbsSkills.last!, rpt: 8, rpe: 7, rpd: 1)
        XCTAssertEqual(CompletionScorer.familyPercent(in: session, family: fam), 100)
    }

    func testRPDFailWithFullTechniqueStillFull() {
        let fam = makeFamily(code: "A", name: "Fam", depths: [1, 2, 3])
        let session = makeSession(code: "A")
        addLog(session, skill: fam.orderedAbsSkills.last!, rpt: 8, rpe: 6, rpd: 2)
        XCTAssertEqual(CompletionScorer.familyPercent(in: session, family: fam), 100)
    }

    // MARK: - Family percent uses LAST set

    func testFamilyPercent_UsesLastSetByRoundOrder() {
        let fam = makeFamily(code: "A", name: "Fam", depths: [1, 2, 3, 4, 5])
        let session = makeSession(code: "A")
        // Earlier round: depth-5 — should NOT be used.
        addLog(session, skill: fam.orderedAbsSkills.last!,
               rpt: 10, rpe: 5, rpd: 1, round: 0)
        // Latest round: depth-2 with full technique — IS used. 2/5 = 40.
        let depth2 = fam.orderedAbsSkills.first { $0.depth == 2 }!
        addLog(session, skill: depth2, rpt: 8, rpe: 6, rpd: 1, round: 1)
        XCTAssertEqual(CompletionScorer.familyPercent(in: session, family: fam), 40)
    }

    func testFamilyPercent_DepthOverMaxDepth() {
        // depth 2 / maxDepth 5 == 40%
        let fam = makeFamily(code: "A", name: "Fam", depths: [1, 2, 3, 4, 5])
        let session = makeSession(code: "A")
        let depth2 = fam.orderedAbsSkills.first { $0.depth == 2 }!
        addLog(session, skill: depth2, rpt: 9, rpe: 6, rpd: 1)
        XCTAssertEqual(CompletionScorer.familyPercent(in: session, family: fam) ?? -1, 40, accuracy: 0.0001)
    }

    func testFamilyPercent_NilWhenFamilyNotLogged() {
        let fam = makeFamily(code: "A", name: "Untouched", depths: [1, 2, 3])
        let session = makeSession(code: "A")
        XCTAssertNil(CompletionScorer.familyPercent(in: session, family: fam))
    }

    // MARK: - Session percent

    func testSessionPercent_MeanAcrossFamilies() throws {
        let famA = makeFamily(code: "A", name: "A1", depths: [1, 2, 3, 4, 5])
        let famB = makeFamily(code: "A", name: "B1", depths: [1, 2, 3, 4, 5])
        let famC = makeFamily(code: "A", name: "C1", depths: [1, 2, 3, 4, 5])
        let session = makeSession(code: "A")
        // All full-technique. famA d5 → 100, famB d3 → 60, famC d5 → 100.
        // Mean = 86.6667.
        addLog(session, skill: famA.orderedAbsSkills.last!,
               rpt: 10, rpe: 6, rpd: 1, round: 0)
        addLog(session, skill: famB.orderedAbsSkills.first { $0.depth == 3 }!,
               rpt: 9, rpe: 6, rpd: 1, round: 0)
        addLog(session, skill: famC.orderedAbsSkills.last!,
               rpt: 8, rpe: 6, rpd: 1, round: 0)
        let p = try XCTUnwrap(CompletionScorer.sessionPercent(session))
        XCTAssertEqual(p, (100.0 + 60.0 + 100.0) / 3.0, accuracy: 0.0001)
    }

    func testSessionPercent_EmptySessionIsNil() {
        let session = makeSession(code: "A")
        XCTAssertNil(CompletionScorer.sessionPercent(session))
    }

    // MARK: - All-time best per family

    func testAllTimeBestFamilyPercent_PicksMaxAcrossSessions() throws {
        let fam = makeFamily(code: "A", name: "Fam", depths: [1, 2, 3, 4, 5])
        let depth2 = fam.orderedAbsSkills.first { $0.depth == 2 }!
        let depth4 = fam.orderedAbsSkills.first { $0.depth == 4 }!
        let depth3 = fam.orderedAbsSkills.first { $0.depth == 3 }!

        let s1 = makeSession(code: "A", startedAt: Date(timeIntervalSinceNow: -3000))
        addLog(s1, skill: depth2, rpt: 8, rpe: 6, rpd: 1)   // 40
        let s2 = makeSession(code: "A", startedAt: Date(timeIntervalSinceNow: -2000))
        addLog(s2, skill: depth4, rpt: 8, rpe: 6, rpd: 1)   // 80
        let s3 = makeSession(code: "A", startedAt: Date(timeIntervalSinceNow: -1000))
        addLog(s3, skill: depth3, rpt: 8, rpe: 6, rpd: 1)   // 60

        let best = try XCTUnwrap(CompletionScorer.allTimeBestFamilyPercent(fam))
        XCTAssertEqual(best, 80, accuracy: 0.0001)
    }

    func testAllTimeBestFamilyPercent_NilWhenNeverLogged() {
        let fam = makeFamily(code: "A", name: "Fam", depths: [1, 2, 3])
        XCTAssertNil(CompletionScorer.allTimeBestFamilyPercent(fam))
    }

    // MARK: - Workout-code rollups

    func testLastSessionPercent_UsesMostRecent() throws {
        let fam = makeFamily(code: "A", name: "Fam", depths: [1, 2, 3, 4, 5])
        let depth2 = fam.orderedAbsSkills.first { $0.depth == 2 }!
        let depth5 = fam.orderedAbsSkills.last!

        let older = makeSession(code: "A", startedAt: Date(timeIntervalSinceNow: -1000))
        addLog(older, skill: depth5, rpt: 8, rpe: 6, rpd: 1) // 100
        let newer = makeSession(code: "A", startedAt: Date(timeIntervalSinceNow: -100))
        addLog(newer, skill: depth2, rpt: 8, rpe: 6, rpd: 1) // 40

        try services.coreData.moc.save()

        let last = try XCTUnwrap(CompletionScorer.lastSessionPercent(workoutCode: "A", moc: moc))
        XCTAssertEqual(last, 40, accuracy: 0.0001)
    }

    func testAllTimeBestSessionPercent_TakesMaxAcrossSessions() throws {
        let fam = makeFamily(code: "A", name: "Fam", depths: [1, 2, 3, 4, 5])
        let depth2 = fam.orderedAbsSkills.first { $0.depth == 2 }!
        let depth5 = fam.orderedAbsSkills.last!

        let s1 = makeSession(code: "A", startedAt: Date(timeIntervalSinceNow: -2000))
        addLog(s1, skill: depth2, rpt: 8, rpe: 6, rpd: 1)   // 40
        let s2 = makeSession(code: "A", startedAt: Date(timeIntervalSinceNow: -1000))
        addLog(s2, skill: depth5, rpt: 8, rpe: 6, rpd: 1)   // 100

        try services.coreData.moc.save()

        let best = try XCTUnwrap(CompletionScorer.allTimeBestSessionPercent(workoutCode: "A", moc: moc))
        XCTAssertEqual(best, 100, accuracy: 0.0001)
    }

    func testAllTimeBestSessionPercent_NilWhenNoSessions() {
        XCTAssertNil(CompletionScorer.allTimeBestSessionPercent(workoutCode: "Z", moc: moc))
    }

    // MARK: - Edge

    func testEmptyFamilyMaxDepthZeroReturnsZero() {
        let fam = makeFamily(code: "A", name: "Empty", depths: [])
        let session = makeSession(code: "A")
        // No skills means no logs can exist for the family — familyPercent
        // returns nil because there are no logs. But guard the math path too.
        XCTAssertEqual(fam.maxDepth, 0)
        XCTAssertNil(CompletionScorer.familyPercent(in: session, family: fam))
    }

    // MARK: - Technique-keyed partial credit

    /// Stuck at L1 with partial technique — non-zero credit.
    /// depth 1 / 5, rpt 4 → (1 × 4/8) / 5 × 100 = 10.
    func testFamilyPercent_StuckAtL1_PartialTechnique() throws {
        let fam = makeFamily(code: "A", name: "Fam", depths: [1, 2, 3, 4, 5])
        let session = makeSession(code: "A")
        let depth1 = fam.orderedAbsSkills.first { $0.depth == 1 }!
        addLog(session, skill: depth1, rpt: 4, rpe: 8, rpd: 3)
        let p = try XCTUnwrap(CompletionScorer.familyPercent(in: session, family: fam))
        XCTAssertEqual(p, (4.0 / 8.0) / 5.0 * 100.0, accuracy: 0.0001)
    }

    /// The ONE case that should read 0: depth 1, rpt 0.
    func testFamilyPercent_StuckAtL1_ZeroTechnique() {
        let fam = makeFamily(code: "A", name: "Fam", depths: [1, 2, 3, 4, 5])
        let session = makeSession(code: "A")
        let depth1 = fam.orderedAbsSkills.first { $0.depth == 1 }!
        addLog(session, skill: depth1, rpt: 0, rpe: 6, rpd: 1)
        XCTAssertEqual(CompletionScorer.familyPercent(in: session, family: fam), 0)
    }

    /// rpt = 10, rptMin = 8: raw fraction 1.25 must clamp to 1 so L1's slot
    /// can't overflow into the next depth's slot. depth 1 / 5 → 20.
    func testFamilyPercent_TechniqueAboveThresholdClamps() {
        let fam = makeFamily(code: "A", name: "Fam", depths: [1, 2, 3, 4, 5])
        let session = makeSession(code: "A")
        let depth1 = fam.orderedAbsSkills.first { $0.depth == 1 }!
        addLog(session, skill: depth1, rpt: 10, rpe: 6, rpd: 1)
        XCTAssertEqual(CompletionScorer.familyPercent(in: session, family: fam), 20)
    }

    /// Banked levels scale by the current technique, not assumed perfect.
    /// depth 3 / 5, rpt 6, rptMin 8 → (3 × 6/8) / 5 × 100 = 45.
    func testFamilyPercent_BankedLevelsScaledByCurrentTechnique() throws {
        let fam = makeFamily(code: "A", name: "Fam", depths: [1, 2, 3, 4, 5])
        let session = makeSession(code: "A")
        let depth3 = fam.orderedAbsSkills.first { $0.depth == 3 }!
        addLog(session, skill: depth3, rpt: 6, rpe: 6, rpd: 1)
        let p = try XCTUnwrap(CompletionScorer.familyPercent(in: session, family: fam))
        XCTAssertEqual(p, (3.0 * (6.0/8.0)) / 5.0 * 100.0, accuracy: 0.0001)
    }
}
