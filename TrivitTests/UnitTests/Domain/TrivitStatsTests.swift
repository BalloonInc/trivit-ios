import Testing
import Foundation
@testable import Trivit

/// Comprehensive tests for TrivitStats.
@Suite("TrivitStats Tests")
struct TrivitStatsTests {

    // MARK: - Initialization Tests

    @Suite("Initialization")
    struct InitializationTests {

        @Test("Creates empty stats")
        func emptyStats() {
            let trivitId = UUID()
            let stats = TrivitStats.empty(for: trivitId)

            #expect(stats.trivitId == trivitId)
            #expect(stats.currentCount == 0)
            #expect(stats.totalIncrements == 0)
            #expect(stats.totalDecrements == 0)
            #expect(stats.resetCount == 0)
            #expect(stats.highestCount == 0)
            #expect(stats.firstActivity == nil)
            #expect(stats.lastActivity == nil)
            #expect(stats.dailyActivity.isEmpty)
        }

        @Test("Creates stats with values")
        func statsWithValues() {
            let stats = TrivitStats(
                trivitId: UUID(),
                currentCount: 100,
                totalIncrements: 150,
                totalDecrements: 50,
                resetCount: 2,
                highestCount: 200
            )

            #expect(stats.currentCount == 100)
            #expect(stats.totalIncrements == 150)
            #expect(stats.totalDecrements == 50)
            #expect(stats.resetCount == 2)
            #expect(stats.highestCount == 200)
        }
    }

    // MARK: - Computed Properties Tests

    @Suite("Computed Properties")
    struct ComputedPropertiesTests {

        @Test("Calculates total interactions")
        func totalInteractions() {
            let stats = TrivitStats(
                trivitId: UUID(),
                totalIncrements: 100,
                totalDecrements: 30,
                resetCount: 5
            )

            #expect(stats.totalInteractions == 135)
        }

        @Test("Calculates net change")
        func netChange() {
            let stats = TrivitStats(
                trivitId: UUID(),
                totalIncrements: 100,
                totalDecrements: 30
            )

            #expect(stats.netChange == 70)
        }

        @Test("Net change can be negative")
        func negativeNetChange() {
            let stats = TrivitStats(
                trivitId: UUID(),
                totalIncrements: 30,
                totalDecrements: 100
            )

            #expect(stats.netChange == -70)
        }

        @Test("Average increments per day with no activity is zero")
        func averageIncrementsNoActivity() {
            let stats = TrivitStats.empty(for: UUID())

            #expect(stats.averageIncrementsPerDay == 0)
        }

        @Test("Average increments per day calculates correctly")
        func averageIncrementsCalculation() {
            let calendar = Calendar.current
            let tenDaysAgo = calendar.date(byAdding: .day, value: -10, to: Date())!

            let stats = TrivitStats(
                trivitId: UUID(),
                totalIncrements: 50,
                firstActivity: tenDaysAgo
            )

            #expect(stats.averageIncrementsPerDay == 5.0)
        }
    }

    // MARK: - Streak Tests

    @Suite("Streak Calculation")
    struct StreakTests {

        @Test("Empty activity has zero streak")
        func emptyStreak() {
            let stats = TrivitStats.empty(for: UUID())

            #expect(stats.currentStreak == 0)
            #expect(stats.longestStreak == 0)
        }

        @Test("Single day activity has streak of 1")
        func singleDayStreak() {
            let today = Date()
            let stats = TrivitStats(
                trivitId: UUID(),
                dailyActivity: [
                    DailyActivity(date: today, increments: 5, decrements: 0, resets: 0)
                ]
            )

            #expect(stats.currentStreak == 1)
            #expect(stats.longestStreak == 1)
        }

        @Test("Consecutive days have correct streak")
        func consecutiveDaysStreak() {
            let calendar = Calendar.current
            let today = Date()

            var dailyActivity: [DailyActivity] = []
            for i in 0..<5 {
                if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                    dailyActivity.append(DailyActivity(
                        date: date,
                        increments: 1,
                        decrements: 0,
                        resets: 0
                    ))
                }
            }

            let stats = TrivitStats(
                trivitId: UUID(),
                dailyActivity: dailyActivity
            )

            #expect(stats.currentStreak == 5)
            #expect(stats.longestStreak == 5)
        }

        @Test("Gap in activity breaks current streak")
        func gapBreaksStreak() {
            let calendar = Calendar.current
            let today = Date()

            // Activity today and yesterday, gap, then 3 days before
            var dailyActivity: [DailyActivity] = []
            for i in [0, 1, 4, 5, 6] {
                if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                    dailyActivity.append(DailyActivity(
                        date: date,
                        increments: 1,
                        decrements: 0,
                        resets: 0
                    ))
                }
            }

            let stats = TrivitStats(
                trivitId: UUID(),
                dailyActivity: dailyActivity
            )

            #expect(stats.currentStreak == 2)  // Only today and yesterday
            #expect(stats.longestStreak == 3)  // The earlier 3-day streak
        }
    }
}

// MARK: - DailyActivity Tests

@Suite("DailyActivity Tests")
struct DailyActivityTests {

    @Test("Calculates total activity")
    func totalActivity() {
        let activity = DailyActivity(
            date: Date(),
            increments: 10,
            decrements: 3,
            resets: 1
        )

        #expect(activity.totalActivity == 14)
    }

    @Test("Calculates net change")
    func netChange() {
        let activity = DailyActivity(
            date: Date(),
            increments: 10,
            decrements: 3,
            resets: 0
        )

        #expect(activity.netChange == 7)
    }

    @Test("Net change ignores resets")
    func netChangeIgnoresResets() {
        let activity = DailyActivity(
            date: Date(),
            increments: 10,
            decrements: 3,
            resets: 5
        )

        #expect(activity.netChange == 7)
    }

    @Test("Activity is identifiable by date")
    func identifiable() {
        let date = Date()
        let activity = DailyActivity(
            date: date,
            increments: 1,
            decrements: 0,
            resets: 0
        )

        #expect(activity.id == date)
    }
}

// MARK: - HourlyActivity Tests

@Suite("HourlyActivity Tests")
struct HourlyActivityTests {

    @Test("Calculates total activity")
    func totalActivity() {
        let activity = HourlyActivity(
            hour: Date(),
            increments: 5,
            decrements: 2
        )

        #expect(activity.totalActivity == 7)
    }

    @Test("Activity is identifiable by hour")
    func identifiable() {
        let hour = Date()
        let activity = HourlyActivity(
            hour: hour,
            increments: 1,
            decrements: 0
        )

        #expect(activity.id == hour)
    }
}
