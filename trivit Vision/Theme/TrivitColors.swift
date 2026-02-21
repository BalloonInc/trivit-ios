//
//  TrivitColors.swift
//  trivit Vision
//
//  Color themes for the visionOS app - matching iOS app design
//

import SwiftUI

struct TrivitColors {
    static let colorCount = 10

    // Main color palette (flat design inspired) - same as iOS app
    static let palette: [Color] = [
        Color(hex: "1ABC9C"), // Turquoise
        Color(hex: "2ECC71"), // Emerald
        Color(hex: "3498DB"), // Peter River
        Color(hex: "9B59B6"), // Amethyst
        Color(hex: "E74C3C"), // Alizarin
        Color(hex: "F39C12"), // Orange
        Color(hex: "E91E63"), // Pink
        Color(hex: "00BCD4"), // Cyan
        Color(hex: "8BC34A"), // Light Green
        Color(hex: "FF5722"), // Deep Orange
    ]

    static func color(at index: Int) -> Color {
        let safeIndex = abs(index) % palette.count
        return palette[safeIndex]
    }

    static func randomColorIndex() -> Int {
        Int.random(in: 0..<palette.count)
    }
}

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
