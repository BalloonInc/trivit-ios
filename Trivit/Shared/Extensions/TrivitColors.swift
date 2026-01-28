import SwiftUI

/// Color management for Trivit app.
///
/// Provides access to the various color schemes available in the app.
/// Each scheme has light and dark variants for cell backgrounds.
enum TrivitColors {
    // MARK: - Color Schemes

    /// All available color scheme names
    static let schemeNames = [
        "Blue",
        "Pinkish",
        "Trivit",
        "Flat",
        "J-Series",
        "M-Series"
    ]

    /// Number of available color schemes
    static var schemeCount: Int {
        schemeNames.count
    }

    // MARK: - Blue Colors

    private static let blueLight: [Color] = [
        Color(hex: "4FC3F7"),
        Color(hex: "4DD0E1"),
        Color(hex: "4DB6AC"),
        Color(hex: "81C784"),
        Color(hex: "AED581"),
        Color(hex: "DCE775"),
        Color(hex: "FFF176"),
        Color(hex: "FFD54F"),
        Color(hex: "FFB74D"),
        Color(hex: "FF8A65")
    ]

    private static let blueDark: [Color] = [
        Color(hex: "0288D1"),
        Color(hex: "0097A7"),
        Color(hex: "00796B"),
        Color(hex: "388E3C"),
        Color(hex: "689F38"),
        Color(hex: "AFB42B"),
        Color(hex: "FBC02D"),
        Color(hex: "FFA000"),
        Color(hex: "F57C00"),
        Color(hex: "E64A19")
    ]

    // MARK: - Pinkish Colors

    private static let pinkishLight: [Color] = [
        Color(hex: "F48FB1"),
        Color(hex: "CE93D8"),
        Color(hex: "B39DDB"),
        Color(hex: "9FA8DA"),
        Color(hex: "90CAF9"),
        Color(hex: "81D4FA"),
        Color(hex: "80DEEA"),
        Color(hex: "80CBC4"),
        Color(hex: "A5D6A7"),
        Color(hex: "C5E1A5")
    ]

    private static let pinkishDark: [Color] = [
        Color(hex: "EC407A"),
        Color(hex: "AB47BC"),
        Color(hex: "7E57C2"),
        Color(hex: "5C6BC0"),
        Color(hex: "42A5F5"),
        Color(hex: "29B6F6"),
        Color(hex: "26C6DA"),
        Color(hex: "26A69A"),
        Color(hex: "66BB6A"),
        Color(hex: "9CCC65")
    ]

    // MARK: - Trivit Colors (Default)

    private static let trivitLight: [Color] = [
        Color(hex: "8BC34A"),
        Color(hex: "CDDC39"),
        Color(hex: "FFEB3B"),
        Color(hex: "FFC107"),
        Color(hex: "FF9800"),
        Color(hex: "FF5722"),
        Color(hex: "E91E63"),
        Color(hex: "9C27B0"),
        Color(hex: "673AB7"),
        Color(hex: "3F51B5")
    ]

    private static let trivitDark: [Color] = [
        Color(hex: "689F38"),
        Color(hex: "AFB42B"),
        Color(hex: "FBC02D"),
        Color(hex: "FFA000"),
        Color(hex: "F57C00"),
        Color(hex: "E64A19"),
        Color(hex: "C2185B"),
        Color(hex: "7B1FA2"),
        Color(hex: "512DA8"),
        Color(hex: "303F9F")
    ]

    // MARK: - Flat Colors

    private static let flatLight: [Color] = [
        Color(hex: "1ABC9C"),
        Color(hex: "2ECC71"),
        Color(hex: "3498DB"),
        Color(hex: "9B59B6"),
        Color(hex: "34495E"),
        Color(hex: "F1C40F"),
        Color(hex: "E67E22"),
        Color(hex: "E74C3C"),
        Color(hex: "95A5A6"),
        Color(hex: "16A085")
    ]

    private static let flatDark: [Color] = [
        Color(hex: "16A085"),
        Color(hex: "27AE60"),
        Color(hex: "2980B9"),
        Color(hex: "8E44AD"),
        Color(hex: "2C3E50"),
        Color(hex: "F39C12"),
        Color(hex: "D35400"),
        Color(hex: "C0392B"),
        Color(hex: "7F8C8D"),
        Color(hex: "1ABC9C")
    ]

    // MARK: - J-Series Colors

    private static let jSeriesLight: [Color] = [
        Color(hex: "FF6B6B"),
        Color(hex: "C44D58"),
        Color(hex: "556270"),
        Color(hex: "4ECDC4"),
        Color(hex: "45B29D"),
        Color(hex: "EFC94C"),
        Color(hex: "E27A3F"),
        Color(hex: "DF5A49"),
        Color(hex: "774F38"),
        Color(hex: "6A4A3C")
    ]

    private static let jSeriesDark: [Color] = [
        Color(hex: "E74C3C"),
        Color(hex: "A3415E"),
        Color(hex: "3E4A52"),
        Color(hex: "2ECC71"),
        Color(hex: "27AE60"),
        Color(hex: "F39C12"),
        Color(hex: "D35400"),
        Color(hex: "C0392B"),
        Color(hex: "5D3A29"),
        Color(hex: "4A3728")
    ]

    // MARK: - M-Series Colors

    private static let mSeriesLight: [Color] = [
        Color(hex: "00BCD4"),
        Color(hex: "009688"),
        Color(hex: "4CAF50"),
        Color(hex: "8BC34A"),
        Color(hex: "CDDC39"),
        Color(hex: "FFEB3B"),
        Color(hex: "FFC107"),
        Color(hex: "FF9800"),
        Color(hex: "FF5722"),
        Color(hex: "795548")
    ]

    private static let mSeriesDark: [Color] = [
        Color(hex: "0097A7"),
        Color(hex: "00796B"),
        Color(hex: "388E3C"),
        Color(hex: "689F38"),
        Color(hex: "AFB42B"),
        Color(hex: "FBC02D"),
        Color(hex: "FFA000"),
        Color(hex: "F57C00"),
        Color(hex: "E64A19"),
        Color(hex: "5D4037")
    ]

    // MARK: - Color Access

    /// Get a color from the specified scheme.
    /// - Parameters:
    ///   - index: The color index (will wrap around)
    ///   - scheme: The color scheme index (0-5)
    ///   - isDark: Whether to use the dark variant
    /// - Returns: The color
    static func color(at index: Int, scheme: Int, isDark: Bool) -> Color {
        let colors = colorSet(for: scheme, isDark: isDark)
        let wrappedIndex = index % colors.count
        return colors[wrappedIndex >= 0 ? wrappedIndex : wrappedIndex + colors.count]
    }

    /// Get all colors for a scheme.
    /// - Parameters:
    ///   - scheme: The color scheme index
    ///   - isDark: Whether to use the dark variant
    /// - Returns: Array of colors
    static func colorSet(for scheme: Int, isDark: Bool) -> [Color] {
        let wrappedScheme = scheme % schemeCount
        let safeScheme = wrappedScheme >= 0 ? wrappedScheme : wrappedScheme + schemeCount

        switch safeScheme {
        case 0:
            return isDark ? blueDark : blueLight
        case 1:
            return isDark ? pinkishDark : pinkishLight
        case 2:
            return isDark ? trivitDark : trivitLight
        case 3:
            return isDark ? flatDark : flatLight
        case 4:
            return isDark ? jSeriesDark : jSeriesLight
        case 5:
            return isDark ? mSeriesDark : mSeriesLight
        default:
            return isDark ? trivitDark : trivitLight
        }
    }

    /// Preview colors for a scheme (first 4 colors).
    static func previewColors(for scheme: Int) -> [Color] {
        let light = colorSet(for: scheme, isDark: false)
        return Array(light.prefix(4))
    }
}

// MARK: - Color Extension

extension Color {
    /// Initialize a color from a hex string.
    /// - Parameter hex: Hex color string (with or without #)
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
            (a, r, g, b) = (255, 0, 0, 0)
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

// MARK: - Preview

#Preview("Color Schemes") {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(0..<TrivitColors.schemeCount, id: \.self) { schemeIndex in
                VStack(alignment: .leading) {
                    Text(TrivitColors.schemeNames[schemeIndex])
                        .font(.headline)

                    HStack(spacing: 4) {
                        ForEach(0..<10, id: \.self) { colorIndex in
                            VStack(spacing: 2) {
                                Circle()
                                    .fill(TrivitColors.color(at: colorIndex, scheme: schemeIndex, isDark: false))
                                    .frame(width: 30, height: 30)
                                Circle()
                                    .fill(TrivitColors.color(at: colorIndex, scheme: schemeIndex, isDark: true))
                                    .frame(width: 30, height: 30)
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }
}
