//
//  TrivitDetailView.swift
//  Trivit Watch App
//
//  Detail view for a single trivit with increment/decrement controls
//

import SwiftUI
import WatchKit

struct TrivitDetailView: View {
    let trivit: Trivit
    @StateObject private var syncService = SyncService.shared
    @State private var showResetConfirmation = false

    private var themeColor: Color {
        TrivitColors.color(at: trivit.colorIndex)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Main count display card
                countCard

                // Tally marks display
                if trivit.count > 0 {
                    tallyMarksSection
                }

                // Action buttons
                actionButtons
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
        }
        .navigationTitle(trivit.title)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Reset Counter?", isPresented: $showResetConfirmation) {
            Button("Reset to Zero", role: .destructive) {
                resetTrivit()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Count Card
    private var countCard: some View {
        VStack(spacing: 8) {
            Text(trivit.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text("\(trivit.count)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: trivit.count)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .background(themeColor)
        .cornerRadius(16)
    }

    // MARK: - Tally Marks Section
    private var tallyMarksSection: some View {
        VStack(spacing: 6) {
            Text("Tally")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            DetailTallyMarksView(count: trivit.count, color: themeColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 10) {
            // Increment/Decrement row
            HStack(spacing: 12) {
                // Decrement button
                Button {
                    decrementTrivit()
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(trivit.count > 0 ? .white : .gray)
                        .frame(width: 50, height: 50)
                        .background(trivit.count > 0 ? themeColor.opacity(0.8) : Color.gray.opacity(0.3))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(trivit.count == 0)

                // Increment button (larger)
                Button {
                    incrementTrivit()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(themeColor)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            // Reset button
            if trivit.count > 0 {
                Button {
                    showResetConfirmation = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 12, weight: .medium))
                        Text("Reset")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(20)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Actions
    private func incrementTrivit() {
        trivit.count += 1
        syncService.syncTrivitUpdate(trivit)
        WKInterfaceDevice.current().play(.click)
    }

    private func decrementTrivit() {
        if trivit.count > 0 {
            trivit.count -= 1
            syncService.syncTrivitUpdate(trivit)
            WKInterfaceDevice.current().play(.directionDown)
        }
    }

    private func resetTrivit() {
        trivit.count = 0
        syncService.syncTrivitUpdate(trivit)
        WKInterfaceDevice.current().play(.notification)
    }
}

// MARK: - Detail Tally Marks View
struct DetailTallyMarksView: View {
    let count: Int
    let color: Color

    var body: some View {
        let fullGroups = min(count / 5, 4) // Show max 4 groups
        let remainder = count % 5
        let showRemainder = fullGroups < 4

        HStack(spacing: 6) {
            ForEach(0..<fullGroups, id: \.self) { _ in
                DetailTallyGroupView(count: 5, color: color)
            }

            if showRemainder && remainder > 0 {
                DetailTallyGroupView(count: remainder, color: color)
            }

            if count > 20 {
                Text("+\(count - 20)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(color)
            }
        }
    }
}

struct DetailTallyGroupView: View {
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<min(count, 4), id: \.self) { _ in
                Rectangle()
                    .fill(color)
                    .frame(width: 2, height: 14)
            }
            if count == 5 {
                Rectangle()
                    .fill(color)
                    .frame(width: 10, height: 2)
                    .rotationEffect(.degrees(-65))
                    .offset(x: -6)
            }
        }
        .frame(width: count == 5 ? 16 : CGFloat(count * 4), height: 16)
    }
}

#Preview {
    NavigationStack {
        TrivitDetailView(trivit: Trivit(title: "Push-ups", count: 42, colorIndex: 1))
    }
}
