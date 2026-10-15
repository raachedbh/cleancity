# CleanCity v9 map and animation revision

## References
Read-only Google Maps satellite views were loaded in a fresh, unauthenticated headless browser and inspected visually:
- Tunis, Avenue Habib Bourguiba / clock roundabout: https://www.google.com/maps/@36.7999,10.186,18z/data=!3m1!1e3
- Lucca, Piazza dell'Anfiteatro: https://www.google.com/maps/@43.8451,10.5063,19z/data=!3m1!1e3

Local reference captures (with Google attribution) are in docs/references/v9/google-tunis.png and google-lucca.png. Street View links were also attempted but returned a black unavailable view; they were not used as visual references. No Google imagery is included in the app. These are original stylized interpretations of the visible street plans, not exact geographic replicas. Earlier city/tree references remain documented in ARCHITECTURE_V8.md.

## Geometry and rendering
All six playable boundaries are elliptical. Lucca-inspired joined frontages wrap an oval piazza with four access lanes. Tunis has a circular clock island, two carriageways around the ficus promenade, branching roads and joined terraces. Other districts use a neighborhood loop, a Paris apartment ring and central garden, a Kyoto canal with five bridges, and winding Midnight streets.

Buildings are extruded from city-specific polygon footprints. Facades have layered windows, shutters, doors, awnings, balconies, roof tiles/parapets and cast shadows. Kyoto uses wooden lattice fronts, overhanging eaves, noren and lanterns; Paris has slate dormers; Midnight has pointed gables. Cafe umbrellas, market stalls and benches share the depth-sorted prop renderer.

Ground paving is rasterized once per map at at most 2048 pixels on its longest side. Buildings and props remain cached vector pictures, culled and depth sorted. Ground collisions use conservative building bounds; these keep characters clear of angled facades. The elliptical boundary is enforced by both joystick movement and tap routes. All stations, litter destinations and bridge crossings are covered by navigation tests.

## Character motion
All twelve player outfits use articulated limbs. The original atlas contributes only the head; the torso, sleeves and arms are drawn independently, eliminating painted stationary arms in normal and premium outfits. Player and NPC arms share the same shoulder/elbow/hand rig with a delayed elbow bend, wrist rotation, alternating swings and smooth stopping. Capes and scarves follow the stride. Distance-driven foot placement, acceleration and obstacle stopping are retained.

## Saves and test mode
Save schema 7 relocates legacy litter to the new streets while preserving item IDs, material types, currencies, inventory, recycling jobs and unlocks. Invalid old player positions move to a valid spawn. Test mode uses cleancity_test_save_v1 and never writes the regular save. It unlocks all six cities, all twelve outfits, level 100, all upgrades/restorations and test supplies; Settings retains refill/event/gear preview controls.
