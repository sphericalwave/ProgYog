//
//  WorkoutStatsCacheTests.swift
//  ProgYogTests
//
//  The launch-time cache round-trips the stats snapshot through JSON.
//  FamilyPercentChart.Point has custom Codable (barColor is excluded and
//  recomputed from `series`, since Color isn't Codable) — this is the
//  specific thing worth pinning down here, not the aggregation math
//  itself (already covered elsewhere).
//

import XCTest
import SwiftUI
@testable import ProgYog

final class WorkoutStatsCacheTests: XCTestCase {

    func testSnapshotRoundTripsThroughJSON() throws {
        let point = FamilyPercentChart.Point(percent: 42, barColor: .red, series: "A")
        let original = WorkoutStatsSnapshot(
            dashboard: DashboardSnapshot(
                completion: [CompletionPoint(id: "A", code: "A", last: 80, best: 95)],
                weekly: [VolumePoint(bucketStart: Date(timeIntervalSince1970: 0), count: 3)],
                monthly: [],
                total: [TimePoint(id: "A", code: "A", minutes: 45)],
                avg: [],
                hasSessions: true
            ),
            workoutList: WorkoutListSnapshot(
                historyPoints: [point],
                rocPoints: [],
                lastPercentByCode: ["A": 80],
                bestPercentByCode: ["A": 95],
                sessionCountByCode: ["A": 3],
                lastDateByCode: ["A": Date(timeIntervalSince1970: 0)],
                orderedCodes: ["A", "B"]
            )
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WorkoutStatsSnapshot.self, from: data)

        XCTAssertEqual(decoded.dashboard.hasSessions, true)
        XCTAssertEqual(decoded.dashboard.completion.first?.last, 80)
        XCTAssertEqual(decoded.workoutList.orderedCodes, ["A", "B"])
        XCTAssertEqual(decoded.workoutList.lastPercentByCode["A"], 80)
    }

    func testPointBarColorIsRecomputedFromSeriesNotSerialized() throws {
        let point = FamilyPercentChart.Point(percent: 10, barColor: .red, series: "A")
        let data = try JSONEncoder().encode(point)

        // barColor must not appear in the wire format at all.
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertFalse(json.contains("barColor"))

        let decoded = try JSONDecoder().decode(FamilyPercentChart.Point.self, from: data)
        XCTAssertEqual(decoded.percent, 10)
        XCTAssertEqual(decoded.series, "A")
        XCTAssertEqual(decoded.barColor, WorkoutPalette.color(for: "A"))
    }

    func testEmptySnapshotRoundTrips() throws {
        let data = try JSONEncoder().encode(WorkoutStatsSnapshot.empty)
        let decoded = try JSONDecoder().decode(WorkoutStatsSnapshot.self, from: data)
        XCTAssertFalse(decoded.dashboard.hasSessions)
        XCTAssertTrue(decoded.workoutList.lastPercentByCode.isEmpty)
    }
}
