//
//  CounterCardView.swift
//  trivit Vision
//
//  Individual floating counter card with glass material styling
//

import SwiftUI

struct CounterCardView: View {
    @Bindable var trivit: Trivit
    @Environment(\.modelContext) private var modelContext
    @State private var isEditing = false
    @State private var showResetConfirmation = false

    private var accentColor: Color {
        TrivitColors.color(at: trivit.colorIndex)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Color accent bar at top
            Rectangle()
                .fill(accentColor)
                .frame(height: 6)

            VStack(spacing: 16) {
                // Title row
                HStack {
                    if isEditing {
                        TextField("Counter name", text: $trivit.title)
                            .font(.headline)
                            .textFieldStyle(.plain)
                            .onSubmit {
                                isEditing = false
                            }
                    } else {
                        Text(trivit.title)
                            .font(.headline)
                            .lineLimit(1)
                    }
                    Spacer()
                }

                // Count display
                Text("\(trivit.count)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(accentColor)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: trivit.count)

                // Tally marks
                if trivit.count > 0 {
                    TallyMarksView(count: trivit.count)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: 24)
                }

                // +/- buttons
                HStack(spacing: 16) {
                    Button {
                        trivit.decrement()
                    } label: {
                        Image(systemName: "minus")
                            .font(.title3.weight(.semibold))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.bordered)
                    .disabled(trivit.count == 0)
                    .hoverEffect(.highlight)

                    Spacer()

                    Button {
                        trivit.increment()
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3.weight(.semibold))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(accentColor)
                    .hoverEffect(.highlight)
                }
            }
            .padding(20)
        }
        .glassBackgroundEffect()
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .hoverEffect(.highlight)
        .contextMenu {
            Button {
                isEditing = true
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            Button {
                trivit.colorIndex = (trivit.colorIndex + 1) % TrivitColors.colorCount
            } label: {
                Label("Change Color", systemImage: "paintpalette")
            }
            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                Label("Reset Count", systemImage: "arrow.counterclockwise")
            }
            Divider()
            Button(role: .destructive) {
                modelContext.delete(trivit)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .confirmationDialog("Reset Counter?", isPresented: $showResetConfirmation) {
            Button("Reset to Zero", role: .destructive) {
                trivit.reset()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

#Preview {
    CounterCardView(trivit: Trivit(title: "Push-ups", count: 42, colorIndex: 1))
        .frame(width: 320)
        .modelContainer(for: [Trivit.self], inMemory: true)
}
