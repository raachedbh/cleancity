# CleanCity 0.6.0+6 test build

## Changes
- Smaller top and bottom bars, both with a default background opacity of 38%. Text stays fully opaque. Settings includes a persistent Bar visibility slider (20-80%); hide/show top bar remains available.
- A modest increase in street litter caps: 22 / 25 / 28 / 32 / 32 / 32 across the six cities. Pedestrians can now drop litter every 8-14 seconds while preserving local spacing and finite cleanup quotas. Older saves receive a one-time top-up that never restores a collected item; reopening a current save never refills the streets.
- Six new animated outfits: Firefighter, Alchemist, Doctor, City chef, Astronaut and Mechanic (12 outfits total). Original vector costumes use the existing face atlas, distance-driven articulated gait, directional headgear, equipment and clothing. CC0 references and credits: [OUTFIT_SOURCES_V6.md](OUTFIT_SOURCES_V6.md).
- Three rotating optional city events: Street sweep (collect 12, 140 coins + 30 XP), Bottle hunt (8 bottles, 180 coins + 40 XP), Recycling rally (20 local items recycled, 240 coins + 55 XP). No expiry, countdown, entry fee or skip penalty. Joining is explicit; progress persists across maps and restarts. Rewards require a claim and can only be paid once.
- Invitations appear after 45 seconds of initial active play, then after 7 minutes of active play following a claim or skip. Menu and offline time do not advance invitations. Stations gain small event flags; relevant litter sparkles when an event is joined. Recycling progress counts only city-matching items in batches started after joining, including those that finish offline.
- Events button beside Daily / Projects; Settings test controls include Preview next city event. Test build still unlocks all content in its own save slot. No real-money payments.

## Validation recorded so far
- All 49 automated model/navigation tests passed, including event eligibility, city/material filtering, persistence, offline recycling, no duplicate rewards, abandoned-batch isolation, outfit ownership, save migration and HUD preferences.
- `flutter analyze --no-pub`: no issues.
- The first Android integration run exposed a test helper that only scrolled forward when returning to an earlier Settings control. The helper now supports either direction. The event scenario uses a fresh city rather than the nearly empty onboarding street.
- All twelve outfits and eight residents exported and visually inspected in the movement review sheet. Back-facing profession costume details corrected after inspection.

- Android integration passed in 3:36 on the API 36 emulator (540x1200, density 210). Covers all six cities, all twelve outfits, new outfit selection through Style, live Light/Dark updates, HUD background opacity/size, slider interaction, invitation/join/world pickups/one-time claim, all joystick layouts, collision-stopped gait, nine dark-mode menus, top-anchored Bag full notice, hide/show and saved settings/event completion.
- Screenshots inspected: `transparent-streets.png`, `new-outfit-8.png`, `settings-dark.png`, `event-reward.png`, `controls-right.png`, and the regenerated movement review sheet in `docs/screenshots/v6/`.

## Release
Build command: `flutter build apk --release --dart-define=CLEANCITY_TEST_MODE=true`.

- Built universal Android APK successfully, version 0.6.0 / code 6, minSdk 24, targetSdk 36; development signing unchanged.
- Installed final release on the emulator and cold-launched successfully. Completed onboarding; native UI verified CleanCity TEST, level 100, bag capacity 64, 1.0m coins, 10.0k gems, Events access, and Settings test build 0.6.0 with 38% bar visibility. No errors appeared in the scoped AndroidRuntime/Flutter error log.
- Copied to `C:/Users/raxhe/Desktop/cleancitytest.apk` and `releases/CleanCity-0.6.0-test.apk`. All three SHA-256 hashes match the built artifact.
- Size: 53,693,564 bytes. SHA-256: `AC4D73B0A377F0E065E34FD300878DB2A8C7302CF3AB98B1E526B163F0B4D510`.
- Restored emulator display overrides and stopped the test emulator after verification. Physical-phone performance and iOS were not tested for this update.
