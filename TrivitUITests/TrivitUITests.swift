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

    func testScreenshot03_Settings() throws {
        let mainList = app.navigationBars["Trivit"]
        XCTAssertTrue(mainList.waitForExistence(timeout: 5), "Main list should appear")

        dismissTutorialIfNeeded()
        openSettings()

        snapshot("03_Settings")
    }

    func testScreenshot04_Statistics() throws {
        let mainList = app.navigationBars["Trivit"]
        XCTAssertTrue(mainList.waitForExistence(timeout: 5), "Main list should appear")

        dismissTutorialIfNeeded()
        openSettings()

        // Navigate to Statistics from Settings
        let statisticsButton = app.buttons["Statistics"]
        if statisticsButton.waitForExistence(timeout: 3) {
            statisticsButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
            snapshot("04_Statistics")
        }
    }

    func testScreenshot05_History() throws {
        let mainList = app.navigationBars["Trivit"]
        XCTAssertTrue(mainList.waitForExistence(timeout: 5), "Main list should appear")

        dismissTutorialIfNeeded()
        openSettings()

        // Navigate to History from Settings
        let historyButton = app.buttons["History"]
        if historyButton.waitForExistence(timeout: 3) {
            historyButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
            snapshot("05_History")
        }
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
        // The trivit rows are in a ScrollView with LazyVStack
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
