# Trivit iOS Architecture

## Overview

Trivit is a tally counter app built with SwiftUI and SwiftData. The app has been fully modernized from Objective-C/UIKit to Swift/SwiftUI.

## Project Structure

```
trivit-ios/
├── trivit/                     # Main iOS app
│   ├── TrivitApp.swift         # App entry point (@main)
│   ├── Models/
│   │   └── Trivit.swift        # SwiftData model
│   ├── Views/
│   │   ├── TrivitListView.swift    # Main list screen
│   │   ├── TrivitRowView.swift     # Individual counter row
│   │   └── SettingsView.swift      # Settings screen
│   ├── Services/
│   │   └── HapticsService.swift    # Haptic feedback
│   ├── Repositories/
│   │   └── TrivitRepository.swift  # Data access layer
│   ├── Theme/
│   │   └── TrivitColors.swift      # Color palette
│   └── Utilities/
│       └── EasterEggs.swift        # Fun messages
│
├── trivit Watch App/           # watchOS companion app
│   ├── TrivitWatchApp.swift
│   ├── Views/
│   │   ├── ContentView.swift
│   │   ├── TrivitRowView.swift
│   │   └── TrivitDetailView.swift
│   └── Services/
│       └── SyncService.swift
│
└── DataKit/                    # Shared framework (legacy, to be removed)
```

## Technology Stack

| Component | Technology |
|-----------|------------|
| UI Framework | SwiftUI |
| Data Persistence | SwiftData |
| Minimum iOS | 17.0 |
| Minimum watchOS | 10.0 |
| Language | Swift 5.0 |

## Data Model

### Trivit (SwiftData @Model)

```swift
@Model
final class Trivit {
    var id: UUID
    var title: String
    var count: Int
    var colorIndex: Int
    var isCollapsed: Bool
    var createdAt: Date
}
```

## Key Patterns

### 1. SwiftUI App Lifecycle
- Uses `@main` attribute on `TrivitApp`
- No AppDelegate or UIApplicationDelegate
- Scene-based with `WindowGroup`

### 2. SwiftData for Persistence
- Model container configured in App
- `@Query` for fetching data in views
- `@Bindable` for two-way binding

### 3. MVVM-ish Architecture
- Views are mostly self-contained
- `@Query` replaces traditional ViewModels for data
- Services handle cross-cutting concerns

### 4. Haptic Feedback
- Singleton `HapticsService` for consistent haptics
- Light impact on increment/decrement
- Warning notification on reset/delete

## Color System

10 vibrant flat colors defined in `TrivitColors`:
1. Turquoise (#1ABC9C)
2. Emerald (#2ECC71)
3. Peter River (#3498DB)
4. Amethyst (#9B59B6)
5. Alizarin (#E74C3C)
6. Orange (#F39C12)
7. Pink (#E91E63)
8. Cyan (#00BCD4)
9. Light Green (#8BC34A)
10. Deep Orange (#FF5722)

## Data Sharing (TODO)

For iOS ↔ watchOS data sync:

1. **App Groups**: Both apps need shared container
   - Group identifier: `group.com.wouterdevriendt.trivit`
   - Model container should use shared URL

2. **WatchConnectivity**: Real-time sync
   - `WCSession` for immediate updates
   - Background context transfer

## Build Configuration

### Bundle Identifiers
- iOS: `com.wouterdevriendt.trivit`
- watchOS: `com.wouterdevriendt.trivit.watchkitapp`

### Code Signing
- Team: N324UX8D9M
- Development: Automatic signing
- Distribution: Manual with certificates

## Dependencies

**None** - Pure Apple frameworks only:
- SwiftUI
- SwiftData
- WatchConnectivity

## Testing Strategy

1. **Unit Tests**: Model logic, repository operations
2. **UI Tests**: Main user flows (add, increment, delete)
3. **Integration Tests**: SwiftData persistence

## Future Improvements

1. CloudKit sync for multi-device
2. Widget support (WidgetKit)
3. Siri Shortcuts integration
4. iPad layout optimization
5. Apple Watch complications
