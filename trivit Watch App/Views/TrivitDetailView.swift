//
//  TrivitDetailView.swift
//  Trivit Watch App
//
//  Full-screen detail view with large tally marks
//  - Small count in top corner
//  - Large, multi-row tally marks filling most of the screen
//  - Tappable tally area to increment
//  - Small decrement/reset buttons at bottom
//

import SwiftUI
import WatchKit

struct TrivitDetailView: View {
    let trivit: Trivit
    @EnvironmentObject var syncService: SyncService
    @State private var showResetConfirmation = false

    private var themeColor: Color {
        TrivitColors.color(at: trivit.colorIndex)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main tappable tally area
            tallyArea

            // Bottom control bar
            controlBar
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

    // MARK: - Tally Area (Main Content)

    private var tallyArea: some View {
        Button {
            incrementTrivit()
        } label: {
            VStack(spacing: 0) {
                // Top bar: Title + Count
                HStack {
                    Text(trivit.title)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)

                    Spacer()

                    Text("\(trivit.count)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: trivit.count)
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 6)

                // Large tally marks area
                ScrollView {
                    VStack(alignment: .leading) {
                        if trivit.count > 0 {
                            WatchTallyMarksView(
                                count: trivit.count,
                                mode: .full,
                                color: .white.opacity(0.9)
                            )
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "hand.tap")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white.opacity(0.4))
                                Text("Tap to count")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 20)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(themeColor)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Control Bar

    private var controlBar: some View {
        HStack(spacing: 12) {
            // Decrement button
            Button {
                decrementTrivit()
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(trivit.count > 0 ? .white : .gray)
                    .frame(width: 36, height: 36)
                    .background(trivit.count > 0 ? themeColor.opacity(0.8) : Color.gray.opacity(0.3))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(trivit.count == 0)

            // Reset button
            Button {
                showResetConfirmation = true
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 10, weight: .medium))
                    Text("Reset")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(trivit.count > 0 ? .orange : .gray)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(trivit.count > 0 ? Color.orange.opacity(0.2) : Color.gray.opacity(0.2))
                .cornerRadius(18)
            }
            .buttonStyle(.plain)
            .disabled(trivit.count == 0)

            // Increment button (smaller, since main area is tappable)
            Button {
                incrementTrivit()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(themeColor)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.3))
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

#Preview {
    NavigationStack {
        TrivitDetailView(trivit: Trivit(title: "Push-ups", count: 42, colorIndex: 1))
            .environmentObject(SyncService())
    }
}
