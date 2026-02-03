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
            print("⌚ First ModelContainer attempt failed: \(error)")

            // Delete old database and retry (handles schema migration issues)
            let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            if let appSupport = urls.first {
                print("⌚ Cleaning up database at: \(appSupport)")
                try? FileManager.default.removeItem(at: appSupport.appendingPathComponent("default.store"))
                try? FileManager.default.removeItem(at: appSupport.appendingPathComponent("default.store-shm"))
                try? FileManager.default.removeItem(at: appSupport.appendingPathComponent("default.store-wal"))
            }

            do {
                print("⌚ Retrying ModelContainer creation...")
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer after cleanup: \(error)")
            }
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
