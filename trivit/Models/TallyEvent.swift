//
//  TallyEvent.swift
//  Trivit
//
//  SwiftData model for tracking individual tally events
//

import Foundation
import SwiftData

@Model
final class TallyEvent {
    var id: UUID
    var trivitId: UUID
    var timestamp: Date
    var delta: Int  // +1 for increment, -1 for decrement

    init(
        id: UUID = UUID(),
        trivitId: UUID,
        timestamp: Date = Date(),
        delta: Int
    ) {
        self.id = id
        self.trivitId = trivitId
        self.timestamp = timestamp
        self.delta = delta
    }
}
