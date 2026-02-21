//
//  ContentView.swift
//  trivit Vision
//
//  Main view displaying floating counter cards in a grid
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trivit.sortOrder) private var trivits: [Trivit]
    @State private var showingAddSheet = false

    private let columns = [
        GridItem(.adaptive(minimum: 280, maximum: 360), spacing: 20)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if trivits.isEmpty {
                    emptyState
                } else {
                    counterGrid
                }
            }
            .navigationTitle("Trivit")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddTrivitView()
            }
        }
    }

    private var counterGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(trivits) { trivit in
                    CounterCardView(trivit: trivit)
                }
            }
            .padding(24)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(TrivitColors.color(at: 0).opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: "tally")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundColor(TrivitColors.color(at: 0))
            }

            VStack(spacing: 8) {
                Text("No Counters")
                    .font(.title2.weight(.semibold))

                Text("Tap + to create your first counter")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Button {
                showingAddSheet = true
            } label: {
                Label("Add Counter", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(TrivitColors.color(at: 0))
        }
        .padding(40)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Trivit.self], inMemory: true)
}
