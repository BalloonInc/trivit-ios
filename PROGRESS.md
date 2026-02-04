# Trivit iOS - Progress

## Current Status: v5.0 Ready for App Store 🚀

The app has been completely rewritten in SwiftUI and is ready for App Store release.

### Completed

#### App Store Submission (Feb 4, 2026) ✅
- [x] Version 5.0 prepared
- [x] Automated App Store release workflow
- [x] Support URLs configured (trivit.be)
- [x] Watch app restored for iOS + watchOS submission
- [x] Sample data mode for screenshots
- [x] Firebase Analytics integrated

#### UX Polish (Feb 3, 2026) ✅
- [x] Swipe-to-delete with undo toast (5 second window)
- [x] Soft delete with 30-day retention
- [x] "Recently Deleted" section in Settings
- [x] Drag-to-reorder with live visual feedback
- [x] Tutorial overlay for first-time users
- [x] 50 random example names for new trivits (localized in 20 languages)
- [x] Auto-edit mode when creating new trivit
- [x] Hide counter when expanded (configurable)

#### UI Redesign (Feb 3, 2026) ✅
- [x] Flat colored row design matching original app
- [x] Title bar with cream/off-white text
- [x] Triangle indicator for expanded state
- [x] Fixed 5th tally mark - diagonal strike-through
- [x] Chinese tally style (正) for underscore-prefixed names

#### Sync & Device Support (Jan 30, 2026) ✅
- [x] CloudKit sync for iPhone ↔ iPad
- [x] WatchConnectivity for iPhone ↔ Watch real-time sync
- [x] App Groups configured

#### SwiftUI Modernization (Jan 28, 2026) ✅
- [x] Complete rewrite from Objective-C to Swift/SwiftUI
- [x] SwiftData for persistence
- [x] iOS 17+ deployment target
- [x] Removed all legacy dependencies

### Closed GitHub Issues
- Issue #2: Configure App Groups ✅
- Issue #3: Swipe-to-delete gesture ✅
- Issue #4: Drag-to-reorder ✅
- Issue #5: iCloud sync ✅
- Issue #6: Tally mark fix ✅
- Issue #7: Chinese tallies ✅

### Future Ideas (Backlog)
- Widget support
- Siri shortcuts
- Apple Watch complications
- Export to CSV

## Build Commands

```bash
# Build for device
xcodebuild -workspace trivit.xcworkspace -scheme trivit \
  -destination 'id=00008150-001625E20AE2401C' build

# Trigger TestFlight
gh workflow run "TestFlight Internal" --repo BalloonInc/trivit-ios

# App Store Release
gh workflow run "App Store Release" --repo BalloonInc/trivit-ios
```
