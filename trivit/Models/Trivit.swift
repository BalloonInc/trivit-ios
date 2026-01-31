//
//  Trivit.swift
//  Trivit
//
//  Modern SwiftData model replacing Objective-C TallyModel
//

import Foundation
import SwiftData

@Model
final class Trivit: Equatable {
    var id: UUID = UUID()
    var title: String = "New Trivit"
    var count: Int = 0
    var colorIndex: Int = 0
    var isCollapsed: Bool = true
    var createdAt: Date = Date()

    init(
        id: UUID = UUID(),
        title: String = "New Trivit",
        count: Int = 0,
        colorIndex: Int = 0,
        isCollapsed: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.count = count
        self.colorIndex = colorIndex
        self.isCollapsed = isCollapsed
        self.createdAt = createdAt
    }

    func increment() {
        count += 1
    }

    func increment(in context: ModelContext) {
        count += 1
        StatisticsService.logEvent(for: self, delta: 1, in: context)
    }

    func decrement() {
        if count > 0 {
            count -= 1
        }
    }

    func decrement(in context: ModelContext) {
        if count > 0 {
            count -= 1
            StatisticsService.logEvent(for: self, delta: -1, in: context)
        }
    }

    func reset() {
        count = 0
    }

    static func == (lhs: Trivit, rhs: Trivit) -> Bool {
        lhs.id == rhs.id
    }
}
