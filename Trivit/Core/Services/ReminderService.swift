import Foundation
import UserNotifications
import CoreLocation
import Observation

/// Service for managing trivit reminders and notifications.
///
/// Supports:
/// - Time-based reminders (daily, weekly, specific times)
/// - Location-based reminders (arrive/leave geofences)
/// - Goal reminders (remind to reach a target count)
@Observable
@MainActor
final class ReminderService: NSObject {
    // MARK: - State

    /// Whether notification permissions have been granted
    private(set) var hasNotificationPermission = false

    /// Whether location permissions have been granted for reminders
    private(set) var hasLocationPermission = false

    /// All active reminders
    private(set) var reminders: [TrivitReminder] = []

    /// Current error, if any
    private(set) var error: ReminderError?

    // MARK: - Dependencies

    private let notificationCenter = UNUserNotificationCenter.current()
    private let locationManager = CLLocationManager()

    // MARK: - Storage Keys

    private let remindersKey = "trivit.reminders"

    // MARK: - Initialization

    override init() {
        super.init()
        locationManager.delegate = self
        loadReminders()
        Task {
            await checkPermissions()
        }
    }

    // MARK: - Permission Management

    /// Requests notification permissions from the user.
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            hasNotificationPermission = granted
            return granted
        } catch {
            self.error = .permissionDenied
            return false
        }
    }

    /// Requests location permissions for geofence reminders.
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// Requests always-on location for background geofence monitoring.
    func requestAlwaysLocationPermission() {
        locationManager.requestAlwaysAuthorization()
    }

    /// Checks current permission status.
    func checkPermissions() async {
        let settings = await notificationCenter.notificationSettings()
        hasNotificationPermission = settings.authorizationStatus == .authorized

        let locationStatus = locationManager.authorizationStatus
        hasLocationPermission = locationStatus == .authorizedWhenInUse ||
                               locationStatus == .authorizedAlways
    }

    // MARK: - Reminder CRUD

    /// Creates a new reminder for a trivit.
    func createReminder(_ reminder: TrivitReminder) async throws {
        guard hasNotificationPermission else {
            let granted = await requestNotificationPermission()
            guard granted else {
                throw ReminderError.permissionDenied
            }
        }

        // Schedule the notification
        try await scheduleNotification(for: reminder)

        // If it's a location reminder, set up geofence
        if case .location = reminder.trigger {
            try setupGeofence(for: reminder)
        }

        reminders.append(reminder)
        saveReminders()
    }

    /// Updates an existing reminder.
    func updateReminder(_ reminder: TrivitReminder) async throws {
        // Remove old notification
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [reminder.id.uuidString])

        // Remove old geofence if applicable
        removeGeofence(for: reminder)

        // Schedule new notification
        try await scheduleNotification(for: reminder)

        // Set up new geofence if applicable
        if case .location = reminder.trigger {
            try setupGeofence(for: reminder)
        }

        // Update in array
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index] = reminder
        }
        saveReminders()
    }

    /// Deletes a reminder.
    func deleteReminder(_ reminder: TrivitReminder) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [reminder.id.uuidString])
        removeGeofence(for: reminder)

        reminders.removeAll { $0.id == reminder.id }
        saveReminders()
    }

    /// Deletes all reminders for a specific trivit.
    func deleteReminders(for trivitId: UUID) {
        let toDelete = reminders.filter { $0.trivitId == trivitId }
        for reminder in toDelete {
            deleteReminder(reminder)
        }
    }

    /// Gets all reminders for a specific trivit.
    func reminders(for trivitId: UUID) -> [TrivitReminder] {
        reminders.filter { $0.trivitId == trivitId }
    }

    // MARK: - Notification Scheduling

    private func scheduleNotification(for reminder: TrivitReminder) async throws {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.message
        content.sound = .default
        content.categoryIdentifier = "TRIVIT_REMINDER"
        content.userInfo = [
            "trivitId": reminder.trivitId.uuidString,
            "reminderId": reminder.id.uuidString
        ]

        let trigger: UNNotificationTrigger

        switch reminder.trigger {
        case .daily(let time):
            var dateComponents = DateComponents()
            dateComponents.hour = Calendar.current.component(.hour, from: time)
            dateComponents.minute = Calendar.current.component(.minute, from: time)
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        case .weekly(let weekday, let time):
            var dateComponents = DateComponents()
            dateComponents.weekday = weekday
            dateComponents.hour = Calendar.current.component(.hour, from: time)
            dateComponents.minute = Calendar.current.component(.minute, from: time)
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        case .specificDate(let date):
            let dateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: date
            )
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        case .interval(let seconds):
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: true)

        case .location:
            // Location notifications are handled separately via geofencing
            return
        }

        let request = UNNotificationRequest(
            identifier: reminder.id.uuidString,
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
    }

    // MARK: - Geofencing

    private func setupGeofence(for reminder: TrivitReminder) throws {
        guard case .location(let config) = reminder.trigger else { return }

        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
            throw ReminderError.geofencingNotAvailable
        }

        let region = CLCircularRegion(
            center: config.coordinate,
            radius: config.radius,
            identifier: reminder.id.uuidString
        )

        region.notifyOnEntry = config.triggerOn == .arrive
        region.notifyOnExit = config.triggerOn == .leave

        locationManager.startMonitoring(for: region)
    }

    private func removeGeofence(for reminder: TrivitReminder) {
        guard case .location = reminder.trigger else { return }

        for region in locationManager.monitoredRegions {
            if region.identifier == reminder.id.uuidString {
                locationManager.stopMonitoring(for: region)
                break
            }
        }
    }

    // MARK: - Persistence

    private func loadReminders() {
        guard let data = UserDefaults.standard.data(forKey: remindersKey),
              let decoded = try? JSONDecoder().decode([TrivitReminder].self, from: data) else {
            return
        }
        reminders = decoded
    }

    private func saveReminders() {
        guard let data = try? JSONEncoder().encode(reminders) else { return }
        UserDefaults.standard.set(data, forKey: remindersKey)
    }

    // MARK: - Error Handling

    func dismissError() {
        error = nil
    }
}

// MARK: - CLLocationManagerDelegate

extension ReminderService: CLLocationManagerDelegate {
    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didEnterRegion region: CLRegion
    ) {
        handleGeofenceEvent(region: region, isEntering: true)
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didExitRegion region: CLRegion
    ) {
        handleGeofenceEvent(region: region, isEntering: false)
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            await checkPermissions()
        }
    }

    private nonisolated func handleGeofenceEvent(region: CLRegion, isEntering: Bool) {
        Task { @MainActor in
            guard let reminder = reminders.first(where: { $0.id.uuidString == region.identifier }),
                  case .location(let config) = reminder.trigger else {
                return
            }

            let shouldNotify = (isEntering && config.triggerOn == .arrive) ||
                              (!isEntering && config.triggerOn == .leave)

            if shouldNotify {
                await sendLocationNotification(for: reminder)
            }
        }
    }

    private func sendLocationNotification(for reminder: TrivitReminder) async {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.message
        content.sound = .default
        content.userInfo = [
            "trivitId": reminder.trivitId.uuidString,
            "reminderId": reminder.id.uuidString
        ]

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil  // Deliver immediately
        )

        try? await notificationCenter.add(request)
    }
}

// MARK: - TrivitReminder Model

/// A reminder configuration for a trivit.
struct TrivitReminder: Codable, Identifiable, Equatable {
    let id: UUID
    let trivitId: UUID
    var title: String
    var message: String
    var trigger: ReminderTrigger
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        trivitId: UUID,
        title: String,
        message: String,
        trigger: ReminderTrigger,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.trivitId = trivitId
        self.title = title
        self.message = message
        self.trigger = trigger
        self.isEnabled = isEnabled
    }
}

// MARK: - ReminderTrigger

/// When a reminder should trigger.
enum ReminderTrigger: Codable, Equatable {
    /// Daily at a specific time
    case daily(time: Date)

    /// Weekly on a specific day and time (weekday: 1 = Sunday, 7 = Saturday)
    case weekly(weekday: Int, time: Date)

    /// Once at a specific date and time
    case specificDate(Date)

    /// Repeating interval in seconds
    case interval(TimeInterval)

    /// Location-based trigger
    case location(LocationTriggerConfig)

    var displayName: String {
        switch self {
        case .daily:
            return "Daily"
        case .weekly:
            return "Weekly"
        case .specificDate:
            return "One-time"
        case .interval:
            return "Interval"
        case .location:
            return "Location"
        }
    }
}

// MARK: - LocationTriggerConfig

/// Configuration for location-based reminders.
struct LocationTriggerConfig: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    let radius: CLLocationDistance
    let triggerOn: LocationTriggerType
    let locationName: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(
        coordinate: CLLocationCoordinate2D,
        radius: CLLocationDistance = 100,
        triggerOn: LocationTriggerType = .arrive,
        locationName: String = ""
    ) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.radius = radius
        self.triggerOn = triggerOn
        self.locationName = locationName
    }
}

// MARK: - LocationTriggerType

/// Whether to trigger on arrival or departure.
enum LocationTriggerType: String, Codable, CaseIterable {
    case arrive
    case leave

    var displayName: String {
        switch self {
        case .arrive: return "When I arrive"
        case .leave: return "When I leave"
        }
    }
}

// MARK: - ReminderError

/// Errors that can occur with reminders.
enum ReminderError: Error, LocalizedError {
    case permissionDenied
    case geofencingNotAvailable
    case invalidTrigger
    case schedulingFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Notification permission is required for reminders."
        case .geofencingNotAvailable:
            return "Location-based reminders are not available on this device."
        case .invalidTrigger:
            return "The reminder trigger configuration is invalid."
        case .schedulingFailed:
            return "Failed to schedule the reminder."
        }
    }
}

// MARK: - Convenience Extensions

extension TrivitReminder {
    /// Creates a simple daily reminder.
    static func daily(
        for trivitId: UUID,
        title: String,
        message: String,
        at time: Date
    ) -> TrivitReminder {
        TrivitReminder(
            trivitId: trivitId,
            title: title,
            message: message,
            trigger: .daily(time: time)
        )
    }

    /// Creates a location-based reminder.
    static func location(
        for trivitId: UUID,
        title: String,
        message: String,
        coordinate: CLLocationCoordinate2D,
        radius: CLLocationDistance = 100,
        triggerOn: LocationTriggerType = .arrive,
        locationName: String = ""
    ) -> TrivitReminder {
        TrivitReminder(
            trivitId: trivitId,
            title: title,
            message: message,
            trigger: .location(LocationTriggerConfig(
                coordinate: coordinate,
                radius: radius,
                triggerOn: triggerOn,
                locationName: locationName
            ))
        )
    }
}
