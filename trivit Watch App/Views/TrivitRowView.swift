//
//  TrivitRowView.swift
//  Trivit Watch App
//
//  A colorful tally counter row with expandable tally marks:
//  - LEFT (80%): Tap to expand/collapse AND increment
//  - RIGHT (20%): Tap chevron to open detail view
//

import SwiftUI
import WatchKit

struct TrivitRowView: View {
    let trivit: Trivit
    let syncService: SyncService

    @State private var isExpanded = false

    private var backgroundColor: Color {
        TrivitColors.color(at: trivit.colorIndex)
    }

    private var tallyBackgroundColor: Color {
        backgroundColor.opacity(0.6)
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // LEFT ZONE (80%): Tap to expand/collapse AND increment
                leftZone
                    .frame(width: geometry.size.width * 0.78)

                // Divider line
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 1)
                    .padding(.vertical, 8)

                // RIGHT ZONE (20%): Tap to open details
                rightZone
            }
            .background(backgroundColor)
            .cornerRadius(10)
        }
        .frame(height: isExpanded ? expandedHeight : 52)
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }

    private var expandedHeight: CGFloat {
        // Calculate height based on tally rows needed
        let fullGroups = trivit.count / 5
        let remainder = trivit.count % 5
        let totalGroups = fullGroups + (remainder > 0 ? 1 : 0)
        let groupsPerRow = 6
        let rows = min(5, max(1, (totalGroups + groupsPerRow - 1) / groupsPerRow)) // max 5 rows in compact mode
        return 52 + CGFloat(rows) * 16 + 12 // base + tally rows + padding
    }

    // MARK: - Left Zone (Expand/Collapse + Increment)

    private var leftZone: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: Title + Count (tap to toggle expand/collapse)
            Button {
                handleTitleTap()
            } label: {
                HStack(spacing: 6) {
                    Text(trivit.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Spacer()

                    // Expand/collapse indicator
                    if isExpanded {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Text("\(trivit.count)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: trivit.count)
                }
                .padding(.leading, 10)
                .padding(.trailing, 6)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)

            // Collapsed: Single row tally preview (tap to expand)
            if !isExpanded && trivit.count > 0 {
                Button {
                    isExpanded = true
                    WKInterfaceDevice.current().play(.click)
                } label: {
                    WatchTallyMarksView(
                        count: min(trivit.count, 15),
                        mode: .compact,
                        color: .white.opacity(0.85)
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 10)
                    .padding(.trailing, 6)
                    .padding(.bottom, 6)
                }
                .buttonStyle(.plain)
            }

            // Expanded: Multi-row tally area (tap to increment)
            if isExpanded {
                Button {
                    incrementTrivit()
                } label: {
                    expandedTallyArea
                        .padding(.horizontal, 6)
                        .padding(.bottom, 6)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var expandedTallyArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Small arrow indicator
            HStack {
                Triangle()
                    .fill(backgroundColor)
                    .frame(width: 10, height: 5)
                    .padding(.leading, 4)
                Spacer()
            }

            // Tally marks on tinted background
            HStack {
                if trivit.count > 0 {
                    WatchTallyMarksView(
                        count: trivit.count,
                        mode: .compact,
                        color: .white.opacity(0.9)
                    )
                } else {
                    Text("Tap to count")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                }
                Spacer()
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity)
            .background(tallyBackgroundColor)
            .cornerRadius(6)
        }
    }

    // MARK: - Right Zone (Navigation)

    private var rightZone: some View {
        NavigationLink {
            TrivitDetailView(trivit: trivit)
                .environmentObject(syncService)
        } label: {
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white.opacity(0.9))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func handleTitleTap() {
        // Title bar toggles expand/collapse
        isExpanded.toggle()
        WKInterfaceDevice.current().play(.click)
    }

    private func incrementTrivit() {
        trivit.count += 1
        syncService.syncTrivitUpdate(trivit)
        WKInterfaceDevice.current().play(.click)
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

#Preview {
    NavigationStack {
        ScrollView {
            LazyVStack(spacing: 8) {
                TrivitRowView(trivit: Trivit(title: "Push-ups", count: 42, colorIndex: 1), syncService: SyncService())
                TrivitRowView(trivit: Trivit(title: "Coffee", count: 3, colorIndex: 0), syncService: SyncService())
                TrivitRowView(trivit: Trivit(title: "Steps", count: 17, colorIndex: 3), syncService: SyncService())
                TrivitRowView(trivit: Trivit(title: "Water", count: 0, colorIndex: 2), syncService: SyncService())
            }
            .padding(.horizontal, 4)
        }
    }
}
