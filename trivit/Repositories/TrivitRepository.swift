//
//  TrivitRepository.swift
//  Trivit
//
//  Repository protocol and SwiftData implementation for Trivit persistence
//

import Foundation
import SwiftData

protocol TrivitRepository {
    func fetchAll() async throws -> [Trivit]
    func save(_ trivit: Trivit) async throws
    func delete(_ trivit: Trivit) async throws
    func insert(_ trivit: Trivit) async throws
}

@MainActor
final class SwiftDataTrivitRepository: TrivitRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() async throws -> [Trivit] {
        let descriptor = FetchDescriptor<Trivit>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try modelContext.fetch(descriptor)
    }

    func save(_ trivit: Trivit) async throws {
        try modelContext.save()
    }

    func delete(_ trivit: Trivit) async throws {
        modelContext.delete(trivit)
        try modelContext.save()
    }

    func insert(_ trivit: Trivit) async throws {
        modelContext.insert(trivit)
        try modelContext.save()
    }
}

// MARK: - Mock Repository for Previews and Testing

final class MockTrivitRepository: TrivitRepository {
    var trivits: [Trivit] = []
    var saveCalled = false
    var deleteCalled = false
    var insertCalled = false

    func fetchAll() async throws -> [Trivit] {
        return trivits
    }

    func save(_ trivit: Trivit) async throws {
        saveCalled = true
    }

    func delete(_ trivit: Trivit) async throws {
        deleteCalled = true
        trivits.removeAll { $0.id == trivit.id }
    }

    func insert(_ trivit: Trivit) async throws {
        insertCalled = true
        trivits.append(trivit)
    }
}
