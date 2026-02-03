//
//  TrivitListView.swift
//  Trivit
//
//  Main list view showing all tally counters
//

import SwiftUI
import SwiftData

// Example habit/counter names for new trivits
private let exampleTrivitNames = [
    "Days without candy",
    "Push-ups today",
    "Glasses of water",
    "Books read",
    "Meetings attended",
    "Miles walked",
    "Coffees consumed",
    "Hours of sleep",
    "Minutes meditated",
    "Workouts completed",
    "Steps taken (thousands)",
    "Fruit servings eaten",
    "Pages read",
    "Phone pickups",
    "Gratitude moments",
    "Acts of kindness",
    "Photos taken",
    "Songs listened to",
    "Calories burned",
    "Stretch sessions",
    "Deep breaths taken",
    "Compliments given",
    "New words learned",
    "Emails sent",
    "Tasks completed",
    "Money saved ($)",
    "Vegetables eaten",
    "No-spend days",
    "Early wake-ups",
    "Screen-free hours",
    "Journaling sessions",
    "Cold showers",
    "Healthy meals",
    "Snacks avoided",
    "Flights of stairs",
    "Minutes of reading",
    "Cups of tea",
    "Positive thoughts",
    "Networking contacts",
    "Creative ideas",
    "Home workouts",
    "Yoga sessions",
    "Bike rides",
    "Swimming laps",
    "Alcohol-free days",
    "Puzzles solved",
    "Languages practiced",
    "Podcast episodes",
    "Thank you notes",
    "Random acts of kindness"
]

struct TrivitListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Trivit> { $0.deletedAt == nil }, sort: \Trivit.sortOrder)
    private var trivits: [Trivit]
    @State private var showingSettings = false
    @State private var scrollToBottom = false
    @State private var expandedTrivitIds: Set<UUID> = []
    @State private var draggingTrivit: Trivit?
    @State private var deletedTrivit: Trivit?
    @State private var showUndoToast = false
    @State private var editingTrivitId: UUID?
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                content

                // Undo toast
                if showUndoToast, let trivit = deletedTrivit {
                    undoToast(for: trivit)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 20)
                        .padding(.horizontal, 16)
                }
            }
            .navigationTitle("Trivit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color(.systemBackground), for: .navigationBar)
            .toolbar { toolbarContent }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .overlay {
                if !hasSeenTutorial {
                    tutorialOverlay
                }
            }
        }
    }

    private var tutorialOverlay: some View {
        ZStack {
            // Semi-transparent dark background
            Color.black.opacity(0.75)
                .ignoresSafeArea()

            // Tutorial content
            VStack(spacing: 32) {
                Text("Welcome to Trivit")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 24) {
                    TutorialTipRow(
                        icon: "plus.circle.fill",
                        text: "Tap + to add a new counter"
                    )

                    TutorialTipRow(
                        icon: "arrow.up.arrow.down",
                        text: "Long press and drag to reorder"
                    )

                    TutorialTipRow(
                        icon: "hand.tap.fill",
                        text: "Long press a counter for more options"
                    )
                }

                Button {
                    withAnimation {
                        hasSeenTutorial = true
                    }
                    HapticsService.shared.impact(.light)
                } label: {
                    Text("Got it")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(TrivitColors.color(at: 0))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 8)
            }
            .padding(32)
            .frame(maxWidth: 320)
        }
        .transition(.opacity)
    }

    private func undoToast(for trivit: Trivit) -> some View {
        HStack {
            Text("Deleted \"\(trivit.title)\"")
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer()

            Button("Undo") {
                undoDelete()
            }
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue)
            .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.darkGray))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var content: some View {
        if trivits.isEmpty {
            emptyState
        } else {
            trivitList
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(TrivitColors.color(at: 0))

            Text("No Trivits Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Tap + to create your first tally counter")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var trivitList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(trivits) { trivit in
                        TrivitRowView(
                            trivit: trivit,
                            isExpanded: expandedTrivitIds.contains(trivit.id),
                            startEditing: editingTrivitId == trivit.id,
                            onToggleExpand: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if expandedTrivitIds.contains(trivit.id) {
                                        expandedTrivitIds.remove(trivit.id)
                                    } else {
                                        expandedTrivitIds.insert(trivit.id)
                                    }
                                }
                            },
                            onDelete: { deleteTrivit(trivit) },
                            onEditingChanged: { isEditing in
                                if !isEditing && editingTrivitId == trivit.id {
                                    editingTrivitId = nil
                                }
                            }
                        )
                        .opacity(draggingTrivit?.id == trivit.id ? 0.5 : 1.0)
                        .id(trivit.id)
                        .draggable(trivit.id.uuidString) {
                            // Drag preview
                            TrivitRowView(
                                trivit: trivit,
                                isExpanded: false,
                                startEditing: false,
                                onToggleExpand: {},
                                onDelete: {},
                                onEditingChanged: { _ in }
                            )
                            .frame(width: 300)
                            .opacity(0.9)
                            .onAppear { draggingTrivit = trivit }
                        }
                        .dropDestination(for: String.self) { items, _ in
                            draggingTrivit = nil
                            return true
                        } isTargeted: { isTargeted in
                            // Live reorder when dragging over this item
                            if isTargeted, let fromTrivit = draggingTrivit,
                               fromTrivit.id != trivit.id {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    reorderTrivit(from: fromTrivit, to: trivit)
                                }
                            }
                        }
                    }

                    // Bottom anchor for scrolling
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
            }
            .background(Color(.systemGray5))
            .onChange(of: scrollToBottom) { _, shouldScroll in
                if shouldScroll {
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                    scrollToBottom = false
                }
            }
        }
    }

    private func reorderTrivit(from source: Trivit, to destination: Trivit) {
        let sourceIndex = trivits.firstIndex(where: { $0.id == source.id }) ?? 0
        let destIndex = trivits.firstIndex(where: { $0.id == destination.id }) ?? 0

        guard sourceIndex != destIndex else { return }

        var reordered = trivits.map { $0 }
        let item = reordered.remove(at: sourceIndex)
        reordered.insert(item, at: destIndex)

        // Update sort orders
        for (index, trivit) in reordered.enumerated() {
            trivit.sortOrder = index
        }

        HapticsService.shared.impact(.light)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .foregroundColor(.primary)
            }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: addTrivit) {
                Image(systemName: "plus")
                    .foregroundColor(.primary)
            }
        }
    }

    private func addTrivit() {
        withAnimation {
            // Use the last created trivit's color + 1, cycling through colors
            let lastColorIndex = trivits.last?.colorIndex ?? -1
            let nextColorIndex = (lastColorIndex + 1) % TrivitColors.colorCount

            // Set sort order to be at the end
            let maxSortOrder = trivits.map { $0.sortOrder }.max() ?? -1

            // Pick a random example name for the new trivit
            let randomTitle = exampleTrivitNames.randomElement() ?? "New Trivit"

            let newTrivit = Trivit(
                title: randomTitle,
                colorIndex: nextColorIndex,
                sortOrder: maxSortOrder + 1
            )
            modelContext.insert(newTrivit)
            HapticsService.shared.impact(.medium)

            // Expand the new trivit and trigger edit mode
            expandedTrivitIds.insert(newTrivit.id)

            // Scroll to bottom and trigger edit mode after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                scrollToBottom = true
                editingTrivitId = newTrivit.id
            }
        }
    }

    private func deleteTrivit(_ trivit: Trivit) {
        withAnimation {
            trivit.softDelete()
            deletedTrivit = trivit
            showUndoToast = true
            HapticsService.shared.notification(.warning)

            // Hide toast after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                if deletedTrivit?.id == trivit.id {
                    withAnimation {
                        showUndoToast = false
                        deletedTrivit = nil
                    }
                }
            }
        }
    }

    private func undoDelete() {
        guard let trivit = deletedTrivit else { return }
        withAnimation {
            trivit.restore()
            showUndoToast = false
            deletedTrivit = nil
            HapticsService.shared.impact(.medium)
        }
    }
}

// MARK: - Tutorial Tip Row

private struct TutorialTipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(TrivitColors.color(at: 2))
                .frame(width: 32)

            Text(text)
                .font(.body)
                .foregroundColor(.white)
        }
    }
}

#Preview {
    TrivitListView()
        .modelContainer(for: Trivit.self, inMemory: true)
}
