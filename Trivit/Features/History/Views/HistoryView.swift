import SwiftUI
import Charts

/// View displaying history and statistics for a trivit.
struct HistoryView: View {
    // MARK: - Properties

    let trivit: Trivit
    @State private var viewModel: HistoryViewModel?
    @State private var selectedTimeRange: TimeRange = .week

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let viewModel, let stats = viewModel.stats {
                        summarySection(stats)
                        heatmapSection(stats)
                        chartSection
                        statsGridSection(stats)
                        recentActivitySection
                    } else {
                        ProgressView()
                    }
                }
                .padding()
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task {
            await setupViewModel()
        }
    }

    // MARK: - Sections

    private func summarySection(_ stats: TrivitStats) -> some View {
        VStack(spacing: 8) {
            Text(trivit.title)
                .font(.headline)

            Text("\(stats.currentCount)")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("Current Count")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @State private var selectedHeatmapDate: Date?
    @State private var selectedHeatmapActivity: Int = 0

    private func heatmapSection(_ stats: TrivitStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Activity Heatmap")
                    .font(.headline)

                Spacer()

                if let date = selectedHeatmapDate {
                    Text("\(date, style: .date): \(selectedHeatmapActivity)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            CalendarHeatmapView(
                dailyActivity: stats.dailyActivity,
                weeksToShow: 26,
                colorScheme: .green
            ) { date, count in
                selectedHeatmapDate = date
                selectedHeatmapActivity = count
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Activity")
                    .font(.headline)

                Spacer()

                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.menu)
            }

            if let viewModel {
                Chart(viewModel.histogramData) { point in
                    BarMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Change", point.value)
                    )
                    .foregroundStyle(point.value >= 0 ? Color.green : Color.red)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func statsGridSection(_ stats: TrivitStats) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(
                title: "Total Increments",
                value: "\(stats.totalIncrements)",
                icon: "plus.circle.fill",
                color: .green
            )

            StatCard(
                title: "Total Decrements",
                value: "\(stats.totalDecrements)",
                icon: "minus.circle.fill",
                color: .red
            )

            StatCard(
                title: "Times Reset",
                value: "\(stats.resetCount)",
                icon: "arrow.counterclockwise",
                color: .orange
            )

            StatCard(
                title: "Highest Count",
                value: "\(stats.highestCount)",
                icon: "chart.line.uptrend.xyaxis",
                color: .blue
            )

            StatCard(
                title: "Current Streak",
                value: "\(stats.currentStreak) days",
                icon: "flame.fill",
                color: .orange
            )

            StatCard(
                title: "Longest Streak",
                value: "\(stats.longestStreak) days",
                icon: "trophy.fill",
                color: .yellow
            )
        }
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)

            if let viewModel, !viewModel.recentHistory.isEmpty {
                ForEach(viewModel.recentHistory.prefix(10)) { entry in
                    HistoryEntryRow(entry: entry)
                }
            } else {
                Text("No activity recorded yet")
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
    }

    // MARK: - Setup

    private func setupViewModel() async {
        let repository = SwiftDataHistoryRepository(modelContext: modelContext)
        viewModel = HistoryViewModel(trivit: trivit, historyRepository: repository)
        await viewModel?.load()
    }
}

// MARK: - Preview Mock Repository

#if DEBUG
/// Mock history repository for SwiftUI previews
@MainActor
final class PreviewHistoryRepository: HistoryRepository {
    nonisolated func fetchHistory(for trivitId: UUID) async throws -> [TrivitHistoryEntry] {
        []
    }

    nonisolated func fetchHistory(for trivitId: UUID, from startDate: Date, to endDate: Date) async throws -> [TrivitHistoryEntry] {
        []
    }

    nonisolated func record(_ entry: TrivitHistoryEntry) async throws {}

    nonisolated func calculateStats(for trivitId: UUID) async throws -> TrivitStats {
        TrivitStats(
            trivitId: trivitId,
            currentCount: 42,
            totalIncrements: 62,
            totalDecrements: 20,
            resetCount: 2,
            highestCount: 92,
            firstActivity: Calendar.current.date(byAdding: .month, value: -1, to: Date()),
            lastActivity: Date(),
            dailyActivity: generateMockDailyActivity()
        )
    }

    nonisolated func deleteHistory(for trivitId: UUID) async throws {}

    private nonisolated func generateMockDailyActivity() -> [DailyActivity] {
        let calendar = Calendar.current
        let today = Date()

        return (0..<365).compactMap { dayOffset -> DailyActivity? in
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                return nil
            }
            let weekday = calendar.component(.weekday, from: date)
            let isWeekend = weekday == 1 || weekday == 7
            let baseChance = isWeekend ? 3 : 7

            if Int.random(in: 0...10) > baseChance {
                return nil
            }

            return DailyActivity(
                date: date,
                increments: Int.random(in: 1...15),
                decrements: Int.random(in: 0...3),
                resets: dayOffset % 14 == 0 ? 1 : 0
            )
        }
    }
}
#endif

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - History Entry Row

struct HistoryEntryRow: View {
    let entry: TrivitHistoryEntry

    var body: some View {
        HStack {
            Image(systemName: entry.changeType.symbolName)
                .foregroundStyle(colorForChangeType)

            VStack(alignment: .leading) {
                Text(entry.changeType.displayName)
                    .font(.subheadline)

                Text(entry.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(entry.previousCount) → \(entry.count)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(colorForChangeType)
        }
        .padding(.vertical, 4)
    }

    private var colorForChangeType: Color {
        switch entry.changeType {
        case .increment:
            return .green
        case .decrement:
            return .red
        case .reset:
            return .orange
        case .set:
            return .blue
        }
    }
}

// MARK: - Preview

#Preview {
    HistoryView(trivit: .preview)
        .modelContainer(for: Trivit.self, inMemory: true)
}
