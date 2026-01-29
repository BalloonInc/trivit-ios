//
//  TrivitRowView.swift
//  Trivit Watch App
//
//  A colorful tally counter row - matching iOS app design
//

import SwiftUI

struct TrivitRowView: View {
    let trivit: Trivit

    private var backgroundColor: Color {
        TrivitColors.color(at: trivit.colorIndex)
    }

    var body: some View {
        HStack(spacing: 8) {
            // Title and tally marks
            VStack(alignment: .leading, spacing: 4) {
                Text(trivit.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                // Tally marks (simplified for watch)
                if trivit.count > 0 {
                    WatchTallyMarksView(count: trivit.count)
                }
            }

            Spacer(minLength: 4)

            // Count display in circle
            Text("\(trivit.count)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(backgroundColor)
                .frame(width: 32, height: 32)
                .background(Color.white.opacity(0.95))
                .clipShape(Circle())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(backgroundColor)
        .cornerRadius(10)
    }
}

// MARK: - Simplified Tally Marks for Watch
struct WatchTallyMarksView: View {
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            let fullGroups = min(count / 5, 3) // Show max 3 groups on watch
            let remainder = count % 5
            let showRemainder = fullGroups < 3

            ForEach(0..<fullGroups, id: \.self) { _ in
                WatchTallyGroupView(count: 5)
            }

            if showRemainder && remainder > 0 {
                WatchTallyGroupView(count: remainder)
            }

            if count > 15 {
                Text("+")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

struct WatchTallyGroupView: View {
    let count: Int

    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<min(count, 4), id: \.self) { _ in
                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 1.5, height: 10)
            }
            if count == 5 {
                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 8, height: 1.5)
                    .rotationEffect(.degrees(-65))
                    .offset(x: -5)
            }
        }
        .frame(width: count == 5 ? 12 : CGFloat(count * 3), height: 12)
    }
}

#Preview {
    List {
        TrivitRowView(trivit: Trivit(title: "Push-ups", count: 42, colorIndex: 1))
        TrivitRowView(trivit: Trivit(title: "Coffee", count: 3, colorIndex: 0))
        TrivitRowView(trivit: Trivit(title: "Steps", count: 7, colorIndex: 3))
    }
    .listStyle(.carousel)
}
