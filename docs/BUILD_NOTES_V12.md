# CleanCity 0.12.0+12

## Changes

- Recycle starts a batch immediately at a station. The timer and expected coins appear above the player; payment is automatic when the timer finishes, with a short coin message. Walking and collecting can continue while recycling. The distant To station button still guides the player to a station.
- Catching a fleeing thief pays 25 coins once. A brief initial escape window gives the thief time to run; catches require close range and a clear line of sight. Caught thieves disappear without an escape notice. The catch count and payment persist.
- Touch anywhere on the map to place the joystick, drag to steer, and lift to stop. Menu buttons do not start movement. Extra fingers cannot hijack an active drag; menus and backgrounding cancel held movement. Settings still choose the resting joystick position.
- NPCs spawn across each city and travel between all four neighborhoods in both directions. Sidewalk destinations extend to outlying streets, and recent destinations are avoided. Existing obstacle navigation keeps routes around buildings and over accessible crossings. Population remains capped at 24 for mobile performance; litter caps and cleanup quotas are unchanged.
- Save schema 10 preserves earlier saves and adds the thief catch count. Regular and unlocked test builds remain separate applications with separate progress.

## Verification

- Static analysis: no issues.
- 65 automated tests passed, including catch rewards/persistence/wall clearance, floating joystick cancellation and multitouch, and six-minute NPC roaming simulations in every city. Each simulated NPC visited at least three neighborhoods and traveled well beyond its starting block; spawn coverage spans over 70% of each map's width and height.
- Full Android integration passed in 3:47 after the NPC changes: all six maps, outfits/settings, one-tap recycling and its head-level timer/payment, floating joystick placement/release, thief catch reward and persistence. Screenshots are in `docs/screenshots/v12`.

- Both final release APKs installed together on the Android emulator and cold-launched successfully. Package IDs, labels, versionCode 12, regular/test mode and the new joystick settings were verified from native Android UI.

## Delivery

Verified copies: `Desktop/CleanCity.apk` and `Desktop/cleancitytest.apk`, with versioned archives under `releases/`.

CleanCity.apk: 55256634 bytes
SHA-256: F92A93C1605B39BCD62B142DC7C9EFA0A9D8CDB71AD34CEEB0F1509D75904E74
cleancitytest.apk: 55256646 bytes
SHA-256: 7EFD9CA3C784AC039511B2DC9541CDF6122D506512F1F764DE6FFB87C549653F

Both apps installed on the Huawei JNY-LX1 phone with existing app data preserved. Version 0.12.0/code 12 and cold launches verified. Both APKs are in phone Downloads and match the Desktop/archive SHA-256 hashes. See `phone-v12-verification.txt`.

Verification emulator overrides were restored and the emulator was stopped. Physical phone display settings were not changed.

Existing development signing remains in use. Store upload requires production signing setup. No store upload or payment integration is included.
