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

        Image(imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: tallySize, height: tallySize)
            .accessibilityHidden(true)
    }

    // MARK: - Layout Calculation

    private func columnsCount(for width: CGFloat) -> Int {
        let availableWidth = width - (horizontalInset * 2)
        return max(1, Int(floor((availableWidth + spacing) / (tallySize + spacing))))
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
