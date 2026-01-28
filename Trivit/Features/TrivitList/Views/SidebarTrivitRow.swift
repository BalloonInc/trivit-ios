import SwiftUI

/// A compact row view for displaying trivits in the sidebar on iPad and macOS.
struct SidebarTrivitRow: View {
    // MARK: - Properties

    let trivit: Trivit

    @Environment(\.colorSchemeIndex) private var colorSchemeIndex

    // MARK: - Computed Properties

    private var accentColor: Color {
        TrivitColors.color(at: trivit.colorIndex, scheme: colorSchemeIndex, isDark: false)
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // Color indicator
            Circle()
                .fill(accentColor)
                .frame(width: 12, height: 12)

            // Title
            Text(trivit.title)
                .font(.body)
                .lineLimit(1)

            Spacer()

            // Count badge
            Text("\(trivit.count)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(trivit.title), count: \(trivit.count)")
    }
}

// MARK: - Preview

#Preview {
    List {
        SidebarTrivitRow(trivit: Trivit(title: "Coffee cups", count: 42, colorIndex: 0))
        SidebarTrivitRow(trivit: Trivit(title: "Push-ups", count: 127, colorIndex: 1))
        SidebarTrivitRow(trivit: Trivit(title: "Days without coffee", count: 3, colorIndex: 2))
        SidebarTrivitRow(trivit: Trivit(title: "Books read", count: 12, colorIndex: 3))
    }
    .listStyle(.sidebar)
}
