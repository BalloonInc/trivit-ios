//
//  StatisticsService.swift
//  Trivit
//
//  Service for calculating statistics from tally events
//

import Foundation
import SwiftData

struct HourlyCount: Identifiable {
    let id = UUID()
    let hour: Int
    let count: Int
}

struct DailyCount: Identifiable {
    let id = UUID()
    let dayOfWeek: Int
    let dayName: String
    let count: Int
}

struct MonthlyCount: Identifiable {
    let id = UUID()
    let month: Date
    let count: Int
}

struct DailyActivity: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

struct StreakData {
    let currentStreak: Int
    let longestStreak: Int
    let lastActivityDate: Date?
}

final class StatisticsService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Fetch Events

    func fetchEvents(for trivitId: UUID) -> [TallyEvent] {
        let descriptor = FetchDescriptor<TallyEvent>(
            predicate: #Predicate { $0.trivitId == trivitId },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching events: \(error)")
            return []
        }
    }

    // MARK: - Counts by Hour of Day

    func countsByHourOfDay(for trivitId: UUID) -> [HourlyCount] {
        let events = fetchEvents(for: trivitId)
        let calendar = Calendar.current

        var hourCounts = [Int: Int]()

        for event in events {
            if event.delta > 0 {  // Only count increments
                let hour = calendar.component(.hour, from: event.timestamp)
                hourCounts[hour, default: 0] += event.delta
            }
        }

        // Return all 24 hours
        return (0..<24).map { hour in
            HourlyCount(hour: hour, count: hourCounts[hour] ?? 0)
        }
    }

    // MARK: - Counts by Day of Week

    func countsByDayOfWeek(for trivitId: UUID) -> [DailyCount] {
        let events = fetchEvents(for: trivitId)
        let calendar = Calendar.current

        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        var dayCounts = [Int: Int]()

        for event in events {
            if event.delta > 0 {  // Only count increments
                let dayOfWeek = calendar.component(.weekday, from: event.timestamp)
                dayCounts[dayOfWeek, default: 0] += event.delta
            }
        }

        // Sunday = 1, Monday = 2, etc.
        return (1...7).map { day in
            DailyCount(
                dayOfWeek: day,
                dayName: dayNames[day - 1],
                count: dayCounts[day] ?? 0
            )
        }
    }

    // MARK: - Monthly Totals

    func monthlyTotals(for trivitId: UUID, months: Int = 12) -> [MonthlyCount] {
        let events = fetchEvents(for: trivitId)
        let calendar = Calendar.current

        var monthlyCounts = [Date: Int]()

        for event in events {
            if event.delta > 0 {  // Only count increments
                let components = calendar.dateComponents([.year, .month], from: event.timestamp)
                if let monthStart = calendar.date(from: components) {
                    monthlyCounts[monthStart, default: 0] += event.delta
                }
            }
        }

        // Get the last N months
        var result = [MonthlyCount]()
        for i in 0..<months {
            if let month = calendar.date(byAdding: .month, value: -i, to: Date()) {
                let components = calendar.dateComponents([.year, .month], from: month)
                if let monthStart = calendar.date(from: components) {
                    result.append(MonthlyCount(
                        month: monthStart,
                        count: monthlyCounts[monthStart] ?? 0
                    ))
                }
            }
        }

        return result.reversed()
    }

    // MARK: - Daily Activity (Last N Days)

    func dailyActivity(for trivitId: UUID, days: Int = 30) -> [DailyActivity] {
        let events = fetchEvents(for: trivitId)
        let calendar = Calendar.current

        var dailyCounts = [Date: Int]()

        for event in events {
            if event.delta > 0 {  // Only count increments
                let dayStart = calendar.startOfDay(for: event.timestamp)
                dailyCounts[dayStart, default: 0] += event.delta
            }
        }

        // Get the last N days
        var result = [DailyActivity]()
        for i in 0..<days {
            if let day = calendar.date(byAdding: .day, value: -i, to: Date()) {
                let dayStart = calendar.startOfDay(for: day)
                result.append(DailyActivity(
                    date: dayStart,
                    count: dailyCounts[dayStart] ?? 0
                ))
            }
        }

        return result.reversed()
    }

    // MARK: - Streak Data

    func streakData(for trivitId: UUID) -> StreakData {
        let events = fetchEvents(for: trivitId)
        let calendar = Calendar.current

        // Get unique days with activity
        var activeDays = Set<Date>()
        for event in events {
            if event.delta > 0 {
                let dayStart = calendar.startOfDay(for: event.timestamp)
                activeDays.insert(dayStart)
            }
        }

        guard !activeDays.isEmpty else {
            return StreakData(currentStreak: 0, longestStreak: 0, lastActivityDate: nil)
        }

        let sortedDays = activeDays.sorted()
        let lastActivityDate = sortedDays.last

        // Calculate current streak
        var currentStreak = 0
        let today = calendar.startOfDay(for: Date())
        var checkDate = today

        // Check if there was activity today or yesterday
        if activeDays.contains(today) {
            currentStreak = 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  activeDays.contains(yesterday) {
            currentStreak = 1
            checkDate = calendar.date(byAdding: .day, value: -2, to: today) ?? today
        } else {
            return StreakData(currentStreak: 0, longestStreak: calculateLongestStreak(sortedDays: sortedDays, calendar: calendar), lastActivityDate: lastActivityDate)
        }

        // Count backwards
        while activeDays.contains(checkDate) {
            currentStreak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }

        let longestStreak = calculateLongestStreak(sortedDays: sortedDays, calendar: calendar)

        return StreakData(
            currentStreak: currentStreak,
            longestStreak: max(currentStreak, longestStreak),
            lastActivityDate: lastActivityDate
        )
    }

    private func calculateLongestStreak(sortedDays: [Date], calendar: Calendar) -> Int {
        guard !sortedDays.isEmpty else { return 0 }

        var longestStreak = 1
        var currentStreak = 1

        for i in 1..<sortedDays.count {
            let previousDay = sortedDays[i - 1]
            let currentDay = sortedDays[i]

            if let nextDay = calendar.date(byAdding: .day, value: 1, to: previousDay),
               calendar.isDate(nextDay, inSameDayAs: currentDay) {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }

        return longestStreak
    }

    // MARK: - Total Count

    func totalCount(for trivitId: UUID) -> Int {
        let events = fetchEvents(for: trivitId)
        return events.reduce(0) { $0 + $1.delta }
    }

    // MARK: - Delete Event

    func deleteEvent(_ event: TallyEvent) {
        modelContext.delete(event)
        do {
            try modelContext.save()
        } catch {
            print("Error deleting event: \(error)")
        }
    }

    // MARK: - Log Event

    static func logEvent(for trivit: Trivit, delta: Int, in context: ModelContext) {
        let event = TallyEvent(trivitId: trivit.id, delta: delta)
        context.insert(event)
    }
}
