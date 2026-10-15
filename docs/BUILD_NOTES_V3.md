# CleanCity 0.3.0+3

- Compact notices inside the top HUD, with a 3-second lifetime. A full bag says only ?Bag full? and is not repeatedly announced until bag space is freed.
- Individual code-rendered houses with dimensional roofs/walls, windows, gardens and different storefronts. City-specific palettes, original landmarks, sidewalk details and outer green belts. Static geometry is cached in pictures; offscreen lots and pedestrians are culled.
- 12?24 pedestrians walk connected routes and occasionally toss litter with a short visible arc. Opening litter appears near curbs, at 36?48 active items across a whole map. Additional drops remain capped and stop at the cleanup quota. Paused/background play produces no new litter.
- Base material values are now 2/3/4 coins, down from 3/4/5. Multipliers remain. Old banked coins and already-deposited batch payouts are preserved.
- Save format 3 persists active street items and migrates formats 1 and 2 without resetting currencies, inventory, unlocks or goals. Reopening cannot refill collected items.

## Validation
- `flutter analyze`: no issues.
- `flutter test`: 29 tests pass, including all six cities? pedestrian navigation, spawn bounds/caps, street persistence, full cleanup renewal and v2 save migration with an old locked payout.
- Existing integration flow updated for the active litter list; full integration run was not repeated for this build after the user requested the APK immediately.
- Universal Android release build. Development signing and application ID remain compatible with the previous preview.

## Limits
Pacing with the new lower payouts needs player feedback; the earlier 60-minute first-map estimate is no longer a measured or guaranteed target. Physical-phone frame performance and iOS still require separate testing. Real-money payments remain disabled.
