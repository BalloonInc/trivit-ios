import SwiftUI

/// Displays tally marks in a grid layout.
///
/// Shows groups of 5 tally marks (IIII with diagonal or 正 character)
/// arranged in a responsive grid that adapts to the available width.
struct TallyMarksView: View {
    // MARK: - Properties

    let count: Int
    let tallyType: TallyType

    // MARK: - Constants

    private let tallySize: CGFloat = 32
    private let spacing: CGFloat = 2
    private let horizontalInset: CGFloat = 5
    private let verticalInset: CGFloat = 15

    // MARK: - Computed Properties

    /// Number of tally images to show
    private var tallyImageCount: Int {
        guard count > 0 else { return 0 }
        return (count - 1) / 5 + 1
    }

    /// The count for the last (possibly incomplete) group
    private var lastGroupCount: Int {
        let remainder = count % 5
        return remainder == 0 ? 5 : remainder
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            let columns = columnsCount(for: geometry.size.width)
            let gridItems = Array(repeating: GridItem(.fixed(tallySize), spacing: spacing), count: columns)

            LazyVGrid(columns: gridItems, alignment: .leading, spacing: spacing) {
                ForEach(0..<tallyImageCount, id: \.self) { index in
                    tallyImage(at: index)
                }
            }
            .padding(.horizontal, horizontalInset)
            .padding(.vertical, verticalInset)
        }
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func tallyImage(at index: Int) -> some View {
        let isLastGroup = index == tallyImageCount - 1
        let imageCount = isLastGroup ? lastGroupCount : 5
        let imageName = tallyType.imageName(for: imageCount)

        // Use programmatically drawn tally marks (no image assets needed)
        TallyMarkShape(count: imageCount, style: tallyType)
            .frame(width: tallySize, height: tallySize)
            .accessibilityHidden(true)
    }

    // MARK: - Layout Calculation

    private func columnsCount(for width: CGFloat) -> Int {
        let availableWidth = width - (horizontalInset * 2)
        return max(1, Int(floor((availableWidth + spacing) / (tallySize + spacing))))
    }
}

// MARK: - Tally Mark Shape

/// A shape that draws tally marks programmatically
struct TallyMarkShape: View {
    let count: Int
    let style: TallyType

    var body: some View {
        Canvas { context, size in
            let strokeWidth: CGFloat = 2
            let markSpacing: CGFloat = size.width / 6
            let startX: CGFloat = markSpacing

            if style == .chinese {
                // Draw Chinese 正 character progressively
                drawChineseTally(context: context, size: size, count: count, strokeWidth: strokeWidth)
            } else {
                // Draw Western tally marks (IIII with diagonal)
                drawWesternTally(context: context, size: size, count: count, strokeWidth: strokeWidth, markSpacing: markSpacing, startX: startX)
            }
        }
    }

    private func drawWesternTally(context: GraphicsContext, size: CGSize, count: Int, strokeWidth: CGFloat, markSpacing: CGFloat, startX: CGFloat) {
        let topY: CGFloat = size.height * 0.15
        let bottomY: CGFloat = size.height * 0.85

        // Draw vertical marks
        for i in 0..<min(count, 4) {
            let x = startX + CGFloat(i) * markSpacing
            var path = Path()
            path.move(to: CGPoint(x: x, y: topY))
            path.addLine(to: CGPoint(x: x, y: bottomY))
            context.stroke(path, with: .foreground, lineWidth: strokeWidth)
        }

        // Draw diagonal for 5
        if count >= 5 {
            var path = Path()
            path.move(to: CGPoint(x: startX - markSpacing * 0.3, y: bottomY))
            path.addLine(to: CGPoint(x: startX + 3 * markSpacing + markSpacing * 0.3, y: topY))
            context.stroke(path, with: .foreground, lineWidth: strokeWidth)
        }
    }

    private func drawChineseTally(context: GraphicsContext, size: CGSize, count: Int, strokeWidth: CGFloat) {
        let padding: CGFloat = size.width * 0.1

        // 正 character strokes in order
        // 1: Top horizontal
        if count >= 1 {
            var path = Path()
            path.move(to: CGPoint(x: padding, y: size.height * 0.2))
            path.addLine(to: CGPoint(x: size.width - padding, y: size.height * 0.2))
            context.stroke(path, with: .foreground, lineWidth: strokeWidth)
        }

        // 2: Left vertical (top part)
        if count >= 2 {
            var path = Path()
            path.move(to: CGPoint(x: size.width * 0.25, y: size.height * 0.2))
            path.addLine(to: CGPoint(x: size.width * 0.25, y: size.height * 0.55))
            context.stroke(path, with: .foreground, lineWidth: strokeWidth)
        }

        // 3: Middle horizontal
        if count >= 3 {
            var path = Path()
            path.move(to: CGPoint(x: padding, y: size.height * 0.55))
            path.addLine(to: CGPoint(x: size.width - padding, y: size.height * 0.55))
            context.stroke(path, with: .foreground, lineWidth: strokeWidth)
        }

        // 4: Right vertical
        if count >= 4 {
            var path = Path()
            path.move(to: CGPoint(x: size.width * 0.75, y: size.height * 0.2))
            path.addLine(to: CGPoint(x: size.width * 0.75, y: size.height * 0.85))
            context.stroke(path, with: .foreground, lineWidth: strokeWidth)
        }

        // 5: Bottom horizontal
        if count >= 5 {
            var path = Path()
            path.move(to: CGPoint(x: padding, y: size.height * 0.85))
            path.addLine(to: CGPoint(x: size.width - padding, y: size.height * 0.85))
            context.stroke(path, with: .foreground, lineWidth: strokeWidth)
        }
    }
}

// MARK: - Preview

#Preview("Different Counts") {
    VStack(spacing: 20) {
        Group {
            Text("Count: 0")
            TallyMarksView(count: 0, tallyType: .western)
                .frame(height: 50)
                .background(Color.gray.opacity(0.2))

            Text("Count: 3")
            TallyMarksView(count: 3, tallyType: .western)
                .frame(height: 50)
                .background(Color.gray.opacity(0.2))

            Text("Count: 5")
            TallyMarksView(count: 5, tallyType: .western)
                .frame(height: 50)
                .background(Color.gray.opacity(0.2))

            Text("Count: 12")
            TallyMarksView(count: 12, tallyType: .western)
                .frame(height: 80)
                .background(Color.gray.opacity(0.2))

            Text("Count: 27")
            TallyMarksView(count: 27, tallyType: .western)
                .frame(height: 120)
                .background(Color.gray.opacity(0.2))
        }

        Text("Chinese Style (Count: 15)")
        TallyMarksView(count: 15, tallyType: .chinese)
            .frame(height: 60)
            .background(Color.gray.opacity(0.2))
    }
    .padding()
}
