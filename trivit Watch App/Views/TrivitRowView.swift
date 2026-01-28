//
//  TrivitRowView.swift
//  Trivit Watch App
//
//  Created by Claude on 28/01/26.
//

import SwiftUI

struct TrivitRowView: View {
    let trivit: Trivit
    @StateObject private var syncService = SyncService.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(trivit.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text("\(trivit.count)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(TrivitColors.color(at: trivit.colorIndex, scheme: 2, isDark: false))
            }
            
            Spacer()
            
            Button {
                incrementTrivit()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(TrivitColors.color(at: trivit.colorIndex, scheme: 2, isDark: false))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
    
    private func incrementTrivit() {
        trivit.count += 1
        
        // Sync to iPhone immediately
        syncService.syncTrivitUpdate(trivit)
        
        // Haptic feedback
        WKInterfaceDevice.current().play(.click)
    }
}

#Preview {
    List {
        TrivitRowView(trivit: Trivit(title: "Push-ups", count: 42, colorIndex: 1))
        TrivitRowView(trivit: Trivit(title: "Coffee", count: 3, colorIndex: 0))
    }
    .modelContainer(for: [Trivit.self], inMemory: true)
}
