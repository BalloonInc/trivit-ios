//
//  TrivitListView.swift
//  Trivit
//
//  Main list view showing all tally counters
//

import SwiftUI
import SwiftData

struct TrivitListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trivit.sortOrder) private var trivits: [Trivit]
    @State private var showingSettings = false
    @State private var scrollToBottom = false
    @State private var expandedTrivitIds: Set<UUID> = []

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Trivit")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(Color(.systemBackground), for: .navigationBar)
                .toolbar { toolbarContent }
                .sheet(isPresented: $showingSettings) {
                    SettingsView()
                }
        }
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
            List {
                ForEach(trivits) { trivit in
                    TrivitRowView(
                        trivit: trivit,
                        isExpanded: expandedTrivitIds.contains(trivit.id),
                        onToggleExpand: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                if expandedTrivitIds.contains(trivit.id) {
                                    expandedTrivitIds.remove(trivit.id)
                                } else {
                                    expandedTrivitIds.insert(trivit.id)
                                }
                            }
                        },
                        onDelete: { deleteTrivit(trivit) }
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color(.systemGray5))
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteTrivit(trivit)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .id(trivit.id)
                }
                .onMove(perform: moveTrivits)

                // Bottom anchor for scrolling
                Color.clear
                    .frame(height: 1)
                    .id("bottom")
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color(.systemGray5))
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
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
        .background(Color(.systemGray5))
    }

    private func moveTrivits(from source: IndexSet, to destination: Int) {
        var reorderedTrivits = trivits.map { $0 }
        reorderedTrivits.move(fromOffsets: source, toOffset: destination)

        // Update sort order for all items
        for (index, trivit) in reorderedTrivits.enumerated() {
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

            let newTrivit = Trivit(
                title: "New Trivit",
                colorIndex: nextColorIndex,
                sortOrder: maxSortOrder + 1
            )
            modelContext.insert(newTrivit)
            HapticsService.shared.impact(.medium)

            // Scroll to bottom after a short delay to allow the view to update
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                scrollToBottom = true
            }
        }
    }

    private func deleteTrivit(_ trivit: Trivit) {
        withAnimation {
            modelContext.delete(trivit)
            HapticsService.shared.notification(.warning)
        }
    }
}

#Preview {
    TrivitListView()
        .modelContainer(for: Trivit.self, inMemory: true)
}
