# CleanCity 0.17.0+19

## Gameplay

- Thieves drop 2-4 randomly chosen pieces of jewelry, wallets, handbags and watches. Step within 42 world units with line of sight to collect them, even with a full litter bag. Uncollected valuables persist in their city through travel and reopening. Items do not count as recycled trash.
- The existing 25-coin catch reward remains. Return collected valuables to a police station for 3 coins per wallet, 4 per handbag, 5 per watch and 6 per jewelry item. The album retains lifetime found/returned totals. Repeated pickup and return actions cannot pay twice.
- Every city has a solid police kiosk with a clear off-road lot, reachable entrance, minimap shield and color palette matching the city. The contextual To police / Return button appears only while carrying valuables; Album also provides this action.
- Album has Rewards and Progress tabs. It tracks lifetime collection, recycling, thieves caught, returned valuables and unlocked cities. Twelve permanent souvenirs include Golden city for 100,000 actually recycled items. Existing lifetime progress earns applicable souvenirs on migration; historic catches do not invent valuables.
- First city activity appears after 120 active seconds; new activities wait 360 seconds after the previous is claimed or left. First thief waits 150 seconds and subsequent encounters wait 240-360 seconds after the previous ends. First truck waits 210 seconds and subsequent trucks wait 300-420 seconds after the previous ends. Failed spawns retry after 45 seconds. Thief/truck countdowns pause while the other is present. Menus and time away do not advance them.
- Thief in the city / Trash truck nearby alerts are queued by city and displayed in the top HUD for five seconds. No modal popup. Existing city activity invitations remain relaxed and do not expire.
- The reduced ambient trash density and NPC throw rates from 0.16.2 are retained. Apple speed remains +35% for five seconds.

## Persistence and validation

Save schema 17 preserves existing wallets, map/outfit ownership, litter IDs, inventory, jobs and event progress. Older street items overlapping a new police kiosk are relocated safely. Older short encounter waits are lengthened once. Valuables and souvenirs are validated and saved alongside normal progress. Regular/test saves remain separate.

- All 91 unit/widget tests pass (7 seconds), including police routing across six cities, drop variety and reachability, pickup/return idempotence, travel/reload persistence, layout migration, souvenir migration and the 100,000 recycling threshold.
- Static analysis passes with no issues (5.7 seconds).
- Android album integration passes (54 seconds), including the city alert, visible dropped valuables, collection with a full bag, Album controls, automatic police navigation, return payouts, save reload, dark mode and the Golden city souvenir. A final label-only cleanup removes a stray question mark from the contextual police action; no gameplay logic changed after these checks. Freshly rendered police screenshots cover all six cities in docs/screenshots/v17.
- Regular and test release builds succeeded. Emulator checks verified application IDs/labels, version 0.17.0 (19), cold launch, normal/test mode separation and Settings.
- Desktop APK copies match the archived builds by SHA256. Physical phone checks follow below.

Development signing remains in use. No store upload or real payment integration is included.

## APK files

```text
CleanCity.apk: 55,683,978 bytes; SHA256 064790204A7F7B432C016F5039D9C73BDD662D525D50FADD613EEB44914E9118
cleancitytest.apk: 55,683,990 bytes; SHA256 2DC4AF222B34A9B97048678661C5058A4A8A787967F54CE916B6DF899FB531F0
```

## Physical delivery

Both apps installed successfully with adb install -r on the authorized Huawei JNY-LX1. Package versions 0.17.0 (19), cold launches and running processes were verified. Existing app data was retained. Both APKs were also copied to the phone Downloads folder and checked against the archive SHA256 hashes; details are in phone-v17-verification.txt.

The test game home screen, Album button and retained Tunis event progress were confirmed on the phone (screenshots/v17/phone-test.png). Another app came to the foreground during the optional phone Album tap check, so the Album flow validation relies on the passing Android emulator integration test rather than claiming that extra phone UI check passed. Temporary emulator display overrides were restored and the emulator stopped.

Final label-cleanup APK rebuilds completed in 36.5 seconds (regular) and 38.2 seconds (test). The final APK metadata, Desktop hashes, phone installation versions and Download hashes were checked again.
