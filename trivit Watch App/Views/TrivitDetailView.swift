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
    @State private var showRenameSheet = false
    @State private var newTitle = ""

    private var themeColor: Color {
        TrivitColors.color(at: trivit.colorIndex)
    }

    private var darkerThemeColor: Color {
        themeColor.opacity(0.7)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main tappable tally area
            tallyArea

            // Bottom control bar
            controlBar
        }
        .background(themeColor)
        .navigationTitle(trivit.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(themeColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .confirmationDialog("Reset Counter?", isPresented: $showResetConfirmation) {
            Button("Reset to Zero", role: .destructive) {
                resetTrivit()
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showRenameSheet) {
            RenameSheetView(
                title: $newTitle,
                themeColor: themeColor,
                onSave: {
                    if !newTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                        trivit.title = newTitle.trimmingCharacters(in: .whitespaces)
                        syncService.syncTrivitUpdate(trivit)
                    }
                    showRenameSheet = false
                },
                onCancel: {
                    showRenameSheet = false
                }
            )
        }
        .onAppear {
            newTitle = trivit.title
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
        HStack(spacing: 8) {
            // Decrement button
            Button {
                decrementTrivit()
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(trivit.count > 0 ? .white : .white.opacity(0.4))
                    .frame(width: 32, height: 32)
                    .background(trivit.count > 0 ? darkerThemeColor : themeColor.opacity(0.3))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(trivit.count == 0)

            // Reset button
            Button {
                showResetConfirmation = true
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(trivit.count > 0 ? .white : .white.opacity(0.4))
                    .frame(width: 32, height: 32)
                    .background(trivit.count > 0 ? darkerThemeColor : themeColor.opacity(0.3))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(trivit.count == 0)

            // Rename button
            Button {
                newTitle = trivit.title
                showRenameSheet = true
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(darkerThemeColor)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            // Increment button
            Button {
                incrementTrivit()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(darkerThemeColor)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            LinearGradient(
                colors: [themeColor.opacity(0.8), themeColor.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
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

// MARK: - Rename Sheet View

struct RenameSheetView: View {
    @Binding var title: String
    let themeColor: Color
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Rename")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            TextField("Title", text: $title)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .padding(8)
                .background(Color.white.opacity(0.15))
                .cornerRadius(8)

            HStack(spacing: 12) {
                Button {
                    onCancel()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Button {
                    onSave()
                } label: {
                    Text("Save")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(themeColor)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(themeColor.opacity(0.8))
    }
}

#Preview {
    NavigationStack {
        TrivitDetailView(trivit: Trivit(title: "Push-ups", count: 42, colorIndex: 1))
            .environmentObject(SyncService())
    }
}
