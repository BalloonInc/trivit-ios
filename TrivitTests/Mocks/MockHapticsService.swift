import Foundation
@testable import Trivit

/// Mock implementation of HapticsService for testing.
///
/// Records all haptic calls for verification.
@MainActor
final class MockHapticsService: Sendable {
    // MARK: - Call Tracking

    var impactCalled = false
    var impactCalledWith: HapticsService.ImpactStyle?
    var impactCount = 0

    var selectionCalled = false
    var selectionCount = 0

    var notificationCalled = false
    var notificationCalledWith: HapticsService.NotificationType?
    var notificationCount = 0

    var prepareCalled = false

    // Trivit-specific haptics
    var incrementHapticCalled = false
    var decrementHapticCalled = false
    var resetHapticCalled = false
    var milestoneHapticCalled = false
    var errorHapticCalled = false
    var toggleHapticCalled = false

    // MARK: - Mock Methods

    func impact(_ style: HapticsService.ImpactStyle) {
        impactCalled = true
        impactCalledWith = style
        impactCount += 1
    }

    func selection() {
        selectionCalled = true
        selectionCount += 1
    }

    func notification(_ type: HapticsService.NotificationType) {
        notificationCalled = true
        notificationCalledWith = type
        notificationCount += 1
    }

    func prepare() {
        prepareCalled = true
    }

    func incrementHaptic() {
        incrementHapticCalled = true
        impact(.light)
    }

    func decrementHaptic() {
        decrementHapticCalled = true
        impact(.light)
    }

    func resetHaptic() {
        resetHapticCalled = true
        notification(.warning)
    }

    func milestoneHaptic() {
        milestoneHapticCalled = true
        notification(.success)
    }

    func errorHaptic() {
        errorHapticCalled = true
        notification(.error)
    }

    func toggleHaptic() {
        toggleHapticCalled = true
        selection()
    }

    // MARK: - Test Helpers

    func reset() {
        impactCalled = false
        impactCalledWith = nil
        impactCount = 0
        selectionCalled = false
        selectionCount = 0
        notificationCalled = false
        notificationCalledWith = nil
        notificationCount = 0
        prepareCalled = false

        incrementHapticCalled = false
        decrementHapticCalled = false
        resetHapticCalled = false
        milestoneHapticCalled = false
        errorHapticCalled = false
        toggleHapticCalled = false
    }
}
