//
//  WatchTallyMarksView.swift
//  Trivit Watch App
//
//  Reusable multi-row tally marks view for watch
//  Groups of 5 (4 vertical + 1 diagonal strike)
//

import SwiftUI

// MARK: - Main Tally Marks View

struct WatchTallyMarksView: View {
    let count: Int
    let mode: TallyDisplayMode
    let color: Color

    enum TallyDisplayMode {
        case compact   // For row preview - smaller marks, limited rows
        case full      // For detail view - larger marks, fills space
    }

    private var markHeight: CGFloat {
        mode == .compact ? 10 : 16
    }

    private var markWidth: CGFloat {
        mode == .compact ? 1.5 : 2
    }

    private var markSpacing: CGFloat {
        mode == .compact ? 2 : 3
    }

    private var groupSpacing: CGFloat {
        mode == .compact ? 4 : 6
    }

    private var groupsPerRow: Int {
        mode == .compact ? 6 : 5
    }

    private var maxRows: Int {
        mode == .compact ? 2 : 10
    }

    var body: some View {
        let fullGroups = count / 5
        let remainder = count % 5
        let totalGroups = fullGroups + (remainder > 0 ? 1 : 0)
        let rows = min(maxRows, max(1, (totalGroups + groupsPerRow - 1) / groupsPerRow))
        let displayedGroups = min(totalGroups, rows * groupsPerRow)
        let overflow = count - (displayedGroups * 5) + (remainder > 0 && displayedGroups == totalGroups ? (5 - remainder) : 0)

        VStack(alignment: .leading, spacing: mode == .compact ? 3 : 5) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: groupSpacing) {
                    let start = row * groupsPerRow
                    let end = min(start + groupsPerRow, totalGroups)

                    ForEach(start..<end, id: \.self) { i in
                        let groupCount = i < fullGroups ? 5 : remainder
                        TallyGroupView(
                            count: groupCount,
                            markHeight: markHeight,
                            markWidth: markWidth,
                            markSpacing: markSpacing,
                            color: color
                        )
                    }

                    // Show overflow indicator on last row
                    if row == rows - 1 && totalGroups > displayedGroups {
                        Text("+\(overflow)")
                            .font(.system(size: mode == .compact ? 8 : 10, weight: .bold))
                            .foregroundColor(color.opacity(0.8))
                    }
                }
            }
        }
    }
}

// MARK: - Single Tally Group (5 marks with strike-through)

struct TallyGroupView: View {
    let count: Int
    let markHeight: CGFloat
    let markWidth: CGFloat
    let markSpacing: CGFloat
    let color: Color

    var body: some View {
        ZStack(alignment: .leading) {
            // 4 vertical marks
            HStack(spacing: markSpacing) {
                ForEach(0..<min(count, 4), id: \.self) { _ in
                    Rectangle()
                        .fill(color)
                        .frame(width: markWidth, height: markHeight)
                }
            }

            // Diagonal strike-through for 5th mark
            if count == 5 {
                let strikeWidth = markHeight * 1.3
                Rectangle()
                    .fill(color)
                    .frame(width: markWidth, height: strikeWidth)
                    .rotationEffect(.degrees(30))
                    .offset(x: (CGFloat(3) * markSpacing + CGFloat(4) * markWidth) / 2 - markWidth / 2)
            }
        }
        .frame(
            width: count == 5
                ? (3 * markSpacing + 4 * markWidth + markHeight * 0.3)
                : (CGFloat(max(0, count - 1)) * markSpacing + CGFloat(count) * markWidth),
            height: markHeight * 1.2
        )
    }
}

// MARK: - Simple Preview for Collapsed Rows

struct WatchTallyInlinePreview: View {
    let count: Int
    let color: Color

    var body: some View {
        if count == 0 {
            EmptyView()
        } else {
            WatchTallyMarksView(count: min(count, 15), mode: .compact, color: color)
        }
    }
}

#Preview("Compact Mode") {
    ScrollView {
        VStack(alignment: .leading, spacing: 16) {
            ForEach([3, 5, 7, 12, 25, 42], id: \.self) { count in
                VStack(alignment: .leading) {
                    Text("Count: \(count)")
                        .font(.caption2)
                    WatchTallyMarksView(count: count, mode: .compact, color: .orange)
                }
                .padding(8)
                .background(Color.orange.opacity(0.2))
                .cornerRadius(8)
            }
        }
        .padding()
    }
}

#Preview("Full Mode") {
    ScrollView {
        VStack(alignment: .leading, spacing: 16) {
            ForEach([5, 12, 27, 42], id: \.self) { count in
                VStack(alignment: .leading) {
                    Text("Count: \(count)")
                        .font(.caption2)
                    WatchTallyMarksView(count: count, mode: .full, color: .blue)
                }
                .padding(8)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(8)
            }
        }
        .padding()
    }
}
