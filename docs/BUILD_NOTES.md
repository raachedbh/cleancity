# Preview build — 8 October 2026

## Delivered

- Flutter + Flame project with Android, iOS, and development web targets.
- Three illustrated districts: Willow Lane, Market Street, and Seabreeze Bay.
- Original directional character art, four purchasable/equippable outfits, lightweight cutout walking motion.
- Joystick and destination-tap movement, automatic collection, inventory limits, recycling and optional sorting bonus.
- Equipment upgrades, eight missions, nine persistent restoration projects, and district unlocks.
- Local automatic saving, offline assets, sound effects, haptics, and lifecycle-aware pausing.
- Installable release-mode Android preview at `releases/Greenhaven-0.1.0-preview.apk`.

## Validation

- `flutter analyze`: no issues.
- `flutter test`: 14 passing model and navigation tests.
- Android emulator integration test: passed. Covers onboarding, rendered world dimensions, joystick input, a full collection bag, recycling, equipment and outfit purchases, restoration, district travel, save round-trip, and lifecycle pausing while a shop is open.
- `flutter build apk --release`: successful, 58,340,212-byte universal APK.
- Release APK installed and launched on the Android API 36 emulator.
- Actual release UI visually checked at 1080×2400 / 420 dpi and 720×1280 / 320 dpi. Emulator display overrides were reset afterward.
- Native device save verified by collecting an item, backgrounding, force-stopping, and relaunching: inventory, collection progress, position, and completed onboarding persisted.
- Screenshots are saved in `docs/screenshots/gameplay.png`, `welcome.png`, `wardrobe.png`, and `compact-phone.png`.
- iOS property list parsed successfully and portrait orientation verified. iOS compilation and device testing remain unperformed on this Windows machine.

The emulator has software graphics. These checks do not establish 60 FPS or battery performance on physical phones. Store signing, final store graphics, iOS validation, and further visual/progression playtesting remain release work.

## Artwork

The built-in imagegen tool produced `assets/images/neighborhood.png`, `market.png`, `waterfront.png`, and `characters.png`. Complete prompts are saved in `docs/ART_PROMPTS.json`. PNG transparency is preserved in the character atlas; the game renders individual source regions directly without producing duplicate outfit textures.

The small Android leaf icon is an original vector drawable. Sound effects were synthesized locally. Nunito is bundled with its OFL license.
