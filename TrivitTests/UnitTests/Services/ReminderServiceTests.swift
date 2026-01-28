import Testing
import Foundation
import CoreLocation
@testable import Trivit

/// Tests for ReminderService and related types.
@Suite("Reminder Service Tests")
struct ReminderServiceTests {

    // MARK: - TrivitReminder Tests

    @Suite("TrivitReminder")
    struct TrivitReminderTests {

        @Test("Creates reminder with default values")
        func defaultCreation() {
            let trivitId = UUID()
            let reminder = TrivitReminder(
                trivitId: trivitId,
                title: "Test Reminder",
                message: "Remember to count!",
                trigger: .daily(time: Date())
            )

            #expect(reminder.trivitId == trivitId)
            #expect(reminder.title == "Test Reminder")
            #expect(reminder.message == "Remember to count!")
            #expect(reminder.isEnabled == true)
        }

        @Test("Reminder is identifiable")
        func identifiable() {
            let id = UUID()
            let reminder = TrivitReminder(
                id: id,
                trivitId: UUID(),
                title: "Test",
                message: "Test",
                trigger: .daily(time: Date())
            )

            #expect(reminder.id == id)
        }

        @Test("Daily reminder factory method")
        func dailyFactory() {
            let trivitId = UUID()
            let time = Date()
            let reminder = TrivitReminder.daily(
                for: trivitId,
                title: "Daily",
                message: "Message",
                at: time
            )

            #expect(reminder.trivitId == trivitId)
            #expect(reminder.title == "Daily")
            if case .daily(let reminderTime) = reminder.trigger {
                #expect(reminderTime == time)
            } else {
                Issue.record("Expected daily trigger")
            }
        }

        @Test("Location reminder factory method")
        func locationFactory() {
            let trivitId = UUID()
            let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
            let reminder = TrivitReminder.location(
                for: trivitId,
                title: "At Gym",
                message: "Time to count!",
                coordinate: coordinate,
                radius: 150,
                triggerOn: .arrive,
                locationName: "My Gym"
            )

            #expect(reminder.trivitId == trivitId)
            if case .location(let config) = reminder.trigger {
                #expect(config.latitude == 37.7749)
                #expect(config.longitude == -122.4194)
                #expect(config.radius == 150)
                #expect(config.triggerOn == .arrive)
                #expect(config.locationName == "My Gym")
            } else {
                Issue.record("Expected location trigger")
            }
        }
    }

    // MARK: - ReminderTrigger Tests

    @Suite("ReminderTrigger")
    struct ReminderTriggerTests {

        @Test("Daily trigger has correct display name")
        func dailyDisplayName() {
            let trigger = ReminderTrigger.daily(time: Date())
            #expect(trigger.displayName == "Daily")
        }

        @Test("Weekly trigger has correct display name")
        func weeklyDisplayName() {
            let trigger = ReminderTrigger.weekly(weekday: 2, time: Date())
            #expect(trigger.displayName == "Weekly")
        }

        @Test("Specific date trigger has correct display name")
        func specificDateDisplayName() {
            let trigger = ReminderTrigger.specificDate(Date())
            #expect(trigger.displayName == "One-time")
        }

        @Test("Interval trigger has correct display name")
        func intervalDisplayName() {
            let trigger = ReminderTrigger.interval(3600)
            #expect(trigger.displayName == "Interval")
        }

        @Test("Location trigger has correct display name")
        func locationDisplayName() {
            let config = LocationTriggerConfig(
                coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                radius: 100,
                triggerOn: .arrive,
                locationName: "Test"
            )
            let trigger = ReminderTrigger.location(config)
            #expect(trigger.displayName == "Location")
        }

        @Test("Triggers are equatable")
        func equatable() {
            let time = Date()
            let trigger1 = ReminderTrigger.daily(time: time)
            let trigger2 = ReminderTrigger.daily(time: time)
            let trigger3 = ReminderTrigger.weekly(weekday: 2, time: time)

            #expect(trigger1 == trigger2)
            #expect(trigger1 != trigger3)
        }
    }

    // MARK: - LocationTriggerConfig Tests

    @Suite("LocationTriggerConfig")
    struct LocationTriggerConfigTests {

        @Test("Creates config from coordinate")
        func fromCoordinate() {
            let coordinate = CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)
            let config = LocationTriggerConfig(
                coordinate: coordinate,
                radius: 200,
                triggerOn: .leave,
                locationName: "London"
            )

            #expect(config.latitude == 51.5074)
            #expect(config.longitude == -0.1278)
            #expect(config.radius == 200)
            #expect(config.triggerOn == .leave)
            #expect(config.locationName == "London")
        }

        @Test("Coordinate property returns correct values")
        func coordinateProperty() {
            let config = LocationTriggerConfig(
                coordinate: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
                radius: 100,
                triggerOn: .arrive,
                locationName: "NYC"
            )

            #expect(config.coordinate.latitude == 40.7128)
            #expect(config.coordinate.longitude == -74.0060)
        }

        @Test("Default radius is 100 meters")
        func defaultRadius() {
            let config = LocationTriggerConfig(
                coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0)
            )
            #expect(config.radius == 100)
        }

        @Test("Default trigger is arrive")
        func defaultTriggerOn() {
            let config = LocationTriggerConfig(
                coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0)
            )
            #expect(config.triggerOn == .arrive)
        }
    }

    // MARK: - LocationTriggerType Tests

    @Suite("LocationTriggerType")
    struct LocationTriggerTypeTests {

        @Test("All cases have display names")
        func displayNames() {
            for type in LocationTriggerType.allCases {
                #expect(!type.displayName.isEmpty)
            }
        }

        @Test("Arrive display name")
        func arriveDisplayName() {
            #expect(LocationTriggerType.arrive.displayName == "When I arrive")
        }

        @Test("Leave display name")
        func leaveDisplayName() {
            #expect(LocationTriggerType.leave.displayName == "When I leave")
        }
    }

    // MARK: - ReminderError Tests

    @Suite("ReminderError")
    struct ReminderErrorTests {

        @Test("Permission denied error has description")
        func permissionDeniedDescription() {
            let error = ReminderError.permissionDenied
            #expect(error.localizedDescription.contains("permission"))
        }

        @Test("Geofencing not available error has description")
        func geofencingNotAvailableDescription() {
            let error = ReminderError.geofencingNotAvailable
            #expect(error.localizedDescription.contains("Location"))
        }

        @Test("Invalid trigger error has description")
        func invalidTriggerDescription() {
            let error = ReminderError.invalidTrigger
            #expect(error.localizedDescription.contains("invalid"))
        }

        @Test("Scheduling failed error has description")
        func schedulingFailedDescription() {
            let error = ReminderError.schedulingFailed
            #expect(error.localizedDescription.contains("schedule"))
        }
    }

    // MARK: - Codable Tests

    @Suite("Codable")
    struct CodableTests {

        @Test("TrivitReminder encodes and decodes")
        func reminderCodable() throws {
            let original = TrivitReminder(
                trivitId: UUID(),
                title: "Test",
                message: "Test message",
                trigger: .daily(time: Date())
            )

            let data = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(TrivitReminder.self, from: data)

            #expect(decoded.id == original.id)
            #expect(decoded.trivitId == original.trivitId)
            #expect(decoded.title == original.title)
            #expect(decoded.message == original.message)
            #expect(decoded.isEnabled == original.isEnabled)
        }

        @Test("Location trigger encodes and decodes")
        func locationTriggerCodable() throws {
            let config = LocationTriggerConfig(
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                radius: 150,
                triggerOn: .arrive,
                locationName: "SF"
            )
            let original = ReminderTrigger.location(config)

            let data = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(ReminderTrigger.self, from: data)

            if case .location(let decodedConfig) = decoded {
                #expect(decodedConfig.latitude == config.latitude)
                #expect(decodedConfig.longitude == config.longitude)
                #expect(decodedConfig.radius == config.radius)
                #expect(decodedConfig.triggerOn == config.triggerOn)
                #expect(decodedConfig.locationName == config.locationName)
            } else {
                Issue.record("Expected location trigger after decoding")
            }
        }

        @Test("All trigger types encode and decode")
        func allTriggerTypesCodable() throws {
            let triggers: [ReminderTrigger] = [
                .daily(time: Date()),
                .weekly(weekday: 3, time: Date()),
                .specificDate(Date()),
                .interval(3600),
                .location(LocationTriggerConfig(
                    coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0)
                ))
            ]

            for original in triggers {
                let data = try JSONEncoder().encode(original)
                let decoded = try JSONDecoder().decode(ReminderTrigger.self, from: data)
                #expect(decoded.displayName == original.displayName)
            }
        }
    }
}
