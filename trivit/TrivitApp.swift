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
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

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
