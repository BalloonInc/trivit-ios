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
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
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
                TrivitListView()
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
