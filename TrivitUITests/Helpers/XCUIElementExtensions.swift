import XCTest

// MARK: - XCUIElement Extensions

extension XCUIElement {
    /// Clears any current text and enters new text.
    func clearAndEnterText(_ text: String) {
        guard let stringValue = self.value as? String else {
            XCTFail("Tried to clear and enter text into a non-string value")
            return
        }

        self.tap()

        // Select all and delete
        if !stringValue.isEmpty {
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
            self.typeText(deleteString)
        }

        self.typeText(text)
    }

    /// Whether the element currently has keyboard focus.
    var hasFocus: Bool {
        let hasKeyboardFocus = (self.value(forKey: "hasKeyboardFocus") as? Bool) ?? false
        return hasKeyboardFocus
    }
}
