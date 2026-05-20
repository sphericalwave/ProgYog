//
//  SessionRecoveryTests.swift
//  ProgYogTests
//
//  Round-trip: snapshot → delete → restore must reproduce the session
//  field-for-field including child relationships.
//

import XCTest
import CoreData
@testable import ProgYog

@MainActor
final class SessionRecoveryTests: XCTestCase {

    private var services: AppServices!
    private var moc: NSManagedObjectContext { services.coreData.moc }

    override func setUpWithError() throws {
        services = AppServices(inMemory: true)
    }

    override func tearDownWithError() throws { services = nil }

    private func makeSkill() -> CDAbsSkill {
        let series = CDYogSeries(context: moc)
        series.name = "A"
        series.url = URL(string: "https://example.com/series/A")!
        let fam = CDSkillFamily(context: moc)
        fam.name = "Fam"
        fam.order = 1
        fam.series = "A"
        fam.yogSeries = series
        let skill = CDAbsSkill(context: moc)
        skill.name = "L1"
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

    func test_snapshotDeleteRestore_roundTrip() throws {
        let skill = makeSkill()
        let s = Session(workoutCode: "A", moc: moc)
        s.endedAt = Date(timeIntervalSinceNow: -100)
        s.notes = "original"

        let originalID = s.id
        let originalStarted = s.startedAt

        for i in 0..<3 {
            let log = SetLog(context: moc)
            log.id = UUID()
            log.session = s
            log.absSkill = skill
            log.roundIndex = 0
            log.orderInRound = Int16(i)
            log.reps = Int16(10 + i)
            log.rom = 95
            log.rpt = 9
            log.rpe = 5
            log.rpd = 1
            log.notes = i == 1 ? "middle" : nil
            log.durationSec = 60
            log.decision = "repeat"
            log.loggedAt = Date(timeIntervalSinceNow: TimeInterval(i))
            log.hrAvg = 130
            if i == 2 {
                for k in 0..<4 {
                    let sample = HRSample(context: moc)
                    sample.t = Double(k) * 0.5
                    sample.bpm = Int16(140 + k)
                    sample.setLog = log
                }
            }
        }
        try moc.save()

        let snap = SessionRecovery.snapshot(s)
        moc.delete(s)
        try moc.save()

        // Confirm gone.
        let fr: NSFetchRequest<Session> = Session.fetchRequest()
        fr.predicate = NSPredicate(format: "id == %@", originalID as CVarArg)
        XCTAssertTrue((try moc.fetch(fr)).isEmpty)

        // Restore.
        let restored = SessionRecovery.restore(snap, into: moc)
        try moc.save()

        XCTAssertEqual(restored.id, originalID)
        XCTAssertEqual(restored.startedAt, originalStarted)
        XCTAssertEqual(restored.notes, "original")
        XCTAssertEqual(restored.workoutCode, "A")
        XCTAssertEqual(restored.orderedSetLogs.count, 3)

        let last = restored.orderedSetLogs.last!
        XCTAssertEqual(last.reps, 12)
        XCTAssertEqual(last.orderedHRSamples.count, 4)
        XCTAssertEqual(last.orderedHRSamples.first?.t, 0)
        XCTAssertEqual(last.orderedHRSamples.last?.bpm, 143)
        XCTAssertTrue(last.absSkill === skill)
    }
}
