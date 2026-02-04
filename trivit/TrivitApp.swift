//
//  TrivitApp.swift
//  Trivit
//
//  Main app entry point using SwiftUI App lifecycle
//

import SwiftUI
import SwiftData
#if canImport(FirebaseCore)
import FirebaseCore
#endif

@main
struct TrivitApp: App {
    @StateObject private var watchSyncService = WatchSyncService.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Trivit.self, TallyEvent.self])

        // CloudKit sync for iPhone <-> iPad via iCloud
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

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
        // Initialize Firebase Analytics & Crashlytics
        AnalyticsService.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            TrivitListView()
                .onAppear {
                    print("📱 TrivitListView.onAppear - configuring watch sync")
                    // Configure watch sync with the model context
                    let context = sharedModelContainer.mainContext
                    watchSyncService.configure(with: context)
                    print("📱 Watch sync configured - paired: \(watchSyncService.isWatchPaired), reachable: \(watchSyncService.isWatchReachable)")

                    // Track session start with analytics
                    trackSessionStart(context: context)
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
}
