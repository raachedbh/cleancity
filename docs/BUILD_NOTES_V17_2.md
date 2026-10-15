# CleanCity 0.17.2+21

New games default to Dark mode, including older saves without a theme preference. An explicitly saved Light or Dark choice is preserved. Existing progress and save schema 17 are unchanged.

The first-launch guide now contains five short, illustrated tips: movement and automatic collection, recycling, upgrades and maps, rewards and the magnet, and the album/police loop. It scrolls on smaller screens. Start, Close, Android Back, tapping outside and swiping down all persist completion through the existing `introduced` flag. Completed players do not see it again.

Validation completed:

- All 27 preference and game-state tests passed, including fresh Dark defaults, legacy defaults, saved Light preferences, guide completion persistence, save recovery and unchanged progress.
- The Android onboarding integration test passed all five dismissal routes and reopening after each. Default Dark rendering and no UI exceptions were verified.
- Visually reviewed `screenshots/v17.2/quick-start-dark.png` and `screenshots/v17.2/dark-home.png` from the Android emulator.
- Static analysis passed with no issues.
- The regular APK built successfully. Its package, version 0.17.2 (21), regular progression mode and Settings screen were verified on the emulator. The first activity-manager launch waits timed out on the resumed emulator; subsequent screenshot and UI checks confirmed the app rendered and responded correctly.

Both release APKs built successfully. Package IDs, app labels and version 0.17.2 (21) match the regular and unlocked test modes. Both installed and opened on the emulator, with the expected game mode and Settings version verified. Versioned archives are retained locally in `releases/`; Desktop copies were verified against those archives by SHA256:

```text
CleanCity.apk: 55,684,362 bytes; SHA256 D6AC72CA989C59665EF2BD97B87417A464A755B556BC7D87CAA32AD35FF5EE90
cleancitytest.apk: 55,684,370 bytes; SHA256 C17BE88984D85DE8514329C3018C0BB12C8B78289B39C5D68239BFDE3FCE267C
```

The physical phone was disconnected when the builds finished, so these updates have not been installed there. No phone saves were changed.
