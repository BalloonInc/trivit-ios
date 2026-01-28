import SwiftUI
import SwiftData

/// The main entry point for the Trivit app.
@main
struct TrivitApp: App {
    /// The shared model container for SwiftData
    let modelContainer: ModelContainer

    /// Shared services
    @State private var hapticsService = HapticsService.shared

    init() {
        do {
            let schema = Schema([
                Trivit.self,
                TrivitHistoryEntry.self
            ])

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true,
                groupContainer: .identifier("group.ballooninc.trivit.Documents"),
                cloudKitDatabase: .automatic
            )

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
        #if os(macOS)
        .windowStyle(.automatic)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1000, height: 700)
        .commands {
            TrivitCommands()
        }
        #endif

        #if os(macOS)
        Settings {
            MacSettingsView()
                .modelContainer(modelContainer)
        }

        Window("Statistics", id: "statistics") {
            MacStatisticsWindow()
                .modelContainer(modelContainer)
        }
        .windowStyle(.automatic)
        .defaultSize(width: 600, height: 400)
        #endif

        #if os(watchOS)
        // Watch-specific scene would go here
        #endif
    }
}

// MARK: - Content View

/// The root content view that handles navigation and initial state.
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("selectedColorScheme") private var selectedColorScheme = 0

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                AdaptiveTrivitListView()
            } else {
                OnboardingView(isComplete: $hasCompletedOnboarding)
            }
        }
        .environment(\.colorSchemeIndex, selectedColorScheme)
    }
}

// MARK: - Environment Keys

/// Custom environment key for the color scheme index.
private struct ColorSchemeIndexKey: EnvironmentKey {
    static let defaultValue: Int = 0
}

extension EnvironmentValues {
    var colorSchemeIndex: Int {
        get { self[ColorSchemeIndexKey.self] }
        set { self[ColorSchemeIndexKey.self] = newValue }
    }
}

// MARK: - macOS Commands

#if os(macOS)
struct TrivitCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        // File menu
        CommandGroup(after: .newItem) {
            Button("New Trivit") {
                NotificationCenter.default.post(name: .createNewTrivit, object: nil)
            }
            .keyboardShortcut("n", modifiers: .command)
        }

        // View menu
        CommandGroup(after: .sidebar) {
            Button("Show Statistics") {
                openWindow(id: "statistics")
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])

            Divider()

            Button("Expand All") {
                NotificationCenter.default.post(name: .expandAllTrivits, object: nil)
            }
            .keyboardShortcut("e", modifiers: [.command, .option])

            Button("Collapse All") {
                NotificationCenter.default.post(name: .collapseAllTrivits, object: nil)
            }
            .keyboardShortcut("c", modifiers: [.command, .option])
        }

        // Help menu additions
        CommandGroup(replacing: .help) {
            Button("Trivit Help") {
                if let url = URL(string: "https://trivit.be/help") {
                    NSWorkspace.shared.open(url)
                }
            }

            Divider()

            Button("Send Feedback") {
                if let url = URL(string: "mailto:support@ballooninc.be") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let createNewTrivit = Notification.Name("createNewTrivit")
    static let expandAllTrivits = Notification.Name("expandAllTrivits")
    static let collapseAllTrivits = Notification.Name("collapseAllTrivits")
}
#endif

// MARK: - macOS Settings View

#if os(macOS)
struct MacSettingsView: View {
    @AppStorage("selectedColorScheme") private var selectedColorScheme = 0
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true

    var body: some View {
        TabView {
            GeneralSettingsTab(
                selectedColorScheme: $selectedColorScheme,
                hapticFeedbackEnabled: $hapticFeedbackEnabled
            )
            .tabItem {
                Label("General", systemImage: "gear")
            }

            AppearanceSettingsTab(selectedColorScheme: $selectedColorScheme)
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }

            AboutSettingsTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 300)
    }
}

struct GeneralSettingsTab: View {
    @Binding var selectedColorScheme: Int
    @Binding var hapticFeedbackEnabled: Bool

    var body: some View {
        Form {
            Toggle("Haptic Feedback (Trackpad)", isOn: $hapticFeedbackEnabled)
                .onChange(of: hapticFeedbackEnabled) { _, newValue in
                    HapticsService.shared.isEnabled = newValue
                }

            Picker("Default Tally Style", selection: .constant(0)) {
                Text("Western").tag(0)
                Text("Chinese").tag(1)
            }
        }
        .padding()
    }
}

struct AppearanceSettingsTab: View {
    @Binding var selectedColorScheme: Int

    var body: some View {
        Form {
            Picker("Color Theme", selection: $selectedColorScheme) {
                ForEach(0..<TrivitColors.schemeCount, id: \.self) { index in
                    HStack {
                        HStack(spacing: 2) {
                            ForEach(0..<4, id: \.self) { colorIndex in
                                Rectangle()
                                    .fill(TrivitColors.previewColors(for: index)[colorIndex])
                                    .frame(width: 16, height: 16)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                        Text(TrivitColors.schemeNames[index])
                    }
                    .tag(index)
                }
            }
        }
        .padding()
    }
}

struct AboutSettingsTab: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tally")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("Trivit")
                .font(.title)
                .fontWeight(.bold)

            Text("Version \(appVersion) (\(buildNumber))")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            Link("Visit Website", destination: URL(string: "https://trivit.be")!)
            Link("Contact Support", destination: URL(string: "mailto:support@ballooninc.be")!)
        }
        .padding()
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
}
#endif

// MARK: - macOS Statistics Window

#if os(macOS)
struct MacStatisticsWindow: View {
    @Query(sort: \Trivit.createdAt, order: .forward)
    private var trivits: [Trivit]

    @State private var selectedTrivit: Trivit?

    var body: some View {
        NavigationSplitView {
            List(trivits, selection: $selectedTrivit) { trivit in
                SidebarTrivitRow(trivit: trivit)
                    .tag(trivit)
            }
            .listStyle(.sidebar)
            .navigationTitle("Statistics")
        } detail: {
            if let trivit = selectedTrivit {
                HistoryView(trivit: trivit)
            } else {
                ContentUnavailableView(
                    "Select a Trivit",
                    systemImage: "chart.bar",
                    description: Text("Choose a trivit to view its statistics")
                )
            }
        }
    }
}
#endif
