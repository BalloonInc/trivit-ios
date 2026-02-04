//
//  WatchSyncService.swift
//  Trivit
//
//  Handles sync between iPhone and Apple Watch via WatchConnectivity
//

import Foundation
import WatchConnectivity
import SwiftData
import UIKit
import os.log

private let logger = Logger(subsystem: "com.wouterdevriendt.trivit", category: "WatchSync")

@MainActor
class WatchSyncService: NSObject, ObservableObject {
    static let shared = WatchSyncService()

    private let session: WCSession
    private var modelContext: ModelContext?
    private var isSessionActivated = false

    @Published var isWatchPaired = false
    @Published var isWatchReachable = false

    override init() {
        // Store session reference before super.init()
        self.session = WCSession.default

        super.init()

        logger.info("WatchSyncService init() - starting immediate setup")

        // Set delegate and activate IMMEDIATELY in init
        // This ensures we're ready before the watch tries to connect
        if WCSession.isSupported() {
            logger.info("WatchConnectivity supported, setting delegate and activating NOW")
            session.delegate = self
            session.activate()
            logger.info("WCSession.activate() called from init()")
        } else {
            logger.warning("WatchConnectivity not supported on this device")
        }
    }

    func configure(with modelContext: ModelContext) {
        logger.info("configure() called with modelContext")
        self.modelContext = modelContext

        // If already activated and watch is reachable, sync now
        if isSessionActivated && session.isReachable {
            logger.info("Already activated and reachable, triggering sync")
            syncAllTrivitsToWatch()
        }
    }

    // MARK: - Sync All Trivits to Watch

    func syncAllTrivitsToWatch() {
        logger.info("📱 syncAllTrivitsToWatch called - isReachable: \(self.session.isReachable), hasContext: \(self.modelContext != nil)")

        guard session.isReachable else {
            logger.warning("📱 Watch not reachable, skipping sync")
            return
        }

        guard let modelContext = modelContext else {
            logger.error("📱 No model context available")
            return
        }

        do {
            // Only sync non-deleted trivits
            let descriptor = FetchDescriptor<Trivit>(
                predicate: #Predicate { $0.deletedAt == nil },
                sortBy: [SortDescriptor(\.sortOrder)]
            )
            let trivits = try modelContext.fetch(descriptor)

            let trivitsData = trivits.map { trivit -> [String: Any] in
                [
                    "id": trivit.id.uuidString,
                    "title": trivit.title,
                    "count": trivit.count,
                    "colorIndex": trivit.colorIndex,
                    "isCollapsed": trivit.isCollapsed,
                    "createdAt": trivit.createdAt.timeIntervalSince1970,
                    "sortOrder": trivit.sortOrder
                ]
            }

            let message: [String: Any] = [
                "type": "trivitsSync",
                "trivits": trivitsData
            ]

            logger.info("📱 Sending \(trivits.count) trivits to watch...")

            session.sendMessage(message, replyHandler: { response in
                logger.info("📱 Watch acknowledged sync: \(response)")
            }) { error in
                logger.error("📱 Failed to sync to watch: \(error.localizedDescription)")
            }

        } catch {
            logger.error("📱 Failed to fetch trivits for sync: \(error)")
        }
    }

    // MARK: - Sync Single Trivit Update

    func syncTrivitToWatch(_ trivit: Trivit) {
        logger.info("📱 syncTrivitToWatch: \(trivit.title) - isReachable: \(self.session.isReachable)")

        guard session.isReachable else {
            logger.warning("📱 Watch not reachable, skipping single sync")
            return
        }

        let trivitData: [String: Any] = [
            "id": trivit.id.uuidString,
            "title": trivit.title,
            "count": trivit.count,
            "colorIndex": trivit.colorIndex,
            "isCollapsed": trivit.isCollapsed,
            "createdAt": trivit.createdAt.timeIntervalSince1970,
            "sortOrder": trivit.sortOrder
        ]

        let message: [String: Any] = [
            "type": "trivitUpdate",
            "data": trivitData
        ]

        session.sendMessage(message, replyHandler: nil) { error in
            logger.error("📱 Failed to sync trivit to watch: \(error.localizedDescription)")
        }
    }

    // MARK: - Sync Trivit Deletion

    func syncTrivitDeletion(_ trivitId: UUID) {
        logger.info("syncTrivitDeletion: \(trivitId.uuidString) - isReachable: \(self.session.isReachable)")

        guard session.isReachable else {
            logger.warning("Watch not reachable, skipping deletion sync")
            return
        }

        let message: [String: Any] = [
            "type": "trivitDelete",
            "id": trivitId.uuidString
        ]

        session.sendMessage(message, replyHandler: nil) { error in
            logger.error("Failed to sync trivit deletion to watch: \(error.localizedDescription)")
        }
    }

    // MARK: - Handle Updates from Watch

    private func handleTrivitUpdate(from data: [String: Any]) {
        guard let modelContext = modelContext else {
            logger.warning("handleTrivitUpdate: No modelContext available")
            return
        }

        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let title = data["title"] as? String,
              let count = data["count"] as? Int,
              let colorIndex = data["colorIndex"] as? Int else {
            logger.warning("handleTrivitUpdate: Invalid data - keys: \(data.keys)")
            return
        }

        logger.info("handleTrivitUpdate: \(title) count=\(count)")

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
                logger.info("handleTrivitUpdate: Updated existing trivit")
            } else {
                // Create new - get max sortOrder first
                let sortDescriptor = FetchDescriptor<Trivit>(sortBy: [SortDescriptor(\.sortOrder, order: .reverse)])
                let maxSortOrder = (try? modelContext.fetch(sortDescriptor).first?.sortOrder) ?? -1

                let newTrivit = Trivit(
                    id: id,
                    title: title,
                    count: count,
                    colorIndex: colorIndex,
                    isCollapsed: data["isCollapsed"] as? Bool ?? true,
                    createdAt: Date(timeIntervalSince1970: data["createdAt"] as? TimeInterval ?? Date().timeIntervalSince1970),
                    sortOrder: maxSortOrder + 1
                )
                modelContext.insert(newTrivit)
                logger.info("handleTrivitUpdate: Created new trivit from watch")
            }

            try modelContext.save()
        } catch {
            logger.error("handleTrivitUpdate: Failed - \(error.localizedDescription)")
        }
    }

    private func handleTrivitDeletion(id: String) {
        guard let modelContext = modelContext else {
            logger.warning("handleTrivitDeletion: No modelContext available")
            return
        }

        guard let uuid = UUID(uuidString: id) else {
            logger.warning("handleTrivitDeletion: Invalid UUID: \(id)")
            return
        }

        logger.info("handleTrivitDeletion: \(id)")

        let descriptor = FetchDescriptor<Trivit>(predicate: #Predicate { $0.id == uuid })

        do {
            let results = try modelContext.fetch(descriptor)
            if let trivitToDelete = results.first {
                modelContext.delete(trivitToDelete)
                try modelContext.save()
                logger.info("handleTrivitDeletion: Deleted successfully")
            } else {
                logger.info("handleTrivitDeletion: Trivit not found (may already be deleted)")
            }
        } catch {
            logger.error("handleTrivitDeletion: Failed - \(error.localizedDescription)")
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchSyncService: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Log immediately from nonisolated context
        let stateStr: String
        switch activationState {
        case .notActivated: stateStr = "notActivated"
        case .inactive: stateStr = "inactive"
        case .activated: stateStr = "activated"
        @unknown default: stateStr = "unknown(\(activationState.rawValue))"
        }

        logger.info("DELEGATE: activationDidCompleteWith state=\(stateStr) paired=\(session.isPaired) reachable=\(session.isReachable)")

        if let error = error {
            logger.error("DELEGATE: activation error: \(error.localizedDescription)")
        }

        Task { @MainActor in
            self.isSessionActivated = true
            self.isWatchPaired = session.isPaired
            self.isWatchReachable = session.isReachable

            logger.info("MainActor: Updated state - paired=\(self.isWatchPaired) reachable=\(self.isWatchReachable) hasContext=\(self.modelContext != nil)")

            if activationState == .activated && session.isReachable && self.modelContext != nil {
                logger.info("MainActor: Watch is reachable and we have context, triggering initial sync...")
                self.syncAllTrivitsToWatch()
            } else if activationState == .activated && session.isReachable {
                logger.info("MainActor: Watch is reachable but no modelContext yet - will sync when configure() is called")
            }
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        logger.info("DELEGATE: sessionDidBecomeInactive")
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        logger.info("DELEGATE: sessionDidDeactivate - reactivating...")
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        logger.info("DELEGATE: reachabilityDidChange reachable=\(session.isReachable)")

        Task { @MainActor in
            self.isWatchReachable = session.isReachable

            if session.isReachable && self.modelContext != nil {
                logger.info("MainActor: Watch became reachable with context, triggering sync...")
                self.syncAllTrivitsToWatch()
            } else if session.isReachable {
                logger.info("MainActor: Watch became reachable but no modelContext yet")
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleMessage(message, replyHandler: nil)
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        handleMessage(message, replyHandler: replyHandler)
    }

    private nonisolated func handleMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)?) {
        let type = message["type"] as? String ?? "unknown"
        logger.info("DELEGATE: didReceiveMessage type=\(type) hasReplyHandler=\(replyHandler != nil)")

        guard type != "unknown" else {
            logger.warning("DELEGATE: Received message without type: \(String(describing: message.keys))")
            replyHandler?(["status": "error", "message": "Missing message type"])
            return
        }

        Task { @MainActor in
            logger.info("MainActor: Processing message type=\(type) hasContext=\(self.modelContext != nil)")

            switch type {
            case "requestSync":
                logger.info("MainActor: Watch requested sync")
                self.syncAllTrivitsToWatch()
                replyHandler?(["status": "ok", "message": "Sync initiated"])

            case "trivitUpdate":
                if let data = message["data"] as? [String: Any] {
                    self.handleTrivitUpdate(from: data)
                    replyHandler?(["status": "ok"])
                } else {
                    logger.warning("MainActor: trivitUpdate missing data")
                    replyHandler?(["status": "error", "message": "Missing data"])
                }

            case "trivitDelete":
                if let id = message["id"] as? String {
                    self.handleTrivitDeletion(id: id)
                    replyHandler?(["status": "ok"])
                } else {
                    logger.warning("MainActor: trivitDelete missing id")
                    replyHandler?(["status": "error", "message": "Missing id"])
                }

            case "createTrivit":
                self.handleCreateTrivit(from: message)
                replyHandler?(["status": "ok"])

            default:
                logger.warning("MainActor: Unknown message type: \(type)")
                replyHandler?(["status": "error", "message": "Unknown type"])
            }
        }
    }

    private func handleCreateTrivit(from message: [String: Any]) {
        guard let modelContext = modelContext else {
            logger.warning("handleCreateTrivit: No modelContext available")
            return
        }

        let title = message["title"] as? String ?? "New Trivit"
        let colorIndex = message["colorIndex"] as? Int ?? 0

        logger.info("handleCreateTrivit: \(title) colorIndex=\(colorIndex)")

        // Get max sortOrder to add at end
        let descriptor = FetchDescriptor<Trivit>(sortBy: [SortDescriptor(\.sortOrder, order: .reverse)])
        let maxSortOrder = (try? modelContext.fetch(descriptor).first?.sortOrder) ?? -1

        let newTrivit = Trivit(
            title: title,
            colorIndex: colorIndex,
            sortOrder: maxSortOrder + 1
        )
        modelContext.insert(newTrivit)

        do {
            try modelContext.save()
            logger.info("handleCreateTrivit: Created successfully, syncing back to watch")
            // Sync back to watch
            syncTrivitToWatch(newTrivit)
        } catch {
            logger.error("handleCreateTrivit: Failed - \(error.localizedDescription)")
        }
    }
}
