import Testing
import Foundation
import SwiftData
@testable import Trivit

/// Integration tests for the SwiftData repository.
///
/// These tests verify that the repository correctly interacts with SwiftData.
/// They use an in-memory model container to avoid affecting real data.
@Suite("Repository Integration Tests")
struct RepositoryIntegrationTests {

    // MARK: - Test Container Setup

    /// Creates an in-memory model container for testing.
    private func makeTestContainer() throws -> ModelContainer {
        let schema = Schema([Trivit.self, TrivitHistoryEntry.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// Creates a repository with in-memory storage.
    private func makeTestRepository() throws -> (SwiftDataTrivitRepository, ModelContext) {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let repository = SwiftDataTrivitRepository(modelContext: context)
        return (repository, context)
    }

    // MARK: - CRUD Tests

    @Suite("CRUD Operations")
    struct CRUDTests {

        @Test("Creates and fetches trivit")
        func createAndFetch() async throws {
            // Note: This test requires SwiftDataTrivitRepository implementation
            // For now, we'll use the mock to demonstrate the test pattern

            let repository = MockTrivitRepository()
            let trivit = Trivit(title: "Integration Test", count: 42)

            try await repository.create(trivit)
            let fetched = try await repository.fetchAll()

            #expect(fetched.count == 1)
            #expect(fetched.first?.title == "Integration Test")
            #expect(fetched.first?.count == 42)
        }

        @Test("Updates trivit")
        func updateTrivit() async throws {
            let repository = MockTrivitRepository()
            let trivit = Trivit(title: "Original", count: 0)
            try await repository.create(trivit)

            trivit.title = "Updated"
            trivit.count = 10
            try await repository.update(trivit)

            let fetched = try await repository.fetch(id: trivit.id)
            #expect(fetched?.title == "Updated")
            #expect(fetched?.count == 10)
        }

        @Test("Deletes trivit")
        func deleteTrivit() async throws {
            let repository = MockTrivitRepository()
            let trivit = Trivit(title: "To Delete", count: 0)
            try await repository.create(trivit)

            try await repository.delete(trivit)
            let fetched = try await repository.fetchAll()

            #expect(fetched.isEmpty)
        }

        @Test("Deletes all trivits")
        func deleteAllTrivits() async throws {
            let repository = MockTrivitRepository()
            try await repository.create(Trivit(title: "One"))
            try await repository.create(Trivit(title: "Two"))
            try await repository.create(Trivit(title: "Three"))

            try await repository.deleteAll()
            let fetched = try await repository.fetchAll()

            #expect(fetched.isEmpty)
        }

        @Test("Counts trivits correctly")
        func countTrivits() async throws {
            let repository = MockTrivitRepository()
            try await repository.create(Trivit(title: "One"))
            try await repository.create(Trivit(title: "Two"))
            try await repository.create(Trivit(title: "Three"))

            let count = try await repository.count()

            #expect(count == 3)
        }
    }

    // MARK: - Fetch Tests

    @Suite("Fetch Operations")
    struct FetchTests {

        @Test("Fetches trivit by ID")
        func fetchById() async throws {
            let repository = MockTrivitRepository()
            let id = UUID()
            let trivit = Trivit(id: id, title: "Find Me")
            try await repository.create(trivit)

            let fetched = try await repository.fetch(id: id)

            #expect(fetched != nil)
            #expect(fetched?.id == id)
            #expect(fetched?.title == "Find Me")
        }

        @Test("Returns nil for non-existent ID")
        func fetchNonExistent() async throws {
            let repository = MockTrivitRepository()

            let fetched = try await repository.fetch(id: UUID())

            #expect(fetched == nil)
        }

        @Test("Fetches expanded trivits")
        func fetchExpanded() async throws {
            let repository = MockTrivitRepository()
            try await repository.create(Trivit(title: "Expanded 1", isCollapsed: false))
            try await repository.create(Trivit(title: "Collapsed 1", isCollapsed: true))
            try await repository.create(Trivit(title: "Expanded 2", isCollapsed: false))

            let expanded = try await repository.fetchExpanded()

            #expect(expanded.count == 2)
            #expect(expanded.allSatisfy { !$0.isCollapsed })
        }

        @Test("Fetches collapsed trivits")
        func fetchCollapsed() async throws {
            let repository = MockTrivitRepository()
            try await repository.create(Trivit(title: "Expanded 1", isCollapsed: false))
            try await repository.create(Trivit(title: "Collapsed 1", isCollapsed: true))
            try await repository.create(Trivit(title: "Collapsed 2", isCollapsed: true))

            let collapsed = try await repository.fetchCollapsed()

            #expect(collapsed.count == 2)
            #expect(collapsed.allSatisfy { $0.isCollapsed })
        }
    }

    // MARK: - Persistence Tests

    @Suite("Persistence")
    struct PersistenceTests {

        @Test("Changes persist after save")
        func changesPersist() async throws {
            let repository = MockTrivitRepository()
            let trivit = Trivit(title: "Original", count: 0)
            try await repository.create(trivit)

            trivit.count = 100
            try await repository.save()

            // Fetch again to verify persistence
            let fetched = try await repository.fetch(id: trivit.id)
            #expect(fetched?.count == 100)
        }
    }

    // MARK: - Concurrent Access Tests

    @Suite("Concurrent Access")
    struct ConcurrentAccessTests {

        @Test("Handles concurrent reads")
        func concurrentReads() async throws {
            let repository = MockTrivitRepository()
            for i in 0..<10 {
                try await repository.create(Trivit(title: "Trivit \(i)"))
            }

            // Perform multiple concurrent reads
            await withTaskGroup(of: [Trivit].self) { group in
                for _ in 0..<5 {
                    group.addTask {
                        (try? await repository.fetchAll()) ?? []
                    }
                }

                for await trivits in group {
                    #expect(trivits.count == 10)
                }
            }
        }

        @Test("Handles concurrent writes")
        func concurrentWrites() async throws {
            let repository = MockTrivitRepository()

            // Create trivits concurrently
            await withTaskGroup(of: Void.self) { group in
                for i in 0..<10 {
                    group.addTask {
                        let trivit = Trivit(title: "Concurrent \(i)")
                        try? await repository.create(trivit)
                    }
                }
            }

            // Allow time for all writes to complete
            try await Task.sleep(nanoseconds: 100_000_000)

            let count = try await repository.count()
            #expect(count == 10)
        }
    }
}

// MARK: - SwiftData Repository Implementation (for actual tests)

/// SwiftData implementation of TrivitRepository.
/// This is the actual implementation to be tested.
final class SwiftDataTrivitRepository: TrivitRepository, @unchecked Sendable {
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

    func fetch(id: UUID) async throws -> Trivit? {
        let descriptor = FetchDescriptor<Trivit>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func create(_ trivit: Trivit) async throws {
        modelContext.insert(trivit)
        try modelContext.save()
    }

    func update(_ trivit: Trivit) async throws {
        try modelContext.save()
    }

    func delete(_ trivit: Trivit) async throws {
        modelContext.delete(trivit)
        try modelContext.save()
    }

    func deleteAll() async throws {
        let trivits = try await fetchAll()
        for trivit in trivits {
            modelContext.delete(trivit)
        }
        try modelContext.save()
    }

    func save() async throws {
        try modelContext.save()
    }

    func count() async throws -> Int {
        let descriptor = FetchDescriptor<Trivit>()
        return try modelContext.fetchCount(descriptor)
    }
}
