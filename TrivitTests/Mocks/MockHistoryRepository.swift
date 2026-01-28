import Foundation
@testable import Trivit

/// Mock implementation of HistoryRepository for testing.
final class MockHistoryRepository: HistoryRepository, @unchecked Sendable {
    // MARK: - Stored Data

    var entries: [UUID: [TrivitHistoryEntry]] = [:]

    // MARK: - Call Tracking

    var fetchHistoryCalled = false
    var fetchHistoryCalledWith: UUID?

    var fetchHistoryRangeCalled = false

    var recordCalled = false
    var recordCalledWith: TrivitHistoryEntry?
    var recordCount = 0

    var calculateStatsCalled = false
    var calculateStatsCalledWith: UUID?

    var deleteHistoryCalled = false
    var deleteHistoryCalledWith: UUID?

    // MARK: - Error Configuration

    var fetchHistoryError: Error?
    var recordError: Error?
    var calculateStatsError: Error?
    var deleteHistoryError: Error?

    // MARK: - Mock Stats

    var mockStats: TrivitStats?

    // MARK: - HistoryRepository Implementation

    func fetchHistory(for trivitId: UUID) async throws -> [TrivitHistoryEntry] {
        fetchHistoryCalled = true
        fetchHistoryCalledWith = trivitId

        if let error = fetchHistoryError {
            throw error
        }

        return entries[trivitId] ?? []
    }

    func fetchHistory(for trivitId: UUID, from startDate: Date, to endDate: Date) async throws -> [TrivitHistoryEntry] {
        fetchHistoryRangeCalled = true

        if let error = fetchHistoryError {
            throw error
        }

        return (entries[trivitId] ?? []).filter { entry in
            entry.timestamp >= startDate && entry.timestamp <= endDate
        }
    }

    func record(_ entry: TrivitHistoryEntry) async throws {
        recordCalled = true
        recordCalledWith = entry
        recordCount += 1

        if let error = recordError {
            throw error
        }

        if let trivitId = entry.trivit?.id {
            entries[trivitId, default: []].append(entry)
        }
    }

    func calculateStats(for trivitId: UUID) async throws -> TrivitStats {
        calculateStatsCalled = true
        calculateStatsCalledWith = trivitId

        if let error = calculateStatsError {
            throw error
        }

        if let mockStats {
            return mockStats
        }

        let history = entries[trivitId] ?? []
        return TrivitStats(
            trivitId: trivitId,
            currentCount: history.last?.count ?? 0,
            totalIncrements: history.filter { $0.changeType == .increment }.count,
            totalDecrements: history.filter { $0.changeType == .decrement }.count,
            resetCount: history.filter { $0.changeType == .reset }.count,
            highestCount: history.map { $0.count }.max() ?? 0,
            firstActivity: history.first?.timestamp,
            lastActivity: history.last?.timestamp
        )
    }

    func deleteHistory(for trivitId: UUID) async throws {
        deleteHistoryCalled = true
        deleteHistoryCalledWith = trivitId

        if let error = deleteHistoryError {
            throw error
        }

        entries[trivitId] = nil
    }

    // MARK: - Test Helpers

    func reset() {
        entries.removeAll()
        fetchHistoryCalled = false
        fetchHistoryCalledWith = nil
        fetchHistoryRangeCalled = false
        recordCalled = false
        recordCalledWith = nil
        recordCount = 0
        calculateStatsCalled = false
        calculateStatsCalledWith = nil
        deleteHistoryCalled = false
        deleteHistoryCalledWith = nil

        fetchHistoryError = nil
        recordError = nil
        calculateStatsError = nil
        deleteHistoryError = nil
        mockStats = nil
    }
}
