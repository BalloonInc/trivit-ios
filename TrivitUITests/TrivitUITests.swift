//
//  TrivitUITests.swift
//  TrivitUITests
//
//  UI Tests for automated screenshot generation using fastlane snapshot
//

import XCTest

@MainActor
final class TrivitUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()

        // Configure app for UI testing with sample data
        app.launchArguments = ["-UITestingMode", "YES", "-SampleDataMode", "YES"]

        // Setup fastlane snapshot
        setupSnapshot(app)

        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Screenshot Tests

    func testScreenshot01_MainList() throws {
        // Wait for app to fully load
        let mainList = app.navigationBars["Trivit"]
        XCTAssertTrue(mainList.waitForExistence(timeout: 5), "Main list should appear")

        // Dismiss tutorial if shown
        dismissTutorialIfNeeded()

        // Wait for list to settle
        Thread.sleep(forTimeInterval: 1)

        // Take screenshot of main list view
        snapshot("01_MainList")
    }

    func testScreenshot02_ExpandedTrivit() throws {
        let mainList = app.navigationBars["Trivit"]
        XCTAssertTrue(mainList.waitForExistence(timeout: 5), "Main list should appear")

        dismissTutorialIfNeeded()
        expandFirstTrivit()

        snapshot("02_ExpandedTrivit")
    }

    func testScreenshot03_Statistics() throws {
        let mainList = app.navigationBars["Trivit"]
        XCTAssertTrue(mainList.waitForExistence(timeout: 5), "Main list should appear")

        dismissTutorialIfNeeded()
        Thread.sleep(forTimeInterval: 0.5)

        // Long-press the first trivit title to trigger context menu
        let firstTitle = app.staticTexts["Glasses of water"]
        XCTAssertTrue(firstTitle.waitForExistence(timeout: 3), "First trivit title should exist")
        firstTitle.press(forDuration: 1.5)

        // Tap Statistics in context menu
        let statisticsButton = app.buttons["Statistics"]
        XCTAssertTrue(statisticsButton.waitForExistence(timeout: 5), "Statistics menu item should appear")
        statisticsButton.tap()

        // Wait for Statistics sheet to appear
        Thread.sleep(forTimeInterval: 1.0)

        snapshot("03_Statistics")
    }

    func testScreenshot04_Settings() throws {
        let mainList = app.navigationBars["Trivit"]
        XCTAssertTrue(mainList.waitForExistence(timeout: 5), "Main list should appear")

        dismissTutorialIfNeeded()
        openSettings()

        snapshot("04_Settings")
    }

    // MARK: - Helper Methods

    private func dismissTutorialIfNeeded() {
        // Look for the "Got it" button in the tutorial overlay
        let gotItButton = app.buttons["Got it"]
        if gotItButton.waitForExistence(timeout: 2) {
            gotItButton.tap()
            // Wait for animation to complete
            Thread.sleep(forTimeInterval: 0.5)
        }
    }

    private func expandFirstTrivit() {
        // Wait a moment for the list to settle
        Thread.sleep(forTimeInterval: 0.3)

        // Find and tap the first trivit row to expand it
        let firstCell = app.scrollViews.firstMatch.otherElements.firstMatch
        if firstCell.exists {
            firstCell.tap()
            // Wait for expansion animation
            Thread.sleep(forTimeInterval: 0.5)
        }
    }

    private func openSettings() {
        // Tap the settings button (gear icon) in the navigation bar
        let settingsButton = app.navigationBars["Trivit"].buttons["gearshape"]
        if settingsButton.exists {
            settingsButton.tap()
        } else {
            // Fallback: try finding any button in leading position
            let navBar = app.navigationBars["Trivit"]
            navBar.buttons.firstMatch.tap()
        }

        // Wait for settings sheet to appear
        let settingsNavBar = app.navigationBars["Settings"]
        _ = settingsNavBar.waitForExistence(timeout: 3)
        Thread.sleep(forTimeInterval: 0.5)
    }
}
