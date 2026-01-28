import Foundation
import SwiftData

/// SwiftData implementation of HistoryRepository.
///
/// Provides history tracking and statistics calculation for Trivits.
@MainActor
final class SwiftDataHistoryRepository: HistoryRepository {
    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - HistoryRepository

    nonisolated func fetchHistory(for trivitId: UUID) async throws -> [TrivitHistoryEntry] {
        try await MainActor.run {
            let predicate = #Predicate<TrivitHistoryEntry> { entry in
                entry.trivit?.id == trivitId
            }
            let descriptor = FetchDescriptor(
                predicate: predicate,
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            return try modelContext.fetch(descriptor)
        }
    }

    nonisolated func fetchHistory(
        for trivitId: UUID,
        from startDate: Date,
        to endDate: Date
    ) async throws -> [TrivitHistoryEntry] {
        try await MainActor.run {
            let predicate = #Predicate<TrivitHistoryEntry> { entry in
                entry.trivit?.id == trivitId &&
                entry.timestamp >= startDate &&
                entry.timestamp <= endDate
            }
            let descriptor = FetchDescriptor(
                predicate: predicate,
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            return try modelContext.fetch(descriptor)
        }
    }

    nonisolated func record(_ entry: TrivitHistoryEntry) async throws {
        try await MainActor.run {
            modelContext.insert(entry)
            try modelContext.save()
        }
    }

    nonisolated func calculateStats(for trivitId: UUID) async throws -> TrivitStats {
        try await MainActor.run {
            // Fetch the trivit
            let trivitPredicate = #Predicate<Trivit> { trivit in
                trivit.id == trivitId
            }
            var trivitDescriptor = FetchDescriptor(predicate: trivitPredicate)
            trivitDescriptor.fetchLimit = 1
            guard let trivit = try modelContext.fetch(trivitDescriptor).first else {
                return TrivitStats.empty(for: trivitId)
            }

            // Fetch all history entries
            let historyPredicate = #Predicate<TrivitHistoryEntry> { entry in
                entry.trivit?.id == trivitId
            }
            let historyDescriptor = FetchDescriptor(
                predicate: historyPredicate,
                sortBy: [SortDescriptor(\.timestamp, order: .forward)]
            )
            let history = try modelContext.fetch(historyDescriptor)

            guard !history.isEmpty else {
                return TrivitStats(
                    trivitId: trivitId,
                    currentCount: trivit.count,
                    highestCount: trivit.count
                )
            }

            // Calculate statistics
            var totalIncrements = 0
            var totalDecrements = 0
            var resetCount = 0
            var highestCount = trivit.count

            for entry in history {
                switch entry.changeType {
                case .increment:
                    totalIncrements += 1
                case .decrement:
                    totalDecrements += 1
                case .reset:
                    resetCount += 1
                case .set:
                    break
                }
                highestCount = max(highestCount, entry.count)
            }

            // Calculate daily activity
            let dailyActivity = calculateDailyActivity(from: history)
            let hourlyActivity = calculateHourlyActivity(from: history)

            return TrivitStats(
                trivitId: trivitId,
                currentCount: trivit.count,
                totalIncrements: totalIncrements,
                totalDecrements: totalDecrements,
                resetCount: resetCount,
                highestCount: highestCount,
                firstActivity: history.first?.timestamp,
                lastActivity: history.last?.timestamp,
                dailyActivity: dailyActivity,
                hourlyActivity: hourlyActivity
            )
        }
    }

    nonisolated func deleteHistory(for trivitId: UUID) async throws {
        try await MainActor.run {
            let predicate = #Predicate<TrivitHistoryEntry> { entry in
                entry.trivit?.id == trivitId
            }
            let descriptor = FetchDescriptor(predicate: predicate)
            let entries = try modelContext.fetch(descriptor)
            for entry in entries {
                modelContext.delete(entry)
            }
            try modelContext.save()
        }
    }

    // MARK: - Private Helpers

    private func calculateDailyActivity(from history: [TrivitHistoryEntry]) -> [DailyActivity] {
        let calendar = Calendar.current

        // Group by day
        var dailyGroups: [Date: (increments: Int, decrements: Int, resets: Int)] = [:]

        for entry in history {
            let day = calendar.startOfDay(for: entry.timestamp)
            var existing = dailyGroups[day] ?? (0, 0, 0)

            switch entry.changeType {
            case .increment:
                existing.increments += 1
            case .decrement:
                existing.decrements += 1
            case .reset:
                existing.resets += 1
            case .set:
                break
            }

            dailyGroups[day] = existing
        }

        return dailyGroups.map { date, counts in
            DailyActivity(
                date: date,
                increments: counts.increments,
                decrements: counts.decrements,
                resets: counts.resets
            )
        }.sorted { $0.date < $1.date }
    }

    private func calculateHourlyActivity(from history: [TrivitHistoryEntry]) -> [HourlyActivity] {
        let calendar = Calendar.current
        let now = Date()
        let oneDayAgo = calendar.date(byAdding: .hour, value: -24, to: now) ?? now

        // Filter to last 24 hours
        let recentHistory = history.filter { $0.timestamp >= oneDayAgo }

        // Group by hour
        var hourlyGroups: [Date: (increments: Int, decrements: Int)] = [:]

        for entry in recentHistory {
            let components = calendar.dateComponents([.year, .month, .day, .hour], from: entry.timestamp)
            guard let hour = calendar.date(from: components) else { continue }

            var existing = hourlyGroups[hour] ?? (0, 0)

            switch entry.changeType {
            case .increment:
                existing.increments += 1
            case .decrement:
                existing.decrements += 1
            default:
                break
            }

            hourlyGroups[hour] = existing
        }

        return hourlyGroups.map { hour, counts in
            HourlyActivity(
                hour: hour,
                increments: counts.increments,
                decrements: counts.decrements
            )
        }.sorted { $0.hour < $1.hour }
    }
}
