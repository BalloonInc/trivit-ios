//
//  AnalyticsService.swift
//  Trivit
//
//  Firebase Analytics and Crashlytics integration
//

import Foundation
#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif
#if canImport(FirebaseCrashlytics)
import FirebaseCrashlytics
#endif

/// Source device for analytics events
enum AnalyticsSource: String {
    case phone = "phone"
    case watch = "watch"
}

/// Analytics service for tracking user behavior and crashes
final class AnalyticsService {
    static let shared = AnalyticsService()

    private init() {}

    // MARK: - Configuration

    /// Call this in AppDelegate.didFinishLaunching or App.init
    func configure() {
        #if canImport(FirebaseCore)
        // Only configure if not already configured
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        #endif

        // Enable analytics (including debug builds for testing)
        #if canImport(FirebaseAnalytics)
        Analytics.setAnalyticsCollectionEnabled(true)
        #endif
    }

    // MARK: - User Properties

    /// Update user properties for segmentation
    func updateUserProperties(totalTrivits: Int, totalCount: Int) {
        #if canImport(FirebaseAnalytics)
        Analytics.setUserProperty(String(totalTrivits), forName: "total_trivits")
        Analytics.setUserProperty(String(totalCount), forName: "total_tally_count")

        // Engagement tiers
        let engagementTier: String
        switch totalCount {
        case 0..<10: engagementTier = "new"
        case 10..<100: engagementTier = "casual"
        case 100..<500: engagementTier = "active"
        case 500..<1000: engagementTier = "power"
        default: engagementTier = "super"
        }
        Analytics.setUserProperty(engagementTier, forName: "engagement_tier")
        #endif
    }

    // MARK: - Trivit Lifecycle Events

    /// Track when user creates a new trivit
    func trackTrivitCreated(title: String, colorIndex: Int, source: AnalyticsSource = .phone, totalTrivits: Int) {
        logEvent("trivit_created", parameters: [
            "title": sanitizeTitle(title),
            "color_index": colorIndex,
            "source": source.rawValue,
            "total_trivits": totalTrivits
        ])
    }

    /// Track when user deletes a trivit
    func trackTrivitDeleted(title: String, finalCount: Int, source: AnalyticsSource = .phone, ageInDays: Int) {
        logEvent("trivit_deleted", parameters: [
            "title": sanitizeTitle(title),
            "final_count": finalCount,
            "source": source.rawValue,
            "age_days": ageInDays
        ])
    }

    /// Track when user renames a trivit
    func trackTrivitRenamed(oldTitle: String, newTitle: String, source: AnalyticsSource = .phone) {
        logEvent("trivit_renamed", parameters: [
            "old_title": sanitizeTitle(oldTitle),
            "new_title": sanitizeTitle(newTitle),
            "source": source.rawValue
        ])
    }

    /// Track when user changes color
    func trackColorChanged(title: String, oldColorIndex: Int, newColorIndex: Int, source: AnalyticsSource = .phone) {
        logEvent("trivit_color_changed", parameters: [
            "title": sanitizeTitle(title),
            "old_color_index": oldColorIndex,
            "new_color_index": newColorIndex,
            "source": source.rawValue
        ])
    }

    // MARK: - Count Events

    /// Track increment action
    func trackIncrement(trivitId: String, title: String, newCount: Int, source: AnalyticsSource = .phone) {
        logEvent("trivit_increment", parameters: [
            "trivit_id": trivitId,
            "title": sanitizeTitle(title),
            "new_count": newCount,
            "source": source.rawValue,
            "count_bucket": countBucket(newCount)
        ])
    }

    /// Track decrement action
    func trackDecrement(trivitId: String, title: String, newCount: Int, source: AnalyticsSource = .phone) {
        logEvent("trivit_decrement", parameters: [
            "trivit_id": trivitId,
            "title": sanitizeTitle(title),
            "new_count": newCount,
            "source": source.rawValue
        ])
    }

    /// Track reset action
    func trackReset(trivitId: String, title: String, previousCount: Int, source: AnalyticsSource = .phone) {
        logEvent("trivit_reset", parameters: [
            "trivit_id": trivitId,
            "title": sanitizeTitle(title),
            "previous_count": previousCount,
            "source": source.rawValue
        ])
    }

    // MARK: - UI Interaction Events

    /// Track expand/collapse action
    func trackExpandCollapse(trivitId: String, title: String, expanded: Bool) {
        logEvent("trivit_expand_collapse", parameters: [
            "trivit_id": trivitId,
            "title": sanitizeTitle(title),
            "expanded": expanded
        ])
    }

    /// Track reorder action
    func trackReorder(trivitId: String, title: String, fromPosition: Int, toPosition: Int) {
        logEvent("trivit_reordered", parameters: [
            "trivit_id": trivitId,
            "title": sanitizeTitle(title),
            "from_position": fromPosition,
            "to_position": toPosition,
            "direction": fromPosition < toPosition ? "down" : "up"
        ])
    }

    /// Track statistics view opened
    func trackStatisticsViewed(trivitId: String, title: String, currentCount: Int) {
        logEvent("statistics_viewed", parameters: [
            "trivit_id": trivitId,
            "title": sanitizeTitle(title),
            "current_count": currentCount
        ])
    }

    /// Track history view opened
    func trackHistoryViewed(trivitId: String, title: String, eventCount: Int) {
        logEvent("history_viewed", parameters: [
            "trivit_id": trivitId,
            "title": sanitizeTitle(title),
            "event_count": eventCount
        ])
    }

    // MARK: - Watch Sync Events

    /// Track when sync to watch is triggered
    func trackWatchSyncStarted(trivitCount: Int) {
        logEvent("watch_sync_started", parameters: [
            "trivit_count": trivitCount
        ])
    }

    /// Track when sync to watch completes successfully
    func trackWatchSyncCompleted(trivitCount: Int) {
        logEvent("watch_sync_completed", parameters: [
            "trivit_count": trivitCount
        ])
    }

    /// Track when sync fails
    func trackWatchSyncFailed(error: String) {
        logEvent("watch_sync_failed", parameters: [
            "error": error
        ])
    }

    /// Track watch connection state changes
    func trackWatchConnectionChanged(isReachable: Bool, isPaired: Bool) {
        logEvent("watch_connection_changed", parameters: [
            "is_reachable": isReachable,
            "is_paired": isPaired
        ])
    }

    // MARK: - Settings Events

    /// Track settings changes
    func trackSettingChanged(setting: String, value: String) {
        logEvent("setting_changed", parameters: [
            "setting": setting,
            "value": value
        ])
    }

    /// Track color scheme change
    func trackColorSchemeChanged(scheme: String) {
        logEvent("color_scheme_changed", parameters: [
            "scheme": scheme
        ])
    }

    // MARK: - App Lifecycle Events

    /// Track app session start
    func trackSessionStart(trivitCount: Int, totalCount: Int) {
        logEvent("session_start", parameters: [
            "trivit_count": trivitCount,
            "total_count": totalCount
        ])
        updateUserProperties(totalTrivits: trivitCount, totalCount: totalCount)
    }

    // MARK: - Screen Tracking

    func trackScreen(_ screenName: String) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName
        ])
        #endif
    }

    // MARK: - Helpers

    /// Sanitize title for analytics (remove PII, limit length)
    private func sanitizeTitle(_ title: String) -> String {
        // Limit to 100 characters for Firebase
        let limited = String(title.prefix(100))
        // Keep the title as-is for now - it's user-generated content we want to understand
        return limited
    }

    /// Bucket counts for easier analysis
    private func countBucket(_ count: Int) -> String {
        switch count {
        case 0: return "0"
        case 1..<5: return "1-4"
        case 5..<10: return "5-9"
        case 10..<25: return "10-24"
        case 25..<50: return "25-49"
        case 50..<100: return "50-99"
        case 100..<250: return "100-249"
        case 250..<500: return "250-499"
        case 500..<1000: return "500-999"
        default: return "1000+"
        }
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
