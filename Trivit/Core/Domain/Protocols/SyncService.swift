import Foundation
import Combine

/// Protocol defining cross-device synchronization.
protocol SyncService: Sendable {
    /// Whether sync is currently enabled
    var isSyncEnabled: Bool { get async }

    /// Whether a sync operation is in progress
    var isSyncing: Bool { get async }

    /// The last time a successful sync occurred
    var lastSyncDate: Date? { get async }

    /// Publisher for sync state changes
    var syncStatePublisher: AnyPublisher<SyncState, Never> { get }

    /// Enables sync (prompts for iCloud if needed).
    /// - Throws: If enabling fails
    func enableSync() async throws

    /// Disables sync.
    /// - Throws: If disabling fails
    func disableSync() async throws

    /// Triggers a manual sync.
    /// - Throws: If sync fails
    func sync() async throws

    /// Resolves a sync conflict.
    /// - Parameters:
    ///   - conflict: The conflict to resolve
    ///   - resolution: How to resolve it
    /// - Throws: If resolution fails
    func resolveConflict(_ conflict: SyncConflict, with resolution: ConflictResolution) async throws
}

// MARK: - Sync State

/// The current state of sync operations.
enum SyncState: Equatable {
    /// Sync is not enabled
    case disabled

    /// Sync is enabled and idle
    case idle

    /// Sync is currently in progress
    case syncing

    /// Sync encountered an error
    case error(SyncError)
}

// MARK: - Sync Error

/// Errors that can occur during sync.
enum SyncError: Error, Equatable {
    /// User is not signed into iCloud
    case notSignedIn

    /// Network is unavailable
    case networkUnavailable

    /// iCloud quota exceeded
    case quotaExceeded

    /// Conflict that requires user resolution
    case conflictDetected

    /// Unknown error
    case unknown(String)

    var localizedDescription: String {
        switch self {
        case .notSignedIn:
            return String(localized: "sync.error.notSignedIn", defaultValue: "Please sign in to iCloud")
        case .networkUnavailable:
            return String(localized: "sync.error.network", defaultValue: "Network unavailable")
        case .quotaExceeded:
            return String(localized: "sync.error.quota", defaultValue: "iCloud storage full")
        case .conflictDetected:
            return String(localized: "sync.error.conflict", defaultValue: "Sync conflict detected")
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - Sync Conflict

/// Represents a conflict between local and remote data.
struct SyncConflict: Identifiable, Equatable {
    let id: UUID
    let trivitId: UUID
    let localTrivit: TrivitSnapshot
    let remoteTrivit: TrivitSnapshot
    let detectedAt: Date
}

/// A lightweight snapshot of trivit data for conflict resolution.
struct TrivitSnapshot: Equatable {
    let title: String
    let count: Int
    let modifiedAt: Date
}

// MARK: - Conflict Resolution

/// How to resolve a sync conflict.
enum ConflictResolution: Equatable {
    /// Keep the local version
    case keepLocal

    /// Keep the remote version
    case keepRemote

    /// Merge: use highest count and most recent title
    case merge
}
