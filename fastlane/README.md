fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios screenshots

```sh
[bundle exec] fastlane ios screenshots
```

Generate App Store screenshots on all required device sizes

### ios screenshots_iphone

```sh
[bundle exec] fastlane ios screenshots_iphone
```

Generate screenshots for iPhone only (faster)

### ios watch_screenshots

```sh
[bundle exec] fastlane ios watch_screenshots
```

Generate Apple Watch screenshots via simctl

### ios deliver_metadata

```sh
[bundle exec] fastlane ios deliver_metadata
```

Upload metadata, screenshots, and app icon to App Store Connect

### ios submit_for_review

```sh
[bundle exec] fastlane ios submit_for_review
```

Upload everything and submit for review (creates draft)

### ios upload_screenshots

```sh
[bundle exec] fastlane ios upload_screenshots
```

Upload only screenshots

### ios upload_icon

```sh
[bundle exec] fastlane ios upload_icon
```

Upload only the app icon

### ios upload_metadata_only

```sh
[bundle exec] fastlane ios upload_metadata_only
```

Upload only metadata (no screenshots)

### ios download_metadata

```sh
[bundle exec] fastlane ios download_metadata
```

Download existing metadata from App Store Connect

### ios prepare_and_upload

```sh
[bundle exec] fastlane ios prepare_and_upload
```

Generate screenshots and upload everything

### ios full_app_store_prep

```sh
[bundle exec] fastlane ios full_app_store_prep
```

Full App Store preparation: icons, screenshots, metadata

### ios testflight_upload

```sh
[bundle exec] fastlane ios testflight_upload
```

Build and upload to TestFlight

### ios release

```sh
[bundle exec] fastlane ios release
```

Build, upload to TestFlight, and update metadata

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
