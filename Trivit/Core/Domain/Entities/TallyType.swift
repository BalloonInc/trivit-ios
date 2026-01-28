import Foundation

/// The type of tally marks to display.
///
/// Different cultures use different visual representations for counting.
/// Trivit supports multiple tally mark styles.
enum TallyType: String, Codable, CaseIterable, Identifiable {
    /// Western tally marks (IIII with diagonal for 5)
    case western

    /// Chinese tally marks (正 character, built stroke by stroke)
    case chinese

    var id: String { rawValue }

    /// Display name for the tally type
    var displayName: String {
        switch self {
        case .western:
            return String(localized: "tally.type.western", defaultValue: "Western (IIII)")
        case .chinese:
            return String(localized: "tally.type.chinese", defaultValue: "Chinese (正)")
        }
    }

    /// Image name prefix for this tally type
    var imagePrefix: String {
        switch self {
        case .western:
            return "tally_"
        case .chinese:
            return "tally_ch_"
        }
    }

    /// Returns the image name for a specific count within a group (1-5)
    /// - Parameter count: The count within the group (1-5)
    /// - Returns: The image asset name
    func imageName(for count: Int) -> String {
        let clampedCount = min(max(count, 1), 5)
        return "\(imagePrefix)\(clampedCount)"
    }
}
