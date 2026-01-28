import Foundation

/// Protocol defining data access for Trivit history entries.
protocol HistoryRepository: Sendable {
    /// Fetches all history entries for a trivit.
    /// - Parameter trivitId: The ID of the trivit
    /// - Returns: Array of history entries, sorted by timestamp descending
    /// - Throws: If the fetch fails
    func fetchHistory(for trivitId: UUID) async throws -> [TrivitHistoryEntry]

    /// Fetches history entries within a date range.
    /// - Parameters:
    ///   - trivitId: The ID of the trivit
    ///   - startDate: Start of the date range
    ///   - endDate: End of the date range
    /// - Returns: Filtered history entries
    /// - Throws: If the fetch fails
    func fetchHistory(for trivitId: UUID, from startDate: Date, to endDate: Date) async throws -> [TrivitHistoryEntry]

    /// Records a new history entry.
    /// - Parameter entry: The history entry to record
    /// - Throws: If the recording fails
    func record(_ entry: TrivitHistoryEntry) async throws

    /// Calculates statistics from history.
    /// - Parameter trivitId: The ID of the trivit
    /// - Returns: Calculated statistics
    /// - Throws: If calculation fails
    func calculateStats(for trivitId: UUID) async throws -> TrivitStats

    /// Deletes all history for a trivit.
    /// - Parameter trivitId: The ID of the trivit
    /// - Throws: If deletion fails
    func deleteHistory(for trivitId: UUID) async throws
}
