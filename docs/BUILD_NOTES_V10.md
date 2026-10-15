# CleanCity 0.10.0+10 unlocked Android test build

## Changes

- Reorganized buildings into clear blocks. Placement reserves roads and pavement and prevents overlapping building silhouettes.
- Larger maps with different street plans and district outlines, varied building types, paved plots, city-specific facades and trees.
- Rebuilt the Tunis clock as a tall bronze tower with a large clock face, perforated panels and fountain, based on the user's reference photo. Camera framing adjusts near the tower.
- Save schema 8 migrates old positions while retaining progress. All maps, outfits and upgrades remain unlocked in the separate test save.
- Research and rendering details: `ARCHITECTURE_V10.md`.

## Verification

- Static analysis: no issues.
- 56 automated tests passed, including full building/road silhouette separation, city routes, bridge crossings, save migration and test-save isolation.
- All six city overview/street exports passed and were visually inspected.
- Full Android integration passed in 3:32 on API 36: movement/collisions, recycling, six maps, twelve outfits, optional events, shop, three joystick positions, HUD transparency/hiding, dark/light UI and save/reload.
- Device screenshots inspected for the new street layouts and tall Tunis clock.
- Release APK installed and cold-launched successfully on API 36. Native UI confirms TEST, level 100, 1.0m coins, 10.0k gems, bag capacity 64 and Settings Test build 0.10.0.
- Universal Android APK: arm64-v8a, armeabi-v7a and x86_64; minSdk 24, targetSdk 36, package com.greenhaven.greenhaven, label CleanCity, versionCode 10, existing development signing.
- Payments remain unavailable; no store publication performed.

## Build

Command: `flutter build apk --release --dart-define=CLEANCITY_TEST_MODE=true`

Target Desktop filename: `C:/Users/raxhe/Desktop/cleancitytest.apk`.
Archive: `releases/CleanCity-0.10.0-test.apk`.
The existing regular `Desktop/CleanCity.apk` is retained.

Size: 55,092,426 bytes.
SHA-256: `ADDF3BB6BC44DAC4E198AFE5C6292226EDDF2FA8344882AB2C3EB4979C47CEC8`.
Build, archive and Desktop copies match exactly.
Verification emulator display overrides restored and emulator stopped. No physical device was modified.
