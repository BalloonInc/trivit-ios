import Testing
import Foundation
@testable import Trivit

/// Comprehensive tests for the Trivit entity.
@Suite("Trivit Entity Tests")
struct TrivitTests {

    // MARK: - Initialization Tests

    @Suite("Initialization")
    struct InitializationTests {

        @Test("Creates trivit with default values")
        func defaultValues() {
            let trivit = Trivit(title: "Test")

            #expect(trivit.title == "Test")
            #expect(trivit.count == 0)
            #expect(trivit.colorIndex == 0)
            #expect(trivit.isCollapsed == true)
            #expect(trivit.tallyType == .western)
            #expect(trivit.id != UUID())  // Has a unique ID
        }

        @Test("Creates trivit with custom values")
        func customValues() {
            let customId = UUID()
            let customDate = Date.distantPast

            let trivit = Trivit(
                id: customId,
                title: "Custom",
                count: 42,
                colorIndex: 5,
                isCollapsed: false,
                createdAt: customDate,
                tallyType: .chinese
            )

            #expect(trivit.id == customId)
            #expect(trivit.title == "Custom")
            #expect(trivit.count == 42)
            #expect(trivit.colorIndex == 5)
            #expect(trivit.isCollapsed == false)
            #expect(trivit.createdAt == customDate)
            #expect(trivit.tallyType == .chinese)
        }

        @Test("Clamps negative count to zero")
        func negativeCountClamped() {
            let trivit = Trivit(title: "Test", count: -10)

            #expect(trivit.count == 0)
        }
    }

    // MARK: - Computed Properties Tests

    @Suite("Computed Properties")
    struct ComputedPropertiesTests {

        @Test("Calculates complete groups correctly")
        func completeGroups() {
            #expect(Trivit(title: "T", count: 0).completeGroups == 0)
            #expect(Trivit(title: "T", count: 4).completeGroups == 0)
            #expect(Trivit(title: "T", count: 5).completeGroups == 1)
            #expect(Trivit(title: "T", count: 9).completeGroups == 1)
            #expect(Trivit(title: "T", count: 10).completeGroups == 2)
            #expect(Trivit(title: "T", count: 27).completeGroups == 5)
        }

        @Test("Calculates remainder marks correctly")
        func remainderMarks() {
            #expect(Trivit(title: "T", count: 0).remainderMarks == 0)
            #expect(Trivit(title: "T", count: 1).remainderMarks == 1)
            #expect(Trivit(title: "T", count: 4).remainderMarks == 4)
            #expect(Trivit(title: "T", count: 5).remainderMarks == 0)
            #expect(Trivit(title: "T", count: 7).remainderMarks == 2)
            #expect(Trivit(title: "T", count: 27).remainderMarks == 2)
        }

        @Test("Calculates tally image count correctly")
        func tallyImageCount() {
            #expect(Trivit(title: "T", count: 0).tallyImageCount == 0)
            #expect(Trivit(title: "T", count: 1).tallyImageCount == 1)
            #expect(Trivit(title: "T", count: 5).tallyImageCount == 1)
            #expect(Trivit(title: "T", count: 6).tallyImageCount == 2)
            #expect(Trivit(title: "T", count: 10).tallyImageCount == 2)
            #expect(Trivit(title: "T", count: 27).tallyImageCount == 6)
        }

        @Test("Reports max count correctly")
        func isAtMaxCount() {
            let normalTrivit = Trivit(title: "T", count: 1000)
            #expect(normalTrivit.isAtMaxCount == false)

            let maxTrivit = Trivit(title: "T", count: Int.max - 1)
            #expect(maxTrivit.isAtMaxCount == true)

            let overMaxTrivit = Trivit(title: "T", count: Int.max)
            #expect(overMaxTrivit.isAtMaxCount == true)
        }

        @Test("Reports can decrement correctly")
        func canDecrement() {
            #expect(Trivit(title: "T", count: 0).canDecrement == false)
            #expect(Trivit(title: "T", count: 1).canDecrement == true)
            #expect(Trivit(title: "T", count: 100).canDecrement == true)
        }
    }

    // MARK: - Increment Tests

    @Suite("Increment")
    struct IncrementTests {

        @Test("Increments count by one")
        func incrementsByOne() {
            let trivit = Trivit(title: "Test", count: 5)

            let result = trivit.increment()

            #expect(result == true)
            #expect(trivit.count == 6)
        }

        @Test("Increments from zero")
        func incrementsFromZero() {
            let trivit = Trivit(title: "Test", count: 0)

            let result = trivit.increment()

            #expect(result == true)
            #expect(trivit.count == 1)
        }

        @Test("Does not overflow at max value")
        func doesNotOverflow() {
            let trivit = Trivit(title: "Test", count: Int.max - 1)

            let result = trivit.increment()

            #expect(result == false)
            #expect(trivit.count == Int.max - 1)
        }

        @Test("Multiple increments accumulate")
        func multipleIncrements() {
            let trivit = Trivit(title: "Test", count: 0)

            for _ in 0..<10 {
                trivit.increment()
            }

            #expect(trivit.count == 10)
        }
    }

    // MARK: - Decrement Tests

    @Suite("Decrement")
    struct DecrementTests {

        @Test("Decrements count by one")
        func decrementsByOne() {
            let trivit = Trivit(title: "Test", count: 5)

            let result = trivit.decrement()

            #expect(result == true)
            #expect(trivit.count == 4)
        }

        @Test("Does not decrement below zero")
        func doesNotGoBelowZero() {
            let trivit = Trivit(title: "Test", count: 0)

            let result = trivit.decrement()

            #expect(result == false)
            #expect(trivit.count == 0)
        }

        @Test("Decrements to zero successfully")
        func decrementsToZero() {
            let trivit = Trivit(title: "Test", count: 1)

            let result = trivit.decrement()

            #expect(result == true)
            #expect(trivit.count == 0)
        }

        @Test("Multiple decrements work correctly")
        func multipleDecrements() {
            let trivit = Trivit(title: "Test", count: 10)

            for _ in 0..<5 {
                trivit.decrement()
            }

            #expect(trivit.count == 5)
        }
    }

    // MARK: - Reset Tests

    @Suite("Reset")
    struct ResetTests {

        @Test("Resets count to zero")
        func resetsToZero() {
            let trivit = Trivit(title: "Test", count: 42)

            trivit.reset()

            #expect(trivit.count == 0)
        }

        @Test("Reset when already zero is safe")
        func resetAtZeroIsSafe() {
            let trivit = Trivit(title: "Test", count: 0)

            trivit.reset()

            #expect(trivit.count == 0)
        }

        @Test("Reset from high count works")
        func resetFromHighCount() {
            let trivit = Trivit(title: "Test", count: 999999)

            trivit.reset()

            #expect(trivit.count == 0)
        }
    }

    // MARK: - Toggle Collapsed Tests

    @Suite("Toggle Collapsed")
    struct ToggleCollapsedTests {

        @Test("Toggles from collapsed to expanded")
        func togglesFromCollapsedToExpanded() {
            let trivit = Trivit(title: "Test", isCollapsed: true)

            trivit.toggleCollapsed()

            #expect(trivit.isCollapsed == false)
        }

        @Test("Toggles from expanded to collapsed")
        func togglesFromExpandedToCollapsed() {
            let trivit = Trivit(title: "Test", count: 10, isCollapsed: false)

            trivit.toggleCollapsed()

            #expect(trivit.isCollapsed == true)
        }

        @Test("Multiple toggles work correctly")
        func multipleToggles() {
            let trivit = Trivit(title: "Test", isCollapsed: true)

            trivit.toggleCollapsed()
            #expect(trivit.isCollapsed == false)

            trivit.toggleCollapsed()
            #expect(trivit.isCollapsed == true)

            trivit.toggleCollapsed()
            #expect(trivit.isCollapsed == false)
        }
    }

    // MARK: - Equality Tests

    @Suite("Equality")
    struct EqualityTests {

        @Test("Trivits with same ID are equal")
        func sameIdEquals() {
            let id = UUID()
            let trivit1 = Trivit(id: id, title: "One", count: 5)
            let trivit2 = Trivit(id: id, title: "Two", count: 10)

            #expect(trivit1 == trivit2)
        }

        @Test("Trivits with different IDs are not equal")
        func differentIdNotEquals() {
            let trivit1 = Trivit(title: "One", count: 5)
            let trivit2 = Trivit(title: "One", count: 5)

            #expect(trivit1 != trivit2)
        }
    }
}

// MARK: - TallyType Tests

@Suite("TallyType Tests")
struct TallyTypeTests {

    @Test("Western type has correct image prefix")
    func westernImagePrefix() {
        #expect(TallyType.western.imagePrefix == "tally_")
    }

    @Test("Chinese type has correct image prefix")
    func chineseImagePrefix() {
        #expect(TallyType.chinese.imagePrefix == "tally_ch_")
    }

    @Test("Image names are generated correctly for western")
    func westernImageNames() {
        let western = TallyType.western
        #expect(western.imageName(for: 1) == "tally_1")
        #expect(western.imageName(for: 5) == "tally_5")
    }

    @Test("Image names are generated correctly for chinese")
    func chineseImageNames() {
        let chinese = TallyType.chinese
        #expect(chinese.imageName(for: 1) == "tally_ch_1")
        #expect(chinese.imageName(for: 5) == "tally_ch_5")
    }

    @Test("Image names clamp to valid range")
    func imageNamesClampedToValidRange() {
        let western = TallyType.western
        #expect(western.imageName(for: 0) == "tally_1")
        #expect(western.imageName(for: -5) == "tally_1")
        #expect(western.imageName(for: 10) == "tally_5")
    }

    @Test("All tally types are enumerable")
    func allCases() {
        #expect(TallyType.allCases.count == 2)
        #expect(TallyType.allCases.contains(.western))
        #expect(TallyType.allCases.contains(.chinese))
    }
}

// MARK: - ChangeType Tests

@Suite("ChangeType Tests")
struct ChangeTypeTests {

    @Test("All change types have display names")
    func displayNames() {
        for changeType in ChangeType.allCases {
            #expect(!changeType.displayName.isEmpty)
        }
    }

    @Test("All change types have symbol names")
    func symbolNames() {
        for changeType in ChangeType.allCases {
            #expect(!changeType.symbolName.isEmpty)
            #expect(changeType.symbolName.contains(".circle"))
        }
    }

    @Test("All cases are enumerable")
    func allCases() {
        #expect(ChangeType.allCases.count == 4)
        #expect(ChangeType.allCases.contains(.increment))
        #expect(ChangeType.allCases.contains(.decrement))
        #expect(ChangeType.allCases.contains(.reset))
        #expect(ChangeType.allCases.contains(.set))
    }
}
