import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Widget Provider

/// Timeline provider for Trivit widgets.
struct TrivitWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> TrivitWidgetEntry {
        TrivitWidgetEntry(
            date: Date(),
            trivits: [
                WidgetTrivit(id: UUID(), title: "Coffee cups", count: 42, colorIndex: 0),
                WidgetTrivit(id: UUID(), title: "Push-ups", count: 25, colorIndex: 1),
                WidgetTrivit(id: UUID(), title: "Steps", count: 10000, colorIndex: 2)
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TrivitWidgetEntry) -> Void) {
        let entry = TrivitWidgetEntry(
            date: Date(),
            trivits: loadTrivits()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TrivitWidgetEntry>) -> Void) {
        let entry = TrivitWidgetEntry(
            date: Date(),
            trivits: loadTrivits()
        )

        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    /// Loads trivits from the shared container.
    private func loadTrivits() -> [WidgetTrivit] {
        // In a real implementation, this would load from SwiftData
        // using a shared App Group container
        return [
            WidgetTrivit(id: UUID(), title: "Coffee cups", count: 42, colorIndex: 0),
            WidgetTrivit(id: UUID(), title: "Push-ups", count: 25, colorIndex: 1),
            WidgetTrivit(id: UUID(), title: "Steps", count: 10000, colorIndex: 2)
        ]
    }
}

// MARK: - Widget Entry

/// Entry for Trivit widget timeline.
struct TrivitWidgetEntry: TimelineEntry {
    let date: Date
    let trivits: [WidgetTrivit]
}

/// Lightweight trivit representation for widgets.
struct WidgetTrivit: Identifiable {
    let id: UUID
    let title: String
    let count: Int
    let colorIndex: Int
}

// MARK: - Small Widget View

/// Small widget showing a single trivit.
struct SmallTrivitWidget: View {
    let entry: TrivitWidgetEntry

    private var trivit: WidgetTrivit? {
        entry.trivits.first
    }

    var body: some View {
        if let trivit {
            VStack(alignment: .leading, spacing: 4) {
                Text(trivit.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Spacer()

                Text("\(trivit.count)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding()
            .background(TrivitColors.color(at: trivit.colorIndex, scheme: 2, isDark: true))
        } else {
            emptyState
        }
    }

    private var emptyState: some View {
        VStack {
            Image(systemName: "tally")
                .font(.title)
            Text("No Trivits")
                .font(.caption)
        }
        .foregroundStyle(.secondary)
    }
}

// MARK: - Medium Widget View

/// Medium widget showing 2-3 trivits.
struct MediumTrivitWidget: View {
    let entry: TrivitWidgetEntry

    var body: some View {
        HStack(spacing: 8) {
            ForEach(entry.trivits.prefix(3)) { trivit in
                trivitCell(trivit)
            }
        }
        .padding(8)
    }

    private func trivitCell(_ trivit: WidgetTrivit) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(trivit.title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            Text("\(trivit.count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(8)
        .background(TrivitColors.color(at: trivit.colorIndex, scheme: 2, isDark: true))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Large Widget View

/// Large widget showing a grid of trivits.
struct LargeTrivitWidget: View {
    let entry: TrivitWidgetEntry

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(entry.trivits.prefix(6)) { trivit in
                trivitCell(trivit)
            }
        }
        .padding(8)
    }

    private func trivitCell(_ trivit: WidgetTrivit) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(trivit.title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .lineLimit(2)

            Spacer()

            HStack {
                Text("\(trivit.count)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Spacer()

                // Tally indicator
                Image(systemName: "tally")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(12)
        .background(TrivitColors.color(at: trivit.colorIndex, scheme: 2, isDark: true))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Widget Configuration

/// The main Trivit widget.
struct TrivitWidget: Widget {
    let kind: String = "TrivitWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TrivitWidgetProvider()) { entry in
            TrivitWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Trivit Counter")
        .description("Track your counts at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

/// Entry view that selects the appropriate size.
struct TrivitWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: TrivitWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallTrivitWidget(entry: entry)
        case .systemMedium:
            MediumTrivitWidget(entry: entry)
        case .systemLarge:
            LargeTrivitWidget(entry: entry)
        default:
            SmallTrivitWidget(entry: entry)
        }
    }
}

// MARK: - Preview

#Preview("Small", as: .systemSmall) {
    TrivitWidget()
} timeline: {
    TrivitWidgetEntry(
        date: Date(),
        trivits: [WidgetTrivit(id: UUID(), title: "Coffee cups", count: 42, colorIndex: 0)]
    )
}

#Preview("Medium", as: .systemMedium) {
    TrivitWidget()
} timeline: {
    TrivitWidgetEntry(
        date: Date(),
        trivits: [
            WidgetTrivit(id: UUID(), title: "Coffee", count: 42, colorIndex: 0),
            WidgetTrivit(id: UUID(), title: "Push-ups", count: 25, colorIndex: 1),
            WidgetTrivit(id: UUID(), title: "Steps", count: 10000, colorIndex: 2)
        ]
    )
}

#Preview("Large", as: .systemLarge) {
    TrivitWidget()
} timeline: {
    TrivitWidgetEntry(
        date: Date(),
        trivits: [
            WidgetTrivit(id: UUID(), title: "Coffee cups", count: 42, colorIndex: 0),
            WidgetTrivit(id: UUID(), title: "Push-ups", count: 25, colorIndex: 1),
            WidgetTrivit(id: UUID(), title: "Steps", count: 10000, colorIndex: 2),
            WidgetTrivit(id: UUID(), title: "Books read", count: 8, colorIndex: 3),
            WidgetTrivit(id: UUID(), title: "Days sober", count: 365, colorIndex: 4),
            WidgetTrivit(id: UUID(), title: "Meetings", count: 127, colorIndex: 5)
        ]
    )
}
