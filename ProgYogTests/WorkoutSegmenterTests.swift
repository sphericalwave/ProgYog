//
//  WorkoutSegmenterTests.swift
//  ProgYogTests
//

import XCTest
import CoreData
@testable import ProgYog

@MainActor
final class WorkoutSegmenterTests: XCTestCase {

    private var services: AppServices!
    private var moc: NSManagedObjectContext { services.coreData.moc }
    private let t0 = Date(timeIntervalSince1970: 1_700_000_000)
    private let dur: Int16 = 60

    override func setUpWithError() throws {
        services = AppServices(inMemory: true)
    }

    override func tearDownWithError() throws {
        services = nil
    }

    @discardableResult
    private func addLog(_ session: Session, at offset: TimeInterval, round: Int16 = 0) -> SetLog {
        let log = SetLog(context: moc)
        log.id = UUID()
        log.session = session
        log.roundIndex = round
        log.orderInRound = Int16(session.orderedSetLogs.filter { $0.roundIndex == round }.count)
        log.durationSec = dur
        log.decision = "repeat"
        log.loggedAt = t0.addingTimeInterval(offset)
        return log
    }

    private func makeSession() -> Session { Session(workoutCode: "X", moc: moc) }

    func testEmptySession() {
        XCTAssertEqual(WorkoutSegmenter.segments(of: makeSession()).count, 0)
    }

    func testSingleSet() {
        let s = makeSession()
        addLog(s, at: 0)
        let segs = WorkoutSegmenter.segments(of: s)
        XCTAssertEqual(segs.count, 1)
        XCTAssertEqual(segs[0].index, 0)
        XCTAssertEqual(segs[0].startedAt, t0.addingTimeInterval(-TimeInterval(dur)))
        XCTAssertEqual(segs[0].endedAt, t0)
        XCTAssertEqual(segs[0].setLogs.count, 1)
    }

    func testTwoSetsWithinGap() {
        let s = makeSession()
        addLog(s, at: 0)
        addLog(s, at: 5 * 60) // 5 min apart, under 10 min threshold
        let segs = WorkoutSegmenter.segments(of: s)
        XCTAssertEqual(segs.count, 1)
        XCTAssertEqual(segs[0].setLogs.count, 2)
        XCTAssertEqual(segs[0].endedAt, t0.addingTimeInterval(5 * 60))
    }

    func testTwoSetsPastGap() {
        let s = makeSession()
        addLog(s, at: 0)
        addLog(s, at: 15 * 60) // well past 10 min
        let segs = WorkoutSegmenter.segments(of: s)
        XCTAssertEqual(segs.count, 2)
        XCTAssertEqual(segs[0].endedAt, t0)
        XCTAssertEqual(segs[1].index, 1)
        XCTAssertEqual(segs[1].startedAt, t0.addingTimeInterval(15 * 60 - TimeInterval(dur)))
    }

    /// `loggedAt` exactly 10 min apart → gap is `>= 10*60`, so new segment.
    func testGapBoundaryExactlyTenMinutesSplits() {
        let s = makeSession()
        addLog(s, at: 0)
        addLog(s, at: 10 * 60)
        XCTAssertEqual(WorkoutSegmenter.segments(of: s).count, 2)
    }

    /// Sets logged out of round/order but in chronological `loggedAt` should
    /// still cluster correctly — segmenter sorts by `loggedAt`, not round.
    func testNonChronologicalRoundOrder() {
        let s = makeSession()
        // Round 1 set logged FIRST (e.g. earlier in the day)
        addLog(s, at: 0, round: 1)
        // Then a round-0 set logged LATER but within gap
        addLog(s, at: 2 * 60, round: 0)
        // Then a gap, then another set
        addLog(s, at: 30 * 60, round: 1)
        let segs = WorkoutSegmenter.segments(of: s)
        XCTAssertEqual(segs.count, 2)
        XCTAssertEqual(segs[0].setLogs.count, 2)
        XCTAssertEqual(segs[1].setLogs.count, 1)
    }

    func testThreeSegments() {
        let s = makeSession()
        addLog(s, at: 0)
        addLog(s, at: 20 * 60)
        addLog(s, at: 60 * 60)
        let segs = WorkoutSegmenter.segments(of: s)
        XCTAssertEqual(segs.count, 3)
        XCTAssertEqual(segs.map(\.index), [0, 1, 2])
    }
}
