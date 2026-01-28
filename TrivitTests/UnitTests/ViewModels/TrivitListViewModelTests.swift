import Testing
import Foundation
@testable import Trivit

/// Comprehensive tests for TrivitListViewModel.
@Suite("TrivitListViewModel Tests")
@MainActor
struct TrivitListViewModelTests {

    // MARK: - Setup

    private func makeViewModel(
        trivits: [Trivit] = [],
        repositoryError: Error? = nil
    ) -> (TrivitListViewModel, MockTrivitRepository, MockHistoryRepository) {
        let repository = MockTrivitRepository()
        repository.trivits = trivits

        if let error = repositoryError {
            repository.fetchAllError = error
            repository.createError = error
            repository.updateError = error
            repository.deleteError = error
        }

        let historyRepository = MockHistoryRepository()

        let viewModel = TrivitListViewModel(
            repository: repository,
            historyRepository: historyRepository
        )

        return (viewModel, repository, historyRepository)
    }

    // MARK: - Loading Tests

    @Suite("Loading")
    struct LoadingTests {

        @Test("Loads trivits from repository")
        @MainActor
        func loadsTrivits() async {
            let testTrivits = [
                Trivit(title: "Test 1", count: 5),
                Trivit(title: "Test 2", count: 10)
            ]
            let (viewModel, repository, _) = await makeViewModel(trivits: testTrivits)

            await viewModel.loadTrivits()

            #expect(viewModel.trivits.count == 2)
            #expect(viewModel.isLoading == false)
            #expect(viewModel.error == nil)
            #expect(repository.fetchAllCalled == true)
        }

        @Test("Sets loading state during load")
        @MainActor
        func setsLoadingState() async {
            let (viewModel, repository, _) = await makeViewModel()
            repository.fetchDelay = 0.1

            let task = Task {
                await viewModel.loadTrivits()
            }

            // Give time for loading to start
            try? await Task.sleep(nanoseconds: 50_000_000)
            #expect(viewModel.isLoading == true)

            await task.value
            #expect(viewModel.isLoading == false)
        }

        @Test("Sets error on load failure")
        @MainActor
        func setsErrorOnFailure() async {
            let (viewModel, _, _) = await makeViewModel(
                repositoryError: NSError(domain: "test", code: 1)
            )

            await viewModel.loadTrivits()

            #expect(viewModel.error != nil)
            #expect(viewModel.trivits.isEmpty)
        }

        @MainActor
        private func makeViewModel(
            trivits: [Trivit] = [],
            repositoryError: Error? = nil
        ) -> (TrivitListViewModel, MockTrivitRepository, MockHistoryRepository) {
            let repository = MockTrivitRepository()
            repository.trivits = trivits
            if let error = repositoryError {
                repository.fetchAllError = error
            }
            let historyRepository = MockHistoryRepository()
            let viewModel = TrivitListViewModel(
                repository: repository,
                historyRepository: historyRepository
            )
            return (viewModel, repository, historyRepository)
        }
    }

    // MARK: - Create Tests

    @Suite("Create Trivit")
    struct CreateTests {

        @Test("Creates new trivit with placeholder title")
        @MainActor
        func createsNewTrivit() async {
            let (viewModel, repository, _) = await makeViewModel()

            let result = await viewModel.createTrivit()

            #expect(result != nil)
            #expect(viewModel.trivits.count == 1)
            #expect(repository.createCalled == true)
            #expect(viewModel.editingTrivit == result)
        }

        @Test("New trivit starts with count zero")
        @MainActor
        func startsWithZeroCount() async {
            let (viewModel, _, _) = await makeViewModel()

            let result = await viewModel.createTrivit()

            #expect(result?.count == 0)
        }

        @Test("New trivit uses next color index")
        @MainActor
        func usesNextColorIndex() async {
            let existingTrivits = [
                Trivit(title: "Existing 1", colorIndex: 0),
                Trivit(title: "Existing 2", colorIndex: 1)
            ]
            let (viewModel, _, _) = await makeViewModel(trivits: existingTrivits)
            await viewModel.loadTrivits()

            let result = await viewModel.createTrivit()

            #expect(result?.colorIndex == 2)
        }

        @Test("Handles create failure gracefully")
        @MainActor
        func handlesCreateFailure() async {
            let (viewModel, _, _) = await makeViewModel(
                repositoryError: NSError(domain: "test", code: 1)
            )

            let result = await viewModel.createTrivit()

            #expect(result == nil)
            #expect(viewModel.error != nil)
        }

        @MainActor
        private func makeViewModel(
            trivits: [Trivit] = [],
            repositoryError: Error? = nil
        ) -> (TrivitListViewModel, MockTrivitRepository, MockHistoryRepository) {
            let repository = MockTrivitRepository()
            repository.trivits = trivits
            if let error = repositoryError {
                repository.createError = error
            }
            let historyRepository = MockHistoryRepository()
            let viewModel = TrivitListViewModel(
                repository: repository,
                historyRepository: historyRepository
            )
            return (viewModel, repository, historyRepository)
        }
    }

    // MARK: - Increment Tests

    @Suite("Increment Trivit")
    struct IncrementTests {

        @Test("Increments trivit count by one")
        @MainActor
        func incrementsByOne() async {
            let trivit = Trivit(title: "Test", count: 5)
            let (viewModel, repository, _) = await makeViewModel(trivits: [trivit])
            await viewModel.loadTrivits()

            await viewModel.incrementTrivit(trivit)

            #expect(trivit.count == 6)
            #expect(repository.updateCalled == true)
        }

        @Test("Records history on increment")
        @MainActor
        func recordsHistory() async {
            let trivit = Trivit(title: "Test", count: 5)
            let (viewModel, _, historyRepository) = await makeViewModel(trivits: [trivit])
            await viewModel.loadTrivits()

            await viewModel.incrementTrivit(trivit)

            #expect(historyRepository.recordCalled == true)
            #expect(historyRepository.recordCalledWith?.changeType == .increment)
            #expect(historyRepository.recordCalledWith?.previousCount == 5)
        }

        @Test("Rolls back on update failure")
        @MainActor
        func rollsBackOnFailure() async {
            let trivit = Trivit(title: "Test", count: 5)
            let repository = MockTrivitRepository()
            repository.trivits = [trivit]
            repository.updateError = NSError(domain: "test", code: 1)
            let viewModel = TrivitListViewModel(repository: repository)
            await viewModel.loadTrivits()

            await viewModel.incrementTrivit(trivit)

            #expect(trivit.count == 5)  // Rolled back
            #expect(viewModel.error != nil)
        }

        @MainActor
        private func makeViewModel(
            trivits: [Trivit] = [],
            repositoryError: Error? = nil
        ) -> (TrivitListViewModel, MockTrivitRepository, MockHistoryRepository) {
            let repository = MockTrivitRepository()
            repository.trivits = trivits
            if let error = repositoryError {
                repository.updateError = error
            }
            let historyRepository = MockHistoryRepository()
            let viewModel = TrivitListViewModel(
                repository: repository,
                historyRepository: historyRepository
            )
            return (viewModel, repository, historyRepository)
        }
    }

    // MARK: - Decrement Tests

    @Suite("Decrement Trivit")
    struct DecrementTests {

        @Test("Decrements trivit count by one")
        @MainActor
        func decrementsByOne() async {
            let trivit = Trivit(title: "Test", count: 5)
            let (viewModel, repository, _) = await makeViewModel(trivits: [trivit])
            await viewModel.loadTrivits()

            await viewModel.decrementTrivit(trivit)

            #expect(trivit.count == 4)
            #expect(repository.updateCalled == true)
        }

        @Test("Does not decrement below zero")
        @MainActor
        func doesNotGoBelowZero() async {
            let trivit = Trivit(title: "Test", count: 0)
            let (viewModel, repository, _) = await makeViewModel(trivits: [trivit])
            await viewModel.loadTrivits()

            await viewModel.decrementTrivit(trivit)

            #expect(trivit.count == 0)
            #expect(repository.updateCalled == false)
        }

        @Test("Records history on decrement")
        @MainActor
        func recordsHistory() async {
            let trivit = Trivit(title: "Test", count: 5)
            let (viewModel, _, historyRepository) = await makeViewModel(trivits: [trivit])
            await viewModel.loadTrivits()

            await viewModel.decrementTrivit(trivit)

            #expect(historyRepository.recordCalled == true)
            #expect(historyRepository.recordCalledWith?.changeType == .decrement)
        }

        @MainActor
        private func makeViewModel(
            trivits: [Trivit] = [],
            repositoryError: Error? = nil
        ) -> (TrivitListViewModel, MockTrivitRepository, MockHistoryRepository) {
            let repository = MockTrivitRepository()
            repository.trivits = trivits
            let historyRepository = MockHistoryRepository()
            let viewModel = TrivitListViewModel(
                repository: repository,
                historyRepository: historyRepository
            )
            return (viewModel, repository, historyRepository)
        }
    }

    // MARK: - Reset Tests

    @Suite("Reset Trivit")
    struct ResetTests {

        @Test("Resets trivit count to zero")
        @MainActor
        func resetsToZero() async {
            let trivit = Trivit(title: "Test", count: 42)
            let (viewModel, repository, _) = await makeViewModel(trivits: [trivit])
            await viewModel.loadTrivits()

            await viewModel.resetTrivit(trivit)

            #expect(trivit.count == 0)
            #expect(repository.updateCalled == true)
        }

        @Test("Does nothing if already at zero")
        @MainActor
        func doesNothingAtZero() async {
            let trivit = Trivit(title: "Test", count: 0)
            let (viewModel, repository, _) = await makeViewModel(trivits: [trivit])
            await viewModel.loadTrivits()

            await viewModel.resetTrivit(trivit)

            #expect(trivit.count == 0)
            #expect(repository.updateCalled == false)
        }

        @Test("Records history on reset")
        @MainActor
        func recordsHistory() async {
            let trivit = Trivit(title: "Test", count: 42)
            let (viewModel, _, historyRepository) = await makeViewModel(trivits: [trivit])
            await viewModel.loadTrivits()

            await viewModel.resetTrivit(trivit)

            #expect(historyRepository.recordCalled == true)
            #expect(historyRepository.recordCalledWith?.changeType == .reset)
            #expect(historyRepository.recordCalledWith?.previousCount == 42)
        }

        @MainActor
        private func makeViewModel(
            trivits: [Trivit] = [],
            repositoryError: Error? = nil
        ) -> (TrivitListViewModel, MockTrivitRepository, MockHistoryRepository) {
            let repository = MockTrivitRepository()
            repository.trivits = trivits
            let historyRepository = MockHistoryRepository()
            let viewModel = TrivitListViewModel(
                repository: repository,
                historyRepository: historyRepository
            )
            return (viewModel, repository, historyRepository)
        }
    }

    // MARK: - Delete Tests

    @Suite("Delete Trivit")
    struct DeleteTests {

        @Test("Deletes trivit from repository")
        @MainActor
        func deletesTrivit() async {
            let trivit = Trivit(title: "Test", count: 5)
            let (viewModel, repository, _) = await makeViewModel(trivits: [trivit])
            await viewModel.loadTrivits()

            await viewModel.deleteTrivit(trivit)

            #expect(viewModel.trivits.isEmpty)
            #expect(repository.deleteCalled == true)
            #expect(repository.deleteCalledWith?.id == trivit.id)
        }

        @Test("Deletes at offsets")
        @MainActor
        func deletesAtOffsets() async {
            let trivits = [
                Trivit(title: "Test 1"),
                Trivit(title: "Test 2"),
                Trivit(title: "Test 3")
            ]
            let (viewModel, repository, _) = await makeViewModel(trivits: trivits)
            await viewModel.loadTrivits()

            await viewModel.deleteTrivits(at: IndexSet([1]))

            #expect(viewModel.trivits.count == 2)
            #expect(repository.deleteCount == 1)
        }

        @MainActor
        private func makeViewModel(
            trivits: [Trivit] = [],
            repositoryError: Error? = nil
        ) -> (TrivitListViewModel, MockTrivitRepository, MockHistoryRepository) {
            let repository = MockTrivitRepository()
            repository.trivits = trivits
            let historyRepository = MockHistoryRepository()
            let viewModel = TrivitListViewModel(
                repository: repository,
                historyRepository: historyRepository
            )
            return (viewModel, repository, historyRepository)
        }
    }

    // MARK: - Rename Tests

    @Suite("Rename Trivit")
    struct RenameTests {

        @Test("Renames trivit successfully")
        @MainActor
        func renamesTrivit() async {
            let trivit = Trivit(title: "Old Name")
            let (viewModel, repository, _) = await makeViewModel(trivits: [trivit])
            await viewModel.loadTrivits()

            await viewModel.renameTrivit(trivit, to: "New Name")

            #expect(trivit.title == "New Name")
            #expect(repository.updateCalled == true)
            #expect(viewModel.editingTrivit == nil)
        }

        @Test("Trims whitespace from title")
        @MainActor
        func trimsWhitespace() async {
            let trivit = Trivit(title: "Old Name")
            let (viewModel, _, _) = await makeViewModel(trivits: [trivit])
            await viewModel.loadTrivits()

            await viewModel.renameTrivit(trivit, to: "  New Name  ")

            #expect(trivit.title == "New Name")
        }

        @Test("Ignores empty title")
        @MainActor
        func ignoresEmptyTitle() async {
            let trivit = Trivit(title: "Old Name")
            let (viewModel, repository, _) = await makeViewModel(trivits: [trivit])
            await viewModel.loadTrivits()

            await viewModel.renameTrivit(trivit, to: "")

            #expect(trivit.title == "Old Name")
            #expect(repository.updateCalled == false)
        }

        @Test("Detects Chinese tally type from underscore prefix")
        @MainActor
        func detectsChineseTallyType() async {
            let trivit = Trivit(title: "Old Name", tallyType: .western)
            let (viewModel, _, _) = await makeViewModel(trivits: [trivit])
            await viewModel.loadTrivits()

            await viewModel.renameTrivit(trivit, to: "_Chinese Counter")

            #expect(trivit.tallyType == .chinese)
        }

        @MainActor
        private func makeViewModel(
            trivits: [Trivit] = [],
            repositoryError: Error? = nil
        ) -> (TrivitListViewModel, MockTrivitRepository, MockHistoryRepository) {
            let repository = MockTrivitRepository()
            repository.trivits = trivits
            let historyRepository = MockHistoryRepository()
            let viewModel = TrivitListViewModel(
                repository: repository,
                historyRepository: historyRepository
            )
            return (viewModel, repository, historyRepository)
        }
    }

    // MARK: - Collapse/Expand Tests

    @Suite("Collapse and Expand")
    struct CollapseExpandTests {

        @Test("Toggles collapsed state")
        @MainActor
        func togglesCollapsed() async {
            let trivit = Trivit(title: "Test", isCollapsed: true)
            let (viewModel, repository, _) = await makeViewModel(trivits: [trivit])
            await viewModel.loadTrivits()

            await viewModel.toggleCollapsed(trivit)

            #expect(trivit.isCollapsed == false)
            #expect(repository.updateCalled == true)
        }

        @Test("Expands all trivits")
        @MainActor
        func expandsAll() async {
            let trivits = [
                Trivit(title: "Test 1", isCollapsed: true),
                Trivit(title: "Test 2", isCollapsed: true),
                Trivit(title: "Test 3", isCollapsed: false)
            ]
            let (viewModel, repository, _) = await makeViewModel(trivits: trivits)
            await viewModel.loadTrivits()

            await viewModel.expandAll()

            #expect(viewModel.trivits.allSatisfy { !$0.isCollapsed })
            #expect(repository.saveCalled == true)
        }

        @Test("Collapses all trivits")
        @MainActor
        func collapsesAll() async {
            let trivits = [
                Trivit(title: "Test 1", isCollapsed: false),
                Trivit(title: "Test 2", isCollapsed: true),
                Trivit(title: "Test 3", isCollapsed: false)
            ]
            let (viewModel, repository, _) = await makeViewModel(trivits: trivits)
            await viewModel.loadTrivits()

            await viewModel.collapseAll()

            #expect(viewModel.trivits.allSatisfy { $0.isCollapsed })
            #expect(repository.saveCalled == true)
        }

        @MainActor
        private func makeViewModel(
            trivits: [Trivit] = [],
            repositoryError: Error? = nil
        ) -> (TrivitListViewModel, MockTrivitRepository, MockHistoryRepository) {
            let repository = MockTrivitRepository()
            repository.trivits = trivits
            let historyRepository = MockHistoryRepository()
            let viewModel = TrivitListViewModel(
                repository: repository,
                historyRepository: historyRepository
            )
            return (viewModel, repository, historyRepository)
        }
    }

    // MARK: - Search Tests

    @Suite("Search")
    struct SearchTests {

        @Test("Filters trivits by search query")
        @MainActor
        func filtersbyQuery() async {
            let trivits = [
                Trivit(title: "Coffee cups"),
                Trivit(title: "Push ups"),
                Trivit(title: "Coffee beans")
            ]
            let (viewModel, _, _) = await makeViewModel(trivits: trivits)
            await viewModel.loadTrivits()

            viewModel.searchQuery = "coffee"

            #expect(viewModel.filteredTrivits.count == 2)
            #expect(viewModel.filteredTrivits.allSatisfy { $0.title.lowercased().contains("coffee") })
        }

        @Test("Empty query returns all trivits")
        @MainActor
        func emptyQueryReturnsAll() async {
            let trivits = [
                Trivit(title: "Coffee cups"),
                Trivit(title: "Push ups")
            ]
            let (viewModel, _, _) = await makeViewModel(trivits: trivits)
            await viewModel.loadTrivits()

            viewModel.searchQuery = ""

            #expect(viewModel.filteredTrivits.count == 2)
        }

        @Test("Search is case insensitive")
        @MainActor
        func caseInsensitive() async {
            let trivits = [
                Trivit(title: "Coffee Cups"),
                Trivit(title: "TEA cups")
            ]
            let (viewModel, _, _) = await makeViewModel(trivits: trivits)
            await viewModel.loadTrivits()

            viewModel.searchQuery = "CUPS"

            #expect(viewModel.filteredTrivits.count == 2)
        }

        @MainActor
        private func makeViewModel(
            trivits: [Trivit] = [],
            repositoryError: Error? = nil
        ) -> (TrivitListViewModel, MockTrivitRepository, MockHistoryRepository) {
            let repository = MockTrivitRepository()
            repository.trivits = trivits
            let historyRepository = MockHistoryRepository()
            let viewModel = TrivitListViewModel(
                repository: repository,
                historyRepository: historyRepository
            )
            return (viewModel, repository, historyRepository)
        }
    }

    // MARK: - Error Handling Tests

    @Suite("Error Handling")
    struct ErrorHandlingTests {

        @Test("Dismiss error clears error state")
        @MainActor
        func dismissErrorClearsState() async {
            let (viewModel, _, _) = await makeViewModel(
                repositoryError: NSError(domain: "test", code: 1)
            )
            await viewModel.loadTrivits()
            #expect(viewModel.error != nil)

            viewModel.dismissError()

            #expect(viewModel.error == nil)
        }

        @MainActor
        private func makeViewModel(
            trivits: [Trivit] = [],
            repositoryError: Error? = nil
        ) -> (TrivitListViewModel, MockTrivitRepository, MockHistoryRepository) {
            let repository = MockTrivitRepository()
            repository.trivits = trivits
            if let error = repositoryError {
                repository.fetchAllError = error
            }
            let historyRepository = MockHistoryRepository()
            let viewModel = TrivitListViewModel(
                repository: repository,
                historyRepository: historyRepository
            )
            return (viewModel, repository, historyRepository)
        }
    }
}
