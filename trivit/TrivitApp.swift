//
//  TrivitApp.swift
//  Trivit
//
//  Main app entry point using SwiftUI App lifecycle.
//  Trivit is a simple tally counter app that helps you track anything you want to count.
//  Features include colorful counters, Apple Watch sync, and iCloud backup.
//

import SwiftUI
import SwiftData
#if canImport(FirebaseCore)
import FirebaseCore
#endif

@main
struct TrivitApp: App {
    @StateObject private var watchSyncService = WatchSyncService.shared

    // MARK: - UI Testing Detection

    /// Returns true if the app is running in UI testing mode
    private static var isUITesting: Bool {
        CommandLine.arguments.contains("-UITestingMode")
    }

    /// Returns true if sample data should be loaded for screenshots
    private static var shouldLoadSampleData: Bool {
        CommandLine.arguments.contains("-SampleDataMode")
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Trivit.self, TallyEvent.self])

        // Use in-memory storage for UI testing to ensure consistent state
        let isUITesting = CommandLine.arguments.contains("-UITestingMode")

        let modelConfiguration: ModelConfiguration
        if isUITesting {
            // In-memory database for UI tests - no CloudKit
            modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )
            print("📸 UI Testing Mode: Using in-memory database")
        } else {
            // CloudKit sync for iPhone <-> iPad via iCloud
            modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
        }

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("❌ First ModelContainer attempt failed: \(error)")
            print("❌ Error details: \(String(describing: error))")

            // Delete old local database and retry with fresh CloudKit
            let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            if let appSupport = urls.first {
                print("🗑️ Cleaning up at: \(appSupport)")
                try? FileManager.default.removeItem(at: appSupport.appendingPathComponent("default.store"))
                try? FileManager.default.removeItem(at: appSupport.appendingPathComponent("default.store-shm"))
                try? FileManager.default.removeItem(at: appSupport.appendingPathComponent("default.store-wal"))
            }

            do {
                print("🔄 Retryincluding ng ModelContainer creation...")
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch let retryError {
                print("❌ Second attempt failed: \(retryError)")
                fatalError("Could not create ModelContainer after cleanup: \(retryError)")
            }
        }
    }()

    init() {
        print("📱 ======== TRIVIT APP STARTING ========")
        print("📱 TrivitApp.init() called")

        if Self.isUITesting {
            print("📸 Running in UI Testing Mode")
        }

        // Initialize Firebase Analytics & Crashlytics (skip for UI tests)
        if !Self.isUITesting {
            AnalyticsService.shared.configure()
        }
    }

    var body: some Scene {
        WindowGroup {
            TrivitListView()
                .onAppear {
                    let context = sharedModelContainer.mainContext

                    // Load sample data for UI testing screenshots
                    if Self.shouldLoadSampleData {
                        print("📸 Loading sample data for screenshots")
                        loadSampleData(context: context)
                    }

                    if !Self.isUITesting {
                        print("📱 TrivitListView.onAppear - configuring watch sync")
                        // Configure watch sync with the model context
                        watchSyncService.configure(with: context)
                        print("📱 Watch sync configured - paired: \(watchSyncService.isWatchPaired), reachable: \(watchSyncService.isWatchReachable)")

                        // Track session start with analytics
                        trackSessionStart(context: context)
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private func trackSessionStart(context: ModelContext) {
        do {
            let descriptor = FetchDescriptor<Trivit>(predicate: #Predicate { $0.deletedAt == nil })
            let trivits = try context.fetch(descriptor)
            let totalCount = trivits.reduce(0) { $0 + $1.count }
            AnalyticsService.shared.trackSessionStart(trivitCount: trivits.count, totalCount: totalCount)
        } catch {
            print("📱 Failed to fetch trivits for session tracking: \(error)")
        }
    }

    // MARK: - Sample Data for UI Testing

    private func loadSampleData(context: ModelContext) {
        // Check if data already exists to prevent duplicates
        let existingCount = (try? context.fetchCount(FetchDescriptor<Trivit>())) ?? 0
        if existingCount > 0 {
            print("📸 Sample data already loaded, skipping")
            return
        }

        // Sample trivits with realistic data for App Store screenshots
        let sampleTrivits: [(title: String, count: Int, colorIndex: Int)] = [
            ("Glasses of water", 7, 0),
            ("Push-ups done", 42, 1),
            ("Books read", 3, 2),
            ("Steps walked (thousands)", 12, 3),
            ("Meditation minutes", 15, 4),
            ("Gratitude moments", 5, 5)
        ]

        for (index, trivit) in sampleTrivits.enumerated() {
            let newTrivit = Trivit(
                title: trivit.title,
                count: trivit.count,
                colorIndex: trivit.colorIndex,
                isCollapsed: index >= 3,  // First 3 trivits expanded, rest collapsed
                sortOrder: index
            )
            context.insert(newTrivit)

            // Generate TallyEvent records so statistics charts have data
            generateSampleEvents(for: newTrivit, in: context)
        }

        // Save the context
        do {
            try context.save()
            print("📸 Sample data loaded successfully")
        } catch {
            print("📸 Failed to save sample data: \(error)")
        }

        // Mark tutorial as seen for UI tests
        UserDefaults.standard.set(true, forKey: "hasSeenTutorial")
    }

    /// Generate realistic TallyEvent records spread across 90 days so statistics charts show data
    private func generateSampleEvents(for trivit: Trivit, in context: ModelContext) {
        let calendar = Calendar.current
        let now = Date()

        // Distribute the trivit's count across the last 90 days with realistic patterns
        // More events on weekdays, varied hours, some days with no activity for streak gaps
        var eventsToCreate = trivit.count
        var day = 0

        while eventsToCreate > 0 && day < 90 {
            guard let date = calendar.date(byAdding: .day, value: -day, to: now) else {
                day += 1
                continue
            }

            // Skip some days randomly for realistic gaps (roughly 30% of days)
            let dayHash = (day * 7 + trivit.colorIndex * 13) % 10
            if dayHash < 3 && day > 0 {
                day += 1
                continue
            }

            // 1-3 events per active day
            let eventsThisDay = min(eventsToCreate, ((day + trivit.colorIndex) % 3) + 1)

            for i in 0..<eventsThisDay {
                // Spread across different hours (8am-10pm) for hourly chart variety
                let hour = 8 + ((day * 3 + i * 5 + trivit.colorIndex * 2) % 14)
                let minute = (day * 7 + i * 17) % 60

                var components = calendar.dateComponents([.year, .month, .day], from: date)
                components.hour = hour
                components.minute = minute

                if let eventDate = calendar.date(from: components) {
                    let event = TallyEvent(trivitId: trivit.id, timestamp: eventDate, delta: 1)
                    context.insert(event)
                }
            }

            eventsToCreate -= eventsThisDay
            day += 1
        }

        print("📸 Generated \(trivit.count - eventsToCreate) events for '\(trivit.title)'")
    }
}
