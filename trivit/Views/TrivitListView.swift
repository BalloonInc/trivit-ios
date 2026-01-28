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
    @Query(sort: \Trivit.createdAt) private var trivits: [Trivit]
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Trivit")
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
        ContentUnavailableView(
            "No Trivits Yet",
            systemImage: "number",
            description: Text("Tap + to create your first tally counter")
        )
    }

    private var trivitList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(trivits) { trivit in
                    TrivitRowView(
                        trivit: trivit,
                        onDelete: { deleteTrivit(trivit) }
                    )
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gear")
            }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: addTrivit) {
                Image(systemName: "plus")
            }
        }
    }

    private func addTrivit() {
        withAnimation {
            let newTrivit = Trivit(
                title: "New Trivit",
                colorIndex: TrivitColors.randomColorIndex()
            )
            modelContext.insert(newTrivit)
            HapticsService.shared.impact(.medium)
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
