# CleanCity 0.4.0+4 test build

## Changes
- New address-specific layouts: single villas, paired houses, terraces, different setbacks, roof shapes and materials, inset windows, balconies, shopfronts and projecting bays.
- City-specific structures: Willow community nursery and market pavilion; Italian loggia, campanile and trattoria courtyard; Tunis covered souk with dome and palm; Paris conservatory and cafe terrace; Kyoto tiered shrine, torii and garden pavilion; Midnight manor, turret and curiosity museum. Existing clock-tower and plaza landmarks remain. Designs are original interpretations, not replicas.
- Eight original NPC appearances with different face shapes, skin tones, hair, glasses, facial hair and clothing. Front, back and profile views use different face geometry; profile eyes stay within the face.
- Opening and maximum active street litter reduced from 36-48 to 18-28 across entire maps. NPC drop attempts occur every 10-16 active-play seconds, versus 2.8-5.2 previously, and avoid local clusters of three items within 150 world units.
- Save format 4 migrates existing dense streets without removing collected progress. Deferred items stay eligible for later emission toward the fixed cleanup quota.
- `CLEANCITY_TEST_MODE=true` uses `cleancity_test_save_v1`; the original `greenhaven_save_v1` is read only when initializing a test save. All content unlocks, level 100, max gear, full restorations and a test wallet are applied. Settings can refill funds/recharge the magnet and switch between starter/max gear. No real payments.

## Build
`flutter build apk --release --dart-define=CLEANCITY_TEST_MODE=true`

Output: `releases/CleanCity-0.4.0-test.apk` and Desktop `cleancitytest.apk`. Regular `CleanCity.apk` on the Desktop is retained. Development signing and application ID are unchanged.

## Validation
- Model/navigation suite: 31 tests, including save isolation, all unlocks, gear switching, migration from v3, finite litter emission and routes in every city.
- Art review sheets are in `docs/screenshots/v4/`; export with `flutter test tool/art_preview.dart`.
- `flutter analyze`: no issues.
- Android emulator integration flow: passed. Joystick movement, automatic pickup, timed recycling, menus, purchases in regular progression, all six city renders, all test unlocks, test gear toggles, test wallet/magnet refill and save/reload were exercised. Screenshots are in `docs/screenshots/v4/`.
- The full interaction run caught a settings card/Material rendering assertion; settings now supplies its own Material surface. The rerun passes without framework exceptions.
- Unique civic structures occur at two addresses per city; they do not repeat down a map column. Roof fading uses a tighter vertical bound so nearby unobstructed buildings stay opaque.

Physical-device frame performance and iOS still need separate testing. This is an unlocked test build; its economy is for exploration, not progression balancing.

## Packaged APK verification
- Installed and cold-launched the final release APK on the Android emulator. Native UI confirms `CleanCity TEST`, level 100, bag capacity 64, 1.0m coins and 10.0k gems.
- Android version 0.4.0, versionCode 4, minSdk 24, targetSdk 36.
- Final APK: 52,644,224 bytes. Desktop copy SHA-256 verified against the built artifact.
- SHA-256: `0C2E596AE7F014C0DE6B0DCC40EACB06A9DF4F5AF0352BDA590A88F1F4891E24`.
