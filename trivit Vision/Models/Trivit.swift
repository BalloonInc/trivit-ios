//
//  Trivit.swift
//  trivit Vision
//
//  Simplified SwiftData model for visionOS (matches watch app pattern)
//

import Foundation
import SwiftData

@Model
final class Trivit: Equatable {
    var id: UUID
    var title: String
    var count: Int
    var colorIndex: Int
    var isCollapsed: Bool
    var createdAt: Date
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        title: String = "New Trivit",
        count: Int = 0,
        colorIndex: Int = 0,
        isCollapsed: Bool = true,
        createdAt: Date = Date(),
        sortOrder: Int = 0
    ) {
        self.id = id
        self.title = title
        self.count = count
        self.colorIndex = colorIndex
        self.isCollapsed = isCollapsed
        self.createdAt = createdAt
        self.sortOrder = sortOrder
    }

    func increment() {
        count += 1
    }

    func decrement() {
        if count > 0 {
            count -= 1
        }
    }

    func reset() {
        count = 0
    }

    static func == (lhs: Trivit, rhs: Trivit) -> Bool {
        lhs.id == rhs.id
    }
}
