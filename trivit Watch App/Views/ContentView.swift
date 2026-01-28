//
//  ContentView.swift
//  Trivit Watch App
//
//  Created by Claude on 28/01/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var trivits: [Trivit]
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
        VStack(spacing: 12) {
            Image(systemName: "tally")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("No Counters")
                .font(.headline)
            
            Text("Create counters on your iPhone to see them here")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var trivitList: some View {
        List(trivits) { trivit in
            NavigationLink {
                TrivitDetailView(trivit: trivit)
            } label: {
                TrivitRowView(trivit: trivit)
            }
        }
        .navigationTitle("Trivit")
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Trivit.self], inMemory: true)
}
