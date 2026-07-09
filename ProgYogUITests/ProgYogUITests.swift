//
//  ProgYogUITests.swift
//  ProgYogUITests
//

import XCTest

final class ProgYogUITests: XCTestCase {

    override func setUpWithError() throws {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    @MainActor
    func testExample() throws {
        // In-memory store (see ProgYogApp.swift) — never touches the real
        // on-disk, CloudKit-backed database.
        let app = XCUIApplication()
        app.launchArguments = ["-UI-TESTING"]
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launchArguments = ["-UI-TESTING"]
            app.launch()
        }
    }
}
