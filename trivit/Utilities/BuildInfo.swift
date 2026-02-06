//
//  BuildInfo.swift
//  Trivit
//
//  Build information including commit hash for debugging
//

import Foundation

/// Provides build information including git commit hash
/// Commit hash is only shown in Debug and TestFlight builds
enum BuildInfo {
    /// The git commit hash (short form) captured at build time
    /// This value is set by a build script phase
    static var commitHash: String {
        // Read from Info.plist where it's set by the build script
        Bundle.main.infoDictionary?["GIT_COMMIT_HASH"] as? String ?? "unknown"
    }

    /// Returns true if the app is running in a TestFlight environment
    static var isTestFlight: Bool {
        guard let receiptURL = Bundle.main.appStoreReceiptURL else {
            return false
        }
        return receiptURL.lastPathComponent == "sandboxReceipt"
    }

    /// Returns true if this is a debug build
    static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    /// Returns true if commit hash should be displayed (Debug or TestFlight)
    static var shouldShowCommitHash: Bool {
        isDebug || isTestFlight
    }

    /// Full version string including commit hash for Debug/TestFlight
    static var fullVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

        if shouldShowCommitHash {
            return "\(version) (\(build)) • \(commitHash)"
        } else {
            return "\(version) (\(build))"
        }
    }
}
