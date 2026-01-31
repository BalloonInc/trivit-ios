//
//  SyncService.swift
//  Trivit Watch App
//
//  Created by Claude on 28/01/26.
//

import Foundation
import WatchConnectivity
import SwiftData

@MainActor
class SyncService: NSObject, ObservableObject {
    static let shared = SyncService()
    
    private let session = WCSession.default
    private let appGroupIdentifier = "group.com.wouterdevriendt.trivit.Documents"
    
    @Published var isConnected = false
    @Published var isReachable = false
    
    override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    // MARK: - Watch Connectivity Setup
    
    func startWatchConnectivity() {
        guard WCSession.isSupported() else { return }
        
        session.delegate = self
        session.activate()
    }
    
    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else { return }
        
        session.delegate = self
        session.activate()
    }
    
    // MARK: - Data Sync

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

    func syncTrivitUpdate(_ trivit: Trivit) {
        guard session.isReachable else {
            // Store for later sync using App Groups
            storeTrivitUpdate(trivit)
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
        
        let message = [
            "type": "trivitUpdate",
            "data": trivitData
        ] as [String: Any]
        
        session.sendMessage(message, replyHandler: nil) { error in
            print("Failed to sync trivit: \(error.localizedDescription)")
            // Fallback to App Groups storage
            self.storeTrivitUpdate(trivit)
        }
    }
    
    private func storeTrivitUpdate(_ trivit: Trivit) {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        
        let trivitData: [String: Any] = [
            "id": trivit.id.uuidString,
            "title": trivit.title,
            "count": trivit.count,
            "colorIndex": trivit.colorIndex,
            "isCollapsed": trivit.isCollapsed,
            "createdAt": trivit.createdAt.timeIntervalSince1970
        ]
        
        var pendingUpdates = sharedDefaults.array(forKey: "pendingWatchUpdates") as? [[String: Any]] ?? []
        pendingUpdates.append(trivitData)
        sharedDefaults.set(pendingUpdates, forKey: "pendingWatchUpdates")
    }
}

// MARK: - WCSessionDelegate

extension SyncService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = activationState == .activated
            self.isReachable = session.isReachable
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // Handle incoming messages from iPhone
        guard let type = message["type"] as? String else { return }
        
        switch type {
        case "trivitsSync":
            // Full sync of all trivits from iPhone
            if let trivitsData = message["trivits"] as? [[String: Any]] {
                // TODO: Update local SwiftData model
                print("Received \(trivitsData.count) trivits from iPhone")
            }
        case "trivitUpdate":
            // Individual trivit update from iPhone
            if let trivitData = message["data"] as? [String: Any] {
                // TODO: Update specific trivit in SwiftData
                print("Received trivit update from iPhone")
            }
        default:
            break
        }
    }
}
