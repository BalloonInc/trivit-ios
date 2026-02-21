//
//  TallyMarksView.swift
//  trivit Vision
//
//  Western-style tally marks for visionOS spatial UI
//

import SwiftUI

struct TallyMarksView: View {
    let count: Int
    private let groupsPerRow = 10

    var body: some View {
        let fullGroups = count / 5
        let remainder = count % 5
        let totalGroups = fullGroups + (remainder > 0 ? 1 : 0)
        let rows = max(1, (totalGroups + groupsPerRow - 1) / groupsPerRow)

        VStack(alignment: .leading, spacing: 8) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 10) {
                    let start = row * groupsPerRow
                    let end = min(start + groupsPerRow, totalGroups)
                    ForEach(start..<end, id: \.self) { i in
                        TallyGroupView(count: i < fullGroups ? 5 : remainder)
                    }
                }
            }
        }
    }
}

struct TallyGroupView: View {
    let count: Int

    var body: some View {
        ZStack(alignment: .leading) {
            // 4 vertical marks
            HStack(spacing: 3) {
                ForEach(0..<min(count, 4), id: \.self) { _ in
                    Rectangle()
                        .fill(Color.primary.opacity(0.7))
                        .frame(width: 2.5, height: 20)
                }
            }
            // Diagonal strike-through for 5th mark
            if count == 5 {
                Rectangle()
                    .fill(Color.primary.opacity(0.7))
                    .frame(width: 2.5, height: 28)
                    .rotationEffect(.degrees(30))
                    .offset(x: 8)
            }
        }
        .frame(
            width: count == 5 ? 26 : CGFloat(count * 6),
            height: 24
        )
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 20) {
        TallyMarksView(count: 3)
        TallyMarksView(count: 5)
        TallyMarksView(count: 12)
        TallyMarksView(count: 42)
    }
    .padding()
}
