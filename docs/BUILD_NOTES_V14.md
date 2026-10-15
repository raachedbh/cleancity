# CleanCity 0.14.0+14

## Changes

- Starting ground litter increases from 28-48 to 64-124 pieces across the six cities. NPC street caps increase from 70-120 to 96-196; thief/truck reserve space and finite cleanup quotas remain intact.
- NPCs attempt a throw every 0.45-0.8 seconds, formerly 1.0-1.8. Individual pedestrians wait 3-5 seconds between throws, formerly 7-12. Up to eight pieces are allowed within 150 world units instead of five; reachable landings, station clearance and minimum spacing remain enforced.
- Save schema 12 tops up older streets once to the new opening density, constrained by remaining cleanup quota and valid spacing. Existing drops, truck timestamps, collected IDs, currency and progress are preserved. Reopening does not keep replenishing litter. Completed cleanups remain completed.
- Apples give +35% movement speed for five active seconds, formerly +45% for 15 seconds. Another apple refreshes five seconds without stacking speed. Overhead feedback shows the new percentage and countdown.
- Separate regular and unlocked test packages retain their existing IDs and save storage.

## Verification

- 74 automated tests passed. Coverage includes one-time v11 migration, retained truck metadata and collected progress, nearly completed/completed maps, repeat loading, accessible litter, at least 28 new NPC drops in 30 simulated seconds in each city, apple pickup/refresh and exact five-second expiry, and existing movement/truck/recycling/event coverage.
- Static analysis passed with no issues (15.4 seconds).
- Focused Android gameplay test passed in 31 seconds, checking the +35% apple boost and expiry after at most five active seconds, truck collisions/trails/bonuses, and joystick auto-walk/cancellation. The updated overhead text was visually verified in the captured Android screenshot.

Existing development signing remains in use. No store upload or payment integration is included.

## Release verification

- Both release APKs built successfully (regular: 81.7 seconds; test: 64.5 seconds).
- Both packaged apps passed emulator checks for package identity, version 0.14.0 (14), cold launch, correct regular/test mode and settings. Native screenshots and UI dumps are under `docs/screenshots/v14` and `docs/release-v14-*`.
- Desktop copies match their versioned release archives by SHA256:

```text
CleanCity.apk: 55,437,150 bytes; SHA256 E226E33640F57F591B790EA2283D4679ED882BA6B02EA7020F1BEAA4BD1BB5C5
cleancitytest.apk: 55,437,162 bytes; SHA256 3FC8EBA804F386F94D12A160719FD50DA38D1F5E278ACF0715FE4E9EA825997D
```

- Temporary emulator display settings were restored and the emulator stopped after verification.

## Phone delivery

- Both updates installed with `adb install -r` on the authorized Huawei JNY-LX1 (AUDUT20813003693), preserving app data.
- Installed package versions 0.14.0 (14), successful cold launches and running processes verified for both apps. The test version was left open.
- `CleanCity.apk` and `cleancitytest.apk` are on the Desktop and in the phone Downloads folder; all copies match their release archive SHA256 values. Details are in `docs/phone-v14-verification.txt`.
