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
                HStack(spacing: 0) {
                    // Title and tally marks
                    VStack(alignment: .leading, spacing: 6) {
                        // Title with small triangle indicator
                        HStack(spacing: 6) {
                            // Small triangle indicator
                            Triangle()
                                .fill(Color.white.opacity(0.6))
                                .frame(width: 8, height: 8)

                            if isEditing {
                                TextField("Title", text: $trivit.title)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                    .focused($isTitleFocused)
                                    .onSubmit {
                                        isEditing = false
                                    }
                            } else {
                                Text(trivit.title)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                    .onLongPressGesture {
                                        isEditing = true
                                        isTitleFocused = true
                                    }
                            }
                        }

                        // Tally marks - using text representation
                        TallyMarksView(count: trivit.count)
                            .padding(.leading, 4)
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
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

// MARK: - Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Tally Marks Visual
struct TallyMarksView: View {
    let count: Int

    // Unicode tally mark (正) or we can use custom text representation
    private let tallyFive = "卌"  // Tally mark for 5

    var body: some View {
        if count == 0 {
            // Empty state
            Text(" ")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
        } else {
            // Wrap tally marks if needed
            let tallyText = buildTallyString()
            Text(tallyText)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
    }

    private func buildTallyString() -> String {
        let fullGroups = count / 5
        let remainder = count % 5

        var result = ""

        // Add full groups (卌)
        for i in 0..<fullGroups {
            result += tallyFive
            // Add space every few groups for readability
            if (i + 1) % 10 == 0 && i < fullGroups - 1 {
                result += " "
            } else if i < fullGroups - 1 {
                result += " "
            }
        }

        // Add remainder as individual marks (|)
        if remainder > 0 {
            if !result.isEmpty {
                result += " "
            }
            result += String(repeating: "I", count: remainder)
        }

        return result
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
