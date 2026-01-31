//
//  TrivitWatchApp.swift
//  Trivit Watch App
//
//  Watch app entry point - syncs with iOS app via WatchConnectivity
//

import SwiftUI
import SwiftData

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
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(syncService)
                .onAppear {
                    // Configure sync service with model context
                    let context = sharedModelContainer.mainContext
                    syncService.configure(with: context)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
