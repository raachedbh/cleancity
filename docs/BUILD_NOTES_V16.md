# CleanCity 0.16.0+16

## Changes

- Road surfaces, textures, curbs and pavements now share rounded footprints. Each road layer is merged before painting, removing internal junction seams and mismatched square ends. Lane dashes stop across junctions. Plaza edging is omitted at street entrances.
- Tunis promenade is shortened to stop before the clock roundabout; Lucca's north/south approaches connect into its piazza; Midnight gains a paved link from its central square to the main street. Existing buildings remain clear of reserved roads and pavement.
- Minimap preserves each city's aspect ratio, shows green trash dots and gold truck-trash dots, groups nearby pieces for legibility, outlines the camera area and keeps player/stations visible above litter. Markers refresh within 0.2 active seconds and immediately when the litter count changes. It remains a compact overlay.
- Initial litter increases from 90-265 to 180-580 pieces, and normal street caps from 108-333 to 280-780. Cleanup budgets grow from 120-345 to 600-1700; event drops retain 36 extra street slots. The finite old quota previously stopped emissions even when NPC cooldowns were fast. Generating a large quota now falls back to other ground if a small square fills up, so generation cannot get stuck trying only that square.
- Reachable nearby ground drops attempt two pieces every 1.0-1.4 seconds. NPC throw attempts change to every 0.18-0.30 seconds, with individual cooldowns of 1.5-2.4 seconds. Spacing, local density, collision, station clearance and finite round budgets remain enforced.
- Optional city event invitations first appear after 15 active seconds, then 90 seconds after claiming or leaving. The thief first appears after 25 seconds and waits 40-65 seconds between encounters. Trucks first appear after 35 seconds and wait 50-80 seconds between encounters. Running encounters finish before their next cooldown advances. Menus/background time do not advance events, and joined optional activities still have no time limit.
- Save schema 14 tops up old unfinished streets once while retaining currency, inventory, collected IDs and truck timestamps. Old completed cleanups retain their original completion target until renewed. Existing saved long event waits shorten once on upgrade. Current saves retain their cooldowns and do not refill repeatedly on reopen.

## Verification

- All 82 automated tests passed (13 seconds), covering road/plaza boundaries, litter generation and routes across all six cities, minimap dots and collection, completed/unfinished save migration, automatic event timers, NPC movement and reserved event capacity.
- All six original city overview and street renders exported under docs/screenshots/v16; overview images visually inspected.
- Broad Android integration passed in four minutes: all six cities render; movement, recycling, progression, map/skin purchases, optional event rewards, thief capture, HUD controls, joystick positions and light/dark settings work. Live minimap/litter screenshots were inspected in both themes.
- Final static analysis passed with no issues (6.3 seconds).

Existing development signing remains in use. No store upload or payment integration is included.

## Release verification

- Both release APKs built successfully: regular 74.7 seconds, test 64.8 seconds.
- Both packages passed emulator checks for package identity, version 0.16.0 (16), cold launch, regular/test mode and settings. Native screenshots and UI dumps are under docs/screenshots/v16 and docs/release-v16-*.
- Desktop copies match the versioned release archives by SHA256:

```text
CleanCity.apk: 55,486,302 bytes; SHA256 3E89D729D6BFE5BAEA2D1FB6CF659A4C1507120AB27000B8972E76A149FEB63C
cleancitytest.apk: 55,486,310 bytes; SHA256 6D46E10B46F447A636486E207DA6D26E00680ECB4F6D3BFEF651B30CF4383AB8
```

## Phone delivery

- Both apps installed with adb install -r on the authorized Huawei JNY-LX1, preserving their app data. Installed version 0.16.0 (16), successful cold launches and running processes verified for both; the test app was left open.
- Desktop and phone Downloads copies match the release archive SHA256 values. Details are in docs/phone-v16-verification.txt.
- Temporary emulator display overrides were reset and the emulator stopped after verification.
