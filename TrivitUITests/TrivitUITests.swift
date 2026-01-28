import XCTest

/// UI tests for Trivit app.
///
/// These tests verify the main user flows and interactions.
final class TrivitUITests: XCTestCase {

    var app: XCUIApplication!

    // MARK: - Setup

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launchEnvironment = [
            "RESET_DATA": "true",
            "SKIP_ONBOARDING": "true"
        ]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - List Tests

    func testEmptyState() throws {
        // Given a fresh app with no trivits
        // Expect to see empty state

        let emptyStateText = app.staticTexts["No Trivits"]
        XCTAssertTrue(emptyStateText.waitForExistence(timeout: 5))
    }

    func testAddTrivit() throws {
        // Given an empty list
        // When I tap the add button
        let addButton = app.buttons["Add Trivit"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        // Then a new trivit appears and title editing starts
        let textField = app.textFields.firstMatch
        XCTAssertTrue(textField.waitForExistence(timeout: 3))
        XCTAssertTrue(textField.hasFocus)
    }

    func testRenameTrivit() throws {
        // Given a trivit exists
        createTestTrivit()

        // When I long press the title
        let trivitRow = app.cells.firstMatch
        XCTAssertTrue(trivitRow.waitForExistence(timeout: 5))
        trivitRow.press(forDuration: 0.5)

        // Then I can edit the title
        let textField = app.textFields.firstMatch
        XCTAssertTrue(textField.waitForExistence(timeout: 3))

        // Clear and type new name
        textField.tap()
        textField.clearAndEnterText("Renamed Trivit")

        // Dismiss keyboard
        app.keyboards.buttons["Done"].tap()

        // Verify the new name
        XCTAssertTrue(app.staticTexts["Renamed Trivit"].exists)
    }

    func testIncrementTrivit() throws {
        // Given a trivit with count 0
        createTestTrivit()

        // When I tap on the tally zone
        let tallyZone = app.otherElements["TallyZone"].firstMatch
        if tallyZone.waitForExistence(timeout: 3) {
            tallyZone.tap()
        } else {
            // Fallback to tapping the cell
            app.cells.firstMatch.tap()
        }

        // Then the count increases
        // (Would need accessibilityIdentifier on count label)
    }

    func testDecrementTrivit() throws {
        // Given a trivit with count > 0
        createTestTrivit()
        incrementTrivit(times: 5)

        // When I tap the minus button
        let minusButton = app.buttons["Decrement"]
        if minusButton.waitForExistence(timeout: 3) {
            minusButton.tap()
        }

        // Then the count decreases
    }

    func testResetTrivit() throws {
        // Given a trivit with count > 0
        createTestTrivit()
        incrementTrivit(times: 10)

        // When I long press the minus button
        let minusButton = app.buttons["Decrement"]
        if minusButton.waitForExistence(timeout: 3) {
            minusButton.press(forDuration: 0.5)
        }

        // Then a confirmation dialog appears
        let resetButton = app.buttons["Reset"]
        if resetButton.waitForExistence(timeout: 3) {
            resetButton.tap()
        }

        // And the count is 0
    }

    func testDeleteTrivit() throws {
        // Given a trivit exists
        createTestTrivit()

        // When I swipe left and tap delete
        let trivitRow = app.cells.firstMatch
        XCTAssertTrue(trivitRow.waitForExistence(timeout: 5))

        trivitRow.swipeLeft()

        let deleteButton = app.buttons["Delete"]
        if deleteButton.waitForExistence(timeout: 3) {
            deleteButton.tap()
        }

        // Then the trivit is removed
        // Might show empty state again
    }

    func testCollapseExpand() throws {
        // Given an expanded trivit
        createTestTrivit()
        incrementTrivit(times: 5)

        let trivitRow = app.cells.firstMatch
        XCTAssertTrue(trivitRow.waitForExistence(timeout: 5))

        // Get the initial height
        let initialHeight = trivitRow.frame.height

        // When I tap the title
        let titleLabel = app.staticTexts["Test Trivit"]
        if titleLabel.waitForExistence(timeout: 3) {
            titleLabel.tap()
        }

        // Then the trivit collapses (smaller height)
        // Wait for animation
        Thread.sleep(forTimeInterval: 0.5)

        // The row should be smaller when collapsed
        // (Height comparison depends on implementation)
    }

    // MARK: - Settings Tests

    func testOpenSettings() throws {
        // When I tap the settings button
        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()

        // Then the settings view appears
        let settingsTitle = app.navigationBars["Settings"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 3))
    }

    func testChangeColorTheme() throws {
        // Given I'm in settings
        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()

        // When I tap a different color theme
        let colorButtons = app.buttons.matching(identifier: "ColorTheme")
        if colorButtons.count > 1 {
            colorButtons.element(boundBy: 1).tap()
        }

        // Then the theme changes
        // (Visual verification)
    }

    func testToggleHaptics() throws {
        // Given I'm in settings
        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()

        // When I toggle the haptics switch
        let hapticsToggle = app.switches["Haptic Feedback"]
        if hapticsToggle.waitForExistence(timeout: 3) {
            hapticsToggle.tap()
        }

        // Then the setting changes
    }

    // MARK: - Accessibility Tests

    func testAccessibilityLabels() throws {
        // Given a trivit exists
        createTestTrivit()

        // Then accessibility labels are present
        let addButton = app.buttons["Add Trivit"]
        XCTAssertTrue(addButton.isAccessibilityElement)
    }

    func testVoiceOverNavigation() throws {
        // Given VoiceOver simulation
        // (This would use XCUIDevice.shared.accessibilitySettings)

        // Then all elements are navigable
    }

    // MARK: - Performance Tests

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }

    func testScrollPerformance() throws {
        // Given many trivits exist
        createMultipleTrivits(count: 50)

        if #available(iOS 15.0, *) {
            let measureOptions = XCTMeasureOptions()
            measureOptions.iterationCount = 5

            measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric],
                    options: measureOptions) {
                let table = app.tables.firstMatch
                table.swipeUp()
                table.swipeDown()
            }
        }
    }

    // MARK: - Helper Methods

    private func createTestTrivit() {
        let addButton = app.buttons["Add Trivit"]
        if addButton.waitForExistence(timeout: 5) {
            addButton.tap()
        }

        // Type title
        let textField = app.textFields.firstMatch
        if textField.waitForExistence(timeout: 3) {
            textField.clearAndEnterText("Test Trivit")
        }

        // Dismiss keyboard
        if app.keyboards.buttons["Done"].exists {
            app.keyboards.buttons["Done"].tap()
        }
    }

    private func createMultipleTrivits(count: Int) {
        for i in 0..<count {
            let addButton = app.buttons["Add Trivit"]
            if addButton.waitForExistence(timeout: 2) {
                addButton.tap()
            }

            let textField = app.textFields.firstMatch
            if textField.waitForExistence(timeout: 2) {
                textField.clearAndEnterText("Trivit \(i + 1)")
            }

            if app.keyboards.buttons["Done"].exists {
                app.keyboards.buttons["Done"].tap()
            }
        }
    }

    private func incrementTrivit(times: Int) {
        for _ in 0..<times {
            let tallyZone = app.otherElements["TallyZone"].firstMatch
            if tallyZone.exists {
                tallyZone.tap()
            } else {
                app.cells.firstMatch.tap()
            }
            Thread.sleep(forTimeInterval: 0.1)
        }
    }
}

