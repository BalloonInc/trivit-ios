import SwiftUI
import SwiftData

/// Detail view for a trivit, optimized for iPad and macOS.
/// Shows the trivit with large interactive tally marks and quick actions.
struct TrivitDetailView: View {
    // MARK: - Properties

    @Bindable var trivit: Trivit

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorSchemeIndex) private var colorSchemeIndex

    // MARK: - State

    @State private var showingHistory = false
    @State private var showingReminders = false
    @State private var showingResetConfirmation = false
    @State private var isEditing = false
    @State private var editedTitle: String = ""

    // MARK: - Computed Properties

    private var primaryColor: Color {
        TrivitColors.color(at: trivit.colorIndex, scheme: colorSchemeIndex, isDark: false)
    }

    private var secondaryColor: Color {
        TrivitColors.color(at: trivit.colorIndex, scheme: colorSchemeIndex, isDark: true)
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 32) {
                    headerSection
                    tallySection(geometry: geometry)
                    actionButtons
                    quickStatsSection
                }
                .padding(24)
            }
        }
        .background(Color(.systemBackground))
        .navigationTitle(trivit.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar { detailToolbar }
        .sheet(isPresented: $showingHistory) {
            HistoryView(trivit: trivit)
        }
        .sheet(isPresented: $showingReminders) {
            ReminderListView(trivit: trivit)
        }
        .alert("Reset Trivit", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                trivit.reset()
                HapticsService.shared.notification(.warning)
            }
        } message: {
            Text("Are you sure you want to reset '\(trivit.title)' to zero?")
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Large count display
            Text("\(trivit.count)")
                .font(.system(size: 96, weight: .bold, design: .rounded))
                .foregroundStyle(primaryColor)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: trivit.count)

            // Title (editable)
            if isEditing {
                TextField("Title", text: $editedTitle)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 300)
                    .submitLabel(.done)
                    .onSubmit { finishEditing() }
            } else {
                Text(trivit.title)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .onTapGesture(count: 2) {
                        startEditing()
                    }
            }

            // Easter egg display
            if let easterEgg = EasterEggs.message(for: trivit.count) {
                Text(easterEgg)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(primaryColor.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(.top, 20)
    }

    // MARK: - Tally Section

    private func tallySection(geometry: GeometryProxy) -> some View {
        let isLandscape = geometry.size.width > geometry.size.height
        let maxWidth = isLandscape ? geometry.size.width * 0.7 : geometry.size.width - 48

        return VStack {
            TallyMarksView(
                count: trivit.count,
                tallyType: trivit.tallyType
            )
            .frame(maxWidth: maxWidth)
            .frame(minHeight: 200)
            .padding(24)
            .background(secondaryColor)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .contentShape(Rectangle())
            .onTapGesture {
                trivit.increment()
                HapticsService.shared.impact(.medium)
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 24) {
            // Decrement button
            ActionButton(
                title: "Decrement",
                systemImage: "minus",
                color: .red
            ) {
                trivit.decrement()
                HapticsService.shared.impact(.light)
            }

            // Increment button (larger)
            ActionButton(
                title: "Increment",
                systemImage: "plus",
                color: primaryColor,
                isLarge: true
            ) {
                trivit.increment()
                HapticsService.shared.impact(.medium)
            }

            // Reset button
            ActionButton(
                title: "Reset",
                systemImage: "arrow.counterclockwise",
                color: .orange
            ) {
                showingResetConfirmation = true
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Quick Stats Section

    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Stats")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 20) {
                QuickStatItem(
                    title: "Created",
                    value: trivit.createdAt.formatted(date: .abbreviated, time: .omitted),
                    icon: "calendar"
                )

                QuickStatItem(
                    title: "Type",
                    value: trivit.tallyType == .western ? "Western" : "Chinese",
                    icon: "tally"
                )

                QuickStatItem(
                    title: "Color",
                    value: TrivitColors.schemeNames[colorSchemeIndex],
                    icon: "paintpalette"
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var detailToolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                showingHistory = true
            } label: {
                Image(systemName: "chart.bar")
            }
            .accessibilityLabel("View History")
        }

        ToolbarItem(placement: .secondaryAction) {
            Button {
                showingReminders = true
            } label: {
                Image(systemName: "bell")
            }
            .accessibilityLabel("Reminders")
        }

        ToolbarItem(placement: .secondaryAction) {
            Menu {
                Button {
                    startEditing()
                } label: {
                    Label("Rename", systemImage: "pencil")
                }

                Button {
                    cycleTallyType()
                } label: {
                    Label("Change Tally Style", systemImage: "tally")
                }

                Button {
                    cycleColor()
                } label: {
                    Label("Change Color", systemImage: "paintpalette")
                }

                Divider()

                Button {
                    showingReminders = true
                } label: {
                    Label("Reminders", systemImage: "bell")
                }

                Divider()

                Button(role: .destructive) {
                    showingResetConfirmation = true
                } label: {
                    Label("Reset Count", systemImage: "arrow.counterclockwise")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    // MARK: - Actions

    private func startEditing() {
        editedTitle = trivit.title
        isEditing = true
    }

    private func finishEditing() {
        isEditing = false
        let trimmed = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && trimmed != trivit.title {
            trivit.title = trimmed
        }
    }

    private func cycleTallyType() {
        trivit.tallyType = trivit.tallyType == .western ? .chinese : .western
        HapticsService.shared.selection()
    }

    private func cycleColor() {
        trivit.colorIndex = (trivit.colorIndex + 1) % TrivitColors.colorCount
        HapticsService.shared.selection()
    }
}

// MARK: - Action Button

private struct ActionButton: View {
    let title: String
    let systemImage: String
    let color: Color
    var isLarge: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(isLarge ? .title : .title2)
                    .fontWeight(.semibold)

                Text(title)
                    .font(.caption)
            }
            .foregroundStyle(.white)
            .frame(width: isLarge ? 80 : 60, height: isLarge ? 80 : 60)
            .background(color)
            .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

// MARK: - Quick Stat Item

private struct QuickStatItem: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TrivitDetailView(trivit: .preview)
    }
    .modelContainer(for: Trivit.self, inMemory: true)
}
