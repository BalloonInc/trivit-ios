//
//  HistoryView.swift
//  Trivit
//
//  Scrollable list of all tally events for a trivit
//

import SwiftUI
import SwiftData

/// Represents events aggregated by minute
struct MinuteAggregate: Identifiable {
    let id = UUID()
    let minute: Date
    let delta: Int
    let events: [TallyEvent]
}

struct HistoryView: View {
    let trivit: Trivit
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var events: [TallyEvent] = []
    @State private var showingDeleteConfirmation = false
    @State private var aggregateToDelete: MinuteAggregate?

    private var themeColor: Color {
        TrivitColors.color(at: trivit.colorIndex)
    }

    private var statisticsService: StatisticsService {
        StatisticsService(modelContext: modelContext)
    }

    /// Group events by day, then aggregate by minute within each day
    private var groupedByDay: [(date: Date, aggregates: [MinuteAggregate])] {
        let calendar = Calendar.current

        // First group by day
        let byDay = Dictionary(grouping: events) { event in
            calendar.startOfDay(for: event.timestamp)
        }

        return byDay.map { (day, dayEvents) in
            // Within each day, group by minute
            let byMinute = Dictionary(grouping: dayEvents) { event in
                calendar.date(from: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: event.timestamp))!
            }

            let aggregates = byMinute.map { (minute, minuteEvents) in
                MinuteAggregate(
                    minute: minute,
                    delta: minuteEvents.reduce(0) { $0 + $1.delta },
                    events: minuteEvents.sorted { $0.timestamp > $1.timestamp }
                )
            }.sorted { $0.minute > $1.minute }

            return (date: day, aggregates: aggregates)
        }.sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            Group {
                if events.isEmpty {
                    emptyState
                } else {
                    eventList
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadEvents()
            }
            .confirmationDialog(
                "Delete Events",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let aggregate = aggregateToDelete {
                        deleteAggregate(aggregate)
                    }
                }
                Button("Cancel", role: .cancel) {
                    aggregateToDelete = nil
                }
            } message: {
                if let aggregate = aggregateToDelete {
                    Text("Delete \(aggregate.events.count) event(s) (\(aggregate.delta > 0 ? "+" : "")\(aggregate.delta))? This will adjust the trivit count.")
                } else {
                    Text("This will also adjust the trivit count. This action cannot be undone.")
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(themeColor.opacity(0.6))

            Text("No History Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Tally events will appear here as you use the counter.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var eventList: some View {
        List {
            ForEach(groupedByDay, id: \.date) { group in
                Section {
                    ForEach(group.aggregates) { aggregate in
                        AggregateRow(aggregate: aggregate, color: themeColor)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    aggregateToDelete = aggregate
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                } header: {
                    Text(formatSectionDate(group.date))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .textCase(nil)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func formatSectionDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if let daysAgo = calendar.dateComponents([.day], from: date, to: Date()).day, daysAgo < 7 {
            formatter.dateFormat = "EEEE"  // Day name
            return formatter.string(from: date)
        } else {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }

    private func loadEvents() {
        events = statisticsService.fetchEvents(for: trivit.id)
    }

    private func deleteAggregate(_ aggregate: MinuteAggregate) {
        // Adjust the trivit count by the total delta
        trivit.count -= aggregate.delta

        // Delete all events in this aggregate
        for event in aggregate.events {
            statisticsService.deleteEvent(event)
        }

        // Reload events
        loadEvents()

        HapticsService.shared.notification(.warning)
    }
}

// MARK: - Aggregate Row

struct AggregateRow: View {
    let aggregate: MinuteAggregate
    let color: Color

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }

    private var isPositive: Bool {
        aggregate.delta > 0
    }

    private var isNeutral: Bool {
        aggregate.delta == 0
    }

    var body: some View {
        HStack(spacing: 12) {
            // Delta indicator
            ZStack {
                Circle()
                    .fill(isNeutral ? Color.gray.opacity(0.3) : (isPositive ? color : Color.red.opacity(0.7)))
                    .frame(width: 36, height: 36)

                Image(systemName: isNeutral ? "equal" : (isPositive ? "plus" : "minus"))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }

            // Time and event count
            VStack(alignment: .leading, spacing: 2) {
                Text(timeFormatter.string(from: aggregate.minute))
                    .font(.body)
                    .foregroundColor(.primary)

                Text("\(aggregate.events.count) event\(aggregate.events.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Delta value
            Text(aggregate.delta >= 0 ? "+\(aggregate.delta)" : "\(aggregate.delta)")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(isNeutral ? .gray : (isPositive ? color : .red))
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistoryView(trivit: Trivit(title: "Coffee", count: 47, colorIndex: 2))
        .modelContainer(for: [Trivit.self, TallyEvent.self], inMemory: true)
}
