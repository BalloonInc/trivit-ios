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
    @Query(filter: #Predicate<Trivit> { $0.deletedAt == nil }, sort: \Trivit.sortOrder)
    private var trivits: [Trivit]
    @State private var showingSettings = false
    @State private var scrollToBottom = false
    @State private var expandedTrivitIds: Set<UUID> = []
    @State private var draggingTrivit: Trivit?
    @State private var deletedTrivit: Trivit?
    @State private var showUndoToast = false

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
        }
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
                            onToggleExpand: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if expandedTrivitIds.contains(trivit.id) {
                                        expandedTrivitIds.remove(trivit.id)
                                    } else {
                                        expandedTrivitIds.insert(trivit.id)
                                    }
                                }
                            },
                            onDelete: { deleteTrivit(trivit) }
                        )
                        .opacity(draggingTrivit?.id == trivit.id ? 0.5 : 1.0)
                        .id(trivit.id)
                        .draggable(trivit.id.uuidString) {
                            // Drag preview
                            TrivitRowView(
                                trivit: trivit,
                                isExpanded: false,
                                onToggleExpand: {},
                                onDelete: {}
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

#Preview {
    TrivitListView()
        .modelContainer(for: Trivit.self, inMemory: true)
}
