//
//  TrivitVisionApp.swift
//  trivit Vision
//
//  visionOS app entry point - syncs with iOS via CloudKit
//

import SwiftUI
import SwiftData
import os.log

private let logger = Logger(subsystem: "com.wouterdevriendt.trivit.vision", category: "VisionApp")

@main
struct TrivitVisionApp: App {
    // Check for sample data mode (for screenshots)
    private static var isSampleDataMode: Bool {
        ProcessInfo.processInfo.arguments.contains("-SampleDataMode")
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Trivit.self])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isSampleDataMode,
            cloudKitDatabase: isSampleDataMode ? .none : .automatic
        )

        do {
            logger.info("🥽 Creating ModelContainer for visionOS app")
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])

            if isSampleDataMode {
                logger.info("🥽 Sample data mode - creating sample trivits")
                let context = container.mainContext
                let sampleTrivits = [
                    Trivit(title: "Glasses of water", count: 7, colorIndex: 0, sortOrder: 0),
                    Trivit(title: "Push-ups done", count: 42, colorIndex: 1, sortOrder: 1),
                    Trivit(title: "Books read", count: 3, colorIndex: 2, sortOrder: 2),
                    Trivit(title: "Meditation", count: 15, colorIndex: 4, sortOrder: 3),
                    Trivit(title: "Coffee cups", count: 5, colorIndex: 5, sortOrder: 4),
                    Trivit(title: "Steps walked", count: 12, colorIndex: 3, sortOrder: 5),
                ]
                for trivit in sampleTrivits {
                    context.insert(trivit)
                }
                try? context.save()
            }

            return container
        } catch {
            logger.error("🥽 Failed to create ModelContainer: \(error)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
