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
    @Environment(\.modelContext) private var modelContext
    @AppStorage("showTotalCount") private var showTotalCount = true
    @State private var isEditing = false
    @State private var dragOffset: CGFloat = 0
    @State private var showingStatistics = false
    @State private var showingHistory = false
    @FocusState private var isTitleFocused: Bool

    let onDelete: () -> Void

    private var backgroundColor: Color {
        TrivitColors.color(at: trivit.colorIndex)
    }

    private let decrementThreshold: CGFloat = -60

    var body: some View {
        ZStack {
            // Background layer showing decrement indicator when swiping
            HStack {
                Spacer()
                Image(systemName: "minus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(dragOffset < decrementThreshold ? 1.0 : 0.5)
                    .padding(.trailing, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(backgroundColor.opacity(0.8))

            // Main content - tappable for increment
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

                    // Tally marks - always show, but limit height when collapsed
                    if trivit.count > 0 {
                        TallyMarksView(count: trivit.count, useChinese: trivit.title.hasPrefix("_"))
                            .frame(maxHeight: trivit.isCollapsed ? 20 : nil)
                            .clipped()
                    }
                }

                Spacer()

                // Collapse/expand indicator when there are many tallies
                if trivit.count > 10 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            trivit.isCollapsed.toggle()
                        }
                    } label: {
                        Image(systemName: trivit.isCollapsed ? "chevron.down" : "chevron.up")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }

                // Count display - smaller and respects setting
                if showTotalCount {
                    Text("\(trivit.count)")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor)
            .offset(x: dragOffset)
            .simultaneousGesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onChanged { value in
                        // Only allow horizontal left swipe - ignore vertical scrolling
                        let horizontalAmount = abs(value.translation.width)
                        let verticalAmount = abs(value.translation.height)

                        // Only activate if horizontal movement is dominant
                        if horizontalAmount > verticalAmount && value.translation.width < 0 {
                            dragOffset = value.translation.width
                        }
                    }
                    .onEnded { value in
                        if dragOffset < decrementThreshold && trivit.count > 0 {
                            trivit.decrement(in: modelContext)
                            HapticsService.shared.impact(.light)
                        }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            dragOffset = 0
                        }
                    }
            )
            .onTapGesture {
                guard !isEditing else { return }
                trivit.increment(in: modelContext)
                HapticsService.shared.impact(.light)
            }
        }
        .frame(minHeight: 70)
        .clipped()
        .contextMenu {
            Button {
                showingStatistics = true
            } label: {
                Label("Statistics", systemImage: "chart.bar.fill")
            }

            Button {
                showingHistory = true
            } label: {
                Label("History", systemImage: "clock.arrow.circlepath")
            }

            Divider()

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
                withAnimation(.easeInOut(duration: 0.2)) {
                    trivit.isCollapsed.toggle()
                }
            } label: {
                Label(trivit.isCollapsed ? "Show Tallies" : "Hide Tallies",
                      systemImage: trivit.isCollapsed ? "eye" : "eye.slash")
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
        .sheet(isPresented: $showingStatistics) {
            StatisticsView(trivit: trivit)
        }
        .sheet(isPresented: $showingHistory) {
            HistoryView(trivit: trivit)
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

            // Draw the diagonal strike-through for the 5th mark (bottom-left to top-right)
            if count == 5 {
                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 2, height: 22)
                    .rotationEffect(.degrees(30))
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
        // 1: Top horizontal line
        // 2: Left vertical line going down from the top horizontal
        // 3: Short horizontal in the middle (extending right from vertical)
        // 4: Right vertical line
        // 5: Bottom horizontal line completing the character
        ZStack {
            // Stroke 1: Top horizontal line
            if strokes >= 1 {
                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 14, height: 2)
                    .offset(y: -7)
            }

            // Stroke 2: Left vertical (from top horizontal going down)
            if strokes >= 2 {
                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 2, height: 16)
                    .offset(x: -5, y: 0)
            }

            // Stroke 3: Middle horizontal (connecting from vertical, going right)
            if strokes >= 3 {
                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 10, height: 2)
                    .offset(x: 0, y: 0)
            }

            // Stroke 4: Right vertical
            if strokes >= 4 {
                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 2, height: 8)
                    .offset(x: 5, y: 4)
            }

            // Stroke 5: Bottom horizontal (completing the character)
            if strokes >= 5 {
                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 14, height: 2)
                    .offset(y: 7)
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
