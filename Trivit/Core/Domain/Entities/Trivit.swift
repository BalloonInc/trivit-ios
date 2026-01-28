import Foundation
import SwiftData

/// The core Trivit entity representing a tally counter.
///
/// A Trivit is a simple counter that can be incremented, decremented, and reset.
/// It supports visual representation through tally marks and can be collapsed
/// to show only a count badge.
@Model
final class Trivit: Identifiable {
    // MARK: - Properties

    /// Unique identifier for the trivit
    @Attribute(.unique) var id: UUID

    /// The display title of the trivit
    var title: String

    /// The current count value
    var count: Int

    /// Index into the color scheme array
    var colorIndex: Int

    /// Whether the trivit is in collapsed state (showing badge vs tally marks)
    var isCollapsed: Bool

    /// Timestamp when the trivit was created
    var createdAt: Date

    /// The type of tally marks to display (western IIII or chinese 正)
    var tallyType: TallyType

    /// History of count changes for statistics
    @Relationship(deleteRule: .cascade, inverse: \TrivitHistoryEntry.trivit)
    var history: [TrivitHistoryEntry]?

    // MARK: - Computed Properties

    /// Number of complete tally groups (groups of 5)
    var completeGroups: Int {
        count / 5
    }

    /// Remainder marks in the current incomplete group (0-4)
    var remainderMarks: Int {
        count % 5
    }

    /// Total number of tally mark images to display
    var tallyImageCount: Int {
        (count + 4) / 5  // Ceiling division
    }

    /// Whether the count is at the maximum safe value
    var isAtMaxCount: Bool {
        count >= Int.max - 1
    }

    /// Whether the count can be decremented (is greater than zero)
    var canDecrement: Bool {
        count > 0
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        title: String,
        count: Int = 0,
        colorIndex: Int = 0,
        isCollapsed: Bool = true,
        createdAt: Date = Date(),
        tallyType: TallyType = .western,
        history: [TrivitHistoryEntry]? = nil
    ) {
        self.id = id
        self.title = title
        self.count = max(0, count)  // Ensure non-negative
        self.colorIndex = colorIndex
        self.isCollapsed = isCollapsed
        self.createdAt = createdAt
        self.tallyType = tallyType
        self.history = history
    }

    // MARK: - Actions

    /// Increments the count by 1, if not at maximum
    /// - Returns: `true` if increment was successful, `false` if at max
    @discardableResult
    func increment() -> Bool {
        guard !isAtMaxCount else { return false }
        count += 1
        return true
    }

    /// Decrements the count by 1, if not at zero
    /// - Returns: `true` if decrement was successful, `false` if already at zero
    @discardableResult
    func decrement() -> Bool {
        guard canDecrement else { return false }
        count -= 1
        return true
    }

    /// Resets the count to zero
    func reset() {
        count = 0
    }

    /// Toggles the collapsed state
    func toggleCollapsed() {
        isCollapsed.toggle()
    }
}

// MARK: - Equatable (for testing)

extension Trivit {
    /// Check equality based on ID
    static func == (lhs: Trivit, rhs: Trivit) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension Trivit {
    /// Sample trivit for previews
    static var preview: Trivit {
        Trivit(
            title: "Days without coffee",
            count: 42,
            colorIndex: 0,
            isCollapsed: false
        )
    }

    /// Multiple sample trivits for previews
    static var previews: [Trivit] {
        [
            Trivit(title: "Cups of coffee", count: 127, colorIndex: 0, isCollapsed: false),
            Trivit(title: "Push-ups today", count: 25, colorIndex: 1, isCollapsed: false),
            Trivit(title: "Books read", count: 8, colorIndex: 2, isCollapsed: true),
            Trivit(title: "Days since last bug", count: 3, colorIndex: 3, isCollapsed: true),
            Trivit(title: "Meetings survived", count: 42, colorIndex: 4, isCollapsed: false)
        ]
    }
}
#endif
