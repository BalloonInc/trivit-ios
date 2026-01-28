//
//  HapticsService.swift
//  Trivit
//
//  Haptic feedback service for the app
//

import UIKit

final class HapticsService {
    static let shared = HapticsService()

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()

    private init() {
        // Prepare generators for lower latency
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        notification.prepare()
        selectionGenerator.prepare()
    }

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        switch style {
        case .light:
            impactLight.impactOccurred()
        case .medium:
            impactMedium.impactOccurred()
        case .heavy:
            impactHeavy.impactOccurred()
        case .soft:
            impactLight.impactOccurred()
        case .rigid:
            impactHeavy.impactOccurred()
        @unknown default:
            impactMedium.impactOccurred()
        }
    }

    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notification.notificationOccurred(type)
    }

    func selection() {
        selectionGenerator.selectionChanged()
    }
}
