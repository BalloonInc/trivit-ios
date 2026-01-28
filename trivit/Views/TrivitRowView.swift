//
//  TrivitRowView.swift
//  Trivit
//
//  A single tally counter row - matching original flat design
//

import SwiftUI
import SwiftData

struct TrivitRowView: View {
    @Bindable var trivit: Trivit
    @State private var isEditing = false
    @FocusState private var isTitleFocused: Bool

    let onDelete: () -> Void

    private var backgroundColor: Color {
        TrivitColors.color(at: trivit.colorIndex)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Main tappable area (increment on tap)
            Button {
                trivit.increment()
                HapticsService.shared.impact(.light)
            } label: {
                HStack(spacing: 12) {
                    // Title and tally marks
                    VStack(alignment: .leading, spacing: 4) {
                        if isEditing {
                            TextField("Title", text: $trivit.title)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white)
                                .focused($isTitleFocused)
                                .onSubmit {
                                    isEditing = false
                                }
                        } else {
                            Text(trivit.title)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white)
                                .onLongPressGesture {
                                    isEditing = true
                                    isTitleFocused = true
                                }
                        }

                        // Tally marks inline
                        if trivit.count > 0 {
                            TallyMarksView(count: trivit.count)
                        }
                    }

                    Spacer()

                    // Count display in circle
                    Text("\(trivit.count)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(backgroundColor)
                        .frame(width: 50, height: 50)
                        .background(Color.white.opacity(0.95))
                        .clipShape(Circle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            // Decrement button
            Button {
                if trivit.count > 0 {
                    trivit.decrement()
                    HapticsService.shared.impact(.light)
                }
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.3))
                    .clipShape(Circle())
            }
            .padding(.trailing, 12)
            .opacity(trivit.count > 0 ? 1 : 0.4)
        }
        .frame(minHeight: 70)
        .background(backgroundColor)
        .contextMenu {
            Button {
                isEditing = true
                isTitleFocused = true
            } label: {
                Label("Rename", systemImage: "pencil")
            }

            Button {
                trivit.colorIndex = (trivit.colorIndex + 1) % TrivitColors.colorCount
            } label: {
                Label("Change Color", systemImage: "paintpalette")
            }

            Button {
                trivit.reset()
                HapticsService.shared.notification(.warning)
            } label: {
                Label("Reset Count", systemImage: "arrow.counterclockwise")
            }

            Divider()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Tally Marks Visual
struct TallyMarksView: View {
    let count: Int

    var body: some View {
        HStack(spacing: 8) {
            let fullGroups = min(count / 5, 6) // Show max 6 groups inline
            let remainder = count % 5
            let showRemainder = fullGroups < 6

            ForEach(0..<fullGroups, id: \.self) { _ in
                TallyGroupView(count: 5)
            }

            if showRemainder && remainder > 0 {
                TallyGroupView(count: remainder)
            }

            if count > 30 {
                Text("...")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

struct TallyGroupView: View {
    let count: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<min(count, 4), id: \.self) { _ in
                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 2, height: 16)
            }
            if count == 5 {
                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 14, height: 2)
                    .rotationEffect(.degrees(-65))
                    .offset(x: -8)
            }
        }
        .frame(width: count == 5 ? 20 : CGFloat(count * 4), height: 18)
    }
}

#Preview {
    VStack(spacing: 0) {
        TrivitRowView(
            trivit: Trivit(title: "Drinks", count: 5, colorIndex: 0),
            onDelete: {}
        )
        TrivitRowView(
            trivit: Trivit(title: "Days without smoking", count: 3, colorIndex: 1),
            onDelete: {}
        )
        TrivitRowView(
            trivit: Trivit(title: "Went swimming this year", count: 8, colorIndex: 3),
            onDelete: {}
        )
        TrivitRowView(
            trivit: Trivit(title: "Cups of coffee this year", count: 13, colorIndex: 5),
            onDelete: {}
        )
    }
}
