//
//  TrivitApp.swift
//  Trivit
//
//  Main app entry point using SwiftUI App lifecycle
//

import SwiftUI
import SwiftData

@main
struct TrivitApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Trivit.self])

        // Use App Group container for shared storage with watch app
        let appGroupID = "group.com.wouterdevriendt.trivit.Documents"
        let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)

        let modelConfiguration: ModelConfiguration
        if let containerURL = containerURL {
            let storeURL = containerURL.appendingPathComponent("Trivit.store")
            modelConfiguration = ModelConfiguration(
                schema: schema,
                url: storeURL,
                cloudKitDatabase: .none
            )
        } else {
            // Fallback to default location if App Group not available
            modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
        }

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            TrivitListView()
        }
        .modelContainer(sharedModelContainer)
    }
}
