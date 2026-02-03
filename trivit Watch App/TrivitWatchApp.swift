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

    // Watch uses its own local storage - data is synced from iPhone via WatchConnectivity
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Trivit.self])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none  // Watch syncs via WatchConnectivity, not CloudKit
        )

        do {
            logger.info("⌚ Creating ModelContainer for watch app")
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
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
