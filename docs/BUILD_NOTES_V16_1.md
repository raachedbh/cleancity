# CleanCity 0.16.1+17

Includes the street/minimap/litter/event changes described in BUILD_NOTES_V16.md.

## Cleared-map follow-up

The first physical-phone inspection of 0.16.0 showed a fully cleared saved Tunis map with items still in the bag. Preserving the old completed round left that map empty until manual recycling and renewal. Active gameplay now starts a fresh round automatically once all street litter is collected, including already-completed legacy rounds. The next round has unique cycle IDs and the increased litter supply; coins, cumulative collection totals, bag contents, event progress and recycling jobs are retained. No reward is paid merely for renewing, and menus/offline loading do not advance the street cycle. The game immediately updates both world litter and minimap markers.

## Verification

- All 83 automated tests passed (9 seconds), including a completed legacy round with both held inventory and a pending recycling job, uniqueness of new cycle IDs, no duplicate payment and no refill on reopening a partial round.
- Focused Android integration passed in 43 seconds, reproducing the cleared legacy map with held inventory and then exercising truck collision/rewards, five-second apple boost, joystick auto-walk and Tunis street/interview navigation.

## Requested density reduction

After seeing the denser update, the user requested less trash. Starting supply is reduced to 120-345 (from 180-580); normal street caps to 170-470 (from 280-780), retaining 36 extra event slots. NPC throw attempts now occur every 0.35-0.55 seconds and individual cooldowns are 2.2-3.5 seconds. Ground emissions add at most one piece every 1.8-2.5 seconds. Faster event schedules, larger per-round budgets and automatic round renewal remain.

Save schema 15 thins already-populated older streets to the new starting density once, prioritizing saved truck drops. Retired uncollected items grant no coins, XP or progress; collected IDs, bag contents, wallet and event/recycling state remain intact. Subsequent reloads do not re-thin or refill the current round.

Final automated suite: all 84 tests passed (10 seconds), including thinning dense schema-14 streets across all six maps without losing collected progress or truck metadata. Final static analysis passed with no issues (7.4 seconds). Release packaging completed.

## Final release and phone delivery

- Both final APKs built successfully (regular 54.8 seconds; test 64.0 seconds). Both passed emulator checks for package identity, version 0.16.1 (17), cold launch, correct regular/test mode and settings.
- Both updates installed with adb install -r on the authorized Huawei JNY-LX1. App data was retained; installed versions, successful cold launches and running processes were verified. The test app remains open.
- The final phone screenshot shows the formerly empty saved Tunis map populated again, with litter markers, truck trail markers and an active thief marker; held inventory and the existing bottle event remain present. Screenshot: docs/screenshots/v16.1/phone-test.png.
- Desktop and phone Downloads copies match the release archives by SHA256. See docs/phone-v16.1-verification.txt.

```text
CleanCity.apk: 55,486,302 bytes; SHA256 6DBEB3E846687A65351BA29336E9AB5DA63AEF8E5F82E95CAA03CDDBE27A982D
cleancitytest.apk: 55,486,310 bytes; SHA256 72479515F5BCB0A1603A987C5E2EFFE3369767407F94D5066AC656793A1212AE
```

- Temporary emulator display overrides were restored and the emulator stopped.
- Existing development signing remains in use. No store publication or payment integration was performed.
