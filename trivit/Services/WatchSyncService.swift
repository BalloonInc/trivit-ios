//
//  WatchSyncService.swift
//  Trivit
//
//  Handles sync between iPhone and Apple Watch via WatchConnectivity
//

import Foundation
import WatchConnectivity
import SwiftData

@MainActor
class WatchSyncService: NSObject, ObservableObject {
    static let shared = WatchSyncService()

    private let session = WCSession.default
    private var modelContext: ModelContext?

    @Published var isWatchPaired = false
    @Published var isWatchReachable = false

    override init() {
        super.init()
    }

    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        setupWatchConnectivity()
    }

    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else {
            print("WatchConnectivity not supported on this device")
            return
        }

        session.delegate = self
        session.activate()
    }

    // MARK: - Sync All Trivits to Watch

    func syncAllTrivitsToWatch() {
        guard session.isReachable, let modelContext = modelContext else {
            print("Watch not reachable or no model context")
            return
        }

        do {
            let descriptor = FetchDescriptor<Trivit>(sortBy: [SortDescriptor(\.createdAt)])
            let trivits = try modelContext.fetch(descriptor)

            let trivitsData = trivits.map { trivit -> [String: Any] in
                [
                    "id": trivit.id.uuidString,
                    "title": trivit.title,
                    "count": trivit.count,
                    "colorIndex": trivit.colorIndex,
                    "isCollapsed": trivit.isCollapsed,
                    "createdAt": trivit.createdAt.timeIntervalSince1970
                ]
            }

            let message: [String: Any] = [
                "type": "trivitsSync",
                "trivits": trivitsData
            ]

            session.sendMessage(message, replyHandler: nil) { error in
                print("Failed to sync all trivits to watch: \(error.localizedDescription)")
            }

            print("Synced \(trivits.count) trivits to watch")
        } catch {
            print("Failed to fetch trivits for sync: \(error)")
        }
    }

    // MARK: - Sync Single Trivit Update

    func syncTrivitToWatch(_ trivit: Trivit) {
        guard session.isReachable else {
            print("Watch not reachable")
            return
        }

        let trivitData: [String: Any] = [
            "id": trivit.id.uuidString,
            "title": trivit.title,
            "count": trivit.count,
            "colorIndex": trivit.colorIndex,
            "isCollapsed": trivit.isCollapsed,
            "createdAt": trivit.createdAt.timeIntervalSince1970
        ]

        let message: [String: Any] = [
            "type": "trivitUpdate",
            "data": trivitData
        ]

        session.sendMessage(message, replyHandler: nil) { error in
            print("Failed to sync trivit to watch: \(error.localizedDescription)")
        }
    }

    // MARK: - Sync Trivit Deletion

    func syncTrivitDeletion(_ trivitId: UUID) {
        guard session.isReachable else { return }

        let message: [String: Any] = [
            "type": "trivitDelete",
            "id": trivitId.uuidString
        ]

        session.sendMessage(message, replyHandler: nil) { error in
            print("Failed to sync trivit deletion to watch: \(error.localizedDescription)")
        }
    }

    // MARK: - Handle Updates from Watch

    private func handleTrivitUpdate(from data: [String: Any]) {
        guard let modelContext = modelContext,
              let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let title = data["title"] as? String,
              let count = data["count"] as? Int,
              let colorIndex = data["colorIndex"] as? Int else {
            return
        }

        // Try to find existing trivit
        let descriptor = FetchDescriptor<Trivit>(predicate: #Predicate { $0.id == id })

        do {
            let results = try modelContext.fetch(descriptor)

            if let existingTrivit = results.first {
                // Update existing
                existingTrivit.title = title
                existingTrivit.count = count
                existingTrivit.colorIndex = colorIndex
                existingTrivit.isCollapsed = data["isCollapsed"] as? Bool ?? true
            } else {
                // Create new
                let newTrivit = Trivit(
                    id: id,
                    title: title,
                    count: count,
                    colorIndex: colorIndex,
                    isCollapsed: data["isCollapsed"] as? Bool ?? true,
                    createdAt: Date(timeIntervalSince1970: data["createdAt"] as? TimeInterval ?? Date().timeIntervalSince1970)
                )
                modelContext.insert(newTrivit)
            }

            try modelContext.save()
        } catch {
            print("Failed to handle trivit update from watch: \(error)")
        }
    }

    private func handleTrivitDeletion(id: String) {
        guard let modelContext = modelContext,
              let uuid = UUID(uuidString: id) else {
            return
        }

        let descriptor = FetchDescriptor<Trivit>(predicate: #Predicate { $0.id == uuid })

        do {
            let results = try modelContext.fetch(descriptor)
            if let trivitToDelete = results.first {
                modelContext.delete(trivitToDelete)
                try modelContext.save()
            }
        } catch {
            print("Failed to handle trivit deletion from watch: \(error)")
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchSyncService: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchPaired = session.isPaired
            self.isWatchReachable = session.isReachable

            if activationState == .activated && session.isReachable {
                self.syncAllTrivitsToWatch()
            }
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        // Handle session becoming inactive
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate session
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable

            if session.isReachable {
                self.syncAllTrivitsToWatch()
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let type = message["type"] as? String else { return }

        DispatchQueue.main.async {
            switch type {
            case "requestSync":
                self.syncAllTrivitsToWatch()

            case "trivitUpdate":
                if let data = message["data"] as? [String: Any] {
                    self.handleTrivitUpdate(from: data)
                }

            case "trivitDelete":
                if let id = message["id"] as? String {
                    self.handleTrivitDeletion(id: id)
                }

            case "createTrivit":
                self.handleCreateTrivit(from: message)

            default:
                break
            }
        }
    }

    private func handleCreateTrivit(from message: [String: Any]) {
        guard let modelContext = modelContext else { return }

        let title = message["title"] as? String ?? "New Trivit"
        let colorIndex = message["colorIndex"] as? Int ?? 0

        let newTrivit = Trivit(
            title: title,
            colorIndex: colorIndex
        )
        modelContext.insert(newTrivit)

        do {
            try modelContext.save()
            // Sync back to watch
            syncTrivitToWatch(newTrivit)
        } catch {
            print("Failed to create trivit from watch: \(error)")
        }
    }
}
