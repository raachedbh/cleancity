# CleanCity 0.9.0+9 unlocked Android test build

## Changes
- All six city boundaries are round, with redesigned street networks and connected building frontages. Tunis and Italy use inspected Google Maps satellite references, interpreted as original game geometry.
- City-specific windows, roofs, shutters, balconies, timber latticework, gables, trees and street furniture. See ARCHITECTURE_V9.md for references and rendering details.
- Replaced static player body/arm image fragments with fully animated vector bodies and a shared shoulder/elbow/wrist rig across all twelve outfits and NPCs.
- Shorter menu titles, removed outfit/map marketing descriptions and compact onboarding.
- Test build unlocks all maps, outfits, upgrades and level 100, with 1,000,000 coins and 10,000 gems. The regular save remains separate. Test refill, event preview and starter/max gear controls remain in Settings.
- Save schema 7 retains progress and moves old player/litter positions onto the new streets.

## Verification
- 55 automated tests passed, including continuous arm joints/swing/settling, elliptical world boundaries, routes to every litter item, all recycling approaches, canal bridges, NPC emissions, migration and test-save isolation.
- Final static analysis passed with no issues.
- Movement and six-city art exporters passed; rendered views inspected in docs/screenshots/v9.
- Full Android integration flow passed in 3:51 on API 36: movement, blocked walking, all joystick positions, collection, recycling, goals, six maps, twelve outfits, optional events, shop, HUD transparency/hiding, dark/light UI and save/reload.
- Release APK installed and cold-launched successfully; native UI verified CleanCity TEST, level 100, test wallet, bag capacity 64 and Settings Test build 0.9.0.
- Universal Android APK, minSdk 24, targetSdk 36, app label CleanCity, package com.greenhaven.greenhaven, existing development signing.
- Payments remain unavailable. No store publication performed.

## Build
Command: flutter build apk --release --dart-define=CLEANCITY_TEST_MODE=true

- Desktop: C:/Users/raxhe/Desktop/cleancitytest.apk
- Archive: releases/CleanCity-0.9.0-test.apk
- Size: 55,043,274 bytes.
- SHA-256: C5A2A5C9070ECBE5F6E49E10430B37F326E624614E5472E55EABC465AD8C41B9
- Build, Desktop and archive hashes match. Final bytes were installed and cold-launched; the test wallet/level were verified again.
- Desktop CleanCity.apk remains the previous regular 0.8.0 build.
- Verification emulator display settings restored and emulator stopped. No physical device was modified.
