import Foundation
import SwiftUI
import Observation

/// ViewModel for the main Trivit list screen.
///
/// Manages the list of trivits and handles all user interactions
/// including CRUD operations and sync.
@Observable
@MainActor
final class TrivitListViewModel {
    // MARK: - Published State

    /// All trivits to display
    private(set) var trivits: [Trivit] = []

    /// Whether data is currently loading
    private(set) var isLoading = false

    /// The current error, if any
    private(set) var error: TrivitError?

    /// The trivit currently being edited (title editing)
    var editingTrivit: Trivit?

    /// Whether the list is in edit mode (reordering)
    var isEditMode = false

    /// Search query for filtering
    var searchQuery = ""

    // MARK: - Filtered Trivits

    /// Trivits filtered by search query
    var filteredTrivits: [Trivit] {
        guard !searchQuery.isEmpty else { return trivits }
        return trivits.filter { $0.title.localizedCaseInsensitiveContains(searchQuery) }
    }

    /// Count of expanded trivits
    var expandedCount: Int {
        trivits.filter { !$0.isCollapsed }.count
    }

    /// Count of collapsed trivits
    var collapsedCount: Int {
        trivits.filter { $0.isCollapsed }.count
    }

    // MARK: - Dependencies

    private let repository: TrivitRepository
    private let historyRepository: HistoryRepository?
    private let hapticsService: HapticsService
    private let placeholderTitles: [String]

    // MARK: - Initialization

    init(
        repository: TrivitRepository,
        historyRepository: HistoryRepository? = nil,
        hapticsService: HapticsService = .shared
    ) {
        self.repository = repository
        self.historyRepository = historyRepository
        self.hapticsService = hapticsService
        self.placeholderTitles = Self.loadPlaceholderTitles()
    }

    // MARK: - Loading

    /// Loads all trivits from the repository.
    func loadTrivits() async {
        isLoading = true
        error = nil

        do {
            trivits = try await repository.fetchAll()
        } catch {
            self.error = .loadFailed(error)
        }

        isLoading = false
    }

    /// Refreshes the trivit list.
    func refresh() async {
        await loadTrivits()
    }

    // MARK: - CRUD Operations

    /// Creates a new trivit with a placeholder title.
    /// - Returns: The newly created trivit, or nil if creation failed
    @discardableResult
    func createTrivit() async -> Trivit? {
        let colorIndex = trivits.count
        let title = placeholderTitle(at: colorIndex)

        let trivit = Trivit(
            title: title,
            count: 0,
            colorIndex: colorIndex,
            isCollapsed: false
        )

        do {
            try await repository.create(trivit)
            trivits.append(trivit)
            editingTrivit = trivit  // Start editing the title
            hapticsService.selection()
            return trivit
        } catch {
            self.error = .createFailed(error)
            return nil
        }
    }

    /// Deletes a trivit.
    /// - Parameter trivit: The trivit to delete
    func deleteTrivit(_ trivit: Trivit) async {
        do {
            try await repository.delete(trivit)
            trivits.removeAll { $0.id == trivit.id }
            hapticsService.selection()
        } catch {
            self.error = .deleteFailed(error)
        }
    }

    /// Deletes trivits at the specified offsets.
    /// - Parameter offsets: The index set of trivits to delete
    func deleteTrivits(at offsets: IndexSet) async {
        let trivitsToDelete = offsets.map { filteredTrivits[$0] }
        for trivit in trivitsToDelete {
            await deleteTrivit(trivit)
        }
    }

    /// Renames a trivit.
    /// - Parameters:
    ///   - trivit: The trivit to rename
    ///   - newTitle: The new title
    func renameTrivit(_ trivit: Trivit, to newTitle: String) async {
        let trimmedTitle = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        trivit.title = trimmedTitle

        // Detect Chinese tally type from title prefix
        if trimmedTitle.hasPrefix("_") {
            trivit.tallyType = .chinese
        }

        do {
            try await repository.update(trivit)
        } catch {
            self.error = .updateFailed(error)
        }

        editingTrivit = nil
    }

    // MARK: - Count Operations

    /// Increments a trivit's count.
    /// - Parameter trivit: The trivit to increment
    func incrementTrivit(_ trivit: Trivit) async {
        let previousCount = trivit.count

        guard trivit.increment() else {
            hapticsService.errorHaptic()
            return
        }

        hapticsService.incrementHaptic()

        // Check for milestones
        if isMilestone(trivit.count) {
            hapticsService.milestoneHaptic()
            // Easter egg handling could go here
        }

        do {
            try await repository.update(trivit)
            await recordHistory(for: trivit, changeType: .increment, previousCount: previousCount)
        } catch {
            // Rollback on failure
            trivit.count = previousCount
            self.error = .updateFailed(error)
        }
    }

    /// Decrements a trivit's count.
    /// - Parameter trivit: The trivit to decrement
    func decrementTrivit(_ trivit: Trivit) async {
        let previousCount = trivit.count

        guard trivit.decrement() else {
            hapticsService.errorHaptic()
            return
        }

        hapticsService.decrementHaptic()

        do {
            try await repository.update(trivit)
            await recordHistory(for: trivit, changeType: .decrement, previousCount: previousCount)
        } catch {
            // Rollback on failure
            trivit.count = previousCount
            self.error = .updateFailed(error)
        }
    }

    /// Resets a trivit's count to zero.
    /// - Parameter trivit: The trivit to reset
    func resetTrivit(_ trivit: Trivit) async {
        let previousCount = trivit.count

        guard previousCount > 0 else { return }

        trivit.reset()
        hapticsService.resetHaptic()

        do {
            try await repository.update(trivit)
            await recordHistory(for: trivit, changeType: .reset, previousCount: previousCount)
        } catch {
            // Rollback on failure
            trivit.count = previousCount
            self.error = .updateFailed(error)
        }
    }

    // MARK: - Collapse/Expand

    /// Toggles a trivit's collapsed state.
    /// - Parameter trivit: The trivit to toggle
    func toggleCollapsed(_ trivit: Trivit) async {
        trivit.toggleCollapsed()
        hapticsService.toggleHaptic()

        do {
            try await repository.update(trivit)
        } catch {
            // Rollback
            trivit.toggleCollapsed()
            self.error = .updateFailed(error)
        }
    }

    /// Expands all trivits.
    func expandAll() async {
        for trivit in trivits where trivit.isCollapsed {
            trivit.isCollapsed = false
        }

        do {
            try await repository.save()
        } catch {
            self.error = .updateFailed(error)
        }
    }

    /// Collapses all trivits.
    func collapseAll() async {
        for trivit in trivits where !trivit.isCollapsed {
            trivit.isCollapsed = true
        }

        do {
            try await repository.save()
        } catch {
            self.error = .updateFailed(error)
        }
    }

    // MARK: - Color

    /// Changes the color of a trivit to the next color in the scheme.
    /// - Parameter trivit: The trivit to update
    func cycleColor(_ trivit: Trivit) async {
        trivit.colorIndex += 1
        hapticsService.selection()

        do {
            try await repository.update(trivit)
        } catch {
            trivit.colorIndex -= 1
            self.error = .updateFailed(error)
        }
    }

    // MARK: - Error Handling

    /// Dismisses the current error.
    func dismissError() {
        error = nil
    }

    // MARK: - Private Helpers

    private func placeholderTitle(at index: Int) -> String {
        placeholderTitles[index % placeholderTitles.count]
    }

    private static func loadPlaceholderTitles() -> [String] {
        let localizedTitles = String(localized: "trivit.placeholders", defaultValue: "Days in prison,Sport cars owned,Days without holiday,Cups of coffee this year,Days of work left,Days without cursing,People stalked,Unfinished Netflix movies,Tallies added,iPhones owned,Bugs in our software,Beers,Pairs of shoes owned,Rainy days,Glasses of water,Stars in the sky")
        return localizedTitles.components(separatedBy: ",")
    }

    private func recordHistory(for trivit: Trivit, changeType: ChangeType, previousCount: Int) async {
        guard let historyRepository else { return }

        let entry = TrivitHistoryEntry(
            trivit: trivit,
            count: trivit.count,
            changeType: changeType,
            previousCount: previousCount
        )

        do {
            try await historyRepository.record(entry)
        } catch {
            // History recording is non-critical, just log
            print("Failed to record history: \(error)")
        }
    }

    private func isMilestone(_ count: Int) -> Bool {
        // Milestones: 10, 25, 50, 100, 250, 500, 1000, etc.
        let milestones = [10, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000]
        return milestones.contains(count) || (count > 0 && count % 1000 == 0)
    }
}

// MARK: - Errors

/// Errors that can occur in TrivitListViewModel
enum TrivitError: LocalizedError, Equatable {
    case loadFailed(Error)
    case createFailed(Error)
    case updateFailed(Error)
    case deleteFailed(Error)
    case syncFailed(Error)

    var errorDescription: String? {
        switch self {
        case .loadFailed:
            return String(localized: "error.load", defaultValue: "Failed to load trivits")
        case .createFailed:
            return String(localized: "error.create", defaultValue: "Failed to create trivit")
        case .updateFailed:
            return String(localized: "error.update", defaultValue: "Failed to save changes")
        case .deleteFailed:
            return String(localized: "error.delete", defaultValue: "Failed to delete trivit")
        case .syncFailed:
            return String(localized: "error.sync", defaultValue: "Sync failed")
        }
    }

    static func == (lhs: TrivitError, rhs: TrivitError) -> Bool {
        switch (lhs, rhs) {
        case (.loadFailed, .loadFailed),
             (.createFailed, .createFailed),
             (.updateFailed, .updateFailed),
             (.deleteFailed, .deleteFailed),
             (.syncFailed, .syncFailed):
            return true
        default:
            return false
        }
    }
}
