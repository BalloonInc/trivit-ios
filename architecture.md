# Trivit - Architecture Documentation

## Current Architecture (Objective-C / UIKit)

### Overview
The current Trivit app follows an MVC (Model-View-Controller) pattern implemented in Objective-C with UIKit. The app uses Core Data for persistence and has a custom `DataKit` framework for data access abstraction.

### Project Structure

```
trivit-ios/
├── trivit/                           # Main iOS app
│   ├── Controllers/
│   │   ├── MainListViewController.m  # Primary list UI
│   │   ├── SettingsViewController.m  # Settings screen
│   │   ├── FeedbackViewController.m  # Feedback form
│   │   ├── TutMasterViewController.m # Onboarding
│   │   └── TutChildViewController.m  # Tutorial pages
│   ├── Views/
│   │   ├── TrivitTableViewCell.m     # Custom table cell
│   │   ├── cellBackground.m          # Custom cell background
│   │   └── settingButtonCell.m       # Settings cell
│   ├── Models/
│   │   ├── TallyModel.m              # Core Data entity
│   │   ├── Tally.m                   # In-memory model
│   │   ├── Colors.m                  # Color management
│   │   ├── Settings.m                # User settings
│   │   └── FeedbackManager.m         # Feedback submission
│   ├── Storyboards/
│   │   ├── Main.storyboard           # Main UI
│   │   └── Launch Screen.storyboard  # Launch screen
│   └── trivits.xcdatamodeld/         # Core Data models
├── trivit Watch App/                  # WatchKit app
│   └── Interface.storyboard
├── trivitWatchKitExtension/          # Watch logic
│   ├── InterfaceController.m         # Main watch list
│   ├── DetailInterfaceController.m   # Counter detail
│   └── WKTableViewRowController.m    # Table rows
├── DataKit/                          # Data access framework
│   └── DataAccess.m                  # Core Data stack
├── trivitTests/                      # Unit tests
└── DataKitTests/                     # DataKit tests
```

### Current Component Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        AppDelegate                               │
│  - Lifecycle management                                          │
│  - 3D Touch shortcuts                                           │
│  - URL scheme handling                                          │
│  - Spotlight indexing                                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   MainListViewController                         │
│  - UITableView delegate/datasource                              │
│  - WCSession delegate (Watch sync)                              │
│  - NSFetchedResultsController delegate                          │
│  - Gesture handling (tap, swipe, long press)                    │
│  - Keyboard management                                          │
└─────────────────────────────────────────────────────────────────┘
                              │
          ┌───────────────────┼───────────────────┐
          ▼                   ▼                   ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│ TrivitTableView │  │    DataAccess   │  │    WCSession    │
│      Cell       │  │   (DataKit)     │  │ (Watch Sync)    │
│                 │  │                 │  │                 │
│ - Custom drawing│  │ - Core Data    │  │ - Send/receive  │
│ - CollectionView│  │ - SQLite       │  │ - Serialize     │
│ - Animations    │  │ - Migrations   │  │ - Background    │
└─────────────────┘  └─────────────────┘  └─────────────────┘
          │                   │
          ▼                   ▼
┌─────────────────┐  ┌─────────────────┐
│      Tally      │  │   TallyModel    │
│  (In-memory)    │  │  (Core Data)    │
│                 │  │                 │
│ - Display logic │  │ - Persistence  │
│ - UI state      │  │ - NSCoding     │
└─────────────────┘  └─────────────────┘
```

### Data Flow

```
User Gesture → Controller → Update Model → Save to Core Data
                                        ↓
                                   Sync to Watch (if connected)
                                        ↓
                                   Update UI via FetchedResultsController
```

### Current Issues

1. **Massive View Controllers** - MainListViewController handles too many responsibilities
2. **Tight Coupling** - Views and models are tightly coupled
3. **No Unit Tests** - Minimal test coverage
4. **Objective-C Legacy** - Verbose syntax, manual memory patterns
5. **UIKit Complexity** - Storyboards, delegates, manual layout
6. **No Modern Concurrency** - GCD instead of async/await
7. **Watch Sync Fragile** - NSKeyedArchiver for serialization

---

## Proposed Architecture (Swift / SwiftUI)

### Architecture Pattern: MVVM with Clean Architecture

We will adopt a modern MVVM (Model-View-ViewModel) pattern with clean architecture principles:

```
┌─────────────────────────────────────────────────────────────────┐
│                         Presentation Layer                       │
│  SwiftUI Views + ViewModels                                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                          Domain Layer                            │
│  Use Cases + Entities + Repository Protocols                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                           Data Layer                             │
│  Repository Implementations + Data Sources                       │
└─────────────────────────────────────────────────────────────────┘
```

### New Project Structure

```
Trivit/
├── App/
│   ├── TrivitApp.swift              # App entry point
│   └── AppDelegate.swift            # Legacy hooks (if needed)
├── Core/
│   ├── Domain/
│   │   ├── Entities/
│   │   │   ├── Trivit.swift         # Core business entity
│   │   │   ├── TrivitHistory.swift  # History record
│   │   │   └── TrivitStats.swift    # Statistics model
│   │   ├── UseCases/
│   │   │   ├── IncrementTrivit.swift
│   │   │   ├── CreateTrivit.swift
│   │   │   ├── DeleteTrivit.swift
│   │   │   ├── SyncTrivits.swift
│   │   │   └── GetTrivitHistory.swift
│   │   └── Protocols/
│   │       ├── TrivitRepository.swift
│   │       └── SyncService.swift
│   ├── Data/
│   │   ├── Repositories/
│   │   │   └── TrivitRepositoryImpl.swift
│   │   ├── DataSources/
│   │   │   ├── SwiftData/
│   │   │   │   └── TrivitDataSource.swift
│   │   │   └── CloudKit/
│   │   │       └── CloudKitDataSource.swift
│   │   └── Models/
│   │       └── TrivitDTO.swift      # Data transfer objects
│   └── Services/
│       ├── WatchConnectivityService.swift
│       ├── SpotlightService.swift
│       ├── HapticsService.swift
│       └── AnalyticsService.swift
├── Features/
│   ├── TrivitList/
│   │   ├── Views/
│   │   │   ├── TrivitListView.swift
│   │   │   ├── TrivitRowView.swift
│   │   │   └── TrivitTallyView.swift
│   │   └── ViewModels/
│   │       └── TrivitListViewModel.swift
│   ├── TrivitDetail/
│   │   ├── Views/
│   │   │   └── TrivitDetailView.swift
│   │   └── ViewModels/
│   │       └── TrivitDetailViewModel.swift
│   ├── Settings/
│   │   ├── Views/
│   │   │   └── SettingsView.swift
│   │   └── ViewModels/
│   │       └── SettingsViewModel.swift
│   ├── History/
│   │   ├── Views/
│   │   │   ├── HistoryView.swift
│   │   │   └── HistogramView.swift
│   │   └── ViewModels/
│   │       └── HistoryViewModel.swift
│   ├── Onboarding/
│   │   └── Views/
│   │       └── OnboardingView.swift
│   └── Widgets/
│       ├── SmallWidget.swift
│       ├── MediumWidget.swift
│       └── LargeWidget.swift
├── Shared/
│   ├── Components/
│   │   ├── TallyMarksView.swift
│   │   ├── CountBadge.swift
│   │   └── ColorSchemeButton.swift
│   ├── Extensions/
│   │   ├── Color+Theme.swift
│   │   └── View+Haptics.swift
│   └── Utilities/
│       └── EasterEggs.swift
├── Resources/
│   ├── Assets.xcassets
│   ├── Localizable.strings
│   └── Colors.xcassets
├── TrivitWatch/                     # watchOS app
│   ├── TrivitWatchApp.swift
│   ├── Views/
│   │   ├── WatchListView.swift
│   │   └── WatchDetailView.swift
│   └── Complications/
│       └── TrivitComplication.swift
├── TrivitWidgets/                   # Widget extension
│   └── TrivitWidgets.swift
├── TrivitMac/                       # macOS target
│   └── MacApp.swift
└── Tests/
    ├── UnitTests/
    │   ├── Domain/
    │   │   └── UseCaseTests.swift
    │   ├── ViewModels/
    │   │   └── TrivitListViewModelTests.swift
    │   └── Services/
    │       └── WatchConnectivityTests.swift
    ├── IntegrationTests/
    │   ├── RepositoryTests.swift
    │   └── CloudKitTests.swift
    └── UITests/
        ├── TrivitListUITests.swift
        └── OnboardingUITests.swift
```

### Technology Stack

| Layer | Technology |
|-------|------------|
| UI Framework | SwiftUI (iOS 17+) |
| Data Persistence | SwiftData |
| Cloud Sync | CloudKit |
| Watch Sync | WatchConnectivity |
| Widgets | WidgetKit |
| Testing | XCTest + Swift Testing |
| Dependency Injection | Environment + Protocols |
| Concurrency | Swift Concurrency (async/await) |

### Key Design Decisions

#### 1. SwiftData over Core Data
- Native Swift integration
- Simpler syntax with @Model macro
- Automatic iCloud sync support
- Better performance with SwiftUI

#### 2. Protocol-Based Repository Pattern
```swift
protocol TrivitRepository {
    func fetchAll() async throws -> [Trivit]
    func create(_ trivit: Trivit) async throws
    func update(_ trivit: Trivit) async throws
    func delete(_ trivit: Trivit) async throws
    func sync() async throws
}
```

#### 3. Observable ViewModels
```swift
@Observable
class TrivitListViewModel {
    var trivits: [Trivit] = []
    var selectedTrivit: Trivit?
    var isLoading = false
    var error: Error?

    private let repository: TrivitRepository

    func increment(_ trivit: Trivit) async { ... }
    func decrement(_ trivit: Trivit) async { ... }
}
```

#### 4. Multiplatform Support
```swift
// Shared code in Core/
#if os(iOS)
    // iOS-specific
#elseif os(watchOS)
    // watchOS-specific
#elseif os(macOS)
    // macOS-specific
#endif
```

### Data Model (SwiftData)

```swift
@Model
final class Trivit {
    var id: UUID
    var title: String
    var count: Int
    var colorIndex: Int
    var isCollapsed: Bool
    var createdAt: Date
    var tallyType: TallyType

    @Relationship(deleteRule: .cascade, inverse: \TrivitHistoryEntry.trivit)
    var history: [TrivitHistoryEntry]
}

@Model
final class TrivitHistoryEntry {
    var id: UUID
    var trivit: Trivit?
    var count: Int
    var timestamp: Date
    var changeType: ChangeType // increment, decrement, reset
}

enum TallyType: String, Codable {
    case western // IIII
    case chinese // 正
}

enum ChangeType: String, Codable {
    case increment
    case decrement
    case reset
}
```

### Sync Architecture

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   iPhone     │◄──►│   iCloud     │◄──►│    iPad      │
│   SwiftData  │    │   CloudKit   │    │   SwiftData  │
└──────────────┘    └──────────────┘    └──────────────┘
       │                                        │
       │ WatchConnectivity                      │
       ▼                                        ▼
┌──────────────┐                        ┌──────────────┐
│ Apple Watch  │                        │    Mac       │
│ Local Cache  │                        │  SwiftData   │
└──────────────┘                        └──────────────┘
```

### Widget Architecture

```swift
struct TrivitWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> TrivitEntry { ... }
    func getSnapshot(in context: Context, completion: @escaping (TrivitEntry) -> ()) { ... }
    func getTimeline(in context: Context, completion: @escaping (Timeline<TrivitEntry>) -> ()) { ... }
}

struct TrivitEntry: TimelineEntry {
    let date: Date
    let trivits: [Trivit]
}

struct SmallTrivitWidget: View {
    var entry: TrivitEntry
    var body: some View {
        // Single trivit display
    }
}

struct MediumTrivitWidget: View {
    var entry: TrivitEntry
    var body: some View {
        // 2-3 trivits display
    }
}

struct LargeTrivitWidget: View {
    var entry: TrivitEntry
    var body: some View {
        // Grid of trivits
    }
}
```

### Testing Strategy

#### Unit Tests
- **ViewModels**: All business logic
- **UseCases**: Domain logic
- **Services**: Service layer (mocked dependencies)
- **Utilities**: Helper functions

#### Integration Tests
- **Repository + SwiftData**: Persistence layer
- **CloudKit Sync**: Cloud operations
- **Watch Connectivity**: Device sync

#### UI Tests
- **User Flows**: Complete journeys
- **Accessibility**: VoiceOver, Dynamic Type
- **Snapshot Tests**: Visual regression

#### Test Doubles
```swift
class MockTrivitRepository: TrivitRepository {
    var trivits: [Trivit] = []
    var createCalled = false
    var deleteCalled = false

    func fetchAll() async throws -> [Trivit] { trivits }
    func create(_ trivit: Trivit) async throws { createCalled = true }
    // ...
}
```

### Performance Considerations

1. **Lazy Loading**: Use `LazyVStack` for lists
2. **Background Sync**: CloudKit operations on background queue
3. **Efficient Animations**: Native SwiftUI animations
4. **Memory Management**: Automatic with SwiftUI
5. **Widget Updates**: Smart timeline updates

### Migration Path

1. **Phase 1**: Create new SwiftUI app with core features
2. **Phase 2**: Migrate Core Data to SwiftData
3. **Phase 3**: Add iCloud sync via CloudKit
4. **Phase 4**: Build Widget extension
5. **Phase 5**: Add Watch app
6. **Phase 6**: Add macOS support
7. **Phase 7**: Add new features (history, stats, Easter eggs)

### Accessibility

- VoiceOver support on all views
- Dynamic Type support
- Reduce Motion support
- High Contrast support
- Keyboard navigation (iPad/Mac)

### Security

- No sensitive data stored
- iCloud sync uses user's Apple ID
- App Groups for widget/watch data sharing
- No analytics PII collection
