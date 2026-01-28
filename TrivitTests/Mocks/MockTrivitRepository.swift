import Foundation
@testable import Trivit

/// Mock implementation of TrivitRepository for testing.
///
/// Tracks all method calls and allows configuration of responses.
final class MockTrivitRepository: TrivitRepository, @unchecked Sendable {
    // MARK: - Stored Data

    var trivits: [Trivit] = []

    // MARK: - Call Tracking

    var fetchAllCalled = false
    var fetchAllCount = 0

    var fetchIdCalled = false
    var fetchIdCalledWith: UUID?

    var createCalled = false
    var createCalledWith: Trivit?
    var createCount = 0

    var updateCalled = false
    var updateCalledWith: Trivit?
    var updateCount = 0

    var deleteCalled = false
    var deleteCalledWith: Trivit?
    var deleteCount = 0

    var deleteAllCalled = false
    var saveCalled = false
    var countCalled = false

    // MARK: - Error Configuration

    var fetchAllError: Error?
    var fetchIdError: Error?
    var createError: Error?
    var updateError: Error?
    var deleteError: Error?
    var deleteAllError: Error?
    var saveError: Error?

    // MARK: - Delays (for testing async behavior)

    var fetchDelay: TimeInterval = 0
    var saveDelay: TimeInterval = 0

    // MARK: - TrivitRepository Implementation

    func fetchAll() async throws -> [Trivit] {
        fetchAllCalled = true
        fetchAllCount += 1

        if fetchDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(fetchDelay * 1_000_000_000))
        }

        if let error = fetchAllError {
            throw error
        }

        return trivits
    }

    func fetch(id: UUID) async throws -> Trivit? {
        fetchIdCalled = true
        fetchIdCalledWith = id

        if let error = fetchIdError {
            throw error
        }

        return trivits.first { $0.id == id }
    }

    func create(_ trivit: Trivit) async throws {
        createCalled = true
        createCalledWith = trivit
        createCount += 1

        if let error = createError {
            throw error
        }

        trivits.append(trivit)
    }

    func update(_ trivit: Trivit) async throws {
        updateCalled = true
        updateCalledWith = trivit
        updateCount += 1

        if saveDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(saveDelay * 1_000_000_000))
        }

        if let error = updateError {
            throw error
        }

        // Simulate update by finding and replacing
        if let index = trivits.firstIndex(where: { $0.id == trivit.id }) {
            trivits[index] = trivit
        }
    }

    func delete(_ trivit: Trivit) async throws {
        deleteCalled = true
        deleteCalledWith = trivit
        deleteCount += 1

        if let error = deleteError {
            throw error
        }

        trivits.removeAll { $0.id == trivit.id }
    }

    func deleteAll() async throws {
        deleteAllCalled = true

        if let error = deleteAllError {
            throw error
        }

        trivits.removeAll()
    }

    func save() async throws {
        saveCalled = true

        if let error = saveError {
            throw error
        }
    }

    func count() async throws -> Int {
        countCalled = true
        return trivits.count
    }

    // MARK: - Test Helpers

    /// Resets all tracking state.
    func reset() {
        fetchAllCalled = false
        fetchAllCount = 0
        fetchIdCalled = false
        fetchIdCalledWith = nil
        createCalled = false
        createCalledWith = nil
        createCount = 0
        updateCalled = false
        updateCalledWith = nil
        updateCount = 0
        deleteCalled = false
        deleteCalledWith = nil
        deleteCount = 0
        deleteAllCalled = false
        saveCalled = false
        countCalled = false

        fetchAllError = nil
        fetchIdError = nil
        createError = nil
        updateError = nil
        deleteError = nil
        deleteAllError = nil
        saveError = nil
    }

    /// Seeds the repository with test trivits.
    func seed(count: Int) {
        trivits = (0..<count).map { index in
            Trivit(
                title: "Test Trivit \(index + 1)",
                count: index * 5,
                colorIndex: index
            )
        }
    }
}
