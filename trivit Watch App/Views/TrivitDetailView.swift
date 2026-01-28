//
//  TrivitDetailView.swift
//  Trivit Watch App
//
//  Created by Claude on 28/01/26.
//

import SwiftUI

struct TrivitDetailView: View {
    let trivit: Trivit
    @StateObject private var syncService = SyncService.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Count display
                VStack(spacing: 8) {
                    Text(trivit.title)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Text("\(trivit.count)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(TrivitColors.color(at: trivit.colorIndex, scheme: 2, isDark: false))
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Button {
                            incrementTrivit()
                        } label: {
                            Label("Add", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(TrivitColors.color(at: trivit.colorIndex, scheme: 2, isDark: false))
                        
                        if trivit.count > 0 {
                            Button {
                                decrementTrivit()
                            } label: {
                                Label("Subtract", systemImage: "minus")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    if trivit.count > 0 {
                        Button {
                            resetTrivit()
                        } label: {
                            Label("Reset", systemImage: "arrow.counterclockwise")
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.orange)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(trivit.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func incrementTrivit() {
        trivit.count += 1
        syncService.syncTrivitUpdate(trivit)
        WKInterfaceDevice.current().play(.success)
    }
    
    private func decrementTrivit() {
        if trivit.count > 0 {
            trivit.count -= 1
            syncService.syncTrivitUpdate(trivit)
            WKInterfaceDevice.current().play(.click)
        }
    }
    
    private func resetTrivit() {
        trivit.count = 0
        syncService.syncTrivitUpdate(trivit)
        WKInterfaceDevice.current().play(.notification)
    }
}

#Preview {
    NavigationStack {
        TrivitDetailView(trivit: Trivit(title: "Push-ups", count: 42, colorIndex: 1))
    }
    .modelContainer(for: [Trivit.self], inMemory: true)
}
