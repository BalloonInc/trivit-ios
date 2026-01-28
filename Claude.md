# Claude.md - AI Development Best Practices for Trivit

## Project Context

Trivit is a SwiftUI tally counter app being modernized from Objective-C/UIKit. This document provides context and best practices for AI-assisted development.

---

## Project Guidelines

### Code Style

#### Swift Style
- Use Swift 5.9+ features
- Prefer value types (structs, enums) over reference types where appropriate
- Use meaningful variable and function names
- Follow Swift API Design Guidelines
- Use trailing closure syntax when appropriate
- Prefer `guard` for early returns
- Use `async/await` over completion handlers

#### SwiftUI Patterns
```swift
// GOOD: Small, focused views
struct TrivitRowView: View {
    let trivit: Trivit
    let onIncrement: () -> Void

    var body: some View {
        // Concise view code
    }
}

// GOOD: Extract complex logic to ViewModels
@Observable
class TrivitListViewModel {
    var trivits: [Trivit] = []

    func increment(_ trivit: Trivit) async {
        // Business logic here
    }
}

// BAD: Massive view with embedded logic
struct BadView: View {
    @State private var data: [Item] = []

    var body: some View {
        // 200+ lines of view code with embedded logic
    }
}
```

#### Naming Conventions
- Views: `*View` (e.g., `TrivitRowView`)
- ViewModels: `*ViewModel` (e.g., `TrivitListViewModel`)
- Models: Plain names (e.g., `Trivit`, `TrivitHistory`)
- Protocols: Descriptive names (e.g., `TrivitRepository`)
- Extensions: `Type+Feature` (e.g., `Color+Theme`)

### Architecture Rules

1. **Separation of Concerns**
   - Views only handle UI rendering
   - ViewModels handle business logic and state
   - Repositories handle data persistence
   - Services handle external integrations

2. **Dependency Injection**
   - Use protocols for dependencies
   - Inject via initializers or environment
   - Enable easy mocking for tests

3. **State Management**
   - Use `@Observable` for ViewModels
   - Use `@State` for view-local state
   - Use `@Environment` for shared dependencies

### Testing Requirements

#### Unit Tests
Every public function should have tests covering:
- Happy path
- Edge cases
- Error conditions

```swift
@Test func incrementTrivit_increasesCountByOne() async {
    let viewModel = TrivitListViewModel(repository: MockRepository())
    let trivit = Trivit(title: "Test", count: 5)

    await viewModel.increment(trivit)

    #expect(trivit.count == 6)
}

@Test func incrementTrivit_atMaxValue_doesNotOverflow() async {
    // Edge case testing
}
```

#### Integration Tests
- Test SwiftData persistence
- Test CloudKit sync
- Test Watch connectivity

#### UI Tests
- Test complete user flows
- Test accessibility
- Test different device sizes

### File Organization

```
Feature/
├── Views/
│   └── FeatureView.swift      # Main view
├── ViewModels/
│   └── FeatureViewModel.swift # View state & logic
├── Components/
│   └── FeatureComponent.swift # Reusable subviews
└── Tests/
    └── FeatureViewModelTests.swift
```

---

## AI Assistant Instructions

### When Writing Code

1. **Always include tests** - Write tests alongside implementation
2. **Follow existing patterns** - Match the established architecture
3. **Add documentation** - Include doc comments for public APIs
4. **Consider accessibility** - Add accessibility modifiers
5. **Handle errors gracefully** - Use proper error handling

### When Reviewing Code

Look for:
- Missing tests
- Accessibility issues
- Memory leaks (retain cycles)
- Performance concerns
- Thread safety issues

### When Fixing Bugs

1. Write a failing test first
2. Fix the bug
3. Verify the test passes
4. Check for similar issues elsewhere

---

## Common Patterns

### SwiftData Model

```swift
import SwiftData

@Model
final class Trivit {
    var id: UUID
    var title: String
    var count: Int
    var colorIndex: Int
    var isCollapsed: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
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
}
```

### Repository Pattern

```swift
protocol TrivitRepository {
    func fetchAll() async throws -> [Trivit]
    func save(_ trivit: Trivit) async throws
    func delete(_ trivit: Trivit) async throws
}

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
        modelContext.insert(trivit)
        try modelContext.save()
    }

    func delete(_ trivit: Trivit) async throws {
        modelContext.delete(trivit)
        try modelContext.save()
    }
}
```

### ViewModel

```swift
import SwiftUI

@Observable
final class TrivitListViewModel {
    private(set) var trivits: [Trivit] = []
    private(set) var isLoading = false
    private(set) var error: Error?

    private let repository: TrivitRepository
    private let hapticsService: HapticsService

    init(
        repository: TrivitRepository,
        hapticsService: HapticsService = .shared
    ) {
        self.repository = repository
        self.hapticsService = hapticsService
    }

    @MainActor
    func loadTrivits() async {
        isLoading = true
        defer { isLoading = false }

        do {
            trivits = try await repository.fetchAll()
        } catch {
            self.error = error
        }
    }

    @MainActor
    func increment(_ trivit: Trivit) async {
        trivit.count += 1
        hapticsService.impact(.light)

        do {
            try await repository.save(trivit)
        } catch {
            trivit.count -= 1
            self.error = error
        }
    }
}
```

### SwiftUI View

```swift
import SwiftUI

struct TrivitListView: View {
    @State private var viewModel: TrivitListViewModel

    init(repository: TrivitRepository) {
        _viewModel = State(initialValue: TrivitListViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Trivits")
                .toolbar { toolbarContent }
        }
        .task { await viewModel.loadTrivits() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView()
        } else if viewModel.trivits.isEmpty {
            ContentUnavailableView(
                "No Trivits",
                systemImage: "tally",
                description: Text("Tap + to create your first counter")
            )
        } else {
            trivitList
        }
    }

    private var trivitList: some View {
        List(viewModel.trivits) { trivit in
            TrivitRowView(
                trivit: trivit,
                onIncrement: { Task { await viewModel.increment(trivit) } }
            )
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(action: { /* add */ }) {
                Image(systemName: "plus")
            }
        }
    }
}
```

### Test with Swift Testing

```swift
import Testing
@testable import Trivit

struct TrivitListViewModelTests {
    @Test("Load trivits populates list")
    func loadTrivits() async {
        let repository = MockTrivitRepository()
        repository.trivits = [
            Trivit(title: "Test 1", count: 5),
            Trivit(title: "Test 2", count: 10)
        ]
        let viewModel = TrivitListViewModel(repository: repository)

        await viewModel.loadTrivits()

        #expect(viewModel.trivits.count == 2)
        #expect(viewModel.trivits[0].title == "Test 1")
    }

    @Test("Increment increases count")
    func incrementTrivit() async {
        let repository = MockTrivitRepository()
        let trivit = Trivit(title: "Test", count: 5)
        let viewModel = TrivitListViewModel(repository: repository)

        await viewModel.increment(trivit)

        #expect(trivit.count == 6)
        #expect(repository.saveCalled)
    }

    @Test("Increment at max value is handled")
    func incrementAtMax() async {
        let repository = MockTrivitRepository()
        let trivit = Trivit(title: "Test", count: Int.max)
        let viewModel = TrivitListViewModel(repository: repository)

        await viewModel.increment(trivit)

        // Should not overflow
        #expect(trivit.count == Int.max)
    }
}

final class MockTrivitRepository: TrivitRepository {
    var trivits: [Trivit] = []
    var saveCalled = false
    var deleteCalled = false

    func fetchAll() async throws -> [Trivit] { trivits }
    func save(_ trivit: Trivit) async throws { saveCalled = true }
    func delete(_ trivit: Trivit) async throws { deleteCalled = true }
}
```

---

## Error Handling

### Custom Errors

```swift
enum TrivitError: LocalizedError {
    case saveFailed
    case loadFailed
    case syncFailed
    case invalidCount

    var errorDescription: String? {
        switch self {
        case .saveFailed: "Failed to save changes"
        case .loadFailed: "Failed to load data"
        case .syncFailed: "Sync failed"
        case .invalidCount: "Invalid count value"
        }
    }
}
```

### Error Presentation

```swift
struct TrivitListView: View {
    @State private var viewModel: TrivitListViewModel

    var body: some View {
        content
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") { viewModel.error = nil }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "Unknown error")
            }
    }
}
```

---

## Accessibility

### Required Modifiers

```swift
TrivitRowView(trivit: trivit)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(trivit.title), count: \(trivit.count)")
    .accessibilityHint("Double tap to increment")
    .accessibilityAddTraits(.isButton)

Button(action: increment) {
    Text("+")
}
.accessibilityLabel("Increment \(trivit.title)")
```

---

## Performance

### Best Practices

1. Use `LazyVStack` for long lists
2. Avoid heavy computation in view body
3. Use `@State` appropriately (not for large data)
4. Profile with Instruments before optimizing

### Lazy Loading

```swift
ScrollView {
    LazyVStack(spacing: 0) {
        ForEach(viewModel.trivits) { trivit in
            TrivitRowView(trivit: trivit)
        }
    }
}
```

---

## Localization

### String Catalog Usage

```swift
// Use String Catalogs (Localizable.xcstrings)
Text("trivit.list.empty.title")
Text("trivit.count \(count)")  // With interpolation
```

### Localization Keys

```
"trivit.list.title" = "My Trivits"
"trivit.list.empty.title" = "No Trivits Yet"
"trivit.action.increment" = "Increment"
"trivit.action.decrement" = "Decrement"
"trivit.action.reset" = "Reset"
"trivit.action.delete" = "Delete"
```

---

## Git Commit Messages

### Format

```
<type>: <short description>

<optional body with more details>

<optional footer with issue references>
```

### Types

- `feat:` New feature
- `fix:` Bug fix
- `test:` Adding tests
- `refactor:` Code refactoring
- `docs:` Documentation
- `chore:` Maintenance tasks

### Examples

```
feat: Add increment animation for tally marks

Adds a subtle scale animation when a new tally mark is added.
The animation uses spring physics for a natural feel.

fix: Prevent count from going negative

Guard against negative counts when decrementing at zero.
Adds haptic feedback to indicate the limit was reached.

test: Add unit tests for TrivitListViewModel

Covers loading, incrementing, and error handling scenarios.
Uses MockTrivitRepository for isolation.
```

---

## Review Checklist

Before merging:

- [ ] All tests pass
- [ ] Code follows style guidelines
- [ ] Documentation updated
- [ ] Accessibility verified
- [ ] No compiler warnings
- [ ] Memory profiled (no leaks)
- [ ] Performance acceptable
- [ ] Localization complete
