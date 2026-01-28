import Foundation
import Observation

/// ViewModel for the history and statistics view.
@Observable
@MainActor
final class HistoryViewModel {
    // MARK: - State

    /// The trivit we're showing history for
    let trivit: Trivit

    /// Statistics for the trivit
    private(set) var stats: TrivitStats?

    /// Recent history entries
    private(set) var recentHistory: [TrivitHistoryEntry] = []

    /// Whether data is loading
    private(set) var isLoading = false

    /// Current error, if any
    private(set) var error: Error?

    /// Selected time range for charts
    var selectedTimeRange: TimeRange = .week

    // MARK: - Computed Properties

    /// Data points for the histogram
    var histogramData: [HistogramDataPoint] {
        guard let stats else { return [] }

        return stats.dailyActivity.map { activity in
            HistogramDataPoint(
                date: activity.date,
                value: activity.netChange
            )
        }
        .sorted { $0.date < $1.date }
        .suffix(selectedTimeRange.days)
        .map { $0 }
    }

    /// Peak activity day
    var peakDay: DailyActivity? {
        stats?.dailyActivity.max { $0.totalActivity < $1.totalActivity }
    }

    /// Average daily increments
    var averageDailyIncrements: Double {
        stats?.averageIncrementsPerDay ?? 0
    }

    // MARK: - Dependencies

    private let historyRepository: HistoryRepository

    // MARK: - Initialization

    init(trivit: Trivit, historyRepository: HistoryRepository) {
        self.trivit = trivit
        self.historyRepository = historyRepository
    }

    // MARK: - Loading

    /// Loads history and stats for the trivit.
    func load() async {
        isLoading = true
        error = nil

        do {
            async let statsTask = historyRepository.calculateStats(for: trivit.id)
            async let historyTask = historyRepository.fetchHistory(for: trivit.id)

            stats = try await statsTask
            recentHistory = try await Array(historyTask.prefix(50))
        } catch {
            self.error = error
        }

        isLoading = false
    }

    /// Refreshes the data.
    func refresh() async {
        await load()
    }

    // MARK: - Error Handling

    func dismissError() {
        error = nil
    }
}

// MARK: - Time Range

/// Time ranges for chart filtering.
enum TimeRange: String, CaseIterable, Identifiable {
    case week = "7 Days"
    case month = "30 Days"
    case threeMonths = "90 Days"
    case year = "1 Year"
    case allTime = "All Time"

    var id: String { rawValue }

    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        case .year: return 365
        case .allTime: return Int.max
        }
    }
}

// MARK: - Histogram Data Point

/// A single data point for the histogram.
struct HistogramDataPoint: Identifiable {
    var id: Date { date }

    let date: Date
    let value: Int
}
