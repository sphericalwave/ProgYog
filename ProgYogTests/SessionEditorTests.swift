//
//  SessionEditorTests.swift
//  ProgYogTests
//

import XCTest
import CoreData
@testable import ProgYog

@MainActor
final class SessionEditorTests: XCTestCase {

    private var services: AppServices!
    private var moc: NSManagedObjectContext { services.coreData.moc }

    override func setUpWithError() throws {
        services = AppServices(inMemory: true)
    }

    override func tearDownWithError() throws { services = nil }

    private func makeSession(start: Date, end: Date?) -> Session {
        let s = Session(workoutCode: "A", moc: moc)
        s.startedAt = start
        s.endedAt = end
        return s
    }

    // MARK: - shiftStart

    func test_shiftStart_preservesDurationWhenEndSet() {
        let start = Date(timeIntervalSince1970: 1_000_000)
        let end = start.addingTimeInterval(3600)             // 1h duration
        let s = makeSession(start: start, end: end)

        let newStart = start.addingTimeInterval(-7200)        // 2h earlier
        SessionEditor.shiftStart(s, to: newStart)

        XCTAssertEqual(s.startedAt, newStart)
        XCTAssertEqual(s.endedAt, newStart.addingTimeInterval(3600))
    }

    func test_shiftStart_endedNilStaysNil() {
        let start = Date(timeIntervalSince1970: 1_000_000)
        let s = makeSession(start: start, end: nil)

        SessionEditor.shiftStart(s, to: start.addingTimeInterval(600))

        XCTAssertEqual(s.startedAt, start.addingTimeInterval(600))
        XCTAssertNil(s.endedAt)
    }

    // MARK: - setEnd

    func test_setEnd_clampsToStartedAt() {
        let start = Date(timeIntervalSince1970: 2_000_000)
        let s = makeSession(start: start, end: start.addingTimeInterval(60))

        // Try to push end BEFORE start
        SessionEditor.setEnd(s, to: start.addingTimeInterval(-500))

        XCTAssertEqual(s.endedAt, start)
    }

    func test_setEnd_acceptsLaterValue() {
        let start = Date(timeIntervalSince1970: 2_000_000)
        let s = makeSession(start: start, end: start.addingTimeInterval(60))

        let newEnd = start.addingTimeInterval(7200)
        SessionEditor.setEnd(s, to: newEnd)

        XCTAssertEqual(s.endedAt, newEnd)
    }

    // MARK: - setCompleted

    func test_setCompleted_onSetsEndedAtToAtLeastStarted() {
        // startedAt is in the FUTURE; max(now, startedAt) == startedAt.
        let future = Date(timeIntervalSinceNow: 86_400)
        let s = makeSession(start: future, end: nil)

        SessionEditor.setCompleted(s, true)

        XCTAssertEqual(s.endedAt, future)
    }

    func test_setCompleted_onWithPastStartUsesNow() {
        let past = Date(timeIntervalSinceNow: -86_400)
        let s = makeSession(start: past, end: nil)

        let beforeCall = Date()
        SessionEditor.setCompleted(s, true)
        let afterCall = Date()

        let end = try! XCTUnwrap(s.endedAt)
        XCTAssertGreaterThanOrEqual(end, beforeCall)
        XCTAssertLessThanOrEqual(end, afterCall)
    }

    func test_setCompleted_offClearsEndedAt() {
        let start = Date(timeIntervalSinceNow: -3600)
        let s = makeSession(start: start, end: Date())

        SessionEditor.setCompleted(s, false)

        XCTAssertNil(s.endedAt)
    }
}
