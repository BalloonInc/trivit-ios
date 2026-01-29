# Trivit iOS - Modernization Progress

## Current Status: UI Polish & Feature Implementation 🚧

### Completed Tasks

#### Phase 1: SwiftUI Modernization (Jan 28, 2026) ✅
- [x] Remove all Objective-C code (~40,000 lines deleted)
- [x] Create SwiftUI App lifecycle (`TrivitApp.swift`)
- [x] Create SwiftData model (`Trivit.swift`)
- [x] Create main list view (`TrivitListView.swift`)
- [x] Create row view with flat design (`TrivitRowView.swift`)
- [x] Create settings view (`SettingsView.swift`)
- [x] Create haptics service (`HapticsService.swift`)
- [x] Create color theme (`TrivitColors.swift`)
- [x] Remove legacy dependencies (RestKit, AFNetworking, NewRelic)
- [x] Update iOS deployment target to 17.0
- [x] Configure App Groups for iOS/watchOS data sharing

### In Progress - Phase 2: UI Polish & Features

#### Tally Marks Fixes (Priority: HIGH)
- [ ] Fix 5th tally mark crossing the other 4 properly (diagonal strike-through)
- [ ] Make tally marks expand to show ALL marks (multiple rows, no ellipsis)
- [ ] Remove "show tally marks" setting - always show them
- [ ] Chinese tally style (正) for names starting with underscore
- [ ] TODO: Add different tally counting styles in settings (Roman, Chinese, dots, etc.)

#### UI Improvements (Priority: HIGH)
- [ ] Make count circle more subtle (20% opacity white background instead of 95%)
- [ ] Colors should cycle in order, not random pick
- [ ] Fix dark mode appearance

#### Settings Screen (Priority: MEDIUM)
- [ ] Add color scheme picker (bring back from old app)
- [ ] Add sync info (device count, last sync time)
- [ ] Remove "show tally marks" toggle

#### Watch App (Priority: MEDIUM)
- [ ] Remove legacy WatchKit Extension from Xcode project
- [ ] Improve watch app UI styling
- [ ] Test data sync with iOS app

#### Cleanup (Priority: LOW)
- [ ] Remove any remaining Objective-C files
- [ ] Clean up DataKit framework (legacy)
- [ ] Remove WatchKit Extension target from project

### Pending - Phase 3: Advanced Features

#### Statistics
- [ ] Total counts across all trivits
- [ ] Daily/weekly/monthly trends
- [ ] Most used trivits
- [ ] History view with graphs
- [ ] Export statistics

#### Tally Style Options
- [ ] Western tally (IIII with strike = 5)
- [ ] Chinese tally (正 = 5)
- [ ] Dot groups
- [ ] Roman numerals
- [ ] Simple numbers only

#### Sharing Features
- [ ] Share trivit as image
- [ ] Share count via Messages/Social
- [ ] Export to CSV

#### Data & Sync
- [ ] iCloud sync via CloudKit
- [ ] Multi-device sync status
- [ ] Backup/restore functionality

#### Other Features
- [ ] Swipe-to-delete gesture
- [ ] Drag-to-reorder
- [ ] Widget support
- [ ] Siri shortcuts
- [ ] Apple Watch complications

## Architecture

See `ARCHITECTURE.md` for detailed architecture documentation.

## Known Issues

1. ~~Watch App Not Loading~~: App Groups configured - needs testing
2. Tally marks 5th stroke not crossing properly
3. Legacy WatchKit Extension still in Xcode project
4. Count circle too prominent (white bg too opaque)

## Recent Changes

### Jan 28, 2026 (Session 2)
- Configured App Groups for data sharing
- Created GitHub issues for tracking
- Starting UI polish phase

### Jan 28, 2026 (Session 1)
- Complete SwiftUI rewrite
- UI redesigned to match original flat design
- Removed all Objective-C (337 files, -40,832 lines)

## Build Commands

```bash
# Build for simulator
xcodebuild -workspace trivit.xcworkspace -scheme trivit -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Build for device
xcodebuild -workspace trivit.xcworkspace -scheme trivit -destination 'platform=iOS,id=00008150-001625E20AE2401C' build

# Run tests
xcodebuild test -workspace trivit.xcworkspace -scheme trivit -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```
