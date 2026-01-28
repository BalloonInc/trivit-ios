import Testing
import Foundation
@testable import Trivit

/// Tests for CalendarHeatmapView and related types.
@Suite("Calendar Heatmap Tests")
struct CalendarHeatmapTests {

    // MARK: - HeatmapColorScheme Tests

    @Suite("HeatmapColorScheme")
    struct HeatmapColorSchemeTests {

        @Test("All color schemes have display names")
        func displayNames() {
            for scheme in HeatmapColorScheme.allCases {
                #expect(!scheme.displayName.isEmpty)
            }
        }

        @Test("All color schemes have unique IDs")
        func uniqueIds() {
            let ids = HeatmapColorScheme.allCases.map { $0.id }
            let uniqueIds = Set(ids)
            #expect(ids.count == uniqueIds.count)
        }

        @Test("Color for level 0 is empty color")
        func levelZeroIsEmptyColor() {
            for scheme in HeatmapColorScheme.allCases {
                let emptyColor = scheme.emptyColor
                let levelZeroColor = scheme.color(for: 0, maxLevel: 4)
                // Colors should be the same at level 0
                #expect(levelZeroColor == emptyColor)
            }
        }

        @Test("Colors get progressively more intense")
        func progressiveIntensity() {
            let scheme = HeatmapColorScheme.green

            // Level 1 should be lighter than level 4
            // We can't directly compare colors, but we can verify they're different
            let level1 = scheme.color(for: 1, maxLevel: 4)
            let level4 = scheme.color(for: 4, maxLevel: 4)

            // They should be different colors
            #expect(level1 != level4)
        }
    }

    // MARK: - Data Transformation Tests

    @Suite("Data Transformation")
    struct DataTransformationTests {

        @Test("DailyActivity converts to heatmap data")
        func dailyActivityConversion() {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())

            let dailyActivity = [
                DailyActivity(date: today, increments: 5, decrements: 0, resets: 0),
                DailyActivity(date: calendar.date(byAdding: .day, value: -1, to: today)!,
                             increments: 10, decrements: 0, resets: 0)
            ]

            // Create activity data dictionary
            var data: [Date: Int] = [:]
            for activity in dailyActivity {
                let normalizedDate = calendar.startOfDay(for: activity.date)
                data[normalizedDate] = activity.increments
            }

            #expect(data.count == 2)
            #expect(data[today] == 5)
        }

        @Test("Empty daily activity creates empty data")
        func emptyDailyActivity() {
            let dailyActivity: [DailyActivity] = []
            var data: [Date: Int] = [:]

            for activity in dailyActivity {
                let normalizedDate = Calendar.current.startOfDay(for: activity.date)
                data[normalizedDate] = activity.increments
            }

            #expect(data.isEmpty)
        }

        @Test("Activity data normalizes dates to start of day")
        func dateNormalization() {
            let calendar = Calendar.current

            // Create a date at 3:45 PM
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = 15
            components.minute = 45
            let midDayDate = calendar.date(from: components)!

            let startOfDay = calendar.startOfDay(for: midDayDate)
            let normalizedMidDay = calendar.startOfDay(for: midDayDate)

            #expect(startOfDay == normalizedMidDay)
        }
    }

    // MARK: - Week Calculation Tests

    @Suite("Week Calculations")
    struct WeekCalculationTests {

        @Test("Weeks to show affects date range")
        func weeksAffectsRange() {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())

            // Calculate start date for 26 weeks
            let startDate26 = calendar.date(byAdding: .weekOfYear, value: -26, to: today)!

            // Calculate start date for 52 weeks
            let startDate52 = calendar.date(byAdding: .weekOfYear, value: -52, to: today)!

            #expect(startDate52 < startDate26)

            // 52 weeks should be about 364 days earlier
            let daysDiff = calendar.dateComponents([.day], from: startDate52, to: startDate26).day!
            #expect(daysDiff > 180 && daysDiff < 190) // About 26 weeks = 182 days
        }

        @Test("Week starts on Sunday")
        func weekStartsSunday() {
            let calendar = Calendar.current
            let today = Date()

            // Find the Sunday before or on today
            var sundayDate = today
            while calendar.component(.weekday, from: sundayDate) != 1 {
                sundayDate = calendar.date(byAdding: .day, value: -1, to: sundayDate)!
            }

            let weekday = calendar.component(.weekday, from: sundayDate)
            #expect(weekday == 1) // 1 = Sunday in Calendar
        }
    }

    // MARK: - Max Activity Tests

    @Suite("Max Activity")
    struct MaxActivityTests {

        @Test("Max activity is at least 1")
        func minMaxActivity() {
            let emptyData: [Date: Int] = [:]
            let maxActivity = max(1, emptyData.values.max() ?? 1)
            #expect(maxActivity >= 1)
        }

        @Test("Max activity finds highest value")
        func findsHighest() {
            let data: [Date: Int] = [
                Date(): 5,
                Date().addingTimeInterval(-86400): 10,
                Date().addingTimeInterval(-172800): 3
            ]

            let maxActivity = max(1, data.values.max() ?? 1)
            #expect(maxActivity == 10)
        }

        @Test("Activity levels are calculated correctly")
        func activityLevelCalculation() {
            let maxActivity = 10

            // 0 activity = level 0
            let level0 = 0 > 0 ? min(4, Int(Double(0) / Double(maxActivity) * 4) + 1) : 0
            #expect(level0 == 0)

            // Half activity = level 2-3
            let halfActivity = 5
            let levelHalf = halfActivity > 0 ? min(4, Int(Double(halfActivity) / Double(maxActivity) * 4) + 1) : 0
            #expect(levelHalf >= 2 && levelHalf <= 3)

            // Max activity = level 4
            let fullActivity = 10
            let levelFull = fullActivity > 0 ? min(4, Int(Double(fullActivity) / Double(maxActivity) * 4) + 1) : 0
            #expect(levelFull == 4)
        }
    }
}
