//
//  SyncService.swift
//  Trivit Watch App
//
//  Handles sync between Apple Watch and iPhone via WatchConnectivity
//

import Foundation
import WatchConnectivity
import SwiftData
import os.log

private let logger = Logger(subsystem: "com.wouterdevriendt.trivit.watchkitapp", category: "WatchSync")

@MainActor
class SyncService: NSObject, ObservableObject {
    static let shared = SyncService()

    private let session = WCSession.default
    private var modelContext: ModelContext?
    private var pendingSyncOnConfigure = false

    @Published var isConnected = false
    @Published var isReachable = false
    @Published var lastSyncDate: Date?
    @Published var isSyncing = false
    @Published var lastSyncError: String?
    @Published var lastSyncSuccess = false

    override init() {
        super.init()
        logger.info("⌚ SyncService initialized")
        // Start WatchConnectivity immediately so we're ready when iPhone becomes reachable
        setupWatchConnectivity()
    }

    func configure(with modelContext: ModelContext) {
        logger.info("⌚ SyncService configured with modelContext")
        self.modelContext = modelContext

        // If we got a sync request before being configured, do it now
        if pendingSyncOnConfigure {
            logger.info("⌚ Processing pending sync request")
            pendingSyncOnConfigure = false
            requestSync()
        }
    }

    // MARK: - Watch Connectivity Setup

    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else { return }

        session.delegate = self
        session.activate()
    }

    // MARK: - Request Sync from iPhone

    func requestSync() {
        logger.info("⌚ requestSync called - isReachable: \(self.session.isReachable), hasModelContext: \(self.modelContext != nil)")

        // If we don't have modelContext yet, defer the sync until configured
        guard modelContext != nil else {
            logger.warning("⌚ No modelContext yet, deferring sync")
            pendingSyncOnConfigure = true
            return
        }

        guard session.isReachable else {
            logger.warning("⌚ iPhone not reachable for sync")
            lastSyncError = "iPhone not reachable"
            lastSyncSuccess = false
            return
        }

        isSyncing = true
        lastSyncError = nil
        lastSyncSuccess = false
        logger.info("⌚ Sending sync request to iPhone...")

        let message: [String: Any] = ["type": "requestSync"]
        session.sendMessage(message, replyHandler: { [weak self] response in
            logger.info("⌚ Sync response received: \(String(describing: response))")
            Task { @MainActor in
                self?.isSyncing = false
                self?.lastSyncSuccess = true
                self?.lastSyncError = nil
            }
        }) { [weak self] error in
            logger.error("⌚ Sync request failed: \(error.localizedDescription)")
            Task { @MainActor in
                self?.isSyncing = false
                self?.lastSyncError = error.localizedDescription
                self?.lastSyncSuccess = false
            }
        }
    }

    // MARK: - Sync Trivit Update to iPhone

    func syncTrivitUpdate(_ trivit: Trivit) {
        guard session.isReachable else {
            print("iPhone not reachable, storing update for later")
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
            print("Failed to sync trivit: \(error.localizedDescription)")
        }
    }

    // MARK: - Create Trivit on iPhone

    func createTrivit(title: String, colorIndex: Int) {
        guard session.isReachable else {
            print("iPhone not reachable, cannot create trivit")
            return
        }

        let message: [String: Any] = [
            "type": "createTrivit",
            "title": title,
            "colorIndex": colorIndex
        ]

        session.sendMessage(message, replyHandler: nil) { error in
            print("Failed to create trivit on iPhone: \(error.localizedDescription)")
        }
    }

    // MARK: - Delete Trivit

    func syncTrivitDeletion(_ trivitId: UUID) {
        guard session.isReachable else { return }

        let message: [String: Any] = [
            "type": "trivitDelete",
            "id": trivitId.uuidString
        ]

        session.sendMessage(message, replyHandler: nil) { error in
            print("Failed to sync trivit deletion: \(error.localizedDescription)")
        }
    }

    // MARK: - Handle Incoming Data

    private func handleFullSync(trivitsData: [[String: Any]]) {
        logger.info("⌚ handleFullSync called with \(trivitsData.count) trivits")

        guard let modelContext = modelContext else {
            logger.error("⌚ No model context for full sync")
            return
        }

        do {
            // Fetch all existing trivits
            let descriptor = FetchDescriptor<Trivit>()
            let existingTrivits = try modelContext.fetch(descriptor)

            var receivedIds = Set<UUID>()

            for data in trivitsData {
                guard let idString = data["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let title = data["title"] as? String,
                      let count = data["count"] as? Int,
                      let colorIndex = data["colorIndex"] as? Int else {
                    logger.warning("⌚ Skipping invalid trivit data: \(String(describing: data))")
                    continue
                }

                let sortOrder = data["sortOrder"] as? Int ?? 0
                receivedIds.insert(id)

                if let existingTrivit = existingTrivits.first(where: { $0.id == id }) {
                    // Update existing trivit
                    existingTrivit.title = title
                    existingTrivit.count = count
                    existingTrivit.colorIndex = colorIndex
                    existingTrivit.isCollapsed = data["isCollapsed"] as? Bool ?? true
                    existingTrivit.sortOrder = sortOrder
                    logger.debug("⌚ Updated trivit: \(title) (count: \(count), order: \(sortOrder))")
                } else {
                    // Create new trivit
                    let newTrivit = Trivit(
                        id: id,
                        title: title,
                        count: count,
                        colorIndex: colorIndex,
                        isCollapsed: data["isCollapsed"] as? Bool ?? true,
                        createdAt: Date(timeIntervalSince1970: data["createdAt"] as? TimeInterval ?? Date().timeIntervalSince1970),
                        sortOrder: sortOrder
                    )
                    modelContext.insert(newTrivit)
                    logger.debug("⌚ Created trivit: \(title) (order: \(sortOrder))")
                }
            }

            // Delete trivits that no longer exist on iPhone
            for trivit in existingTrivits {
                if !receivedIds.contains(trivit.id) {
                    logger.debug("⌚ Deleting trivit not on phone: \(trivit.title)")
                    modelContext.delete(trivit)
                }
            }

            try modelContext.save()
            lastSyncDate = Date()
            logger.info("⌚ Full sync completed: \(trivitsData.count) trivits")

        } catch {
            logger.error("⌚ Failed to handle full sync: \(error)")
        }
    }

    private func handleSingleUpdate(data: [String: Any]) {
        logger.info("⌚ handleSingleUpdate called")

        guard let modelContext = modelContext,
              let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let title = data["title"] as? String,
              let count = data["count"] as? Int,
              let colorIndex = data["colorIndex"] as? Int else {
            logger.warning("⌚ Invalid data in single update")
            return
        }

        let sortOrder = data["sortOrder"] as? Int ?? 0

        do {
            let descriptor = FetchDescriptor<Trivit>(predicate: #Predicate { $0.id == id })
            let results = try modelContext.fetch(descriptor)

            if let existingTrivit = results.first {
                existingTrivit.title = title
                existingTrivit.count = count
                existingTrivit.colorIndex = colorIndex
                existingTrivit.isCollapsed = data["isCollapsed"] as? Bool ?? true
                existingTrivit.sortOrder = sortOrder
                logger.info("⌚ Updated trivit: \(title)")
            } else {
                let newTrivit = Trivit(
                    id: id,
                    title: title,
                    count: count,
                    colorIndex: colorIndex,
                    isCollapsed: data["isCollapsed"] as? Bool ?? true,
                    createdAt: Date(timeIntervalSince1970: data["createdAt"] as? TimeInterval ?? Date().timeIntervalSince1970),
                    sortOrder: sortOrder
                )
                modelContext.insert(newTrivit)
                logger.info("⌚ Created trivit: \(title)")
            }

            try modelContext.save()
            lastSyncDate = Date()

        } catch {
            logger.error("⌚ Failed to handle single update: \(error)")
        }
    }

    private func handleDeletion(id: String) {
        guard let modelContext = modelContext,
              let uuid = UUID(uuidString: id) else {
            return
        }

        do {
            let descriptor = FetchDescriptor<Trivit>(predicate: #Predicate { $0.id == uuid })
            let results = try modelContext.fetch(descriptor)

            if let trivitToDelete = results.first {
                modelContext.delete(trivitToDelete)
                try modelContext.save()
            }
        } catch {
            print("Failed to handle deletion: \(error)")
        }
    }
}

// MARK: - WCSessionDelegate

extension SyncService: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        logger.info("⌚ WCSession activation completed - state: \(activationState.rawValue), reachable: \(session.isReachable)")

        if let error = error {
            logger.error("⌚ WCSession activation error: \(error.localizedDescription)")
        }

        Task { @MainActor in
            self.isConnected = activationState == .activated
            self.isReachable = session.isReachable

            if activationState == .activated && session.isReachable {
                logger.info("⌚ iPhone reachable on activation, requesting sync...")
                self.requestSync()
            } else if activationState == .activated {
                logger.info("⌚ WCSession activated but iPhone not reachable yet")
            }
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        logger.info("⌚ iPhone reachability changed: \(session.isReachable)")

        Task { @MainActor in
            self.isReachable = session.isReachable

            if session.isReachable {
                logger.info("⌚ iPhone became reachable, requesting sync...")
                self.requestSync()
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let type = message["type"] as? String else {
            logger.warning("⌚ Received message without type")
            return
        }

        logger.info("⌚ Received message from iPhone: \(type)")

        Task { @MainActor in
            switch type {
            case "trivitsSync":
                if let trivitsData = message["trivits"] as? [[String: Any]] {
                    self.handleFullSync(trivitsData: trivitsData)
                    self.isSyncing = false
                    self.lastSyncSuccess = true
                }

            case "trivitUpdate":
                if let data = message["data"] as? [String: Any] {
                    self.handleSingleUpdate(data: data)
                }

            case "trivitDelete":
                if let id = message["id"] as? String {
                    self.handleDeletion(id: id)
                }

            default:
                logger.warning("⌚ Unknown message type: \(type)")
            }
        }
    }
}
