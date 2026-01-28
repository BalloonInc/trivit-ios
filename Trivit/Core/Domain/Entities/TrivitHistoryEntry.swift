import Foundation
import SwiftData

/// A record of a change to a Trivit's count.
///
/// Used for building statistics and history views.
@Model
final class TrivitHistoryEntry: Identifiable {
    // MARK: - Properties

    /// Unique identifier for this history entry
    @Attribute(.unique) var id: UUID

    /// The trivit this entry belongs to
    var trivit: Trivit?

    /// The count value after this change
    var count: Int

    /// When this change occurred
    var timestamp: Date

    /// The type of change that was made
    var changeType: ChangeType

    /// The previous count value (for calculating deltas)
    var previousCount: Int

    // MARK: - Computed Properties

    /// The delta (change) in count
    var delta: Int {
        count - previousCount
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        trivit: Trivit? = nil,
        count: Int,
        timestamp: Date = Date(),
        changeType: ChangeType,
        previousCount: Int
    ) {
        self.id = id
        self.trivit = trivit
        self.count = count
        self.timestamp = timestamp
        self.changeType = changeType
        self.previousCount = previousCount
    }
}

// MARK: - ChangeType

/// The type of change made to a trivit's count.
enum ChangeType: String, Codable, CaseIterable {
    /// Count was increased by 1
    case increment

    /// Count was decreased by 1
    case decrement

    /// Count was set to zero
    case reset

    /// Count was set directly (e.g., sync, import)
    case set

    /// Display name for the change type
    var displayName: String {
        switch self {
        case .increment:
            return String(localized: "history.change.increment", defaultValue: "Increment")
        case .decrement:
            return String(localized: "history.change.decrement", defaultValue: "Decrement")
        case .reset:
            return String(localized: "history.change.reset", defaultValue: "Reset")
        case .set:
            return String(localized: "history.change.set", defaultValue: "Set")
        }
    }

    /// SF Symbol name for the change type
    var symbolName: String {
        switch self {
        case .increment:
            return "plus.circle.fill"
        case .decrement:
            return "minus.circle.fill"
        case .reset:
            return "arrow.counterclockwise.circle.fill"
        case .set:
            return "pencil.circle.fill"
        }
    }
}
