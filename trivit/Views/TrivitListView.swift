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
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(trivits) { trivit in
                    TrivitRowView(
                        trivit: trivit,
                        onDelete: { deleteTrivit(trivit) }
                    )
                }
            }
        }
        .background(Color(.systemGray5))
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
            // Find the highest colorIndex currently in use and assign the next one in sequence
            let maxColorIndex = trivits.map(\.colorIndex).max() ?? -1
            let nextColorIndex = (maxColorIndex + 1) % TrivitColors.colorCount

            let newTrivit = Trivit(
                title: "New Trivit",
                colorIndex: nextColorIndex
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
