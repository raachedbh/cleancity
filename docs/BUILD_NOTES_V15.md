# CleanCity 0.15.0+15

## Changes

- Starting litter increases from 64-124 to 90-265 pieces across the six cities. The placement pattern now mixes roadways, open plazas/gardens and building fronts; litter no longer clusters almost entirely around buildings. Street caps increase to 108-333. Cleanup quotas and collected IDs remain finite and unchanged.
- During active play, ground litter attempts to add up to two pieces every 1.4-2.0 seconds, 180-620 world units from the player. Landings must be reachable, clear of stations, buildings and the truck, spaced from existing pieces and below local density/cap/quota limits. No offline emissions or menu/background spawning.
- NPCs attempt a throw every 0.22-0.38 seconds, formerly 0.45-0.8. Individual cooldowns decrease to 1.8-3 seconds; the local cluster limit rises from eight to twelve within 150 world units. Throw animations and mapwide roaming remain in place.
- Tunis Avenue has a three-person interview scene on the central promenade near the clock: a female reporter with a moving microphone, a guest who speaks and gestures, and a camera operator holding a shoulder camera with viewfinder, lens and recording light. They use the existing character art and jointed limbs. Speech alternates over a smooth 12-second cycle; the crew has collision footprints and shares normal depth sorting.
- Fourteen benches form two evenly spaced rows along the Tunis promenade, leaving the central lane and station approaches clear. Bench art gains curved metal arms and timber highlights. A tree/lamp pair is omitted beside the interview so the crew stays visible.
- The requested location screenshot was not received. The central promenade near the clock is the stated provisional position (reporter at 2340,1390).
- Save schema 13 preserves earlier currency, collected progress and truck timestamps. Existing streets receive one top-up to the new density; items covered by new street furniture relocate onto safe ground. Reopening does not repeatedly refill a city. Completed cleanups stay complete.
- Apple boosts remain +35% for five active seconds.

## Verification

- All 77 automated tests passed, including accessible litter on every city, nearby ground spawning/caps/quotas, new bench/crew collisions and walking routes, saved-item relocation without losing truck rewards, existing migrations and NPC/truck/joystick behavior.
- Original vector previews of the interview and promenade were exported and inspected. The crew was moved clear of the road and its collision boxes separated from planted areas after visual/route checks.
- Static analysis passed with no issues before Android verification.
- Android integration passed in 42 seconds: truck collision/bonuses, five-second apple boost, joystick auto-walk/cancellation, travel to Tunis, walking beside the interview crew and live scene/bench screenshots. The final screenshots show the new road/plaza litter and were inspected at phone resolution.

Existing development signing remains in use. No store upload or payment integration is included.

## Release verification

- Final static analysis passed with no issues (7.6 seconds).
- The first release attempt with `--no-pub` retained the integration-test plugin registrant and failed Java compilation. Building normally regenerated plugin metadata, removed the test-only registration and produced the regular release successfully. No generated Java file was hand-edited. The failed attempt is retained in `docs/build-v15-regular-first-attempt.log`.

- Both release APKs built successfully (regular retry: 34.3 seconds; test: 66.7 seconds).
- Both packaged apps passed emulator checks for package identity, version 0.15.0 (15), cold launch, correct regular/test mode and settings. Screenshots and UI dumps are under `docs/screenshots/v15` and `docs/release-v15-*`.
- Desktop copies match their versioned release archives by SHA256:

```text
CleanCity.apk: 55,453,534 bytes; SHA256 261B85E7E1B717AE7AEA9A8B48A69DA8B7499E859F22D6EF69E614CB6295B39B
cleancitytest.apk: 55,453,546 bytes; SHA256 D01FAC50C091929EFCFA6BB754E4F31177526E2315BDB692C2501E7CCD6A628F
```

- Temporary emulator display settings were restored and the emulator stopped after verification.

## Phone delivery

- After the user reconnected the authorized Huawei JNY-LX1 (AUDUT20813003693), both packages installed with `adb install -r`, preserving app data.
- Both installed versions report 0.15.0 (15); successful cold launches and running processes verified. The test app was left open.
- `CleanCity.apk` and `cleancitytest.apk` are on the Desktop and in the phone Downloads folder. All copies match their release archive SHA256 values. Details are in `docs/phone-v15-verification.txt`.
