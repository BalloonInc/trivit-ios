//
//  WatchSyncService.swift
//  Trivit
//
//  Created by Claude on 28/01/26.
//

import Foundation
import WatchConnectivity

@objc class WatchSyncService: NSObject {
    @objc static let shared = WatchSyncService()
    
    private let session = WCSession.default
    private let appGroupIdentifier = "group.com.wouterdevriendt.trivit.Documents"
    
    @objc var isWatchConnected = false
    @objc var isWatchReachable = false
    
    override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    // MARK: - Watch Connectivity Setup
    
    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else { return }
        
        session.delegate = self
        session.activate()
    }
    
    // MARK: - Data Sync (Objective-C Compatible)
    
    @objc func syncTrivitUpdate(id: String, title: String, count: Int, colorIndex: Int) {
        guard session.isReachable else {
            // Store for later sync using App Groups
            storeTrivitUpdate(id: id, title: title, count: count, colorIndex: colorIndex)
            return
        }
        
        let trivitData: [String: Any] = [
            "id": id,
            "title": title,
            "count": count,
            "colorIndex": colorIndex,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        let message = [
            "type": "trivitUpdate",
            "data": trivitData
        ] as [String: Any]
        
        session.sendMessage(message, replyHandler: nil) { error in
            print("Failed to sync trivit: \(error.localizedDescription)")
            // Fallback to App Groups storage
            self.storeTrivitUpdate(id: id, title: title, count: count, colorIndex: colorIndex)
        }
    }
    
    private func storeTrivitUpdate(id: String, title: String, count: Int, colorIndex: Int) {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        
        let trivitData: [String: Any] = [
            "id": id,
            "title": title,
            "count": count,
            "colorIndex": colorIndex,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        var pendingUpdates = sharedDefaults.array(forKey: "pendingPhoneUpdates") as? [[String: Any]] ?? []
        pendingUpdates.append(trivitData)
        sharedDefaults.set(pendingUpdates, forKey: "pendingPhoneUpdates")
    }
    
    @objc func processPendingUpdates() {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        
        // Process updates from watch
        if let pendingUpdates = sharedDefaults.array(forKey: "pendingWatchUpdates") as? [[String: Any]] {
            for updateData in pendingUpdates {
                // Notify Objective-C code about the update
                NotificationCenter.default.post(
                    name: NSNotification.Name("TrivitUpdateFromWatch"),
                    object: nil,
                    userInfo: updateData
                )
            }
            sharedDefaults.removeObject(forKey: "pendingWatchUpdates")
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchSyncService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchConnected = activationState == .activated && session.isPaired
            self.isWatchReachable = session.isReachable
            
            if activationState == .activated && session.isPaired {
                // Notify Objective-C code that watch is connected
                NotificationCenter.default.post(name: NSNotification.Name("WatchConnected"), object: nil)
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchConnected = false
            self.isWatchReachable = false
        }
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
            
            if session.isReachable {
                self.processPendingUpdates()
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        guard let type = message["type"] as? String else { return }
        
        switch type {
        case "trivitUpdate":
            // Handle trivit update from watch
            if let trivitData = message["data"] as? [String: Any] {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("TrivitUpdateFromWatch"),
                        object: nil,
                        userInfo: trivitData
                    )
                }
            }
        default:
            break
        }
    }
}
