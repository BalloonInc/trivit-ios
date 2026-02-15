# Build and Test Trivit

## Build

```bash
xcodebuild -workspace trivit.xcworkspace -scheme trivit \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Run Tests

```bash
# Unit tests
xcodebuild test -workspace trivit.xcworkspace -scheme trivit \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:trivitTests -quiet

# UI tests
xcodebuild test -workspace trivit.xcworkspace -scheme trivit \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:TrivitUITests -quiet
```

## Deploy to Physical Device

```bash
xcodebuild -workspace trivit.xcworkspace -scheme trivit \
  -destination 'id=00008150-001625E20AE2401C' -configuration Debug build

xcrun devicectl device install app --device "00008150-001625E20AE2401C" \
  ~/Library/Developer/Xcode/DerivedData/trivit-*/Build/Products/Debug-iphoneos/trivit.app
```

## Notes
- Workspace-based project (not xcodeproj)
- Scheme: `trivit`
- Simulator: iPhone 17 Pro (iOS 26 SDK)
- Device ID: `00008150-001625E20AE2401C`
