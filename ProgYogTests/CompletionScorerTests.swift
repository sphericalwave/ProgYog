//
//  CompletionScorerTests.swift
//  ProgYogTests
//
//  Unit tests for the % completed metric.
//  ROM-keyed continuous: familyPercent =
//      (depth × clamp(rom/romMin, 0...1)) / maxDepth × 100.
//      Banked depth levels are scaled by the current ROM%, not assumed perfect.
//  RPT / RPE / RPD are advisory — they do not gate the metric.
//

import XCTest
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
    @discardableResult
    private func addLog(
        _ session: Session,
        skill: CDAbsSkill,
        rpt: Int16 = 8, rpe: Int16 = 6, rpd: Int16 = 1, rom: Int16 = 100,
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
        log.rom = rom
        log.durationSec = 60
        log.decision = "repeat"
        log.loggedAt = Date()
        return log
    }

    // MARK: - Qualifying boundaries

    func testQualifyingCriteria_BoundaryPasses() {
        let fam = makeFamily(code: "A", name: "Fam", depths: [1, 2, 3, 4, 5])
        let session = makeSession(code: "A")
        // Boundary values exactly meeting the bar
        addLog(session, skill: fam.orderedAbsSkills.last!, rpt: 8, rpe: 6, rpd: 1, rom: 95)
        XCTAssertEqual(CompletionScorer.familyPercent(in: session, family: fam), 100)
    }

    // RPT / RPE / RPD are advisory under the ROM-keyed formula; a fail on
    // any of them with full ROM still yields full credit at the logged depth.
    func testQualifyingCriteria_OneTickOff_RPTFails() {
        let fam = makeFamily(code: "A", name: "Fam", depths: [1, 2, 3])
        let session = makeSession(code: "A")
        addLog(session, skill: fam.orderedAbsSkills.last!, rpt: 7, rpe: 6, rpd: 1, rom: 100)
        XCTAssertEqual(CompletionScorer.familyPercent(in: session, family: fam), 100)
    }

    func testQualifyingCriteria_OneTickOff_RPEFails() {
        let fam = makeFamily(code: "A", name: "Fam", depths: [1, 2, 3])
        let session = makeSession(code: "A")
        addLog(session, skill: fam.orderedAbsSkills.last!, rpt: 8, rpe: 7, rpd: 1, rom: 100)
        XCTAssertEqual(CompletionScorer.familyPercent(in: session, family: fam), 100)
    }

    func testQualifyingCriteria_OneTickOff_RPDFails() {
        let fam = makeFamily(code: "A", name: "Fam", depths: [1, 2, 3])
        let session = makeSession(code: "A")
        addLog(session, skill: fam.orderedAbsSkills.last!, rpt: 8, rpe: 6, rpd: 2, rom: 100)
        XCTAssertEqual(CompletionScorer.familyPercent(in: session, family: fam), 100)
    }

    // ROM under threshold scales credit across ALL banked levels, not just
    // the current slot. depth 3 / 3, rom 94 → (3 × 94/95 / 3) * 100 ≈ 98.95.
    func testQualifyingCriteria_OneTickOff_ROMFails() throws {
        let fam = makeFamily(code: "A", name: "Fam", depths: [1, 2, 3])
        let session = makeSession(code: "A")
        addLog(session, skill: fam.orderedAbsSkills.last!, rpt: 8, rpe: 6, rpd: 1, rom: 94)
        let p = try XCTUnwrap(CompletionScorer.familyPercent(in: session, family: fam))
        XCTAssertEqual(p, (3.0 * (94.0/95.0)) / 3.0 * 100.0, accuracy: 0.0001)
    }

    // MARK: - Family percent uses LAST set

    func testFamilyPercent_UsesLastSetByRoundOrder() {
        let fam = makeFamily(code: "A", name: "Fam", depths: [1, 2, 3, 4, 5])
        let session = makeSession(code: "A")
        // Earlier round: depth-5 — should NOT be used.
        addLog(session, skill: fam.orderedAbsSkills.last!,
               rpt: 10, rpe: 5, rpd: 1, rom: 100, round: 0)
        // Latest round: depth-2 with full ROM — IS used. (1 + 1)/5 = 40.
        let depth2 = fam.orderedAbsSkills.first { $0.depth == 2 }!
        addLog(session, skill: depth2,
               rpt: 5, rpe: 6, rpd: 1, rom: 100, round: 1)
        XCTAssertEqual(CompletionScorer.familyPercent(in: session, family: fam), 40)
    }

    func testFamilyPercent_DepthOverMaxDepth() {
        // depth 2 / maxDepth 5 == 40%
        let fam = makeFamily(code: "A", name: "Fam", depths: [1, 2, 3, 4, 5])
        let session = makeSession(code: "A")
        let depth2 = fam.orderedAbsSkills.first { $0.depth == 2 }!
        addLog(session, skill: depth2, rpt: 9, rpe: 6, rpd: 1, rom: 100)
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
        // All full-ROM. famA d5 → 100, famB d3 → 60, famC d5 (low rpt) → 100.
        // Mean = 86.6667.
        addLog(session, skill: famA.orderedAbsSkills.last!,
               rpt: 10, rpe: 6, rpd: 1, rom: 100, round: 0)
        addLog(session, skill: famB.orderedAbsSkills.first { $0.depth == 3 }!,
               rpt: 9, rpe: 6, rpd: 1, rom: 100, round: 0)
        addLog(session, skill: famC.orderedAbsSkills.last!,
               rpt: 4, rpe: 6, rpd: 1, rom: 100, round: 0)
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
        addLog(s1, skill: depth2, rpt: 8, rpe: 6, rpd: 1, rom: 100)   // 40
        let s2 = makeSession(code: "A", startedAt: Date(timeIntervalSinceNow: -2000))
        addLog(s2, skill: depth4, rpt: 8, rpe: 6, rpd: 1, rom: 100)   // 80
        let s3 = makeSession(code: "A", startedAt: Date(timeIntervalSinceNow: -1000))
        addLog(s3, skill: depth3, rpt: 8, rpe: 6, rpd: 1, rom: 100)   // 60

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
        addLog(older, skill: depth5, rpt: 8, rpe: 6, rpd: 1, rom: 100) // 100
        let newer = makeSession(code: "A", startedAt: Date(timeIntervalSinceNow: -100))
        addLog(newer, skill: depth2, rpt: 8, rpe: 6, rpd: 1, rom: 100) // 40

        try services.coreData.moc.save()

        let last = try XCTUnwrap(CompletionScorer.lastSessionPercent(workoutCode: "A", moc: moc))
        XCTAssertEqual(last, 40, accuracy: 0.0001)
    }

    func testAllTimeBestSessionPercent_TakesMaxAcrossSessions() throws {
        let fam = makeFamily(code: "A", name: "Fam", depths: [1, 2, 3, 4, 5])
        let depth2 = fam.orderedAbsSkills.first { $0.depth == 2 }!
        let depth5 = fam.orderedAbsSkills.last!

        let s1 = makeSession(code: "A", startedAt: Date(timeIntervalSinceNow: -2000))
        addLog(s1, skill: depth2, rpt: 8, rpe: 6, rpd: 1, rom: 100)   // 40
        let s2 = makeSession(code: "A", startedAt: Date(timeIntervalSinceNow: -1000))
        addLog(s2, skill: depth5, rpt: 8, rpe: 6, rpd: 1, rom: 100)   // 100

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

    // MARK: - ROM-keyed partial credit

    /// Stuck at L1 with partial ROM — non-zero credit (the user's
    /// motivating case). RPT/RPE/RPD failing too, but ignored.
    func testFamilyPercent_StuckAtL1_PartialROM() throws {
        let fam = makeFamily(code: "A", name: "Fam", depths: [1, 2, 3, 4, 5])
        let session = makeSession(code: "A")
        let depth1 = fam.orderedAbsSkills.first { $0.depth == 1 }!
        addLog(session, skill: depth1, rpt: 5, rpe: 8, rpd: 3, rom: 50)
        let p = try XCTUnwrap(CompletionScorer.familyPercent(in: session, family: fam))
        XCTAssertEqual(p, (50.0 / 95.0) / 5.0 * 100.0, accuracy: 0.0001)
    }

    /// The ONE case that should still read 0: depth 1, rom 0.
    func testFamilyPercent_StuckAtL1_ZeroROM() {
        let fam = makeFamily(code: "A", name: "Fam", depths: [1, 2, 3, 4, 5])
        let session = makeSession(code: "A")
        let depth1 = fam.orderedAbsSkills.first { $0.depth == 1 }!
        addLog(session, skill: depth1, rpt: 8, rpe: 6, rpd: 1, rom: 0)
        XCTAssertEqual(CompletionScorer.familyPercent(in: session, family: fam), 0)
    }

    /// rom = 100, romMin = 95: raw fraction 1.0526… must clamp to 1 so
    /// L1's slot can't overflow into the next depth's slot.
    func testFamilyPercent_ROMAboveThresholdClamps() {
        let fam = makeFamily(code: "A", name: "Fam", depths: [1, 2, 3, 4, 5])
        let session = makeSession(code: "A")
        let depth1 = fam.orderedAbsSkills.first { $0.depth == 1 }!
        addLog(session, skill: depth1, rpt: 8, rpe: 6, rpd: 1, rom: 100)
        XCTAssertEqual(CompletionScorer.familyPercent(in: session, family: fam), 20)
    }

    /// Banked levels scale by the current ROM%, not assumed perfect (the
    /// motivating case for the formula change). depth 3 / 5, rom 80,
    /// romMin 95 → (3 × 80/95 / 5) * 100 ≈ 50.53, well below the old
    /// formula's (2 + 80/95)/5*100 ≈ 56.84.
    func testFamilyPercent_BankedLevelsScaledByCurrentROM() throws {
        let fam = makeFamily(code: "A", name: "Fam", depths: [1, 2, 3, 4, 5])
        let session = makeSession(code: "A")
        let depth3 = fam.orderedAbsSkills.first { $0.depth == 3 }!
        addLog(session, skill: depth3, rpt: 8, rpe: 6, rpd: 1, rom: 80)
        let p = try XCTUnwrap(CompletionScorer.familyPercent(in: session, family: fam))
        XCTAssertEqual(p, (3.0 * (80.0/95.0)) / 5.0 * 100.0, accuracy: 0.0001)
    }

    /// Full ROM at top depth — RPT/RPE/RPD failures don't dock the metric.
    func testFamilyPercent_RPTFailWithFullROM_StillFullCredit() {
        let fam = makeFamily(code: "A", name: "Fam", depths: [1, 2, 3, 4, 5])
        let session = makeSession(code: "A")
        addLog(session, skill: fam.orderedAbsSkills.last!,
               rpt: 1, rpe: 10, rpd: 5, rom: 100)
        XCTAssertEqual(CompletionScorer.familyPercent(in: session, family: fam), 100)
    }
}
