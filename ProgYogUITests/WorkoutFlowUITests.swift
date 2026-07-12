//
//  WorkoutFlowUITests.swift
//  ProgYogUITests
//

import XCTest

final class WorkoutFlowUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Runs through a full mock workout (1 exercise × 5 rounds = 5 sets —
    /// totalRounds is hardcoded in WorkoutSessionViewModel, so this is the
    /// minimum reachable) and confirms the Summary screen appears at the end.
    ///
    /// Uses -UI-TESTING-MOCK-WORKOUT (see CoreDataService.seedMockWorkout)
    /// on top of -UI-TESTING's in-memory store, so this never touches the
    /// real on-disk, CloudKit-backed dev database — the mock workout ("A")
    /// exists only in that throwaway in-memory container and is seeded fresh
    /// on every launch, replacing the full real catalog rather than adding
    /// to it.
    @MainActor
    func testRunThroughMockWorkout_showsSummary() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UI-TESTING", "-UI-TESTING-MOCK-WORKOUT"]
        app.launch()

        let workoutRow = app.staticTexts["progYog A"]
        XCTAssertTrue(workoutRow.waitForExistence(timeout: 5), "Mock workout row should appear in the Workouts list")
        workoutRow.tap()

        let startButton = app.buttons["Start"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        let playButton = app.buttons["workoutSession.play"]
        let skipButton = app.buttons["workoutSession.skip"]
        let saveButton = app.buttons["ratedSetForm.save"]

        // 1 mock exercise × totalRounds (hardcoded to 5 in WorkoutSessionViewModel).
        let totalSets = 1 * 5
        for setNumber in 1...totalSets {
            XCTAssertTrue(playButton.waitForExistence(timeout: 5), "Play button missing before set \(setNumber)")
            playButton.tap()

            XCTAssertTrue(skipButton.waitForExistence(timeout: 5), "Skip button missing before set \(setNumber)")
            skipButton.tap()

            XCTAssertTrue(saveButton.waitForExistence(timeout: 5), "Save button missing before set \(setNumber)")
            saveButton.tap()
        }

        let summaryNavBar = app.navigationBars["Summary"]
        XCTAssertTrue(summaryNavBar.waitForExistence(timeout: 5), "Workout summary screen should appear after the final set")
    }
}
