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
    @Query(sort: \Trivit.createdAt) private var trivits: [Trivit]
    @StateObject private var syncService = SyncService.shared

    var body: some View {
        NavigationStack {
            if trivits.isEmpty {
                emptyState
            } else {
                trivitList
            }
        }
        .onAppear {
            syncService.startWatchConnectivity()
        }
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

                Text("Create counters on your iPhone")
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
                    NavigationLink {
                        TrivitDetailView(trivit: trivit)
                    } label: {
                        TrivitRowView(trivit: trivit)
                    }
                    .buttonStyle(.plain)
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
