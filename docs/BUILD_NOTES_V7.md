# CleanCity 0.7.0+7 regular Android build

## Behavior
- App display name and APK filename: CleanCity / `CleanCity.apk`.
- Build explicitly sets `CLEANCITY_TEST_MODE=false`. Uses the existing normal save and ordinary map, outfit and gear requirements. Test-only currency, levels and Settings controls are inactive. A new player starts at level 1, zero gems and starter gear, with the usual attendance reward after onboarding.
- Retains all 0.6 gameplay features: twelve outfits, city events, transparent HUD, settings, six cities, NPC litter, timed recycling and goals.
- App ID and signing identity stay unchanged for in-place updates and save continuity. Regular and test saves remain separate. The earlier Desktop `cleancitytest.apk` remains available.
- Modern city/leaf/C emblem generated with the built-in image tool. Installed in adaptive/legacy Android icons, Android launch screen, Flutter HUD/welcome, and iOS icon/launch assets. See [branding assets and exact prompt](BRANDING_V7.md).
- Settings labels the regular app Version 0.7.0.

## Verification
- `flutter analyze --no-pub`: no issues.
- All 49 automated tests passed, including isolation between normal and unlocked test saves.
- Branding export succeeded. Original transparent master is preserved. Mask review inspected at round, rounded-square, square and small sizes. All iOS app icons verified as RGB PNG files without an alpha channel.
- Gameplay logic is unchanged from the passing 0.6 Android integration flow; final regular release installation/UI checks are recorded below.

## Artifact
Build: `flutter build apk --release --dart-define=CLEANCITY_TEST_MODE=false`.

- Universal regular APK built successfully; version 0.7.0 / code 7, minSdk 24, targetSdk 36, development signing unchanged.
- Installed over the previous test app on the Android emulator and cold-launched. Onboarding showed the new brand; the normal save opened at level 1, zero gems, starter bag capacity 16, and 25 attendance coins. HUD read CleanCity, without TEST.
- Native Settings read CleanCity - Version 0.7.0, with no wallet refill, max-gear or test-event controls. Maps showed Porto Sole locked behind level 10 and 4,500 coins. The existing test bootstrap isolation check passed in the 49-test suite.
- Actual Android launcher icon and CleanCity app label visually verified in `docs/screenshots/v7/android-launcher.png`. Welcome screenshot: `release-welcome.png`. Scoped AndroidRuntime/Flutter error log was empty after launch and menu checks.
- Desktop deliverables: `C:/Users/raxhe/Desktop/CleanCity.apk` and `C:/Users/raxhe/Desktop/CleanCity-logo.png`. Archive: `releases/CleanCity-0.7.0.apk`.
- APK size: 54,420,682 bytes. SHA-256: `C4A98E77EA76CA5F34AF5C39C2EDD78A73849CB5C53563FCEFACCC2542EB65FD`. Build, Desktop copy and archive hashes match.
- The prior Desktop test APK remains byte-for-byte unchanged (SHA-256 `AC4D73B0A377F0E065E34FD300878DB2A8C7302CF3AB98B1E526B163F0B4D510`).
- Restored display overrides and stopped the verification emulator. iOS and physical-phone performance were not tested in this update. This is a locally installable APK, not a store publication.
