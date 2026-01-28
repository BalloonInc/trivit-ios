# Trivit - Feature Documentation

## Overview
Trivit is a tally counter app for iOS and watchOS that allows users to track counts with an intuitive, visual interface using tally marks (IIII). The app features a unique collapsible UI design where counters can be expanded to show visual tally marks or collapsed to show just the count.

---

## Core Features

### 1. Counter Management

#### Create Counters ("Trivits")
- Users can create unlimited tally counters
- Each counter has a customizable title
- Counters are assigned colors automatically (rotating through color schemes)
- New counters start at 0
- Placeholder titles are randomly selected from a predefined list

#### Increment Counter
- **Tap** anywhere on the tally zone to increment by 1
- Visual tally marks update in real-time
- Haptic feedback (vibration) on increment (configurable)
- Counters have no upper limit

#### Decrement Counter
- **Tap minus button** (shown when expanded) to decrement by 1
- **Swipe left** on counter to access decrement
- Counter cannot go below 0
- Haptic feedback on decrement

#### Reset Counter
- **Long press on minus button** to reset counter to 0
- Confirmation dialog prevents accidental resets
- "Are you sure you want to reset '[counter name]'?"

#### Delete Counter
- **Swipe left** and tap "Delete" button
- Counter is permanently removed
- No confirmation required

#### Rename Counter
- **Long press on title** to edit
- Inline editing with keyboard
- Done button on keyboard confirms change

#### Reorder Counters
- **Edit mode** allows drag-to-reorder
- Edit button in toolbar toggles edit mode

### 2. Visual Display

#### Tally Mark System
- Counts displayed as visual tally marks (IIII with diagonal for 5)
- Each group of 5 shows as a complete tally
- Tally images are 32x32 pixels
- Multiple rows of tallies supported
- Automatic row wrapping based on screen width

#### Collapsed/Expanded States
- **Collapsed**: Shows only title bar with count badge
- **Expanded**: Shows title bar + full tally mark display
- **Tap on title** toggles collapse/expand
- Animated transitions between states

#### Count Badge
- Shown in collapsed state
- Rounded rectangle design (40x30px)
- White text on darker color background
- Shows numerical count

#### Color Schemes
Six color schemes available (each with light/dark variants):
1. Blue Colors
2. Pinkish Colors
3. Trivit Colors (default)
4. Flat Design Colors
5. J-Series Colors
6. M-Series Colors

#### Alternative Tally Types
- Standard Western tally marks (IIII)
- Chinese tally marks (indicated by "_" prefix in title)
  - Uses 正 character style counting

### 3. Apple Watch Integration

#### Watch App Features
- Full list view of all trivits
- Individual trivit detail view
- Increment button (+)
- Decrement button (-)
- Reset button
- Delete button
- Rename via force press (text input)
- Create new trivit on watch

#### Watch-iPhone Sync
- Real-time bidirectional sync via WatchConnectivity
- Changes on watch immediately reflected on iPhone
- Changes on iPhone synced to watch via application context
- Sync works in background
- Data serialized via NSKeyedArchiver

### 4. Quick Actions (3D Touch)

#### Static Shortcuts
- "Add new Trivit" - Creates new counter

#### Dynamic Shortcuts
- "Increment [Last Used Trivit Name]" - Quick increment most recent
- "Increment [Previous Trivit Name]" - Quick increment second-most recent
- Dynamic shortcuts update based on usage

### 5. Spotlight Search Integration

#### Searchable Items
- All trivits indexed in Core Spotlight
- Search by trivit name
- Search results show trivit with current count

#### Deep Linking
- Tapping search result opens app to specific trivit
- Trivit scrolls into view and expands
- Visual flash effect highlights the trivit

### 6. URL Scheme Support

#### Custom URL Scheme: `trivit://`
- `trivit://index/[n]` - Jump to trivit at index n
- `trivit://new` - Create new trivit
- Universal links via associated domains (trivit.be)

### 7. Settings

#### Color Theme Selection
- 6 color schemes to choose from
- Preview of each scheme in settings
- Applied immediately app-wide

#### Haptic Feedback Toggle
- Enable/disable vibration on interactions
- Applies to increment, decrement, reset

#### Reset All Data
- Delete all trivits and start fresh
- Requires confirmation

#### Tutorial
- Re-show onboarding tutorial
- 6-page tutorial walkthrough

### 8. Onboarding Tutorial

#### Tutorial Pages (6 screens)
1. Welcome/Introduction
2. How to increment (tap)
3. How to collapse/expand (tap title)
4. How to decrement (minus button)
5. How to reset (long press minus)
6. Settings and customization

#### First Launch
- Tutorial shown automatically on first launch
- Creates sample trivits to demonstrate
- "Skip" button available

### 9. Feedback System

#### In-App Feedback
- 5-star rating scale
- Free-text message field
- Optional name and email
- Submitted to backend API
- Unsent feedback queued and retried

### 10. Orientation Support
- Portrait mode supported
- Landscape mode supported
- Dynamic layout adjustment
- Tally rows reflow based on screen width

### 11. Localization

#### Supported Languages (7)
1. English (base)
2. Spanish (es)
3. French (fr)
4. Japanese (ja)
5. Dutch (nl)
6. Russian (ru)
7. Chinese Simplified (zh-CN)

---

## Technical Features

### Data Persistence
- Core Data with SQLite backend
- Automatic lightweight migration between versions
- App Groups for shared storage (Watch + iPhone)
- Version tracking for data migrations

### Analytics
- Google Analytics integration
- Event tracking for:
  - Screen views
  - Trivit creation (iOS/Watch)
  - Trivit deletion
  - Trivit renaming
  - Color changes
  - 3D Touch actions
  - Startup sources

### Background Operations
- Watch data sync in background
- Spotlight indexing in background
- Feedback retry queue

---

## Missing Features (To Be Added in SwiftUI Rewrite)

### Not Yet Implemented
1. **iCloud Sync** - Cross-device sync via CloudKit
2. **Widgets** - Home screen widgets (S/M/L)
3. **History** - Historical count tracking over time
4. **Statistics** - Charts and stats per counter
5. **iPad Optimized UI** - Multi-column layout
6. **macOS Support** - Catalyst or native macOS app
7. **Easter Eggs** - Fun animations for special numbers
8. **Apple Watch Complications** - Quick glance at counts
9. **Siri Shortcuts** - Voice control for counters
10. **Share Counter** - Export/share counter data

---

## User Flows

### Creating a New Counter
1. Tap "+" button in toolbar
2. New counter appears at bottom of list
3. Keyboard opens for title editing
4. Type counter name
5. Tap "Done" on keyboard
6. Counter is ready to use

### Incrementing a Counter
1. If collapsed, tap title to expand
2. Tap anywhere in tally zone
3. Counter increments, new tally mark appears
4. Phone vibrates (if enabled)

### Checking Count on Watch
1. Open Trivit on Apple Watch
2. Scroll to find counter
3. Tap counter row
4. View large count display
5. Optionally increment/decrement

### Changing Color Theme
1. Tap settings gear in toolbar
2. Scroll to color schemes
3. Tap desired color scheme
4. All counters immediately update

---

## Gesture Reference

| Gesture | Location | Action |
|---------|----------|--------|
| Tap | Tally zone | Increment |
| Tap | Title bar | Toggle collapse |
| Tap | Minus button | Decrement |
| Long press | Minus button | Reset (with confirm) |
| Long press | Title | Edit title |
| Swipe left | Any cell | Show Delete/Color |
| Swipe right | Any cell | Reset (disabled) |

---

## Data Model

### TallyModel (Core Data Entity)
- `title` (String) - Counter name
- `counter` (Integer32) - Current count
- `color` (Integer32) - Color index
- `createdAt` (Date) - Creation timestamp
- `isCollapsed` (Boolean) - UI state
- `type` (String) - Tally style ("" or "ch_")

### Feedback (Core Data Entity)
- `feedbackMessage` (String)
- `scaleValue` (Integer32) - 1-5 rating
- `softwareIdentifier` (String)
- `deviceIdentifier` (String)
- `name` (String)
- `email` (String)

### Version (Core Data Entity)
- `versionNumber` (String)
- `dateFirstOpened` (Date)
