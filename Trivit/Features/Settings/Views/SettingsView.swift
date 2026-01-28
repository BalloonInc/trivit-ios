import SwiftUI

/// Settings view for configuring the app.
struct SettingsView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @AppStorage("selectedColorScheme") private var selectedColorScheme = 0
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true

    @State private var showingResetConfirmation = false
    @State private var showingTutorial = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                appearanceSection
                feedbackSection
                tutorialSection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingTutorial) {
            OnboardingView(isComplete: .constant(true))
        }
        .alert("Reset All Data", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("This will delete all your trivits. This action cannot be undone.")
        }
    }

    // MARK: - Sections

    private var appearanceSection: some View {
        Section("Appearance") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Color Theme")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                colorSchemeGrid
            }
            .padding(.vertical, 8)
        }
    }

    private var colorSchemeGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ForEach(0..<TrivitColors.schemeCount, id: \.self) { schemeIndex in
                ColorSchemeButton(
                    name: TrivitColors.schemeNames[schemeIndex],
                    colors: TrivitColors.previewColors(for: schemeIndex),
                    isSelected: selectedColorScheme == schemeIndex
                ) {
                    withAnimation {
                        selectedColorScheme = schemeIndex
                    }
                    HapticsService.shared.selection()
                }
            }
        }
    }

    private var feedbackSection: some View {
        Section("Feedback") {
            Toggle("Haptic Feedback", isOn: $hapticFeedbackEnabled)
                .onChange(of: hapticFeedbackEnabled) { _, newValue in
                    HapticsService.shared.isEnabled = newValue
                    if newValue {
                        HapticsService.shared.selection()
                    }
                }
        }
    }

    private var tutorialSection: some View {
        Section("Help") {
            Button {
                showingTutorial = true
            } label: {
                Label("Show Tutorial", systemImage: "book")
            }
        }
    }

    private var dataSection: some View {
        Section("Data") {
            Button(role: .destructive) {
                showingResetConfirmation = true
            } label: {
                Label("Reset All Data", systemImage: "trash")
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: appVersion)
            LabeledContent("Build", value: buildNumber)

            Link(destination: URL(string: "https://trivit.be")!) {
                Label("Website", systemImage: "globe")
            }

            Link(destination: URL(string: "mailto:support@ballooninc.be")!) {
                Label("Contact Support", systemImage: "envelope")
            }
        }
    }

    // MARK: - Computed Properties

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    // MARK: - Actions

    private func resetAllData() {
        // Delete all trivits
        do {
            try modelContext.delete(model: Trivit.self)
            try modelContext.delete(model: TrivitHistoryEntry.self)
            try modelContext.save()
            HapticsService.shared.notification(.warning)
        } catch {
            print("Failed to reset data: \(error)")
        }
    }
}

// MARK: - Color Scheme Button

struct ColorSchemeButton: View {
    let name: String
    let colors: [Color]
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                HStack(spacing: 2) {
                    ForEach(0..<min(4, colors.count), id: \.self) { index in
                        Rectangle()
                            .fill(colors[index])
                            .frame(height: 24)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                )

                Text(name)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(name) color scheme\(isSelected ? ", selected" : "")")
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .modelContainer(for: Trivit.self, inMemory: true)
}
