//
//  TrivitRowView.swift
//  Trivit
//
//  A single tally counter row - matching original flat design with two-tone layout
//

import SwiftUI
import SwiftData

struct TrivitRowView: View {
    @Bindable var trivit: Trivit
    @Environment(\.modelContext) private var modelContext
    @State private var isEditing = false
    @State private var dragOffset: CGFloat = 0
    @State private var showingStatistics = false
    @State private var showingHistory = false
    @FocusState private var isTitleFocused: Bool

    let isExpanded: Bool
    let onExpand: () -> Void
    let onDelete: () -> Void

    private var backgroundColor: Color {
        TrivitColors.color(at: trivit.colorIndex)
    }

    // Darker shade for title bar
    private var titleBackgroundColor: Color {
        backgroundColor.opacity(0.85)
    }

    // Lighter shade for tally area
    private var tallyBackgroundColor: Color {
        backgroundColor.opacity(0.65)
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

            // Main content
            VStack(spacing: 0) {
                // Title bar (darker) - always visible
                HStack {
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

                    Spacer()

                    // Count badge - always visible
                    Text("\(trivit.count)")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(backgroundColor)
                        .frame(width: 44, height: 32)
                        .background(Color.white.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(titleBackgroundColor)
                .contentShape(Rectangle())
                .onTapGesture {
                    guard !isEditing else { return }
                    trivit.increment(in: modelContext)
                    HapticsService.shared.impact(.light)
                }

                // Tally area (lighter) - only when expanded and has tallies
                if isExpanded && trivit.count > 0 {
                    VStack(spacing: 0) {
                        // Triangle indicator pointing down from title
                        HStack {
                            Spacer()
                            Triangle()
                                .fill(titleBackgroundColor)
                                .frame(width: 24, height: 12)
                            Spacer()
                        }
                        .background(tallyBackgroundColor)

                        // Tally marks
                        HStack {
                            TallyMarksView(count: trivit.count, useChinese: trivit.title.hasPrefix("_"))
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .background(tallyBackgroundColor)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        trivit.increment(in: modelContext)
                        HapticsService.shared.impact(.light)
                    }
                }
            }
            .offset(x: dragOffset)
            .simultaneousGesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onChanged { value in
                        let horizontalAmount = abs(value.translation.width)
                        let verticalAmount = abs(value.translation.height)
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
        }
        .contentShape(Rectangle())
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
                    onExpand()
                }
            } label: {
                Label(isExpanded ? "Collapse" : "Expand",
                      systemImage: isExpanded ? "chevron.up" : "chevron.down")
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

// MARK: - Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
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
        ZStack {
            if strokes >= 1 {
                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 14, height: 2)
                    .offset(y: -7)
            }
            if strokes >= 2 {
                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 2, height: 16)
                    .offset(x: -5, y: 0)
            }
            if strokes >= 3 {
                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 10, height: 2)
                    .offset(x: 0, y: 0)
            }
            if strokes >= 4 {
                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 2, height: 8)
                    .offset(x: 5, y: 4)
            }
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
                trivit: Trivit(title: "Days of work left", count: 13, colorIndex: 0),
                isExpanded: true,
                onExpand: {},
                onDelete: {}
            )
            TrivitRowView(
                trivit: Trivit(title: "Tallies added", count: 8, colorIndex: 1),
                isExpanded: true,
                onExpand: {},
                onDelete: {}
            )
            TrivitRowView(
                trivit: Trivit(title: "Bugs in our software", count: 5, colorIndex: 3),
                isExpanded: false,
                onExpand: {},
                onDelete: {}
            )
            TrivitRowView(
                trivit: Trivit(title: "Pairs of shoes owned", count: 3, colorIndex: 4),
                isExpanded: false,
                onExpand: {},
                onDelete: {}
            )
        }
    }
}
