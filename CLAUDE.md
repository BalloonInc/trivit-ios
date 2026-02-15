# Claude.md - AI Development Context for Trivit

## Quick Start for AI Agents

This document helps AI agents quickly understand and continue work on this project.

### Project State (Jan 28, 2026)

**Status**: SwiftUI modernization complete, watch app needs App Groups

**Recent Work**:
1. Converted entire codebase from Objective-C to Swift/SwiftUI
2. Redesigned UI to match original flat colored row design
3. Removed all legacy dependencies

**Immediate TODO**:
1. Configure App Groups in Apple Developer Portal for data sharing
2. Fix watch app data sync (currently shows empty - needs shared container)
3. Push to TestFlight for testing

### Key Files to Know

| Purpose | File |
|---------|------|
| App Entry | `trivit/TrivitApp.swift` |
| Data Model | `trivit/Models/Trivit.swift` |
| Main Screen | `trivit/Views/TrivitListView.swift` |
| Row Design | `trivit/Views/TrivitRowView.swift` |
| Colors | `trivit/Theme/TrivitColors.swift` |
| Progress | `PROGRESS.md` |
| Architecture | `ARCHITECTURE.md` |

### Build Commands

```bash
# Build for simulator
xcodebuild -workspace trivit.xcworkspace -scheme trivit \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Install on device (device ID: 00008150-001625E20AE2401C)
xcrun devicectl device install app --device "00008150-001625E20AE2401C" \
  "/Users/wouter/Library/Developer/Xcode/DerivedData/trivit-cwmzghghkkqutrbjdbkrafbilzvc/Build/Products/Debug-iphoneos/trivit.app"

# Trigger TestFlight
gh workflow run 227871014 --repo BalloonInc/trivit-ios
```

### Secrets & Config

- **Apple Team ID**: N324UX8D9M
- **Bundle ID**: com.wouterdevriendt.trivit
- **App Store Connect Key**: GA9T4G84AU
- **App Store Issuer**: 39f22957-9a03-421a-ada6-86471b32ee9f
- **Device**: i17pw (00008150-001625E20AE2401C)

### Workflow

1. Always read `PROGRESS.md` first to understand current state
2. Build and test before committing
3. Update `PROGRESS.md` after significant changes
4. Push often - user prefers frequent commits
5. Create GitHub issues for tracking work
6. Trigger TestFlight after major changes

### Code Style

- SwiftUI with SwiftData (iOS 17+)
- No external dependencies - pure Apple frameworks
- Flat, colorful design - full-width colored rows
- Haptic feedback on all interactions
- Context menus for secondary actions

### Common Issues

1. **Watch app empty**: Needs App Groups configured
2. **Build fails**: Clean derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData/trivit-*`
3. **Signing fails**: Check team ID and bundle ID match

### GitHub Actions

- `227871014` - TestFlight Internal
- `227871015` - TestFlight External
- `227871016` - App Store Release

### Related Repos

- `../footprint` - Has App Store Connect credentials
- `../snow` - Has shared config

## Available Skills

Detailed instructions in `.claude/commands/`:

- **`/build-test`** — Build and run unit/UI tests (workspace-based, iPhone 17 Pro simulator)
- **`/deploy-testflight`** — Deploy to TestFlight (via GH Actions `gh workflow run` or manual xcodebuild)
- **`/app-store-release`** — Full App Store release with AI-generated screenshots and release notes
