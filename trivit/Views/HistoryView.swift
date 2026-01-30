//
//  HistoryView.swift
//  Trivit
//
//  Scrollable list of all tally events for a trivit
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    let trivit: Trivit
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var events: [TallyEvent] = []
    @State private var showingDeleteConfirmation = false
    @State private var eventToDelete: TallyEvent?

    private var themeColor: Color {
        TrivitColors.color(at: trivit.colorIndex)
    }

    private var statisticsService: StatisticsService {
        StatisticsService(modelContext: modelContext)
    }

    private var groupedEvents: [(date: Date, events: [TallyEvent])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: events) { event in
            calendar.startOfDay(for: event.timestamp)
        }
        return grouped.map { (date: $0.key, events: $0.value) }
            .sorted { $0.date > $1.date }
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
                "Delete Event",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let event = eventToDelete {
                        deleteEvent(event)
                    }
                }
                Button("Cancel", role: .cancel) {
                    eventToDelete = nil
                }
            } message: {
                Text("This will also adjust the trivit count. This action cannot be undone.")
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
            ForEach(groupedEvents, id: \.date) { group in
                Section {
                    ForEach(group.events) { event in
                        EventRow(event: event, color: themeColor)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    eventToDelete = event
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

    private func deleteEvent(_ event: TallyEvent) {
        // Adjust the trivit count
        trivit.count -= event.delta

        // Delete the event
        statisticsService.deleteEvent(event)

        // Reload events
        loadEvents()

        HapticsService.shared.notification(.warning)
    }
}

// MARK: - Event Row

struct EventRow: View {
    let event: TallyEvent
    let color: Color

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        HStack(spacing: 12) {
            // Delta indicator
            ZStack {
                Circle()
                    .fill(event.delta > 0 ? color : Color.gray.opacity(0.3))
                    .frame(width: 36, height: 36)

                Image(systemName: event.delta > 0 ? "plus" : "minus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }

            // Time and delta
            VStack(alignment: .leading, spacing: 2) {
                Text(timeFormatter.string(from: event.timestamp))
                    .font(.body)
                    .foregroundColor(.primary)

                Text(event.delta > 0 ? "Increment" : "Decrement")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Delta value
            Text(event.delta > 0 ? "+1" : "-1")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(event.delta > 0 ? color : .gray)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistoryView(trivit: Trivit(title: "Coffee", count: 47, colorIndex: 2))
        .modelContainer(for: [Trivit.self, TallyEvent.self], inMemory: true)
}
