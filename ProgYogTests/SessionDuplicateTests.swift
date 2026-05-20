//
//  SessionDuplicateTests.swift
//  ProgYogTests
//

import XCTest
import CoreData
@testable import ProgYog

@MainActor
final class SessionDuplicateTests: XCTestCase {

    private var services: AppServices!
    private var moc: NSManagedObjectContext { services.coreData.moc }

    override func setUpWithError() throws {
        services = AppServices(inMemory: true)
    }

    override func tearDownWithError() throws { services = nil }

    // MARK: - Fixture

    private func makeFamilyAndSkill() -> CDAbsSkill {
        let series = CDYogSeries(context: moc)
        series.name = "A"
        series.url = URL(string: "https://example.com/series/A")!

        let fam = CDSkillFamily(context: moc)
        fam.name = "Fam"
        fam.order = 1
        fam.series = "A"
        fam.yogSeries = series

        let skill = CDAbsSkill(context: moc)
        skill.name = "Fam L1"
        skill.depth = 1
        skill.instructions = ""
        skill.symetrical = false
        skill.timeCode = 0
        skill.family = "Fam"
        skill.series = "A"
        skill.url = URL(string: "https://example.com")!
        skill.skillFamily = fam
        return skill
    }

    private func makeSession(skill: CDAbsSkill, completed: Bool) -> Session {
        let s = Session(workoutCode: "A", moc: moc)
        if completed { s.endedAt = Date() }
        s.notes = "src notes"

        for i in 0..<3 {
            let log = SetLog(context: moc)
            log.id = UUID()
            log.session = s
            log.absSkill = skill
            log.roundIndex = Int16(i / 3)
            log.orderInRound = Int16(i % 3)
            log.reps = Int16(10 + i)
            log.rom = 90
            log.rpt = 8
            log.rpe = 6
            log.rpd = 1
            log.notes = i == 2 ? "third" : nil
            log.durationSec = 60
            log.decision = "repeat"
            log.loggedAt = Date(timeIntervalSinceNow: TimeInterval(i))
            log.hrAvg = 120
            log.hrMin = 100
            log.hrMax = 140

            if i == 2 {
                for k in 0..<5 {
                    let sample = HRSample(context: moc)
                    sample.t = Double(k)
                    sample.bpm = Int16(120 + k)
                    sample.setLog = log
                }
            }
        }
        return s
    }

    // MARK: - Tests

    func test_duplicateSession_newUUIDs() throws {
        let skill = makeFamilyAndSkill()
        let src = makeSession(skill: skill, completed: true)
        let dup = services.coreData.duplicateSession(src)
        XCTAssertNotEqual(dup.id, src.id)
        let srcIDs = Set(src.orderedSetLogs.map { $0.id })
        let dupIDs = Set(dup.orderedSetLogs.map { $0.id })
        XCTAssertTrue(srcIDs.isDisjoint(with: dupIDs))
    }

    func test_duplicateSession_setCountMatches() {
        let skill = makeFamilyAndSkill()
        let src = makeSession(skill: skill, completed: true)
        let dup = services.coreData.duplicateSession(src)
        XCTAssertEqual(dup.orderedSetLogs.count, src.orderedSetLogs.count)
    }

    func test_duplicateSession_preservesFieldValues() {
        let skill = makeFamilyAndSkill()
        let src = makeSession(skill: skill, completed: true)
        let dup = services.coreData.duplicateSession(src)
        for (s, d) in zip(src.orderedSetLogs, dup.orderedSetLogs) {
            XCTAssertEqual(s.roundIndex, d.roundIndex)
            XCTAssertEqual(s.orderInRound, d.orderInRound)
            XCTAssertEqual(s.reps, d.reps)
            XCTAssertEqual(s.rom, d.rom)
            XCTAssertEqual(s.rpt, d.rpt)
            XCTAssertEqual(s.rpe, d.rpe)
            XCTAssertEqual(s.rpd, d.rpd)
            XCTAssertEqual(s.notes, d.notes)
            XCTAssertEqual(s.decision, d.decision)
            XCTAssertEqual(s.loggedAt, d.loggedAt)
        }
    }

    func test_duplicateSession_copiesHRSamples() {
        let skill = makeFamilyAndSkill()
        let src = makeSession(skill: skill, completed: true)
        let dup = services.coreData.duplicateSession(src)
        // Third source log has 5 HRSamples.
        let srcLast = src.orderedSetLogs.last!
        let dupLast = dup.orderedSetLogs.last!
        XCTAssertEqual(srcLast.orderedHRSamples.count, 5)
        XCTAssertEqual(dupLast.orderedHRSamples.count, 5)
        for (a, b) in zip(srcLast.orderedHRSamples, dupLast.orderedHRSamples) {
            XCTAssertEqual(a.t, b.t)
            XCTAssertEqual(a.bpm, b.bpm)
        }
    }

    func test_duplicateSession_relinksSameAbsSkill() {
        let skill = makeFamilyAndSkill()
        let src = makeSession(skill: skill, completed: true)
        let dup = services.coreData.duplicateSession(src)
        for d in dup.orderedSetLogs {
            XCTAssertTrue(d.absSkill === skill)
        }
    }

    func test_duplicateSession_startedAtIsNewerThanSource() {
        let skill = makeFamilyAndSkill()
        let src = makeSession(skill: skill, completed: true)
        // Force source startedAt into the past.
        src.startedAt = Date(timeIntervalSinceNow: -3600)
        let dup = services.coreData.duplicateSession(src)
        XCTAssertGreaterThan(dup.startedAt, src.startedAt)
    }

    func test_duplicateSession_preservesInProgressFlavor() {
        let skill = makeFamilyAndSkill()
        let src = makeSession(skill: skill, completed: false)
        let dup = services.coreData.duplicateSession(src)
        XCTAssertNil(dup.endedAt)
    }
}
