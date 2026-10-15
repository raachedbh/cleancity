# CleanCity v10 city organization

## Reference study

The user's Tour de l'Horloge photo was downloaded from the image embedded in their Google Maps link and inspected at 1600 pixels. Local reference: `docs/references/v10/tunis-clock-user-reference.jpg` (photographer credit visible in the source: AKIRA OHKAWADA). It shows the tapered perforated bronze tower, large square clock housing, pyramidal cap and fountain basin. These features informed the new original Canvas drawing; the photo is not included in the app.

Additional Google Maps satellite views were opened in an unauthenticated browser and visually inspected. Captures retain Google's attribution and live only in `docs/references/v10`:

- Lucca, Piazza dell'Anfiteatro: https://www.google.com/maps/@43.8451,10.5063,18z/data=!3m1!1e3
- Paris, Place des Vosges: https://www.google.com/maps/@48.8556,2.3655,18z/data=!3m1!1e3
- Kyoto, Shirakawa: https://www.google.com/maps/@35.0058,135.7746,18z/data=!3m1!1e3
- Burford high street: https://www.google.com/maps/@51.8076,-1.6367,18z/data=!3m1!1e3
- Rothenburg old town: https://www.google.com/maps/@49.3777,10.1789,18z/data=!3m1!1e3

The Tunis avenue satellite reference remains in `docs/references/v9/google-tunis.png`. All game artwork is original vector geometry: the street plans are stylized interpretations, not exact geographic replicas or imported Google imagery.

## Layout and placement

Each city now has a distinct polygonal district boundary, with more than twice its previous rectangular world area. Road networks are reserved before buildings. Placement rejects both ground-footprint collisions and projected building silhouettes crossing roads, pavement, neighboring buildings, parks, water or the district boundary. This addresses roofs and upper floors appearing in the road even when their ground footprint was technically outside it.

Building types are townhouses, apartments, cafes, markets, villas, civic buildings and workshops. They vary in width, height, floors, roof shape, facade and frontage. Straight building rows, individual paved plots, sidewalks and smaller gardens make the blocks readable. City palettes and details remain distinct: Italian terracotta and shutters, Tunisian pale stone and flat parapets, Paris slate dormers, Kyoto timber/eaves, and Midnight pointed gables.

| City | World size | Street plan |
| --- | --- | --- |
| Willow | 2700 x 1900 | Branching high street, residential blocks and a small park |
| Italy | 3300 x 2600 | Oval piazza with access lanes, surrounding blocks and an eastern market quarter |
| Tunis | 4000 x 2700 | Divided avenue, long planted promenade, clock roundabout and side neighborhoods |
| Paris | 4200 x 3300 | Rectangular garden square, perimeter streets and outer boulevards |
| Kyoto | 4700 x 3300 | Canal, five bridges, parallel lanes and branching residential streets |
| Midnight | 5100 x 3800 | Angular winding streets, market square, graveyard and outer neighborhoods |

Tunis's new clock is approximately 590 world units tall, rendered independently of the old fixed-size landmark template. Its culling bounds include the entire tower. The camera lifts smoothly near the clock so the clock face is visible on the portrait screen.

## Runtime and persistence

Ground painting remains cached at a maximum 2048-pixel longest side. Buildings, trees and props use cached vector pictures, viewport culling and depth sorting. Expanded districts do not require new bitmap assets. The articulated character animation from v9 is retained.

Navigation uses the same convex district boundary and building footprints as rendering; canal water requires bridge crossings. Stations are placed off roads with clear approaches. Save schema 8 preserves progression, inventories, jobs and litter identities while relocating old geometry. The unlocked test build remains isolated from regular saves.

## Regression coverage

The city layout tests independently intersect every projected building envelope with every road segment plus pavement, check neighboring silhouettes, enforce minimum building diversity/counts and verify the expanded world area. Existing route, station, water, litter, migration and animation tests are retained. Rendered previews and device captures are in `docs/screenshots/v10`.
