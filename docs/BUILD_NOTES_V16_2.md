# CleanCity 0.16.2+18

## Reduced street litter

- Starting ground litter falls from 120-345 to 45-105 pieces (63-70% fewer), with normal street caps reduced from 170-470 to 65-140. Event reserve remains 36 pieces. Existing minimap markers and automatic completed-round renewal remain.
- The whole pedestrian population attempts one throw every 8-12 active seconds, previously every 0.35-0.55 seconds. Each NPC waits 45-75 seconds before another throw, formerly 2.2-3.5 seconds. Eligible pedestrians are shuffled so the nearest walkers no longer constantly throw around the player. No throws during onboarding.
- NPC throws are rejected if three pieces already lie within 180 world units of the landing. Nearby ground spawning adds at most one piece every 18-26 seconds (formerly 1.8-2.5), rejects landings with three pieces within 200 units and pauses while the bag is full. Starting delays are eight seconds for NPCs and 18 for ground spawning.
- Save schema 16 thins existing schema-15 and earlier streets to the reduced opening density once. Previous version capacity checks are retained so populated saves do not reset. Saved truck timestamps are prioritized; removed uncollected items grant no rewards. Wallets, collected IDs, inventory, goals, outfits, event progress and recycling jobs are retained.
- Event frequency remains unchanged.

## Verification

- All 85 automated tests passed (7 seconds). Two-minute simulations on all six maps verify only 1-5 new ordinary pieces in the first 30 seconds and 3-22 over two minutes, with valid movement and reachable drops. Dense schema-14 and schema-15 migration checks preserve wallets, bag contents, collected IDs and truck timestamps; full bags block ambient ground spawning.
- Static analysis passed with no issues (54.8 seconds). Focused Android integration passed in 41 seconds: cleared-map renewal, truck collision/trail/rewards, five-second apple speed boost, joystick auto-walk and Tunis street/interview navigation. The Tunis gameplay screenshot was inspected and has visibly fewer pieces. Release packaging is complete.

Development signing remains in use; no store upload or payment integration is included.


## Final delivery

- Regular and test release builds succeeded (69.2 and 57.1 seconds). Emulator checks verified package identities, version 0.16.2 (18), cold launch, mode separation and settings.
- Both updates installed with adb install -r on the authorized Huawei JNY-LX1, preserving app data. Installed package versions, successful cold launches and running processes verified. The test app remains open.
- Desktop and phone Downloads APK copies match their versioned release archives. Details are in docs/phone-v16.2-verification.txt.

```text
CleanCity.apk: 55,486,302 bytes; SHA256 31E379E702325BEC8520F9A69BFB8D0ADB66BD9E5EA4E3FCFD8A591233527CF0
cleancitytest.apk: 55,486,314 bytes; SHA256 797B4D457AD9C7B6102011616544CB0F3E909A7982560EC61A68CC6D5F829083
```

- Final phone screenshot: docs/screenshots/v16.2/phone-test.png. Temporary emulator display overrides were restored and the emulator stopped.
