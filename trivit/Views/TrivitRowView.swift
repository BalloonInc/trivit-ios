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
                            TallyMarksView(count: trivit.count, useChinese: trivit.title.hasPrefix("_"))
                        }
                    }

                    Spacer()

                    // Count display in circle
                    Text("\(trivit.count)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(backgroundColor)
                        .frame(width: 50, height: 50)
                        .background(Color.white.opacity(0.2))
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
    var useChinese: Bool = false

    var body: some View {
        if useChinese {
            ChineseTallyMarksView(count: count)
        } else {
            WesternTallyMarksView(count: count)
        }
    }
}

// MARK: - Western Tally Marks (||||/)
struct WesternTallyMarksView: View {
    let count: Int

    private let groupsPerRow = 10

    var body: some View {
        let fullGroups = count / 5
        let remainder = count % 5
        let totalGroups = fullGroups + (remainder > 0 ? 1 : 0)
        let numberOfRows = max(1, (totalGroups + groupsPerRow - 1) / groupsPerRow)

        VStack(alignment: .leading, spacing: 4) {
            ForEach(0..<numberOfRows, id: \.self) { rowIndex in
                HStack(spacing: 8) {
                    let startGroup = rowIndex * groupsPerRow
                    let endGroup = min(startGroup + groupsPerRow, totalGroups)

                    ForEach(startGroup..<endGroup, id: \.self) { groupIndex in
                        if groupIndex < fullGroups {
                            WesternTallyGroupView(count: 5)
                        } else if groupIndex == fullGroups && remainder > 0 {
                            WesternTallyGroupView(count: remainder)
                        }
                    }
                }
            }
        }
    }
}

struct WesternTallyGroupView: View {
    let count: Int

    var body: some View {
        ZStack(alignment: .leading) {
            // Draw the vertical marks (up to 4)
            HStack(spacing: 3) {
                ForEach(0..<min(count, 4), id: \.self) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 2, height: 16)
                }
            }

            // Draw the diagonal strike-through for the 5th mark
            if count == 5 {
                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 2, height: 22)
                    .rotationEffect(.degrees(-30))
                    .offset(x: 7, y: 0)
            }
        }
        .frame(width: count == 5 ? 22 : CGFloat(count * 5), height: 20)
    }
}

// MARK: - Chinese Tally Marks (正)
struct ChineseTallyMarksView: View {
    let count: Int

    private let groupsPerRow = 10

    var body: some View {
        let fullGroups = count / 5
        let remainder = count % 5
        let totalGroups = fullGroups + (remainder > 0 ? 1 : 0)
        let numberOfRows = max(1, (totalGroups + groupsPerRow - 1) / groupsPerRow)

        VStack(alignment: .leading, spacing: 4) {
            ForEach(0..<numberOfRows, id: \.self) { rowIndex in
                HStack(spacing: 6) {
                    let startGroup = rowIndex * groupsPerRow
                    let endGroup = min(startGroup + groupsPerRow, totalGroups)

                    ForEach(startGroup..<endGroup, id: \.self) { groupIndex in
                        if groupIndex < fullGroups {
                            ChineseTallyGroupView(strokes: 5)
                        } else if groupIndex == fullGroups && remainder > 0 {
                            ChineseTallyGroupView(strokes: remainder)
                        }
                    }
                }
            }
        }
    }
}

struct ChineseTallyGroupView: View {
    let strokes: Int

    var body: some View {
        // The character 正 is drawn stroke by stroke:
        // 1: horizontal top
        // 2: vertical left
        // 3: short horizontal middle
        // 4: vertical right
        // 5: horizontal bottom
        ZStack {
            // Stroke 1: Top horizontal
            if strokes >= 1 {
                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 14, height: 2)
                    .offset(y: -6)
            }

            // Stroke 2: Left vertical
            if strokes >= 2 {
                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 2, height: 14)
                    .offset(x: -6, y: 0)
            }

            // Stroke 3: Middle short horizontal
            if strokes >= 3 {
                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 12, height: 2)
                    .offset(x: 0, y: 0)
            }

            // Stroke 4: Right vertical
            if strokes >= 4 {
                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 2, height: 14)
                    .offset(x: 6, y: 0)
            }

            // Stroke 5: Bottom horizontal
            if strokes >= 5 {
                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 14, height: 2)
                    .offset(y: 6)
            }
        }
        .frame(width: 18, height: 18)
    }
}

#Preview {
    ScrollView {
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
                trivit: Trivit(title: "Cups of coffee this year", count: 47, colorIndex: 5),
                onDelete: {}
            )
            TrivitRowView(
                trivit: Trivit(title: "_Chinese tally test", count: 12, colorIndex: 2),
                onDelete: {}
            )
            TrivitRowView(
                trivit: Trivit(title: "_Many Chinese tallies", count: 53, colorIndex: 4),
                onDelete: {}
            )
        }
    }
}
