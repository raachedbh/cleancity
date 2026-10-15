# CleanCity 0.11.0+11

## Changes

- NPC litter attempts now occur every 2.5–4.5 seconds (previously 8–14). Cities start with 28–48 pieces, grow to 42–72 through NPC activity, and reserve 16 extra slots for thief trails. Spacing, accessible landings, station clearance and finite cleanup quotas still apply. Existing saves fill naturally through NPC activity.
- Optional thief encounter: first appearance after 65 seconds of active play, then a 3–5 minute active-play cooldown. A masked, animated character has an orange exclamation marker in the world and minimap. Tap the minimap or Find thief in Events to approach. Within 260 world units and line of sight, the thief flees along valid routes, tossing up to 16 pieces at 1.1–1.8 second intervals, and escapes after a randomized 18–32 seconds. Ignored encounters depart after 90 seconds. Menus pause the encounter; leaving the city or closing the app ends the encounter while preserving its litter and cooldown. No coins are stolen.
- Personal lifetime collection ranks: Rookie (0), Bronze (100), Silver (500), Gold (1,500), Platinum (4,000), Diamond (10,000), City Legend (25,000). Trophy button opens current rank, progress and thresholds. Only successful unique pickups raise the score; rank persists across cleanup renewals. This is a local progression system, not an online player leaderboard.
- Test Settings includes Preview thief. Unlocking test content does not fabricate rank points.
- Save schema 9 accepts earlier saves and persists the new cooldown and larger litter capacity.
- Two separate Android installations: CleanCity uses `com.greenhaven.greenhaven`; CleanCity Test uses `com.greenhaven.greenhaven.test`. The build derives package/label from the same CLEANCITY_TEST_MODE Dart define used by the game. Regular saves remain separate and are not reset.
- Fresh regular installs start at level 1, 0 gems, starter gear, first city and starter outfit. The normal day-one gift is awarded after onboarding. Test installs unlock all maps/outfits/upgrades, level 100, 1,000,000 coins and 10,000 gems.

## Verification

- Static analysis passed.
- 61 automated tests passed, including thief navigation across all six cities, variable escape times, reserved litter capacity/save round-trip, no offline spawning, rank thresholds/duplicate pickups/persistence and fresh regular-build restrictions.
- Full Android integration passed in 3:50: existing gameplay and all six cities, twelve outfits, themes/controls, the Bronze ranking screen, test Settings thief preview, a running thief with visible world/minimap markers, actual litter drops and escape. Screenshots inspected in `docs/screenshots/v11`.
- Both final APKs installed together and cold-launched on API 36. Native UI verified regular LV 1 / bag 16 / 0 gems / no test controls, and test LV 100 / bag 64 / 1.0m coins / 10.0k gems / test controls, both version 0.11.0.
- Both APKs installed on the connected Huawei JNY-LX1 phone and cold-launched. Both packages report versionCode 11. Existing app data was preserved.
- APK copies in phone Downloads match the Desktop and versioned archives by SHA-256.

## Delivery

Delivered: Desktop/CleanCity.apk and Desktop/cleancitytest.apk, plus releases/CleanCity-0.11.0.apk and releases/CleanCity-0.11.0-test.apk. Both APKs are also in the phone Downloads folder; both apps are installed side by side.
Existing Android development signing remains in use. A Play Store upload requires production signing setup; these APKs are device-installable builds. Payments and online accounts are not implemented. No store upload performed.


CleanCity.apk: 55109178 bytes
SHA-256: 5F9C38ECD21505FE84EAFB4159055063F6E4F64E6BCDBCE9176DDBB7D4B91545
cleancitytest.apk: 55191110 bytes
SHA-256: 1D1EEA337B5C93C917AB95BBFF73B0CFCD264D9CDACB4D00FF9B61100A2A0E1B
Verification emulator overrides restored and emulator stopped. Physical phone display settings were not changed.
