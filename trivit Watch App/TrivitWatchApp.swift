//
//  TrivitWatchApp.swift
//  Trivit Watch App
//
//  Watch app entry point - syncs with iOS app via WatchConnectivity
//

import SwiftUI
import SwiftData
import os.log

private let logger = Logger(subsystem: "com.wouterdevriendt.trivit.watchkitapp", category: "WatchApp")

@main
struct TrivitWatchApp: App {
    @StateObject private var syncService = SyncService.shared

    // Check for sample data mode (for screenshots)
    private static var isSampleDataMode: Bool {
        ProcessInfo.processInfo.arguments.contains("-SampleDataMode")
    }

    // Watch uses its own local storage - data is synced from iPhone via WatchConnectivity
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Trivit.self])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isSampleDataMode,  // Use memory storage for screenshots
            cloudKitDatabase: .none  // Watch syncs via WatchConnectivity, not CloudKit
        )

        do {
            logger.info("⌚ Creating ModelContainer for watch app")
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])

            // Insert sample data if in sample data mode
            if isSampleDataMode {
                logger.info("⌚ Sample data mode - creating sample trivits")
                let context = container.mainContext
                let sampleTrivits = [
                    Trivit(title: "Glasses of water", count: 7, colorIndex: 0, isCollapsed: false, sortOrder: 0),
                    Trivit(title: "Push-ups done", count: 42, colorIndex: 1, isCollapsed: false, sortOrder: 1),
                    Trivit(title: "Books read", count: 3, colorIndex: 2, isCollapsed: true, sortOrder: 2),
                    Trivit(title: "Meditation", count: 15, colorIndex: 4, isCollapsed: true, sortOrder: 3)
                ]
                for trivit in sampleTrivits {
                    context.insert(trivit)
                }
                try? context.save()
            }

            return container
        } catch {
            logger.error("⌚ Failed to create ModelContainer: \(error)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(syncService)
                .onAppear {
                    logger.info("⌚ ContentView appeared, configuring sync service")
                    // Configure sync service with model context
                    let context = sharedModelContainer.mainContext
                    syncService.configure(with: context)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
