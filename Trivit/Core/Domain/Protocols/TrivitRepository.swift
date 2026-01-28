import Foundation

/// Protocol defining the data access layer for Trivits.
///
/// This abstraction allows for different implementations:
/// - SwiftData for local persistence
/// - CloudKit for sync
/// - Mock implementations for testing
protocol TrivitRepository: Sendable {
    /// Fetches all trivits, sorted by creation date.
    /// - Returns: Array of all trivits
    /// - Throws: If the fetch operation fails
    func fetchAll() async throws -> [Trivit]

    /// Fetches a single trivit by ID.
    /// - Parameter id: The unique identifier of the trivit
    /// - Returns: The trivit if found, nil otherwise
    /// - Throws: If the fetch operation fails
    func fetch(id: UUID) async throws -> Trivit?

    /// Creates a new trivit.
    /// - Parameter trivit: The trivit to create
    /// - Throws: If the creation fails
    func create(_ trivit: Trivit) async throws

    /// Updates an existing trivit.
    /// - Parameter trivit: The trivit to update
    /// - Throws: If the update fails
    func update(_ trivit: Trivit) async throws

    /// Deletes a trivit.
    /// - Parameter trivit: The trivit to delete
    /// - Throws: If the deletion fails
    func delete(_ trivit: Trivit) async throws

    /// Deletes all trivits.
    /// - Throws: If the deletion fails
    func deleteAll() async throws

    /// Saves any pending changes.
    /// - Throws: If the save fails
    func save() async throws

    /// Counts the total number of trivits.
    /// - Returns: The count of trivits
    /// - Throws: If the operation fails
    func count() async throws -> Int
}

// MARK: - Default Implementations

extension TrivitRepository {
    /// Convenience method to fetch all and filter
    func fetchFiltered(_ predicate: (Trivit) -> Bool) async throws -> [Trivit] {
        try await fetchAll().filter(predicate)
    }

    /// Fetches trivits that are not collapsed
    func fetchExpanded() async throws -> [Trivit] {
        try await fetchFiltered { !$0.isCollapsed }
    }

    /// Fetches trivits that are collapsed
    func fetchCollapsed() async throws -> [Trivit] {
        try await fetchFiltered { $0.isCollapsed }
    }
}
