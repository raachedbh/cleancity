# CleanCity 0.2.0 preview — 8 October 2026

## Delivered APK
- Workspace: `releases/CleanCity-0.2.0-preview.apk`
- Desktop: `C:/Users/raxhe/Desktop/CleanCity.apk`
- 57,881,910 bytes (55.2 MiB), universal ARM32/ARM64/x86_64 release-mode APK.
- SHA-256: `F59695D362A60F27BCC05690E83EA92396CA80EFB8A73C7BDE5D1BE3E01A25D7`
- Android package `com.greenhaven.greenhaven`, version name 0.2.0, version code 2, min SDK 24, target SDK 36.
- Same development signing identity as the 0.1 preview; this is not a store-signed release.
- Install as an update over Greenhaven. Do not uninstall first if you want to retain progress.

## Features
Full-screen portrait play; connected roads and sidewalks; improved joystick movement and obstacle-aware tap routes; multiple recycling stations; minimap; six progressively larger city maps; origin-city earning multipliers; level-and-coin map unlocks and a gems-only spooky map with a vampire outfit; one-time map unlock gifts; XP and level milestones; 15-second magnet with cooldown; more expensive gear and outfits; 15-second recycling jobs with capacity/speed upgrades; daily/weekly/monthly goals; automatic seven-day gifts and 5 gems on day 7; local gem wallet and shop with real-money purchasing disabled.

See GAME_DESIGN.md for exact prices, rewards, reset rules and pacing assumptions.

## Completed validation
- `flutter analyze`: no issues.
- `flutter test`: 25 passing tests. Covers inventory limits, duplicate pickups, timer completion, offline/restart settlement, partial batches, locked payouts, origin-city earnings, level rewards, magnet expiry/cooldown, shop balances, map bonuses, daily reset/cycle/rollback, independent calendar periods, offline goal attribution, migration, save failures and cleanup renewal.
- Reachability check: every item across all six maps has a clear route from the spawn, with station/building clearance. Each map has the expected item count and larger area than its predecessor.
- Android API 36 integration test passed on the standard phone viewport. Exercises onboarding, full viewport world dimensions, joystick input, automatic collection, timer recycling, magnet, gear, outfits, goals, map unlock/travel, gem confirmation, disabled real-purchase button, all six environments, lifecycle pausing and persistence.
- Compact 720×1280 / 320 dpi integration/screenshot run passed. All city art rendered and menus were inspected for overflow. The final screenshot driver returned VISUAL_TEST_EXIT=0.
- Final release build returned BUILD_EXIT=0.
- Actual APK upgrade check: installed 0.1, completed onboarding and collected cardboard (1/12), then installed 0.2 over it. The bag retained its item (1/16), onboarding remained completed, the new display name appeared and day-one coins were granted once.
- Actual closed-app timer check: deposited the migrated cardboard, backgrounded/force-stopped the app before processing finished, waited, relaunched. The item completed, the bag was empty and coins became 30 (25 daily + 5 recycling), without a duplicate daily gift.
- Release APK visually inspected on Android; system status/navigation bars hidden with transient edge-swipe access. Emulator display overrides reset afterward.
- iOS plist parsed; display name CleanCity and portrait orientations verified. No iOS compilation/device test on this Windows machine.
- Desktop and workspace APK SHA-256 hashes match.

## Evidence
`docs/screenshots/v2/` contains streets, Tunis, night district, daily rewards, maps, shop, final release UI, upgrade-before/after and offline-recycling captures. Gallery screenshots use an isolated funded test fixture; production starts at zero coins/gems before its first daily gift.

## Implementation notes
- Native Android WindowInsetsControllerCompat handles fullscreen on API 36, where Flutter's legacy immersive mode alone is insufficient. System bars remain accessible by swiping.
- Street pictures, atlas textures, labels and navigation edges are reused. Offscreen scenery/litter is culled; pickup effects are bounded; position saves are periodic.
- Legacy map IDs are retained, but their scenery becomes the first three new maps. Positions and litter layouts reset to fit connected streets; inventory, purchases, statistics and unlocked access migrate.
- Old background PNGs remain in the workspace but are excluded from the APK asset manifest.
- Run Flutter tests and release packaging sequentially: concurrent commands can regenerate Android plugin registration for conflicting build modes. The final release build ran after testing completed.

## Artwork
Built-in imagegen mode produced:
- `assets/images/city_blocks_v2.png`
- `assets/images/landmarks_v2.png`
- `assets/images/special_skins_v2.png`

Prompts and mode are recorded in `docs/ART_PROMPTS_V2.json`. All three PNGs are 1536×1024 RGBA with preserved transparency. Sprite source rectangles avoid adjacent-cell overlap. Existing original character art, audio and the licensed Nunito font are retained. Skins are original generated designs, not reused franchise characters.

## Practical limits before publication
The first coin map targets roughly an hour under the assumptions in GAME_DESIGN.md; a full human pacing study is still needed. Graphics and physics were tested on a software-rendered emulator, not benchmarked at 60 FPS on physical phones. Maps use expanding street grids with themed building clusters and landmarks; buildings are not enterable. Walking uses lightweight cutout animation.

This is an offline preview. Device time and local saves are not a secure paid economy. Before enabling real purchases, add store product configuration, localized prices, verified and idempotent receipt fulfillment, and recoverable server-managed balances. iOS build/testing, final store/iOS icon artwork, release signing and store metadata remain future work.

## Technical references
- [Flutter SystemUiMode](https://api.flutter.dev/flutter/services/SystemUiMode.html)
- [Android immersive mode](https://developer.android.com/develop/ui/views/layout/immersive)
