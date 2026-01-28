import Foundation
import SwiftData

/// SwiftData implementation of TrivitRepository.
///
/// Provides local persistence for Trivit entities using SwiftData.
@MainActor
final class SwiftDataTrivitRepository: TrivitRepository {
    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - TrivitRepository

    nonisolated func fetchAll() async throws -> [Trivit] {
        try await MainActor.run {
            let descriptor = FetchDescriptor<Trivit>(
                sortBy: [SortDescriptor(\.createdAt, order: .forward)]
            )
            return try modelContext.fetch(descriptor)
        }
    }

    nonisolated func fetch(id: UUID) async throws -> Trivit? {
        try await MainActor.run {
            let predicate = #Predicate<Trivit> { trivit in
                trivit.id == id
            }
            var descriptor = FetchDescriptor(predicate: predicate)
            descriptor.fetchLimit = 1
            return try modelContext.fetch(descriptor).first
        }
    }

    nonisolated func create(_ trivit: Trivit) async throws {
        try await MainActor.run {
            modelContext.insert(trivit)
            try modelContext.save()
        }
    }

    nonisolated func update(_ trivit: Trivit) async throws {
        try await MainActor.run {
            // SwiftData tracks changes automatically, just save
            try modelContext.save()
        }
    }

    nonisolated func delete(_ trivit: Trivit) async throws {
        try await MainActor.run {
            modelContext.delete(trivit)
            try modelContext.save()
        }
    }

    nonisolated func deleteAll() async throws {
        try await MainActor.run {
            let trivits = try modelContext.fetch(FetchDescriptor<Trivit>())
            for trivit in trivits {
                modelContext.delete(trivit)
            }
            try modelContext.save()
        }
    }

    nonisolated func save() async throws {
        try await MainActor.run {
            try modelContext.save()
        }
    }

    nonisolated func count() async throws -> Int {
        try await MainActor.run {
            let descriptor = FetchDescriptor<Trivit>()
            return try modelContext.fetchCount(descriptor)
        }
    }
}
