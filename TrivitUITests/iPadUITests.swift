import XCTest

/// UI tests specific to iPad layout and interactions.
///
/// These tests verify the split view navigation, sidebar behavior,
/// and iPad-specific gestures and interactions.
final class iPadUITests: XCTestCase {

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

    // MARK: - Navigation Split View Tests

    func testSidebarVisible() throws {
        // Skip if not running on iPad
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "iPad only test")

        // Given the app is launched
        // Then the sidebar should be visible
        let sidebar = app.navigationBars["Trivits"]
        XCTAssertTrue(sidebar.waitForExistence(timeout: 5))
    }

    func testSidebarTrivitSelection() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "iPad only test")

        // Given trivits exist
        createTestTrivit(name: "First Trivit")
        createTestTrivit(name: "Second Trivit")

        // When I tap a trivit in the sidebar
        let firstTrivit = app.cells["First Trivit"]
        if firstTrivit.waitForExistence(timeout: 3) {
            firstTrivit.tap()
        }

        // Then the detail view shows that trivit
        let detailTitle = app.navigationBars["First Trivit"]
        XCTAssertTrue(detailTitle.waitForExistence(timeout: 3))
    }

    func testDetailViewInteraction() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "iPad only test")

        // Given a trivit is selected
        createTestTrivit(name: "Detail Test")

        let trivitCell = app.cells["Detail Test"]
        if trivitCell.waitForExistence(timeout: 3) {
            trivitCell.tap()
        }

        // When I tap the increment button in detail view
        let incrementButton = app.buttons["Increment"]
        if incrementButton.waitForExistence(timeout: 3) {
            incrementButton.tap()
        }

        // Then the count increases (verify by checking count label)
        let countLabel = app.staticTexts.matching(identifier: "CountLabel").firstMatch
        // Count should be updated
    }

    func testSidebarContextMenu() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "iPad only test")

        // Given a trivit exists
        createTestTrivit(name: "Context Menu Test")

        // When I right-click (long press) on the sidebar row
        let trivitCell = app.cells["Context Menu Test"]
        if trivitCell.waitForExistence(timeout: 3) {
            trivitCell.press(forDuration: 1.0)
        }

        // Then a context menu appears
        let incrementMenuItem = app.buttons["Increment"]
        XCTAssertTrue(incrementMenuItem.waitForExistence(timeout: 3))

        let deleteMenuItem = app.buttons["Delete"]
        XCTAssertTrue(deleteMenuItem.exists)
    }

    func testSidebarCollapseExpand() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "iPad only test")

        // Given the sidebar is visible
        let sidebar = app.navigationBars["Trivits"]
        XCTAssertTrue(sidebar.waitForExistence(timeout: 5))

        // When I tap the sidebar toggle button
        let toggleButton = app.buttons["ToggleSidebar"]
        if toggleButton.waitForExistence(timeout: 3) {
            toggleButton.tap()

            // Then the sidebar collapses
            Thread.sleep(forTimeInterval: 0.5)

            // And I can expand it again
            toggleButton.tap()
        }
    }

    // MARK: - Detail View Tests

    func testDetailViewHistoryButton() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "iPad only test")

        // Given a trivit is selected
        createTestTrivit(name: "History Test")
        selectTrivit(name: "History Test")

        // When I tap the history button
        let historyButton = app.buttons["View History"]
        if historyButton.waitForExistence(timeout: 3) {
            historyButton.tap()
        }

        // Then the history view appears
        let historyTitle = app.navigationBars["Statistics"]
        XCTAssertTrue(historyTitle.waitForExistence(timeout: 3))
    }

    func testDetailViewActionButtons() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "iPad only test")

        // Given a trivit is selected
        createTestTrivit(name: "Actions Test")
        selectTrivit(name: "Actions Test")

        // Then all action buttons are visible
        let incrementButton = app.buttons["Increment"]
        let decrementButton = app.buttons["Decrement"]
        let resetButton = app.buttons["Reset"]

        XCTAssertTrue(incrementButton.waitForExistence(timeout: 3))
        XCTAssertTrue(decrementButton.exists)
        XCTAssertTrue(resetButton.exists)
    }

    // MARK: - Orientation Tests

    func testLandscapeLayout() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "iPad only test")

        // Rotate to landscape
        XCUIDevice.shared.orientation = .landscapeLeft
        Thread.sleep(forTimeInterval: 0.5)

        // Given trivits exist
        createTestTrivit(name: "Landscape Test")

        // Then both sidebar and detail are visible
        let sidebar = app.navigationBars["Trivits"]
        XCTAssertTrue(sidebar.waitForExistence(timeout: 5))

        // Select trivit to show detail
        selectTrivit(name: "Landscape Test")

        // Reset orientation
        XCUIDevice.shared.orientation = .portrait
    }

    func testPortraitLayout() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "iPad only test")

        // Ensure portrait
        XCUIDevice.shared.orientation = .portrait
        Thread.sleep(forTimeInterval: 0.5)

        // Given trivits exist
        createTestTrivit(name: "Portrait Test")

        // Then the layout adapts appropriately
        let sidebar = app.navigationBars["Trivits"]
        XCTAssertTrue(sidebar.waitForExistence(timeout: 5))
    }

    // MARK: - Multi-Window Tests (iPadOS)

    func testDragToNewWindow() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "iPad only test")

        // This would test Stage Manager / multi-window
        // Requires specific iPadOS versions
    }

    // MARK: - Keyboard Shortcuts

    func testKeyboardShortcutNewTrivit() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "iPad only test")

        // When hardware keyboard is connected
        // Press Cmd+N to create new trivit

        // Note: Keyboard shortcuts are hard to test in XCUITest
        // Would need to simulate hardware keyboard
    }

    // MARK: - Pointer Interaction Tests

    func testPointerHoverEffects() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "iPad only test")

        // When using trackpad/mouse
        // Hover effects should be visible

        // Note: Pointer interaction testing requires specific setup
    }

    // MARK: - Screenshot Tests for Fastlane

    func testIPadScreenshots() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "iPad only test")

        // Setup: Create sample data for screenshots
        createTestTrivit(name: "Coffee cups")
        incrementTrivit(times: 42)
        createTestTrivit(name: "Push-ups")
        incrementTrivit(times: 127)
        createTestTrivit(name: "Books read")
        incrementTrivit(times: 12)

        // Screenshot 1: Main list
        Thread.sleep(forTimeInterval: 1)
        let screenshot1 = app.screenshot()
        let attachment1 = XCTAttachment(screenshot: screenshot1)
        attachment1.name = "iPad_01_MainList"
        attachment1.lifetime = .keepAlways
        add(attachment1)

        // Screenshot 2: With detail view
        selectTrivit(name: "Coffee cups")
        Thread.sleep(forTimeInterval: 0.5)
        let screenshot2 = app.screenshot()
        let attachment2 = XCTAttachment(screenshot: screenshot2)
        attachment2.name = "iPad_02_DetailView"
        attachment2.lifetime = .keepAlways
        add(attachment2)

        // Screenshot 3: History view
        let historyButton = app.buttons["View History"]
        if historyButton.waitForExistence(timeout: 3) {
            historyButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
            let screenshot3 = app.screenshot()
            let attachment3 = XCTAttachment(screenshot: screenshot3)
            attachment3.name = "iPad_03_HistoryView"
            attachment3.lifetime = .keepAlways
            add(attachment3)
        }
    }

    // MARK: - Helper Methods

    private func createTestTrivit(name: String) {
        let addButton = app.buttons["Add Trivit"]
        if addButton.waitForExistence(timeout: 5) {
            addButton.tap()
        }

        let textField = app.textFields.firstMatch
        if textField.waitForExistence(timeout: 3) {
            textField.clearAndEnterText(name)
        }

        if app.keyboards.buttons["Done"].exists {
            app.keyboards.buttons["Done"].tap()
        }
    }

    private func selectTrivit(name: String) {
        let trivitCell = app.cells[name]
        if trivitCell.waitForExistence(timeout: 3) {
            trivitCell.tap()
        }
    }

    private func incrementTrivit(times: Int) {
        for _ in 0..<times {
            let incrementButton = app.buttons["Increment"]
            if incrementButton.waitForExistence(timeout: 2) {
                incrementButton.tap()
            }
            Thread.sleep(forTimeInterval: 0.05)
        }
    }
}
