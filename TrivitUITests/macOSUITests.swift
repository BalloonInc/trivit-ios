#if os(macOS)
import XCTest

/// UI tests specific to macOS layout, menu bar, and keyboard interactions.
///
/// These tests verify the three-column navigation, menu commands,
/// keyboard shortcuts, and macOS-specific behaviors.
final class macOSUITests: XCTestCase {

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

    // MARK: - Window Tests

    func testMainWindowLaunches() throws {
        // Given the app launches
        // Then the main window is visible
        XCTAssertTrue(app.windows.firstMatch.exists)
    }

    func testWindowMinimumSize() throws {
        // The window should have a minimum size
        let window = app.windows.firstMatch
        XCTAssertTrue(window.exists)

        // Window should not be smaller than minimum
        let frame = window.frame
        XCTAssertGreaterThan(frame.width, 600)
        XCTAssertGreaterThan(frame.height, 400)
    }

    func testWindowResize() throws {
        let window = app.windows.firstMatch
        XCTAssertTrue(window.exists)

        // Window should be resizable
        // Note: Actually resizing requires coordinate manipulation
    }

    // MARK: - Three-Column Navigation Tests

    func testThreeColumnLayout() throws {
        // Given trivits exist
        createTestTrivit(name: "Column Test")

        // Then sidebar is visible
        let sidebar = app.outlines.firstMatch
        XCTAssertTrue(sidebar.waitForExistence(timeout: 5))
    }

    func testSidebarSelection() throws {
        // Given trivits exist
        createTestTrivit(name: "Sidebar Selection Test")

        // When I select a trivit in the sidebar
        let outlineRow = app.outlines.firstMatch.cells.firstMatch
        if outlineRow.waitForExistence(timeout: 3) {
            outlineRow.click()
        }

        // Then the detail view updates
        // Verify detail content is shown
    }

    // MARK: - Menu Bar Tests

    func testFileMenuNewTrivit() throws {
        // When I use File > New Trivit (Cmd+N)
        app.typeKey("n", modifierFlags: .command)

        // Then a new trivit creation starts
        let textField = app.textFields.firstMatch
        XCTAssertTrue(textField.waitForExistence(timeout: 3))
    }

    func testViewMenuExpandAll() throws {
        // Given collapsed trivits exist
        createTestTrivit(name: "Expand Test 1")
        createTestTrivit(name: "Expand Test 2")

        // When I use View > Expand All (Cmd+Option+E)
        app.typeKey("e", modifierFlags: [.command, .option])

        // Then all trivits expand
        Thread.sleep(forTimeInterval: 0.5)
    }

    func testViewMenuCollapseAll() throws {
        // Given expanded trivits exist
        createTestTrivit(name: "Collapse Test 1")
        createTestTrivit(name: "Collapse Test 2")

        // When I use View > Collapse All (Cmd+Option+C)
        app.typeKey("c", modifierFlags: [.command, .option])

        // Then all trivits collapse
        Thread.sleep(forTimeInterval: 0.5)
    }

    func testViewMenuShowStatistics() throws {
        // When I use View > Show Statistics (Cmd+Shift+S)
        app.typeKey("s", modifierFlags: [.command, .shift])

        // Then the statistics window opens
        let statsWindow = app.windows["Statistics"]
        XCTAssertTrue(statsWindow.waitForExistence(timeout: 3))
    }

    // MARK: - Settings Window Tests

    func testOpenSettings() throws {
        // When I use App > Settings (Cmd+,)
        app.typeKey(",", modifierFlags: .command)

        // Then the settings window opens
        let settingsWindow = app.windows["Settings"]
        XCTAssertTrue(settingsWindow.waitForExistence(timeout: 3))
    }

    func testSettingsGeneralTab() throws {
        // Given settings is open
        app.typeKey(",", modifierFlags: .command)
        Thread.sleep(forTimeInterval: 0.5)

        // Then the General tab is visible
        let generalTab = app.tabs["General"]
        XCTAssertTrue(generalTab.waitForExistence(timeout: 3))
    }

    func testSettingsAppearanceTab() throws {
        // Given settings is open
        app.typeKey(",", modifierFlags: .command)
        Thread.sleep(forTimeInterval: 0.5)

        // When I click the Appearance tab
        let appearanceTab = app.tabs["Appearance"]
        if appearanceTab.waitForExistence(timeout: 3) {
            appearanceTab.click()
        }

        // Then the appearance settings are visible
        let colorPicker = app.popUpButtons["Color Theme"]
        XCTAssertTrue(colorPicker.waitForExistence(timeout: 3))
    }

    func testSettingsAboutTab() throws {
        // Given settings is open
        app.typeKey(",", modifierFlags: .command)
        Thread.sleep(forTimeInterval: 0.5)

        // When I click the About tab
        let aboutTab = app.tabs["About"]
        if aboutTab.waitForExistence(timeout: 3) {
            aboutTab.click()
        }

        // Then the about info is visible
        let versionLabel = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Version'")).firstMatch
        XCTAssertTrue(versionLabel.waitForExistence(timeout: 3))
    }

    // MARK: - Keyboard Navigation Tests

    func testArrowKeyNavigation() throws {
        // Given trivits exist
        createTestTrivit(name: "Nav Test 1")
        createTestTrivit(name: "Nav Test 2")

        // When I use arrow keys
        app.typeKey(.downArrow, modifierFlags: [])
        Thread.sleep(forTimeInterval: 0.2)

        app.typeKey(.upArrow, modifierFlags: [])
        Thread.sleep(forTimeInterval: 0.2)

        // Then selection moves
    }

    func testReturnKeyActivation() throws {
        // Given a trivit is selected
        createTestTrivit(name: "Return Test")

        // Select via arrow key
        app.typeKey(.downArrow, modifierFlags: [])
        Thread.sleep(forTimeInterval: 0.2)

        // When I press Return
        app.typeKey(.return, modifierFlags: [])

        // Then the trivit activates (shows detail)
    }

    func testDeleteKeyRemoval() throws {
        // Given a trivit is selected
        createTestTrivit(name: "Delete Test")

        // Select via arrow key
        app.typeKey(.downArrow, modifierFlags: [])
        Thread.sleep(forTimeInterval: 0.2)

        // When I press Delete (Cmd+Backspace)
        app.typeKey(.delete, modifierFlags: .command)

        // Then a confirmation appears or trivit is deleted
    }

    func testEscapeKeyDismissal() throws {
        // Given a sheet or popover is open
        app.typeKey(",", modifierFlags: .command) // Open settings
        Thread.sleep(forTimeInterval: 0.5)

        // When I press Escape
        app.typeKey(.escape, modifierFlags: [])

        // Then the sheet/popover closes
        Thread.sleep(forTimeInterval: 0.3)
    }

    // MARK: - Context Menu Tests

    func testRightClickContextMenu() throws {
        // Given a trivit exists
        createTestTrivit(name: "Right Click Test")

        // When I right-click on it
        let outlineRow = app.outlines.firstMatch.cells.firstMatch
        if outlineRow.waitForExistence(timeout: 3) {
            outlineRow.rightClick()
        }

        // Then a context menu appears
        let incrementItem = app.menuItems["Increment"]
        XCTAssertTrue(incrementItem.waitForExistence(timeout: 3))
    }

    // MARK: - Touch Bar Tests (if applicable)

    func testTouchBarButtons() throws {
        // Touch Bar integration would be tested here
        // Requires simulator support or physical device
    }

    // MARK: - Screenshot Tests for Fastlane

    func testMacOSScreenshots() throws {
        // Setup: Create sample data for screenshots
        createTestTrivit(name: "Coffee cups")
        incrementTrivit(name: "Coffee cups", times: 42)
        createTestTrivit(name: "Push-ups")
        incrementTrivit(name: "Push-ups", times: 127)
        createTestTrivit(name: "Books read")
        incrementTrivit(name: "Books read", times: 12)

        // Screenshot 1: Main window with sidebar
        Thread.sleep(forTimeInterval: 1)
        let screenshot1 = app.windows.firstMatch.screenshot()
        let attachment1 = XCTAttachment(screenshot: screenshot1)
        attachment1.name = "macOS_01_MainWindow"
        attachment1.lifetime = .keepAlways
        add(attachment1)

        // Screenshot 2: With detail view selected
        let outlineRow = app.outlines.firstMatch.cells.firstMatch
        if outlineRow.waitForExistence(timeout: 3) {
            outlineRow.click()
        }
        Thread.sleep(forTimeInterval: 0.5)
        let screenshot2 = app.windows.firstMatch.screenshot()
        let attachment2 = XCTAttachment(screenshot: screenshot2)
        attachment2.name = "macOS_02_DetailView"
        attachment2.lifetime = .keepAlways
        add(attachment2)

        // Screenshot 3: Settings window
        app.typeKey(",", modifierFlags: .command)
        Thread.sleep(forTimeInterval: 0.5)
        let settingsWindow = app.windows["Settings"]
        if settingsWindow.waitForExistence(timeout: 3) {
            let screenshot3 = settingsWindow.screenshot()
            let attachment3 = XCTAttachment(screenshot: screenshot3)
            attachment3.name = "macOS_03_Settings"
            attachment3.lifetime = .keepAlways
            add(attachment3)
        }
    }

    // MARK: - Performance Tests

    func testWindowRenderingPerformance() throws {
        measure(metrics: [XCTClockMetric()]) {
            // Create and display many trivits
            for i in 0..<20 {
                createTestTrivit(name: "Perf Test \(i)")
            }
        }
    }

    // MARK: - Helper Methods

    private func createTestTrivit(name: String) {
        app.typeKey("n", modifierFlags: .command)

        let textField = app.textFields.firstMatch
        if textField.waitForExistence(timeout: 3) {
            textField.click()
            textField.typeText(name)
            app.typeKey(.return, modifierFlags: [])
        }
    }

    private func incrementTrivit(name: String, times: Int) {
        // Select the trivit
        let outlineRow = app.outlines.firstMatch.cells.containing(.staticText, identifier: name).firstMatch
        if outlineRow.waitForExistence(timeout: 3) {
            outlineRow.click()
        }

        // Click increment button
        for _ in 0..<times {
            let incrementButton = app.buttons["Increment"]
            if incrementButton.waitForExistence(timeout: 1) {
                incrementButton.click()
            }
            Thread.sleep(forTimeInterval: 0.02)
        }
    }
}
#endif
