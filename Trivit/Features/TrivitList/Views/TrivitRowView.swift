import SwiftUI

/// A single row in the trivit list, showing the trivit with its tally marks.
struct TrivitRowView: View {
    // MARK: - Properties

    let trivit: Trivit
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let onResetRequest: () -> Void
    let onToggleCollapse: () -> Void
    let onRename: (String) -> Void

    // MARK: - State

    @State private var isEditing = false
    @State private var editedTitle: String = ""

    @Environment(\.colorSchemeIndex) private var colorSchemeIndex

    // MARK: - Computed Properties

    private var primaryColor: Color {
        TrivitColors.color(at: trivit.colorIndex, scheme: colorSchemeIndex, isDark: false)
    }

    private var secondaryColor: Color {
        TrivitColors.color(at: trivit.colorIndex, scheme: colorSchemeIndex, isDark: true)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            titleSection
            if !trivit.isCollapsed {
                tallySection
            }
        }
        .background(trivit.isCollapsed ? primaryColor : secondaryColor)
        .clipShape(RoundedRectangle(cornerRadius: 0))
        .contentShape(Rectangle())
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: trivit.isCollapsed)
    }

    // MARK: - Title Section

    private var titleSection: some View {
        HStack {
            if isEditing {
                titleTextField
            } else {
                titleLabel
            }

            Spacer()

            accessoryView
        }
        .frame(height: 44)
        .padding(.horizontal, 16)
        .background(primaryColor)
        .onTapGesture {
            onToggleCollapse()
        }
        .onLongPressGesture(minimumDuration: 0.3) {
            startEditing()
        }
    }

    private var titleLabel: some View {
        Text(trivit.title)
            .font(.body)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .lineLimit(1)
    }

    private var titleTextField: some View {
        TextField("Title", text: $editedTitle)
            .font(.body)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .tint(.white)
            .textFieldStyle(.plain)
            .submitLabel(.done)
            .onSubmit {
                finishEditing()
            }
    }

    @ViewBuilder
    private var accessoryView: some View {
        if trivit.isCollapsed {
            // Collapsed: show count badge
            Text("\(trivit.count)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(secondaryColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            // Expanded: show minus button
            Button {
                onDecrement()
            } label: {
                Text("−")
                    .font(.title)
                    .fontWeight(.regular)
                    .foregroundStyle(secondaryColor)
                    .frame(width: 40, height: 30)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Decrement")
            .onLongPressGesture(minimumDuration: 0.3) {
                onResetRequest()
            }
        }
    }

    // MARK: - Tally Section

    private var tallySection: some View {
        TallyMarksView(
            count: trivit.count,
            tallyType: trivit.tallyType
        )
        .frame(maxWidth: .infinity)
        .frame(minHeight: 88)
        .background(secondaryColor)
        .contentShape(Rectangle())
        .onTapGesture {
            onIncrement()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(trivit.title), count: \(trivit.count)")
        .accessibilityHint("Double tap to increment")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Editing

    private func startEditing() {
        editedTitle = trivit.title
        isEditing = true
    }

    private func finishEditing() {
        isEditing = false
        let trimmed = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && trimmed != trivit.title {
            onRename(trimmed)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        TrivitRowView(
            trivit: Trivit(title: "Coffee cups", count: 42, colorIndex: 0, isCollapsed: false),
            onIncrement: {},
            onDecrement: {},
            onResetRequest: {},
            onToggleCollapse: {},
            onRename: { _ in }
        )

        TrivitRowView(
            trivit: Trivit(title: "Push-ups", count: 127, colorIndex: 1, isCollapsed: true),
            onIncrement: {},
            onDecrement: {},
            onResetRequest: {},
            onToggleCollapse: {},
            onRename: { _ in }
        )

        TrivitRowView(
            trivit: Trivit(title: "Days without coffee", count: 3, colorIndex: 2, isCollapsed: false),
            onIncrement: {},
            onDecrement: {},
            onResetRequest: {},
            onToggleCollapse: {},
            onRename: { _ in }
        )
    }
}
