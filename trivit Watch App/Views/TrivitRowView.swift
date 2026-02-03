//
//  TrivitRowView.swift
//  Trivit Watch App
//
//  A colorful tally counter row with two tap zones:
//  - LEFT (80%): Tap to increment count
//  - RIGHT (20%): Tap chevron to open detail view
//

import SwiftUI
import WatchKit

struct TrivitRowView: View {
    let trivit: Trivit
    let syncService: SyncService

    private var backgroundColor: Color {
        TrivitColors.color(at: trivit.colorIndex)
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // LEFT ZONE (80%): Tap to increment
                Button {
                    incrementTrivit()
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        // Title
                        Text(trivit.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        // Count display
                        HStack(spacing: 6) {
                            Text("\(trivit.count)")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .contentTransition(.numericText())
                                .animation(.spring(response: 0.3), value: trivit.count)

                            // Compact tally preview
                            if trivit.count > 0 {
                                WatchTallyPreview(count: trivit.count)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding(.leading, 10)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .frame(width: geometry.size.width * 0.78)

                // Divider line
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 1)
                    .padding(.vertical, 8)

                // RIGHT ZONE (20%): Tap to open details
                NavigationLink {
                    TrivitDetailView(trivit: trivit)
                        .environmentObject(syncService)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(.plain)
            }
            .background(backgroundColor)
            .cornerRadius(10)
        }
        .frame(height: 52)
    }

    private func incrementTrivit() {
        trivit.count += 1
        syncService.syncTrivitUpdate(trivit)
        WKInterfaceDevice.current().play(.click)
    }
}

// MARK: - Compact Tally Preview for Row
// Shows a visual hint of tally marks, scrollable for large counts
struct WatchTallyPreview: View {
    let count: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 3) {
                let fullGroups = count / 5
                let remainder = count % 5

                ForEach(0..<fullGroups, id: \.self) { _ in
                    WatchTallyGroupView(count: 5)
                }

                if remainder > 0 {
                    WatchTallyGroupView(count: remainder)
                }
            }
        }
        .frame(maxWidth: 80)
    }
}

struct WatchTallyGroupView: View {
    let count: Int

    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<min(count, 4), id: \.self) { _ in
                Rectangle()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: 1.5, height: 12)
            }
            if count == 5 {
                Rectangle()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: 9, height: 1.5)
                    .rotationEffect(.degrees(-65))
                    .offset(x: -5)
            }
        }
        .frame(width: count == 5 ? 12 : CGFloat(count * 3), height: 14)
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            LazyVStack(spacing: 8) {
                TrivitRowView(trivit: Trivit(title: "Push-ups", count: 42, colorIndex: 1), syncService: SyncService())
                TrivitRowView(trivit: Trivit(title: "Coffee", count: 3, colorIndex: 0), syncService: SyncService())
                TrivitRowView(trivit: Trivit(title: "Steps", count: 17, colorIndex: 3), syncService: SyncService())
                TrivitRowView(trivit: Trivit(title: "Water", count: 0, colorIndex: 2), syncService: SyncService())
            }
            .padding(.horizontal, 4)
        }
    }
}
