import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Service for providing haptic feedback.
///
/// Centralizes haptic feedback to ensure consistent experience
/// and easy enable/disable control.
final class HapticsService: @unchecked Sendable {
    // MARK: - Shared Instance

    static let shared = HapticsService()

    // MARK: - Properties

    /// Whether haptic feedback is enabled
    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "hapticFeedbackEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "hapticFeedbackEnabled") }
    }

    #if canImport(UIKit) && !os(watchOS)
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()
    #endif

    // MARK: - Initialization

    private init() {
        // Register default value
        UserDefaults.standard.register(defaults: ["hapticFeedbackEnabled": true])
    }

    // MARK: - Impact Feedback

    /// Provides impact haptic feedback.
    /// - Parameter style: The intensity of the impact
    func impact(_ style: ImpactStyle) {
        guard isEnabled else { return }

        #if canImport(UIKit) && !os(watchOS)
        switch style {
        case .light:
            impactLight.impactOccurred()
        case .medium:
            impactMedium.impactOccurred()
        case .heavy:
            impactHeavy.impactOccurred()
        }
        #endif
    }

    /// Provides selection haptic feedback.
    func selection() {
        guard isEnabled else { return }

        #if canImport(UIKit) && !os(watchOS)
        selectionFeedback.selectionChanged()
        #endif
    }

    /// Provides notification haptic feedback.
    /// - Parameter type: The type of notification
    func notification(_ type: NotificationType) {
        guard isEnabled else { return }

        #if canImport(UIKit) && !os(watchOS)
        notificationFeedback.notificationOccurred(type.uiKitType)
        #endif
    }

    // MARK: - Prepare

    /// Prepares the haptic engines for feedback.
    /// Call before a known upcoming haptic to reduce latency.
    func prepare() {
        #if canImport(UIKit) && !os(watchOS)
        impactLight.prepare()
        impactMedium.prepare()
        selectionFeedback.prepare()
        #endif
    }
}

// MARK: - Impact Style

extension HapticsService {
    /// The intensity of impact feedback.
    enum ImpactStyle {
        case light
        case medium
        case heavy
    }
}

// MARK: - Notification Type

extension HapticsService {
    /// The type of notification feedback.
    enum NotificationType {
        case success
        case warning
        case error

        #if canImport(UIKit) && !os(watchOS)
        var uiKitType: UINotificationFeedbackGenerator.FeedbackType {
            switch self {
            case .success: return .success
            case .warning: return .warning
            case .error: return .error
            }
        }
        #endif
    }
}

// MARK: - Trivit-Specific Haptics

extension HapticsService {
    /// Haptic for incrementing a trivit
    func incrementHaptic() {
        impact(.light)
    }

    /// Haptic for decrementing a trivit
    func decrementHaptic() {
        impact(.light)
    }

    /// Haptic for resetting a trivit
    func resetHaptic() {
        notification(.warning)
    }

    /// Haptic for reaching a milestone (like 100, 500, etc.)
    func milestoneHaptic() {
        notification(.success)
    }

    /// Haptic for an error
    func errorHaptic() {
        notification(.error)
    }

    /// Haptic for collapsing/expanding
    func toggleHaptic() {
        selection()
    }
}
