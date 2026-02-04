//
//  TrivitUITests.swift
//  TrivitUITests
//
//  UI Tests for automated screenshot generation
//

import XCTest

final class TrivitUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()

        // Configure app for UI testing with sample data
        app.launchArguments = ["-UITestingMode", "YES", "-SampleDataMode", "YES"]

        // Reset app state for consistent screenshots
        setupSnapshot(app)

        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Screenshot Tests

    func testScreenshots() throws {
        // Wait for app to fully load
        let mainList = app.navigationBars["Trivit"]
        XCTAssertTrue(mainList.waitForExistence(timeout: 5), "Main list should appear")

        // Dismiss tutorial if shown
        dismissTutorialIfNeeded()

        // Take screenshot of main list view
        takeScreenshot(named: "01_MainList")

        // Tap on first trivit to expand it (show tally marks)
        expandFirstTrivit()
        takeScreenshot(named: "02_Expanded")

        // Open settings screen
        openSettings()
        takeScreenshot(named: "03_Settings")
    }

    // MARK: - Individual Screenshot Tests

    func testMainListScreenshot() throws {
        let mainList = app.navigationBars["Trivit"]
        XCTAssertTrue(mainList.waitForExistence(timeout: 5), "Main list should appear")

        dismissTutorialIfNeeded()

        takeScreenshot(named: "01_MainList")
    }

    func testExpandedTrivitScreenshot() throws {
        let mainList = app.navigationBars["Trivit"]
        XCTAssertTrue(mainList.waitForExistence(timeout: 5), "Main list should appear")

        dismissTutorialIfNeeded()
        expandFirstTrivit()

        takeScreenshot(named: "02_Expanded")
    }

    func testSettingsScreenshot() throws {
        let mainList = app.navigationBars["Trivit"]
        XCTAssertTrue(mainList.waitForExistence(timeout: 5), "Main list should appear")

        dismissTutorialIfNeeded()
        openSettings()

        takeScreenshot(named: "03_Settings")
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

    private func takeScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - Snapshot Helper (for fastlane snapshot compatibility)

    private func setupSnapshot(_ app: XCUIApplication) {
        // This method provides compatibility with fastlane snapshot
        // It sets up the app for consistent screenshot generation
        Snapshot.setupSnapshot(app)
    }
}

// MARK: - Snapshot Helper Class

/// Helper class for fastlane snapshot compatibility
/// This provides the setupSnapshot functionality for automated screenshot generation
enum Snapshot {
    static func setupSnapshot(_ app: XCUIApplication) {
        // Add snapshot-specific launch arguments
        app.launchArguments += ["-FASTLANE_SNAPSHOT", "YES"]

        // Disable animations for consistent screenshots
        app.launchArguments += ["-UIAnimationsDisabled", "YES"]

        // Set preferred language if needed (can be configured via scheme)
        if let language = ProcessInfo.processInfo.environment["SNAPSHOT_LANGUAGE"] {
            app.launchArguments += ["-AppleLanguages", "(\(language))"]
            app.launchArguments += ["-AppleLocale", "\"\(language)\""]
        }
    }
}
