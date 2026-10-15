# CleanCity 0.8.0+8 regular Android build

## Changes
- Redesigned NPC faces and arms to match the player; eight distinct residents and direction-aware walk/throw poses.
- Separate street plans for all six cities, synchronized with collisions, pathfinding, pickups and the minimap.
- Tunis promenade with granite paving and ficus rows; Florence-inspired stone piazza, palazzi and loggia; Paris garden square and apartment variants; Kyoto canal with five real bridge crossings and teahouses; staggered Willow blocks; winding Midnight cobbles and graveyard planting.
- Larger city-specific trees, directional shadows and cached ground rendering. See ARCHITECTURE_V8.md for source references and rendering details.
- Save migration retains progress and relocates legacy litter/player positions as needed for changed geometry.
- Regular CleanCity progression, app identity, modern logo, transparent HUD/settings, 12 outfits, optional events and economy retained. Payments are still not connected.

## Verification
- Final `flutter analyze --no-pub`: no issues.
- All 52 automated tests passed. Coverage includes routing to all litter in six maps, two minutes of pedestrian simulation per city, all spawns/stations, Kyoto canal/bridge collision, and v5-to-v6 progress migration followed by another save/load.
- Architecture, resident (front/back/side/walk/throw), movement and six-map preview exporters passed. Images visually reviewed in docs/screenshots/v8.
- Full Android integration flow passed in 3:34 on the API 36 emulator: onboarding, collection, recycling, rewards, map/outfit access, all six districts, HUD opacity/hiding, joystick placement and blocked walking, dark/light themes, goals, shop, settings and optional city events. Device screenshots saved under docs/screenshots/v8.
- Final release installed and cold-launched successfully. Verified native app label CleanCity, version 0.8.0/code 8, starter level 1, bag capacity 16, zero gems, normal day-1 reward and Porto Sole locked at level 10 / 4,500 coins. Settings shows Version 0.8.0 without test controls.
- Scoped AndroidRuntime/Flutter error log was empty after release launch and menu checks. iOS and physical-phone performance were not measured. Ground texture memory is bounded by code; this is not a physical-device frame-rate guarantee.

## Artifact

Build command: `flutter build apk --release --dart-define=CLEANCITY_TEST_MODE=false`.

- Desktop: `C:/Users/raxhe/Desktop/CleanCity.apk`.
- Archive: `releases/CleanCity-0.8.0.apk`; earlier version archives remain.
- Size: 54,830,282 bytes (52.3 MiB).
- SHA-256: `7D64C288AB01F9F742266050A2C80BABD41DCEFAF3ABA7B74425EFEE4D3B4731`.
- Build output, Desktop APK and archive hashes match.
- Universal APK includes armeabi-v7a, arm64-v8a and x86_64. minSdk 24, targetSdk 36, package com.greenhaven.greenhaven, existing development signing.
- Previous Desktop `cleancitytest.apk` was not replaced; its SHA-256 remains `AC4D73B0A377F0E065E34FD300878DB2A8C7302CF3AB98B1E526B163F0B4D510`.
- Display overrides were reset and the verification emulator was stopped. No store publication or payment setup was performed.
