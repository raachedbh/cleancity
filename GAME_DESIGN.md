# CleanCity — confirmed version 0.2 design

Confirmed by the owner on 8 October 2026. This replaces the initial Greenhaven proposal.

## Experience
Portrait, full-screen Flutter + Flame exploration with original cartoon art. The world renders behind compact floating controls. Move with the joystick or tap a destination; routes follow connected streets and avoid buildings. Collect nearby litter automatically. Multiple recycling stations and a live minimap help with larger cities. Main progression remains relaxed.

## Cities and unlocks
| City | Blocks | Litter per cleanup | Unlock | Recycling multiplier | One-time gift |
| --- | ---: | ---: | --- | ---: | --- |
| Willow Lane | 6 | 120 | Free | 1.00× | Starter outfit |
| Porto Sole, Italy | 9 | 165 | Level 10 + 4,500 coins | 1.35× | 350 coins |
| Tunis Avenue, Tunisia | 12 | 210 | Level 18 + 14,000 coins | 1.75× | 750 coins |
| Paris Gardens, France | 16 | 255 | Level 26 + 32,000 coins | 2.20× | 1,500 coins |
| Kyoto Lanterns, Japan | 20 | 300 | Level 35 + 65,000 coins | 2.80× | 3,000 coins + Lantern ranger |
| Midnight Hollow | 25 | 345 | 80 gems only | 3.20× | 1,200 coins + Velvet vampire |

Unlock gifts are credited once. Outfits included with a city are awarded even if the player is wearing something else; an already owned outfit is not duplicated or refunded. The current six maps use different artwork on expanding connected street grids. Tunis is a stylized interpretation of the avenue and clock, not a geographic reconstruction.

## Economy and pace
- Bottle: 3 coins; can: 4; cardboard: 5.
- Batch payout = rounded sum of material value × origin-city multiplier × (1 + 0.12 × recycling-value upgrade).
- First purchasable outfit costs 1,000 coins, then 3,000 and 7,500.
- Original premium outfits: Velvet vampire 35 gems; Lantern ranger 50 gems. Both also come with their respective map unlocks.
- Gear starts at 350/550/800/650/500 coins (bag/reach/value/machine speed/batch capacity).
- Each next upgrade costs base × 1.85^current level, rounded. Six upgrades per gear item.
- Capacity starts at 16, +8 per bag upgrade. Batch capacity starts at 16, +12 per batch upgrade.
- First new city targets roughly one hour of active play. Level 10 requires 4,320 XP, roughly 1,080 collected-and-recycled items. At an assumed 18–22 items/minute, that is 49–60 minutes before discretionary gear/outfit spending. This is a tuning estimate, not a measured player guarantee.

## Levels and magnet
- 1 XP for collecting; 3 XP when recycling finishes.
- Cumulative XP at level L: 120 × (L−1) + 40 × (L−1)^2. Level cap: 100.
- Every level awards 10 + 2L coins; every fifth level adds 15L; every tenth adds another 25L.
- Level 5 unlocks a 15-second activated magnet, followed by 90 seconds of recharge.
- Magnet attracts visible nearby litter from much farther away. Bag limits still apply; buildings block collection.
- Activation, expiry and recharge timestamps survive app closure.

## Recycling and replay
- Each city has one processing job shared across its stations.
- Deposit up to the machine capacity; those items leave the bag immediately.
- Starting time is 15 seconds. Speed upgrades reduce it to a minimum of 3 seconds.
- Walk, collect, change cities, open menus or close the app during processing.
- Coins and XP are credited once on completion; closed-app completion is settled on return.
- A running batch retains the price, quantity and end time agreed at deposit.
- Finish collecting and processing a city cleanup, then start another at a station. Restoration projects remain permanent.

## Calendar challenges
Calendar periods use UTC: daily at midnight, weekly on Monday, monthly on the first day.
| Period | Goal | Reward |
| --- | --- | --- |
| Daily | Collect 50 | 50 coins |
| Daily | Recycle 150 | 150 coins |
| Weekly | Collect 1,500 | 1,200 coins |
| Weekly | Recycle 2,200 | 1,800 coins + 1 gem |
| Monthly | Collect 9,000 | 7,500 coins |
| Monthly | Recycle 12,000 | 11,000 coins + 2 gems |

One activity can advance all three current periods. Claims are explicit and single-use per period. An offline batch advances only periods containing its actual completion timestamp, so returning tomorrow does not misattribute yesterday's recycling.

## Seven-day attendance
A visit automatically awards that day's gift once. Consecutive UTC days give 25, 40, 60, 85, 120, 160, and 250 coins. Day 7 also gives 5 gems. Day 8 starts another seven-day cycle. Missing a day resets the streak to day 1, without removing earned coins, gems or owned items.

## Store stage
The owner does not have store accounts yet. Earned gems and spending work locally. The planned 100-gem pack is shown at around €5 with purchasing disabled. No charge, simulated receipt, free top-up or payment credential collection is implemented.

Before enabling real purchases: configure store accounts/products, release signing and localized store prices; implement receipt verification, idempotent transaction fulfillment and recoverable server-managed balances. Local offline saves and device time are suitable for this preview, not an authoritative paid economy. Clock rollback cannot duplicate claims in a running save, but forward clock changes and edited local data are not secure.

## Save compatibility
Application ID and preference key remain from Greenhaven to support updating an installed preview. Version 1 saves migrate coins, inventory, gear, outfits, restoration, statistics and previously unlocked maps. The old three map slots become Willow Lane, Porto Sole and Tunis Avenue. Litter layouts and positions are reset to fit the new roads; new cities and premium outfits start locked. XP is derived from prior collection/recycling without retroactive level reward duplication.

## Art and performance
Original generated building, landmark and character atlases, created with the built-in imagegen tool; prompts and workspace paths are in ART_PROMPTS_V2.json. No franchise characters or unverified third-party skin assets are included.
The renderer shares textures, caches the street drawing, culls off-screen sprites, limits pickup effects and precomputes navigation edges. Position saves occur periodically; transactions save immediately.

## Remaining release work
Physical-phone pacing/performance testing, broader character animation, iOS build/testing on a Mac, release signing, final iOS/store artwork, cloud saves and the future billing backend. Android emulator success does not establish 60 FPS or battery performance on physical devices.


## 0.3 feedback update
Notifications move inside the existing HUD; the full-bag notice reads only ?Bag full?. Individual dimensional buildings replace the repeated painted cluster. Pedestrians follow connected routes and visibly drop litter occasionally. Initial street litter is capped at 36?48 near curbs and fronts, with a fixed total cleanup quota and persisted active items. Base material prices change from 3/4/5 to 2/3/4 coins; old pending payouts remain locked. Previous first-map pacing estimates need fresh playtesting after these changes.

## 0.4 unlocked test build
Buildings now include address-specific house layouts and separate civic structures for every city, with eight resident appearances. Active litter caps are 18-28 items per map and NPC drop attempts are spaced 10-16 seconds apart. The test build is named `cleancitytest.apk`: level 100, all maps, outfits, upgrades, restorations and powers; 1,000,000 test coins and 10,000 test gems. A separate save preserves normal progression. Payments remain disabled.
