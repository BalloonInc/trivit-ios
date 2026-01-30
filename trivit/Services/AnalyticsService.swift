//
//  AnalyticsService.swift
//  Trivit
//
//  Firebase Analytics and Crashlytics integration
//

import Foundation
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif
#if canImport(FirebaseCrashlytics)
import FirebaseCrashlytics
#endif

/// Analytics service for tracking user behavior and crashes
final class AnalyticsService {
    static let shared = AnalyticsService()

    private init() {}

    // MARK: - Configuration

    /// Call this in AppDelegate.didFinishLaunching or App.init
    func configure() {
        #if canImport(FirebaseCore)
        FirebaseApp.configure()
        #endif

        #if DEBUG
        // Disable analytics in debug builds
        #if canImport(FirebaseAnalytics)
        Analytics.setAnalyticsCollectionEnabled(false)
        #endif
        #endif
    }

    // MARK: - Event Tracking

    /// Track when user creates a new trivit
    func trackTrivitCreated(colorIndex: Int) {
        logEvent("trivit_created", parameters: [
            "color_index": colorIndex
        ])
    }

    /// Track when user deletes a trivit
    func trackTrivitDeleted(count: Int) {
        logEvent("trivit_deleted", parameters: [
            "final_count": count
        ])
    }

    /// Track increment action
    func trackIncrement(trivitId: String, newCount: Int) {
        logEvent("trivit_increment", parameters: [
            "trivit_id": trivitId,
            "new_count": newCount
        ])
    }

    /// Track decrement action
    func trackDecrement(trivitId: String, newCount: Int) {
        logEvent("trivit_decrement", parameters: [
            "trivit_id": trivitId,
            "new_count": newCount
        ])
    }

    /// Track reset action
    func trackReset(trivitId: String, previousCount: Int) {
        logEvent("trivit_reset", parameters: [
            "trivit_id": trivitId,
            "previous_count": previousCount
        ])
    }

    /// Track statistics view opened
    func trackStatisticsViewed(trivitId: String) {
        logEvent("statistics_viewed", parameters: [
            "trivit_id": trivitId
        ])
    }

    /// Track history view opened
    func trackHistoryViewed(trivitId: String) {
        logEvent("history_viewed", parameters: [
            "trivit_id": trivitId
        ])
    }

    // MARK: - Screen Tracking

    func trackScreen(_ screenName: String) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName
        ])
        #endif
    }

    // MARK: - Crash Reporting

    /// Record a non-fatal error
    func recordError(_ error: Error, context: [String: Any]? = nil) {
        #if canImport(FirebaseCrashlytics)
        if let context = context {
            for (key, value) in context {
                Crashlytics.crashlytics().setCustomValue(value, forKey: key)
            }
        }
        Crashlytics.crashlytics().record(error: error)
        #endif
    }

    /// Set user identifier for crash reports (anonymized)
    func setUserId(_ userId: String?) {
        #if canImport(FirebaseCrashlytics)
        Crashlytics.crashlytics().setUserID(userId ?? "")
        #endif
        #if canImport(FirebaseAnalytics)
        Analytics.setUserID(userId)
        #endif
    }

    /// Log a breadcrumb message for crash context
    func log(_ message: String) {
        #if canImport(FirebaseCrashlytics)
        Crashlytics.crashlytics().log(message)
        #endif
    }

    // MARK: - Private

    private func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(name, parameters: parameters)
        #endif
    }
}
