# CleanCity 0.17.1+20

NPCs attempt one litter throw across the city every 7-10 active seconds, previously 8-12 seconds. This is approximately 18% more frequent attempts on average, with the first attempt after seven seconds instead of eight. Actual drops still require an eligible NPC and an uncluttered, reachable landing.

The existing 45-75 second cooldown per NPC, local crowding limits, ground spawning, street caps, starting litter and rare event timings remain unchanged. No save migration is required; schema 17 and both app save identities are retained.

Seven existing city-life and pedestrian-roaming tests passed (6 seconds of test execution). Coverage includes two-minute simulations across all six cities, conservative litter growth bounds, unique saved drops, valid pedestrian movement, reachable litter, quota enforcement and save preservation. No new tests were added for this small tuning change.

Static analysis passed with no issues (192.6 seconds). The regular release build completed successfully in 342.8 seconds. Its package, application label and version 0.17.1 (20) were verified. The test release build also completed successfully in 207.8 seconds. Both APK package identities, labels and version 0.17.1 (20) were verified. Desktop copies match their versioned release archives by SHA256.

```text
CleanCity.apk: 55,683,974 bytes; SHA256 6680EC1BF5E8259BB300B250AE58AE83F605CD7B3D0F1B4DC996C40862E95BDD
cleancitytest.apk: 55,683,986 bytes; SHA256 549686A55BBFAB6A18D03CCD13ECF93345CD251F1E5790BC15A8056B7F9B07EA
```

Both updates installed with adb install -r on the authorized Huawei JNY-LX1, preserving app data. Installed version 0.17.1 (20), running app processes and SHA256 hashes for both phone Downloads copies were verified. The phone was locked during launch checks, so no new claim of visual phone verification is made. Full delivery details: phone-v17.1-verification.txt.
