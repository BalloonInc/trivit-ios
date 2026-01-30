//
//  StatisticsView.swift
//  Trivit
//
//  Statistics dashboard with charts for a trivit
//

import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    let trivit: Trivit
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab = 0

    private var statisticsService: StatisticsService {
        StatisticsService(modelContext: modelContext)
    }

    private var themeColor: Color {
        TrivitColors.color(at: trivit.colorIndex)
    }

    private var darkThemeColor: Color {
        TrivitColors.darkColor(at: trivit.colorIndex)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Summary Cards
                    summarySection

                    // Charts
                    VStack(spacing: 20) {
                        hourlyChart
                        weeklyChart
                        monthlyChart
                        dailyActivityChart
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        let streak = statisticsService.streakData(for: trivit.id)

        return VStack(spacing: 12) {
            HStack(spacing: 12) {
                SummaryCard(
                    title: "Total",
                    value: "\(trivit.count)",
                    icon: "number",
                    color: themeColor
                )

                SummaryCard(
                    title: "Current Streak",
                    value: "\(streak.currentStreak)",
                    icon: "flame.fill",
                    color: streak.currentStreak > 0 ? .orange : .gray
                )
            }

            HStack(spacing: 12) {
                SummaryCard(
                    title: "Longest Streak",
                    value: "\(streak.longestStreak)",
                    icon: "trophy.fill",
                    color: .yellow
                )

                SummaryCard(
                    title: "Days Tracked",
                    value: formattedDaysSinceCreation,
                    icon: "calendar",
                    color: themeColor
                )
            }
        }
        .padding(.horizontal)
    }

    private var formattedDaysSinceCreation: String {
        let days = Calendar.current.dateComponents([.day], from: trivit.createdAt, to: Date()).day ?? 0
        return "\(max(1, days))"
    }

    // MARK: - Hourly Chart

    private var hourlyChart: some View {
        let data = statisticsService.countsByHourOfDay(for: trivit.id)
        let maxCount = data.map(\.count).max() ?? 1

        return ChartCard(title: "Activity by Hour", icon: "clock") {
            Chart(data) { item in
                BarMark(
                    x: .value("Hour", formatHour(item.hour)),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(themeColor.gradient)
                .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel()
                    AxisGridLine()
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: 6)) { value in
                    AxisValueLabel()
                }
            }
            .chartYScale(domain: 0...(max(Double(maxCount), 1)))
            .frame(height: 180)
        }
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let date = Calendar.current.date(from: DateComponents(hour: hour)) ?? Date()
        return formatter.string(from: date).lowercased()
    }

    // MARK: - Weekly Chart

    private var weeklyChart: some View {
        let data = statisticsService.countsByDayOfWeek(for: trivit.id)
        let maxCount = data.map(\.count).max() ?? 1

        return ChartCard(title: "Activity by Day of Week", icon: "calendar.badge.clock") {
            Chart(data) { item in
                BarMark(
                    x: .value("Day", item.dayName),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(themeColor.gradient)
                .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartYScale(domain: 0...(max(Double(maxCount), 1)))
            .frame(height: 180)
        }
    }

    // MARK: - Monthly Chart

    private var monthlyChart: some View {
        let data = statisticsService.monthlyTotals(for: trivit.id, months: 6)
        let maxCount = data.map(\.count).max() ?? 1

        return ChartCard(title: "Monthly Trend", icon: "chart.line.uptrend.xyaxis") {
            Chart(data) { item in
                LineMark(
                    x: .value("Month", item.month, unit: .month),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(themeColor)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .symbol(Circle())
                .symbolSize(40)

                AreaMark(
                    x: .value("Month", item.month, unit: .month),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [themeColor.opacity(0.3), themeColor.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { value in
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
            .chartYScale(domain: 0...(max(Double(maxCount) * 1.1, 1)))
            .frame(height: 180)
        }
    }

    // MARK: - Daily Activity Chart

    private var dailyActivityChart: some View {
        let data = statisticsService.dailyActivity(for: trivit.id, days: 30)
        let maxCount = data.map(\.count).max() ?? 1

        return ChartCard(title: "Last 30 Days", icon: "chart.bar.fill") {
            Chart(data) { item in
                BarMark(
                    x: .value("Date", item.date, unit: .day),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(item.count > 0 ? themeColor : Color.gray.opacity(0.3))
                .cornerRadius(2)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { value in
                    AxisValueLabel(format: .dateTime.day())
                }
            }
            .chartYScale(domain: 0...(max(Double(maxCount), 1)))
            .frame(height: 180)
        }
    }
}

// MARK: - Summary Card

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Chart Card

struct ChartCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            content
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    StatisticsView(trivit: Trivit(title: "Coffee", count: 47, colorIndex: 2))
        .modelContainer(for: [Trivit.self, TallyEvent.self], inMemory: true)
}
