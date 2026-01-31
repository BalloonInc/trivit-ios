//
//  SyncService.swift
//  Trivit Watch App
//
//  Handles sync between Apple Watch and iPhone via WatchConnectivity
//

import Foundation
import WatchConnectivity
import SwiftData

@MainActor
class SyncService: NSObject, ObservableObject {
    static let shared = SyncService()

    private let session = WCSession.default
    private var modelContext: ModelContext?

    @Published var isConnected = false
    @Published var isReachable = false
    @Published var lastSyncDate: Date?

    override init() {
        super.init()
    }

    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        setupWatchConnectivity()
    }

    // MARK: - Watch Connectivity Setup

    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else { return }

        session.delegate = self
        session.activate()
    }

    // MARK: - Request Sync from iPhone

    func requestSync() {
        guard session.isReachable else {
            print("iPhone not reachable for sync")
            return
        }

        let message: [String: Any] = ["type": "requestSync"]
        session.sendMessage(message, replyHandler: { response in
            print("Sync response: \(response)")
        }) { error in
            print("Sync request failed: \(error.localizedDescription)")
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
        guard let modelContext = modelContext else { return }

        do {
            // Fetch all existing trivits
            let descriptor = FetchDescriptor<Trivit>()
            let existingTrivits = try modelContext.fetch(descriptor)
            let existingIds = Set(existingTrivits.map { $0.id })

            var receivedIds = Set<UUID>()

            for data in trivitsData {
                guard let idString = data["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let title = data["title"] as? String,
                      let count = data["count"] as? Int,
                      let colorIndex = data["colorIndex"] as? Int else {
                    continue
                }

                receivedIds.insert(id)

                if let existingTrivit = existingTrivits.first(where: { $0.id == id }) {
                    // Update existing trivit
                    existingTrivit.title = title
                    existingTrivit.count = count
                    existingTrivit.colorIndex = colorIndex
                    existingTrivit.isCollapsed = data["isCollapsed"] as? Bool ?? true
                } else {
                    // Create new trivit
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
            }

            // Delete trivits that no longer exist on iPhone
            for trivit in existingTrivits {
                if !receivedIds.contains(trivit.id) {
                    modelContext.delete(trivit)
                }
            }

            try modelContext.save()
            lastSyncDate = Date()
            print("Synced \(trivitsData.count) trivits from iPhone")

        } catch {
            print("Failed to handle full sync: \(error)")
        }
    }

    private func handleSingleUpdate(data: [String: Any]) {
        guard let modelContext = modelContext,
              let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let title = data["title"] as? String,
              let count = data["count"] as? Int,
              let colorIndex = data["colorIndex"] as? Int else {
            return
        }

        do {
            let descriptor = FetchDescriptor<Trivit>(predicate: #Predicate { $0.id == id })
            let results = try modelContext.fetch(descriptor)

            if let existingTrivit = results.first {
                existingTrivit.title = title
                existingTrivit.count = count
                existingTrivit.colorIndex = colorIndex
                existingTrivit.isCollapsed = data["isCollapsed"] as? Bool ?? true
            } else {
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
            lastSyncDate = Date()

        } catch {
            print("Failed to handle single update: \(error)")
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
        DispatchQueue.main.async {
            self.isConnected = activationState == .activated
            self.isReachable = session.isReachable

            if activationState == .activated && session.isReachable {
                self.requestSync()
            }
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable

            if session.isReachable {
                self.requestSync()
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let type = message["type"] as? String else { return }

        DispatchQueue.main.async {
            switch type {
            case "trivitsSync":
                if let trivitsData = message["trivits"] as? [[String: Any]] {
                    self.handleFullSync(trivitsData: trivitsData)
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
                break
            }
        }
    }
}
