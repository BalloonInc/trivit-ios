import SwiftUI

/// A GitHub-style contribution heatmap calendar view.
///
/// Displays activity intensity over time using colored cells,
/// with weeks as columns and days as rows.
struct CalendarHeatmapView: View {
    // MARK: - Properties

    /// Activity data by date
    let activityData: [Date: Int]

    /// Number of weeks to display
    let weeksToShow: Int

    /// Color scheme for the heatmap
    let colorScheme: HeatmapColorScheme

    /// Optional: When a cell is tapped
    var onCellTap: ((Date, Int) -> Void)?

    @State private var selectedCell: Date?

    // MARK: - Constants

    private let cellSize: CGFloat = 12
    private let cellSpacing: CGFloat = 3
    private let dayLabels = ["", "Mon", "", "Wed", "", "Fri", ""]

    // MARK: - Computed Properties

    /// The end date (today)
    private var endDate: Date {
        Calendar.current.startOfDay(for: Date())
    }

    /// The start date based on weeks to show
    private var startDate: Date {
        Calendar.current.date(byAdding: .weekOfYear, value: -weeksToShow, to: endDate) ?? endDate
    }

    /// Weeks of dates for the heatmap
    private var weeks: [[Date?]] {
        let calendar = Calendar.current

        // Find the Sunday before or on start date
        var currentDate = startDate
        while calendar.component(.weekday, from: currentDate) != 1 {
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }

        var result: [[Date?]] = []

        while currentDate <= endDate {
            var week: [Date?] = []
            for _ in 0..<7 {
                if currentDate >= startDate && currentDate <= endDate {
                    week.append(currentDate)
                } else {
                    week.append(nil)
                }
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
            result.append(week)
        }

        return result
    }

    /// Maximum activity value for scaling colors
    private var maxActivity: Int {
        max(1, activityData.values.max() ?? 1)
    }

    /// Month labels and positions
    private var monthLabels: [(String, Int)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        var labels: [(String, Int)] = []
        var lastMonth: Int?

        for (weekIndex, week) in weeks.enumerated() {
            for day in week.compactMap({ $0 }) {
                let month = calendar.component(.month, from: day)
                if month != lastMonth {
                    labels.append((formatter.string(from: day), weekIndex))
                    lastMonth = month
                    break
                }
            }
        }

        return labels
    }

    // MARK: - Initialization

    init(
        activityData: [Date: Int],
        weeksToShow: Int = 52,
        colorScheme: HeatmapColorScheme = .green,
        onCellTap: ((Date, Int) -> Void)? = nil
    ) {
        self.activityData = activityData
        self.weeksToShow = weeksToShow
        self.colorScheme = colorScheme
        self.onCellTap = onCellTap
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Month labels
            monthLabelsRow

            HStack(alignment: .top, spacing: cellSpacing) {
                // Day labels
                dayLabelsColumn

                // Heatmap grid
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: cellSpacing) {
                        ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                            VStack(spacing: cellSpacing) {
                                ForEach(0..<7, id: \.self) { dayIndex in
                                    if let date = week[dayIndex] {
                                        cellView(for: date)
                                    } else {
                                        Color.clear
                                            .frame(width: cellSize, height: cellSize)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Legend
            legendView
        }
    }

    // MARK: - Subviews

    private var monthLabelsRow: some View {
        HStack(spacing: 0) {
            // Spacer for day labels
            Color.clear
                .frame(width: 30)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(monthLabels, id: \.1) { label, weekIndex in
                        Text(label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(width: CGFloat(weekIndex) * (cellSize + cellSpacing), alignment: .leading)
                    }
                    Spacer()
                }
            }
        }
    }

    private var dayLabelsColumn: some View {
        VStack(spacing: cellSpacing) {
            ForEach(0..<7, id: \.self) { index in
                Text(dayLabels[index])
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: cellSize, alignment: .trailing)
            }
        }
    }

    private func cellView(for date: Date) -> some View {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)
        let activity = activityData[normalizedDate] ?? 0
        let isSelected = selectedCell == normalizedDate

        return RoundedRectangle(cornerRadius: 2)
            .fill(colorForActivity(activity))
            .frame(width: cellSize, height: cellSize)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 1)
            )
            .onTapGesture {
                selectedCell = normalizedDate
                onCellTap?(normalizedDate, activity)
            }
            .accessibilityLabel(accessibilityLabel(for: date, activity: activity))
    }

    private var legendView: some View {
        HStack(spacing: 4) {
            Spacer()

            Text("Less")
                .font(.caption2)
                .foregroundStyle(.secondary)

            ForEach(0..<5, id: \.self) { level in
                RoundedRectangle(cornerRadius: 2)
                    .fill(colorScheme.color(for: level, maxLevel: 4))
                    .frame(width: cellSize, height: cellSize)
            }

            Text("More")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private func colorForActivity(_ activity: Int) -> Color {
        guard activity > 0 else {
            return colorScheme.emptyColor
        }

        let normalized = Double(activity) / Double(maxActivity)
        let level = min(4, Int(normalized * 4) + 1)

        return colorScheme.color(for: level, maxLevel: 4)
    }

    private func accessibilityLabel(for date: Date, activity: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateString = formatter.string(from: date)

        if activity == 0 {
            return "\(dateString): No activity"
        } else if activity == 1 {
            return "\(dateString): 1 count"
        } else {
            return "\(dateString): \(activity) counts"
        }
    }
}

// MARK: - Heatmap Color Scheme

/// Color schemes for the heatmap.
enum HeatmapColorScheme: String, CaseIterable, Identifiable {
    case green
    case blue
    case purple
    case orange
    case pink

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var emptyColor: Color {
        Color(.systemGray5)
    }

    func color(for level: Int, maxLevel: Int) -> Color {
        guard level > 0 else { return emptyColor }

        let intensity = Double(level) / Double(maxLevel)

        switch self {
        case .green:
            return Color(
                hue: 0.35,
                saturation: 0.6 + (intensity * 0.3),
                brightness: 0.9 - (intensity * 0.4)
            )
        case .blue:
            return Color(
                hue: 0.58,
                saturation: 0.6 + (intensity * 0.3),
                brightness: 0.9 - (intensity * 0.4)
            )
        case .purple:
            return Color(
                hue: 0.75,
                saturation: 0.5 + (intensity * 0.4),
                brightness: 0.85 - (intensity * 0.35)
            )
        case .orange:
            return Color(
                hue: 0.08,
                saturation: 0.6 + (intensity * 0.3),
                brightness: 0.95 - (intensity * 0.3)
            )
        case .pink:
            return Color(
                hue: 0.92,
                saturation: 0.5 + (intensity * 0.4),
                brightness: 0.9 - (intensity * 0.3)
            )
        }
    }
}

// MARK: - Convenience Extensions

extension CalendarHeatmapView {
    /// Creates a heatmap from DailyActivity array.
    init(
        dailyActivity: [DailyActivity],
        weeksToShow: Int = 52,
        colorScheme: HeatmapColorScheme = .green,
        onCellTap: ((Date, Int) -> Void)? = nil
    ) {
        let calendar = Calendar.current
        var data: [Date: Int] = [:]

        for activity in dailyActivity {
            let normalizedDate = calendar.startOfDay(for: activity.date)
            data[normalizedDate] = activity.increments
        }

        self.init(
            activityData: data,
            weeksToShow: weeksToShow,
            colorScheme: colorScheme,
            onCellTap: onCellTap
        )
    }
}

// MARK: - Preview

#Preview("Calendar Heatmap") {
    let calendar = Calendar.current
    let today = Date()

    // Generate sample data
    var sampleData: [Date: Int] = [:]
    for dayOffset in 0..<365 {
        if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
            let normalizedDate = calendar.startOfDay(for: date)
            // Random activity with higher probability of zero
            if Int.random(in: 0...10) > 3 {
                sampleData[normalizedDate] = Int.random(in: 1...15)
            }
        }
    }

    return ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            Text("Activity Heatmap")
                .font(.headline)

            CalendarHeatmapView(
                activityData: sampleData,
                weeksToShow: 26,
                colorScheme: .green
            ) { date, count in
                print("Tapped \(date): \(count)")
            }

            Divider()

            Text("Color Schemes")
                .font(.headline)

            ForEach(HeatmapColorScheme.allCases) { scheme in
                VStack(alignment: .leading) {
                    Text(scheme.displayName)
                        .font(.subheadline)

                    CalendarHeatmapView(
                        activityData: sampleData,
                        weeksToShow: 12,
                        colorScheme: scheme
                    )
                }
            }
        }
        .padding()
    }
}
