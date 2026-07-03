//
//  WorkoutSegmenterTests.swift
//  ProgYogTests
//

import XCTest
import SetLogKit
import CoreData
@testable import ProgYog

@MainActor
final class WorkoutSegmenterTests: XCTestCase {

    private var services: AppServices!
    private var moc: NSManagedObjectContext { services.coreData.moc }
    /// Local-TZ noon, far from any DST edge.
    private let day0: Date = {
        var c = DateComponents()
        c.year = 2026; c.month = 5; c.day = 24; c.hour = 12
        return Calendar.current.date(from: c)!
    }()
    private let dur: Int16 = 60

    override func setUpWithError() throws {
        services = AppServices(inMemory: true)
    }

    override func tearDownWithError() throws {
        services = nil
    }

    @discardableResult
    private func addLog(_ session: Session, at date: Date, round: Int16 = 0) -> SetLog {
        let log = SetLog(context: moc)
        log.id = UUID()
        log.session = session
        log.roundIndex = round
        log.orderInRound = Int16(session.orderedSetLogs.filter { $0.roundIndex == round }.count)
        log.durationSec = dur
        log.decision = "repeat"
        log.loggedAt = date
        return log
    }

    private func makeSession() -> Session { Session(workoutCode: "X", moc: moc) }

    func testEmptySession() {
        XCTAssertEqual(WorkoutSegmenter.segments(of: makeSession()).count, 0)
    }

    func testSingleSet() {
        let s = makeSession()
        addLog(s, at: day0)
        let segs = WorkoutSegmenter.segments(of: s)
        XCTAssertEqual(segs.count, 1)
        XCTAssertEqual(segs[0].index, 0)
        XCTAssertEqual(segs[0].dayStart, Calendar.current.startOfDay(for: day0))
        XCTAssertEqual(segs[0].startedAt, day0.addingTimeInterval(-TimeInterval(dur)))
        XCTAssertEqual(segs[0].endedAt, day0)
    }

    /// Two sets on the same calendar day, hours apart → one segment.
    func testTwoSetsSameDayHoursApart() {
        let s = makeSession()
        addLog(s, at: day0)                                  // noon
        addLog(s, at: day0.addingTimeInterval(6 * 60 * 60))  // 6pm
        let segs = WorkoutSegmenter.segments(of: s)
        XCTAssertEqual(segs.count, 1)
        XCTAssertEqual(segs[0].setLogs.count, 2)
        // Active duration (sum of set durations), not wall-clock: the segment
        // starts dur before the first set and spans 2 × dur.
        XCTAssertEqual(segs[0].endedAt, day0.addingTimeInterval(TimeInterval(dur)))
    }

    /// Sets on different local-TZ days → one segment per day.
    func testTwoSetsDifferentDays() {
        let s = makeSession()
        addLog(s, at: day0)
        addLog(s, at: day0.addingTimeInterval(24 * 60 * 60))
        let segs = WorkoutSegmenter.segments(of: s)
        XCTAssertEqual(segs.count, 2)
        XCTAssertEqual(segs[0].index, 0)
        XCTAssertEqual(segs[1].index, 1)
        XCTAssertEqual(segs[0].setLogs.count, 1)
        XCTAssertEqual(segs[1].setLogs.count, 1)
    }

    func testThreeSetsAcrossTwoDays() {
        let s = makeSession()
        addLog(s, at: day0)                                  // day A
        addLog(s, at: day0.addingTimeInterval(60 * 60))      // day A, 1h later
        addLog(s, at: day0.addingTimeInterval(25 * 60 * 60)) // day B
        let segs = WorkoutSegmenter.segments(of: s)
        XCTAssertEqual(segs.count, 2)
        XCTAssertEqual(segs[0].setLogs.count, 2)
        XCTAssertEqual(segs[1].setLogs.count, 1)
        // Active duration, not wall-clock (see testTwoSetsSameDayHoursApart).
        XCTAssertEqual(segs[0].endedAt, day0.addingTimeInterval(TimeInterval(dur)))
    }

    /// Late-night + early-morning across midnight → two segments.
    func testMidnightCrossingSplits() {
        let s = makeSession()
        let cal = Calendar.current
        let lateNight = cal.date(bySettingHour: 23, minute: 50, second: 0, of: day0)!
        let earlyMorning = cal.date(byAdding: .minute, value: 20, to: lateNight)!
        addLog(s, at: lateNight)
        addLog(s, at: earlyMorning)
        let segs = WorkoutSegmenter.segments(of: s)
        XCTAssertEqual(segs.count, 2)
        XCTAssertEqual(segs[0].endedAt, lateNight)
        XCTAssertEqual(segs[1].startedAt, earlyMorning.addingTimeInterval(-TimeInterval(dur)))
    }
}
