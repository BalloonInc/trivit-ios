//
//  ContentView.swift
//  Trivit Watch App
//
//  Main view displaying the list of trivit counters
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trivit.sortOrder) private var trivits: [Trivit]
    @EnvironmentObject var syncService: SyncService
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if trivits.isEmpty {
                    emptyState
                } else {
                    trivitList
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        createNewTrivit()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            WatchSettingsView()
                .environmentObject(syncService)
        }
    }

    private func createNewTrivit() {
        // Use last trivit's color + 1, cycling through colors
        let lastColorIndex = trivits.last?.colorIndex ?? -1
        let nextColorIndex = (lastColorIndex + 1) % TrivitColors.colorCount

        // Create locally and sync to iPhone
        let newTrivit = Trivit(
            title: "Counter",
            count: 0,
            colorIndex: nextColorIndex
        )
        modelContext.insert(newTrivit)
        try? modelContext.save()

        // Sync to iPhone
        syncService.syncTrivitUpdate(newTrivit)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(TrivitColors.color(at: 0).opacity(0.2))
                    .frame(width: 60, height: 60)

                Image(systemName: "tally")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(TrivitColors.color(at: 0))
            }

            VStack(spacing: 4) {
                Text("No Counters")
                    .font(.system(size: 16, weight: .semibold))

                Text("Tap + to create a counter")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }

    private var trivitList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(trivits) { trivit in
                    TrivitRowView(trivit: trivit, syncService: syncService)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
        }
        .navigationTitle("Trivit")
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Trivit.self], inMemory: true)
}
