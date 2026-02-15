# Release Trivit to App Store

## Via GitHub Actions

```bash
gh workflow run "App Store Release" --repo BalloonInc/trivit-ios \
  -f app_version="5.0.2" \
  -f build_number="3" \
  -f generate_screenshots=true \
  -f generate_description=true \
  -f generate_release_notes=true \
  -f submit_for_review=true
```

## Via Fastlane

```bash
# Upload metadata and screenshots
fastlane ios deliver_metadata

# Submit for review
fastlane ios submit_for_review

# Generate screenshots
fastlane ios screenshots
```

## Notes
- Current version: 5.0.1 (build 2)
- App Store Connect App ID: `6758600865`
- Screenshots are AI-generated via Fastlane Snapfile
- Release notes are AI-generated from commits
