# CleanCity 0.5.0+5 test build

## Changes
- Settings: Light / Dark appearance, and Left / Middle / Right joystick positions. Settings apply immediately and persist in the local save. Existing saves default to Light, Left and a visible top bar.
- Actions move opposite a left/right joystick, or above the joystick in Middle mode. Changing layout clears movement input.
- The top bar background is 72% opaque with full-opacity text. Its up arrow hides it; the down arrow restores it. Settings remains accessible while hidden, and short notices remain at the top. Settings also includes a Show top bar switch.
- Dark mode covers menus, dialogs, cards, navigation, joystick and minimap. Daytime streets receive a subtle evening tint.
- New city architecture based on real reference photos: Tunis Municipal Theatre, Florence's Piazza della Repubblica arch, Paris Place des Vosges arcades, and Kyoto Gion machiya. See [architecture references](architecture-references.md). The game remains an angled cartoon interpretation.
- Movement: distance-driven walk cycles for the player and pedestrians, alternating planted/lifted feet, bending knees, arm swings, smoother acceleration/braking, and diagonal-facing hysteresis. Feet stop animating against an obstacle. Original faces and outfit torso/cape artwork remain.
- All content stays unlocked in the test build. Save isolation, reduced litter and the existing test controls are retained. No payment processing.

## Build
`flutter build apk --release --dart-define=CLEANCITY_TEST_MODE=true`

Desktop filename: `cleancitytest.apk`. Backup: `releases/CleanCity-0.5.0-test.apk`.

## Validation
- 37 model/navigation tests passed, including preference persistence, migration from older saves, gait timing, alternating support feet and stable facing changes.
- Architecture review sheet exported and inspected in `docs/screenshots/v5/architecture-review.png`.
- `flutter analyze`: no issues.
- Android integration flow passed (2:45): recycling/progression, all six maps and outfits, Light -> Dark -> Light updates while Settings is open, all joystick placements selected through the UI, movement and non-overlapping controls, stopping animation against a building, all eight menu categories in dark mode, hide/show HUD with Settings still reachable, top-anchored Bag full notice, and saved preferences restored.
- Review screenshots include `settings-dark.png`, `settings-light.png`, `controls-left.png`, `controls-center.png`, `controls-right.png`, `hud-hidden.png`, and `test-city-0.png` through `test-city-5.png`.
- The initial device run exposed a missing integration-test plugin in the generated Android registrant left by the previous release; refreshing Flutter dependencies fixed test registration. A subsequent debug emulator startup stalled under host load. The final passing run used 540x1200 rendering at density 210, preserving the original logical phone layout; release verification follows separately.
- The player and resident pose sheet was inspected, and visible sleeve seams were corrected before the passing Android run.
- Installed the final release APK on the Android emulator and cold-launched it. Native UI confirmed CleanCity TEST, level 100, capacity 64, 1.0m coins and 10.0k gems.
- Changed Dark / Middle / hidden HUD in the actual release UI, force-stopped the process, relaunched, and verified all three preferences survived in SharedPreferences. Settings remained accessible with the HUD hidden. Restored Light / Left / visible HUD and the emulator's original 1080x2400 / density 420 display afterward.
- Release version 0.5.0, versionCode 5, minSdk 24, targetSdk 36. Development signing is unchanged.
- Desktop `cleancitytest.apk` is 53,086,844 bytes; SHA-256 matches the built artifact: `64F08C014C11DFA6F34C39EDE4DEF1386C90CA45D8585B34045190910E0FDC41`.
- Backup: `releases/CleanCity-0.5.0-test.apk`.

Physical-phone performance and iOS have not been tested for this update.
