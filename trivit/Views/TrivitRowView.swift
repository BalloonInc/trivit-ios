//
//  TrivitRowView.swift
//  Trivit
//
//  A single tally counter row - flat colored design with expand/collapse
//

import SwiftUI
import SwiftData

struct TrivitRowView: View {
    @Bindable var trivit: Trivit
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hideCounterWhenExpanded") private var hideCounterWhenExpanded = true
    @State private var isEditing = false
    @State private var dragOffset: CGFloat = 0
    @State private var showingStatistics = false
    @State private var showingHistory = false
    @State private var hasHandledStartEditing = false
    @FocusState private var isTitleFocused: Bool

    let isExpanded: Bool
    let startEditing: Bool
    let onToggleExpand: () -> Void
    let onDelete: () -> Void
    let onEditingChanged: (Bool) -> Void

    private var backgroundColor: Color {
        TrivitColors.color(at: trivit.colorIndex)
    }

    private var tallyBackgroundColor: Color {
        backgroundColor.opacity(0.55)
    }

    private let decrementThreshold: CGFloat = -60
    private let deleteThreshold: CGFloat = -200

    var body: some View {
        ZStack {
            // Swipe background
            swipeBackground

            // Main content
            mainContent
                .offset(x: dragOffset)
                .simultaneousGesture(swipeGesture)
        }
        .contentShape(Rectangle())
        .contextMenu { contextMenuItems }
        .sheet(isPresented: $showingStatistics) {
            StatisticsView(trivit: trivit)
        }
        .sheet(isPresented: $showingHistory) {
            HistoryView(trivit: trivit)
        }
        .onChange(of: startEditing) { _, shouldEdit in
            if shouldEdit && !hasHandledStartEditing {
                hasHandledStartEditing = true
                isEditing = true
                // Small delay to ensure the TextField is visible before focusing
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isTitleFocused = true
                }
            }
        }
        .onChange(of: isEditing) { _, editing in
            onEditingChanged(editing)
        }
        .onAppear {
            // Handle initial startEditing state
            if startEditing && !hasHandledStartEditing {
                hasHandledStartEditing = true
                isEditing = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isTitleFocused = true
                }
            }
        }
    }

    // MARK: - Swipe Background

    private var swipeBackground: some View {
        HStack {
            Spacer()
            if dragOffset < deleteThreshold {
                Image(systemName: "trash.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.trailing, 24)
            } else {
                Image(systemName: "minus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(dragOffset < decrementThreshold ? 1.0 : 0.4)
                    .padding(.trailing, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(dragOffset < deleteThreshold ? Color.red : backgroundColor.opacity(0.7))
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            titleBar
            if isExpanded {
                tallyArea
            }
        }
    }

    // MARK: - Title Bar

    private var titleBar: some View {
        HStack(spacing: 12) {
            // Title text
            if isEditing {
                TextField("Title", text: $trivit.title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white.opacity(0.95))
                    .focused($isTitleFocused)
                    .onSubmit { isEditing = false }
            } else {
                Text(trivit.title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white.opacity(0.95))
                    .lineLimit(1)
            }

            Spacer()

            // Count display (hidden when expanded if setting is on)
            if !isExpanded || !hideCounterWhenExpanded {
                Text("\(trivit.count)")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(backgroundColor)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isEditing else { return }
            onToggleExpand()
            HapticsService.shared.impact(.light)
        }
        .onLongPressGesture {
            isEditing = true
            isTitleFocused = true
        }
    }

    // MARK: - Tally Area

    private var tallyArea: some View {
        VStack(spacing: 0) {
            // Arrow indicator - positioned ~5% from left
            HStack {
                Triangle()
                    .fill(backgroundColor)
                    .frame(width: 18, height: 9)
                    .padding(.leading, 20)
                Spacer()
            }

            // Tally marks (or empty space if count is 0)
            HStack {
                if trivit.count > 0 {
                    TallyMarksView(count: trivit.count, useChinese: trivit.title.hasPrefix("_"))
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(minHeight: 36)
        }
        .background(tallyBackgroundColor)
        .contentShape(Rectangle())
        .onTapGesture {
            trivit.increment(in: modelContext)
            HapticsService.shared.impact(.light)
        }
    }

    // MARK: - Swipe Gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .local)
            .onChanged { value in
                let horizontal = abs(value.translation.width)
                let vertical = abs(value.translation.height)
                if horizontal > vertical && value.translation.width < 0 {
                    dragOffset = value.translation.width
                }
            }
            .onEnded { _ in
                if dragOffset < deleteThreshold {
                    // Delete
                    HapticsService.shared.notification(.warning)
                    onDelete()
                } else if dragOffset < decrementThreshold && trivit.count > 0 {
                    // Decrement
                    trivit.decrement(in: modelContext)
                    HapticsService.shared.impact(.light)
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    dragOffset = 0
                }
            }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private var contextMenuItems: some View {
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

// MARK: - Tally Preview (collapsed - one row with ellipsis if more)

struct TallyPreviewView: View {
    let count: Int
    var useChinese: Bool = false

    private let maxGroups = 6

    var body: some View {
        let fullGroups = count / 5
        let remainder = count % 5
        let totalGroups = fullGroups + (remainder > 0 ? 1 : 0)
        let hasMore = totalGroups > maxGroups

        HStack(spacing: useChinese ? 6 : 8) {
            ForEach(0..<min(totalGroups, maxGroups), id: \.self) { i in
                if useChinese {
                    ChineseTallyGroupView(strokes: i < fullGroups ? 5 : remainder)
                } else {
                    WesternTallyGroupView(count: i < fullGroups ? 5 : remainder)
                }
            }
            if hasMore {
                Text("...")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}

// MARK: - Full Tally Marks

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

// MARK: - Western Tally Marks

struct WesternTallyMarksView: View {
    let count: Int
    private let groupsPerRow = 10

    var body: some View {
        let fullGroups = count / 5
        let remainder = count % 5
        let totalGroups = fullGroups + (remainder > 0 ? 1 : 0)
        let rows = max(1, (totalGroups + groupsPerRow - 1) / groupsPerRow)

        VStack(alignment: .leading, spacing: 6) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 8) {
                    let start = row * groupsPerRow
                    let end = min(start + groupsPerRow, totalGroups)
                    ForEach(start..<end, id: \.self) { i in
                        WesternTallyGroupView(count: i < fullGroups ? 5 : remainder)
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
            HStack(spacing: 3) {
                ForEach(0..<min(count, 4), id: \.self) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 2, height: 16)
                }
            }
            if count == 5 {
                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 2, height: 22)
                    .rotationEffect(.degrees(30))
                    .offset(x: 7)
            }
        }
        .frame(width: count == 5 ? 22 : CGFloat(count * 5), height: 20)
    }
}

// MARK: - Chinese Tally Marks

struct ChineseTallyMarksView: View {
    let count: Int
    private let groupsPerRow = 10

    var body: some View {
        let fullGroups = count / 5
        let remainder = count % 5
        let totalGroups = fullGroups + (remainder > 0 ? 1 : 0)
        let rows = max(1, (totalGroups + groupsPerRow - 1) / groupsPerRow)

        VStack(alignment: .leading, spacing: 6) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 6) {
                    let start = row * groupsPerRow
                    let end = min(start + groupsPerRow, totalGroups)
                    ForEach(start..<end, id: \.self) { i in
                        ChineseTallyGroupView(strokes: i < fullGroups ? 5 : remainder)
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
                Rectangle().fill(Color.white.opacity(0.9))
                    .frame(width: 14, height: 2).offset(y: -7)
            }
            if strokes >= 2 {
                Rectangle().fill(Color.white.opacity(0.9))
                    .frame(width: 2, height: 16).offset(x: -5)
            }
            if strokes >= 3 {
                Rectangle().fill(Color.white.opacity(0.9))
                    .frame(width: 10, height: 2)
            }
            if strokes >= 4 {
                Rectangle().fill(Color.white.opacity(0.9))
                    .frame(width: 2, height: 8).offset(x: 5, y: 4)
            }
            if strokes >= 5 {
                Rectangle().fill(Color.white.opacity(0.9))
                    .frame(width: 14, height: 2).offset(y: 7)
            }
        }
        .frame(width: 18, height: 18)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 1) {
            TrivitRowView(
                trivit: Trivit(title: "Days of work left", count: 13, colorIndex: 0),
                isExpanded: true,
                startEditing: false,
                onToggleExpand: {},
                onDelete: {},
                onEditingChanged: { _ in }
            )
            TrivitRowView(
                trivit: Trivit(title: "Tallies added", count: 8, colorIndex: 1),
                isExpanded: true,
                startEditing: false,
                onToggleExpand: {},
                onDelete: {},
                onEditingChanged: { _ in }
            )
            TrivitRowView(
                trivit: Trivit(title: "Bugs in our software", count: 5, colorIndex: 3),
                isExpanded: false,
                startEditing: false,
                onToggleExpand: {},
                onDelete: {},
                onEditingChanged: { _ in }
            )
            TrivitRowView(
                trivit: Trivit(title: "Pairs of shoes owned", count: 3, colorIndex: 4),
                isExpanded: false,
                startEditing: false,
                onToggleExpand: {},
                onDelete: {},
                onEditingChanged: { _ in }
            )
        }
    }
    .background(Color(.systemGray5))
}
