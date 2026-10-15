# CleanCity 0.13.0+13

## Changes

- NPCs attempt a litter drop every 1.0-1.8 seconds instead of 2.5-4.5 seconds. All pedestrians can participate; each takes a 7-12 second break between throws. Nearby pedestrians are preferred. The street cap increases from 42-72 to 70-120 across cities, with 36 shared extra spaces for thief/truck trails. Opening litter stays unchanged; existing saves fill naturally through NPC activity. Accessible landings, spacing and finite cleanup quotas still apply.
- Trash Truck is an optional street encounter. First arrival is after 95 active seconds, followed by randomized 150-240 second waits. A nearby curbside spawn and travel direction are selected from real street geometry. Every route has full vehicle clearance. The truck runs for 28-40 seconds or until its route ends, yields to the player/pedestrians, and drops up to 20 pieces behind it. Player movement and pickups cannot pass through its collider. A world label, minimap truck marker and Events card identify it.
- Truck litter pays an immediate pickup bonus of 8 coins, decreasing by 1 every four seconds to a minimum of 1 after 28 seconds. The ordinary recycling value is still earned later. The displayed bonus and gold ground highlight show freshness. Bonus timestamps persist across saves and city changes; menus/time away do not reset freshness. Full bags and duplicate pickups never pay a bonus.
- Nearby trees have a 40% chance to drop an apple on each 4-7 second check. Landings must be reachable; each tree has a 60-second cooldown. Up to six apples may be present, disappearing after 65 active seconds. Stepping within 24 world units of a landed apple gives +45% walking speed for 15 active seconds, even with a full bag. Another apple refreshes the duration without stacking speed. Menus/backgrounding pause the effect; changing city/relaunching clears this temporary effect.
- Double-tapping the same joystick edge starts continuous movement in that direction. A map touch cancels it; regular drags still stop on release. Menus/backgrounding cancel auto-walk and hitting an obstacle stops it. Only short, nearby edge taps count; ordinary map taps and second fingers cannot trigger it. The joystick icon and overhead status show auto-walk.
- Test Settings includes Preview trash truck and Drop an apple. These controls are absent from the regular build.
- Save schema 11 preserves earlier streets, wallets, pickups and unlocks; it adds truck timestamps and the encounter cooldown. Regular and test packages/saves remain separate.

## Verification

- 72 automated tests passed, plus a new six-city traffic regression: pedestrians route around the truck and its trail continues without a deadlock. Coverage includes truck routes and clearance over three seeds per city, player yielding, no onboarding/quota spawns, saved/decaying/single-payment pickup bonuses, v10 save migration, apple pickup/expiry/boost behavior and joystick direction/timing/cancellation.
- Final static analysis passed with no issues (6.3 seconds).
- Focused Android event test passed in 27 seconds: test preview controls, solid truck/player collision, a live litter trail, immediate bonus payment, an apple pickup/speed boost, actual joystick double-tap movement, touch cancellation and menu cancellation. Screenshots inspected under `docs/screenshots/v13`.
- Full Android regression passed in 3:50, including all six maps, outfits, progression, recycling, thief capture, controls/settings, events and saved state.

Existing development signing remains in use. No store upload or payment integration is included.

## Release verification

- Both release APKs built successfully (regular: 112.2 seconds; test: 67.3 seconds).
- Both packaged apps passed emulator checks for package identity, version 0.13.0 (13), cold launch, regular/test mode and the new joystick settings. Native screenshots and UI dumps are saved under `docs/screenshots/v13` and `docs/release-v13-*`.
- Desktop APK copies match their versioned archives by SHA256:

```text
CleanCity.apk: 55,437,150 bytes; SHA256 56235C23434CB1EB90765427F27C93CD85F8638051A6BF06F1A74A63854C64A8
cleancitytest.apk: 55,437,162 bytes; SHA256 BB182A1EAF30502BF177A1B249AB508C09CAA1297E582CA711A37C07FF4BD7EB
```

- Temporary emulator display settings were restored and the emulator stopped after verification.

## Phone delivery

- Both packages installed successfully with `adb install -r` on the authorized Huawei JNY-LX1 (AUDUT20813003693), preserving application data. The phone was unlocked by the user to complete launch verification.
- Both installed packages report version 0.13.0 (13), returned successful cold launches and remained running after launch. The test app was left open.
- `CleanCity.apk` and `cleancitytest.apk` are on the Desktop and in the phone Downloads folder. Both downloaded files match the archived/Desktop SHA256 values. Detailed results are in `docs/phone-v13-verification.txt`.
