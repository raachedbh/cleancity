# CleanCity 0.18.0+22

Each unlocked city receives up to 20 new litter pieces at the phone's local midnight. Positions and material types vary by night and use the existing safe-placement rules. When the app is closed, missed nights are applied once on reopening, bounded by free map capacity and the remaining cleanup quota. No background service or alarm is required. Goals and attendance retain their existing UTC schedule.

The map limit scales with world area, rounded to ten pieces. New streets begin half full. Normal NPC and ground drops leave eight spaces inside the limit for encounters; midnight refills, thieves and trucks can use those spaces. Nothing can exceed the total cap.

| Map | Starting litter | Total limit |
| --- | ---: | ---: |
| Willow Lane | 20 | 40 |
| Porto Sole | 35 | 70 |
| Tunis Avenue | 40 | 80 |
| Paris Gardens | 55 | 110 |
| Kyoto Lanterns | 60 | 120 |
| Midnight Hollow | 75 | 150 |

Maps shows the cap and a short midnight-refill note. The cap describes litter currently on the ground; the existing 600+ piece cleanup-round targets still track work across repeated pickups.

Save schema 18 persists the last processed local calendar date, including nights when the map was full. Reopening, travel and clock rollback do not grant a second refill. Upgrades from older saves start counting nights on the upgrade date. Overfull legacy streets are trimmed once, prioritizing recent truck drops; collected IDs, wallets, outfits, album progress, bag contents and recycling jobs are preserved. A completed cleanup round can begin again at midnight without replacing the live litter list or duplicating rewards.

Validation: all 99 unit/widget tests passed. The seven focused midnight tests cover live midnight, offline catch-up, duplicate prevention, clock rollback, all-source caps, random reachable placements in every city, cleanup quotas and migration from schemas 16 and 17. The cap test was also rerun after strengthening it to attempt drops on an unoccupied location at the limit.

Static analysis passed with no issues. The regular release APK installed and opened on the Android emulator. Its version, regular progression mode and Maps labels were verified, with a visual review of `screenshots/v18/release-regular-maps.png`.

Both regular and test release APKs built successfully. Package IDs, labels, version 0.18.0 (22), startup, game mode and the new Maps labels were verified on the emulator. Desktop copies match the versioned local archives by SHA256:

```text
CleanCity.apk: 55,700,746 bytes; SHA256 5E27BA6B8643E4AD47E8D072DC4BDB36E738D2B945EF303B7EAF96EE9A4CAEFC
cleancitytest.apk: 55,700,754 bytes; SHA256 975B86B2452D00DF557A7335134CB400DDDF78A3CF8242E3B3E529A7FCD9B26E
```

Both updates were installed on the connected Android phone with app data preserved. Installed version, cold launch and the matching APK copies in Downloads were verified. This update did not reset either save.
