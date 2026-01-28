import Foundation

/// Statistics calculated from a Trivit's history.
struct TrivitStats: Equatable {
    // MARK: - Properties

    /// The trivit these stats are for
    let trivitId: UUID

    /// Current count value
    let currentCount: Int

    /// Total number of increments ever made
    let totalIncrements: Int

    /// Total number of decrements ever made
    let totalDecrements: Int

    /// Number of times the counter was reset
    let resetCount: Int

    /// Highest count ever reached
    let highestCount: Int

    /// Date of the first ever count change
    let firstActivity: Date?

    /// Date of the most recent count change
    let lastActivity: Date?

    /// Count changes grouped by day for charting
    let dailyActivity: [DailyActivity]

    /// Count changes grouped by hour for charting (last 24 hours)
    let hourlyActivity: [HourlyActivity]

    // MARK: - Computed Properties

    /// Total number of interactions (increments + decrements + resets)
    var totalInteractions: Int {
        totalIncrements + totalDecrements + resetCount
    }

    /// Net change (increments minus decrements, ignoring resets)
    var netChange: Int {
        totalIncrements - totalDecrements
    }

    /// Average increments per day (since first activity)
    var averageIncrementsPerDay: Double {
        guard let first = firstActivity else { return 0 }
        let days = max(1, Calendar.current.dateComponents([.day], from: first, to: Date()).day ?? 1)
        return Double(totalIncrements) / Double(days)
    }

    /// Streak: consecutive days with at least one increment
    var currentStreak: Int {
        calculateStreak(from: dailyActivity)
    }

    /// Longest streak ever
    var longestStreak: Int {
        calculateLongestStreak(from: dailyActivity)
    }

    // MARK: - Initialization

    init(
        trivitId: UUID,
        currentCount: Int = 0,
        totalIncrements: Int = 0,
        totalDecrements: Int = 0,
        resetCount: Int = 0,
        highestCount: Int = 0,
        firstActivity: Date? = nil,
        lastActivity: Date? = nil,
        dailyActivity: [DailyActivity] = [],
        hourlyActivity: [HourlyActivity] = []
    ) {
        self.trivitId = trivitId
        self.currentCount = currentCount
        self.totalIncrements = totalIncrements
        self.totalDecrements = totalDecrements
        self.resetCount = resetCount
        self.highestCount = highestCount
        self.firstActivity = firstActivity
        self.lastActivity = lastActivity
        self.dailyActivity = dailyActivity
        self.hourlyActivity = hourlyActivity
    }

    // MARK: - Private Helpers

    private func calculateStreak(from activity: [DailyActivity]) -> Int {
        guard !activity.isEmpty else { return 0 }

        var streak = 0
        let calendar = Calendar.current
        var currentDate = calendar.startOfDay(for: Date())

        let sortedActivity = activity.sorted { $0.date > $1.date }
        var activitySet = Set(sortedActivity.map { calendar.startOfDay(for: $0.date) })

        while activitySet.contains(currentDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDay
        }

        return streak
    }

    private func calculateLongestStreak(from activity: [DailyActivity]) -> Int {
        guard !activity.isEmpty else { return 0 }

        let calendar = Calendar.current
        let sortedDates = activity.map { calendar.startOfDay(for: $0.date) }.sorted()

        var longestStreak = 1
        var currentStreak = 1

        for i in 1..<sortedDates.count {
            let daysBetween = calendar.dateComponents([.day], from: sortedDates[i-1], to: sortedDates[i]).day ?? 0
            if daysBetween == 1 {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else if daysBetween > 1 {
                currentStreak = 1
            }
        }

        return longestStreak
    }

    // MARK: - Factory

    /// Creates stats with no activity
    static func empty(for trivitId: UUID) -> TrivitStats {
        TrivitStats(trivitId: trivitId)
    }
}

// MARK: - Daily Activity

/// Count activity for a single day.
struct DailyActivity: Equatable, Identifiable {
    var id: Date { date }

    let date: Date
    let increments: Int
    let decrements: Int
    let resets: Int

    var totalActivity: Int {
        increments + decrements + resets
    }

    var netChange: Int {
        increments - decrements
    }
}

// MARK: - Hourly Activity

/// Count activity for a single hour.
struct HourlyActivity: Equatable, Identifiable {
    var id: Date { hour }

    let hour: Date
    let increments: Int
    let decrements: Int

    var totalActivity: Int {
        increments + decrements
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension TrivitStats {
    static var preview: TrivitStats {
        let calendar = Calendar.current
        let now = Date()

        var dailyActivity: [DailyActivity] = []
        for dayOffset in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) {
                dailyActivity.append(DailyActivity(
                    date: date,
                    increments: Int.random(in: 0...10),
                    decrements: Int.random(in: 0...3),
                    resets: dayOffset % 7 == 0 ? 1 : 0
                ))
            }
        }

        return TrivitStats(
            trivitId: UUID(),
            currentCount: 127,
            totalIncrements: 450,
            totalDecrements: 23,
            resetCount: 4,
            highestCount: 200,
            firstActivity: calendar.date(byAdding: .month, value: -3, to: now),
            lastActivity: now,
            dailyActivity: dailyActivity
        )
    }
}
#endif
