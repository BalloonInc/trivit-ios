# Deploy Trivit to TestFlight

## Via GitHub Actions (preferred)

```bash
# Internal beta
gh workflow run "TestFlight Internal" --repo BalloonInc/trivit-ios

# External beta
gh workflow run "TestFlight External" --repo BalloonInc/trivit-ios

# Check status
gh run list --repo BalloonInc/trivit-ios --limit 5
```

## Via Fastlane (local)

```bash
cd ios  # if in a subdirectory structure
fastlane ios testflight_upload
```

## Via xcodebuild (manual)

1. Bump build number in project settings
2. Archive:
```bash
xcodebuild archive -workspace trivit.xcworkspace -scheme trivit \
  -archivePath /tmp/trivit.xcarchive -destination 'generic/platform=iOS' -quiet
```
3. Export and upload:
```bash
cat > /tmp/ExportOptions.plist << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key><string>app-store-connect</string>
    <key>teamID</key><string>N324UX8D9M</string>
    <key>destination</key><string>upload</string>
</dict>
</plist>
PLIST

xcodebuild -exportArchive -archivePath /tmp/trivit.xcarchive \
  -exportOptionsPlist /tmp/ExportOptions.plist -exportPath /tmp/trivit-export \
  -allowProvisioningUpdates \
  -authenticationKeyPath ~/.private_keys/AuthKey_GA9T4G84AU.p8 \
  -authenticationKeyID GA9T4G84AU \
  -authenticationKeyIssuerID 39f22957-9a03-421a-ada6-86471b32ee9f
```
4. Clean up: `rm -rf /tmp/trivit.xcarchive /tmp/trivit-export /tmp/ExportOptions.plist`

## Notes
- Team ID: `N324UX8D9M`
- Bundle ID: `com.wouterdevriendt.trivit`
- Branch: `master` (not main)
- Workflow IDs: Internal=227871014, External=227871015, App Store=227871016
