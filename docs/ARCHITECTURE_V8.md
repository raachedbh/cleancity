# CleanCity 0.8 city and resident artwork

The six districts now have separate street plans shared by rendering, collision, litter placement, the minimap and pedestrian/player navigation. These are original, stylized city interpretations at game scale. They are not exact geographic reconstructions.

## References reviewed on 10 October 2026

Google Maps searches were attempted for Avenue Habib Bourguiba and Piazza della Repubblica. The Florence place listing was accessible, but interactive Maps / Street View did not load in this environment. No Google Maps imagery was copied into the game.

- Tunis: [Google Maps place search](https://www.google.com/maps/search/Avenue+Habib+Bourguiba+Tunis/), [firsthand avenue photographs from International Bicycle Fund](https://www.ibike.org/bikeafrica/tunisia/essay/north/1-Tunis.htm), [architectural guide by Daniel E. Coslett](https://soukra.co/top-ten-architecture-sites-tunis/), and the prior Municipal Theatre references in architecture-references.md. The photographed promenade, pruned ficus rows, masonry facades, lamps and stone paving informed the new avenue. Original Art Deco apartment variants and low courtyard shops complement the theatre and clock tower. The game layout runs horizontally to fit portrait navigation.
- Italy: [Florence Google Maps place listing](https://www.google.com/maps/search/Piazza%20della%20Repubblica%2C%20Florence%2C%20Italy), [FeelFlorence / Municipality of Florence](https://www.feelflorence.it/en/points-interest/piazza-della-repubblica), and [Progenia's Palazzo Levi project photographs](https://www.progenia.it/en/case-histories.88/palazzo-levi-florence). Large stone paving, an open piazza, rusticated palazzo fronts, cornices, pediments, loggias and the existing Arcone interpretation guide the district. The campanile, loggia and palazzi are original composite designs, not reconstructions of named buildings. Cypress and lemon trees distinguish its planting.
- Paris: [Ville de Paris, Square Louis XIII](https://www.paris.fr/lieux/square-louis-xiii-36), and [Paris tourism, Place des Vosges](https://parisjetaime.com/eng/transport/place-des-vosges-p1907). Central lawn, crossing gravel paths, garden beds, plane trees, slate roofs and brick arcades inspired the garden-square plan. Limestone apartment blocks add a second architectural silhouette.
- Kyoto: [Japan National Tourism Organization, Gion](https://www.japan.travel/en/spot/84/). Timber machiya, bamboo blinds, tiled eaves, teahouses and the Shirakawa canal informed narrow stone lanes, a long canal, five usable bridges, willows and cherry trees. A lower tea pavilion provides a different building form alongside two-storey shopfronts.
- Willow Lane and Midnight Hollow are fictional. Willow has staggered suburban blocks and oak planting; Midnight has winding cobbled streets, a graveyard garden, bare trees, pines and warm lamps.

Reference images under docs/references/v8 are local visual references only and are not Flutter assets. No city photo, Google Maps tile, or new downloaded art is bundled. Architecture, trees, paving, shadows and residents are original Canvas drawing code. Existing branding and outfit assets are retained.

## Rendering and scale

Buildings have side faces, roof planes, recessed openings, cornices, balconies, masonry joints and directional cast shadows. Architecture variants are selected by city/address. Native vector pictures are recorded once per lot/prop, culled outside the camera and sorted against actor foot positions. Foliage fades near the player when it would obscure them. Larger, species-specific silhouettes replace the small universal tree.

The flat pavement/road picture is rasterized once per loaded district to a texture capped at 2048 pixels on its longest side (at most 16 MiB RGBA). It is disposed on map change. Detailed buildings, trees and actors remain vector pictures/drawings. No online map requests are made by the app.

## Residents

Eight original residents have larger white cartoon eyes, distinct hair/jaw shapes, skin tones and accessories, matching the player's outline weight and proportions. Front, back and both side views are separate. Legs use the existing distance-based gait; arms are continuous jointed paths with shoulder sleeves, elbows and palms. Throwing turns the resident toward the drop and starts litter at the drawn hand.

## Save continuity

Save schema 6 migrates earlier active litter to the new valid curb positions while preserving each ID and material. Collected IDs are not regenerated. Coins, gems, XP, outfits, unlocked maps, inventory, events and queued recycling jobs use their existing fields. A player saved inside a newly blocked building or canal is moved to that city's safe spawn. Normal/test save isolation remains unchanged.

Review exports are in docs/screenshots/v8. Native gameplay screenshots are captured by the Android integration flow; offline art sheets show multiple poses and all city plans for review.
