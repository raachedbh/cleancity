# CleanCity

A full-screen portrait Flutter + Flame recycling adventure for Android and iPhone.

## Regular Android build
The regular 0.17.2 APK is `releases/CleanCity-0.17.2.apk`, copied to the Desktop as `CleanCity.apk`. It uses normal progression and the original normal save: level/coin map requirements, outfit prices, starter gear and earned rewards. Build with `flutter build apk --release --dart-define=CLEANCITY_TEST_MODE=false`. The installed app is named **CleanCity**. Its application ID is unchanged, so installing the regular APK updates the existing app while the separate test save remains stored.

The new city-and-leaf logo appears on the launcher, native launch screen, welcome panel and HUD. See [brand assets and generation prompt](docs/BRANDING_V7.md). iPhone/iPad icon assets are updated, but this deliverable is an Android APK.

## Android test build
The unlocked 0.17.2 test APK is `releases/CleanCity-0.17.2-test.apk`, copied to the Desktop as `cleancitytest.apk`. It has every map, outfit, upgrade, restoration and the magnet available, level 100, one million test coins and 10,000 test gems. Settings offers a wallet/magnet refill, a starter/max gear toggle, and a preview button for the three optional city events.

The test build installs alongside the regular game as **CleanCity Test**, with application ID `com.greenhaven.greenhaven.test` and isolated progress. The regular game keeps `com.greenhaven.greenhaven`. Both update in place with the existing development signing key. Real payments remain disabled.

Build with `flutter build apk --release --dart-define=CLEANCITY_TEST_MODE=true`. Omitting that define builds regular progression and loads the normal save. Previous preview APKs remain in `releases/`.

## Play
- New games start in Dark mode. Settings remembers a chosen Light/Dark preference. A short first-launch guide covers the essentials; Start, Close, Back or swipe-dismiss marks it complete, so it does not appear again.
- Choose Light or Dark, joystick Left/Middle/Right, and bar visibility in Settings. Both bars default to 38% opacity; the arrow hides the top bar.
- Wear any of twelve outfits, including firefighter, alchemist, doctor, chef, astronaut and mechanic.
- Tap the celebration icon to join an optional city event. There is no countdown; saved progress and a reward wait for you.
- Open the book icon for **Album**. Catch thieves, step on their dropped valuables, then use **To police** and **Return** for a small reward. Lifetime counts remain in Rewards; Progress holds totals and earned souvenirs, including the Golden city for 100,000 recycled items.
- Street encounters are several active-play minutes apart. Thieves and trucks do not spawn together. A short city alert announces them; exclamation marks identify thieves and shields identify police stations on the minimap.
- Notices appear inside the top HUD; full bags show just **Bag full**, once until space is freed.
- Streets begin with a small amount of litter near curbs. Pedestrians occasionally drop more, up to a fixed cleanup quota.
- Touch and drag to place the floating joystick. Double-tap its edge to auto-walk; touch again to stop. Nearby bottles, cans and cardboard collect automatically.
- Tap **To station**, then **Recycle**, to deposit a batch. Processing starts at 15 seconds while you keep exploring.
- Earn XP, upgrade your bag and recycler, and activate the 15-second magnet after level 5.
- Unlock larger maps with levels and coins. Midnight Hollow uses gems only and includes a vampire outfit.
- Buy coin outfits starting at 1,000 coins or original gem outfits in Style/Shop.
- Visit each day for increasing rewards. Day 7 gives 5 gems; missing a day resets the streak.
- Goals has Daily, Weekly and Monthly tabs. The hardest challenges give 1 or 2 gems.
- Completed street cleanups refresh automatically during play, even while a recycling batch runs. Restore gardens with the flower button.
- Tap your level badge to see milestones, or the gift icon to see attendance rewards.

Progress is saved on this device. All assets and normal gameplay work offline. Calendar resets use UTC. Real-money purchases are disabled; the planned 100-gem pack is a preview only.

## Run and verify
Flutter 3.44.0 / Dart 3.12.0. Dependencies are pinned in pubspec.lock.

Clone with `git clone https://github.com/raachedbh/cleancity.git`, then run `flutter pub get` in the project directory. Android builds require an Android SDK and Java 17 or newer compatible with the installed Flutter toolchain. APK archives, local SDK paths, signing keys, device captures and downloaded art references are kept outside version control.

```powershell
flutter pub get
flutter run -d <android-device-id>
flutter analyze
flutter test
flutter test integration_test/game_flow_test.dart -d <android-device-id>
flutter drive --driver=test_driver/screenshots.dart --target=integration_test/game_flow_test.dart -d <android-device-id>
flutter build apk --release
```

The screenshot driver saves images in `docs/screenshots/v17.2/`. Integration tests use a separate in-memory fixture; production does not receive test coins/gems. On a fresh Android emulator, acknowledge the Android fullscreen help overlay before running input tests.

The universal APK uses development signing. iOS sources are included but require macOS/Xcode for compilation and testing.

## Project
- `lib/data/album.dart`: valuable collection records and souvenir definitions.
- `lib/ui/album_panel.dart`: Rewards and Progress album views.
- `lib/game/album_art.dart`: original vector valuables and police station artwork.
- `lib/data/city_events.dart`: optional event definitions and saved progress.
- `lib/game/profession_art.dart`: six original vector costumes with CC0 references.
- `docs/OUTFIT_SOURCES_V6.md`: costume reference credits and licenses.
- `lib/data/catalog.dart`: six cities, prices, progression curves, goals and deterministic litter.
- `lib/state/game_state.dart`: inventory, jobs, rewards, currency, save migration and period tracking.
- `lib/game/recycling_game.dart`: movement, collection, camera, character animation and rendering.
- `lib/game/world_art.dart`: cached streets, landmarks and restoration.
- `lib/game/architecture.dart`: varied homes and city-specific public buildings.
- `lib/game/people_art.dart`: eight original resident designs and directional faces.
- `lib/state/bootstrap.dart`: isolated test save and build configuration.
- `lib/game/city_life.dart`: pedestrians, sidewalk routes and occasional animated litter drops.
- `lib/game/navigation.dart`: obstacle-aware route graph.
- `lib/ui/`: floating controls, shop, wardrobe, goals and rewards.
- `GAME_DESIGN.md`: accepted design and economy.
- `docs/ART_PROMPTS_V2.json`: built-in imagegen prompts and asset locations.
- `docs/BUILD_NOTES_V17.md`: album, police returns and less frequent events.
- `docs/BUILD_NOTES_V17_2.md`: default Dark mode and the one-time quick-start guide.
- `docs/BUILD_NOTES_V7.md`: regular build and branding validation.
- `docs/BUILD_NOTES_V6.md`: earlier gameplay/test build validation.

## Before publication
Playtest pacing and performance on physical phones, test iOS on a Mac, configure release signing and store listings, and finish iOS icons. Paid gems require store integration, verified transactions and recoverable server-managed balances before enabling purchase buttons. The current local save and device clock are not a secure paid economy.
