# CleanCity 0.7 brand assets

Created with the built-in `image_gen` tool on 9 October 2026, following the imagegen skill. The output is an original generated illustration, not a downloaded brand logo. Exporting only resizes and pads the artwork, adds the solid brand background where required, and converts native icon file formats.

## Files
- `assets/branding/cleancity-mark.png`: original generated transparent master, preserved unchanged.
- `assets/branding/cleancity-icon.png`: 1024px square icon on forest teal, suitable for sharing.
- `assets/branding/cleancity-icon-ui.png`: 192px app UI asset; only this small file is bundled in Flutter's assets.
- `android/app/src/main/res/mipmap-*`: legacy and adaptive launcher sizes; Android 13 themed icons use the same foreground alpha silhouette.
- `ios/Runner/Assets.xcassets/AppIcon.appiconset`: all existing iPhone/iPad icon sizes updated; RGB PNG encoding with no alpha channel.
- `docs/screenshots/v7/icon-masks.png`: round, rounded-square and square mask review, plus small icon previews.
- `tool/export_branding.ps1`: repeatable export on Windows (pass `-Flutter` if Flutter is not on PATH). Uses `tool/export_branding.dart` for deterministic platform sizes and mask-safe padding; strips the iOS icon alpha channel using System.Drawing.

The Android layers keep all visible content within a centered 64dp circle on a 108dp layer, inside the [Android adaptive-icon safe region](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive). Native launch screens use the same brand and follow [Android's splash screen resources](https://developer.android.com/develop/ui/views/launch/splash-screen). iOS assets are prepared; iOS compilation requires macOS/Xcode and was not performed here.

## Final generation prompt (built-in mode)
```text
Use case: logo-brand
Asset type: modern mobile game app icon foreground / standalone brand symbol for CleanCity, a relaxed cartoon city-cleaning and recycling game.
Primary request: an original, polished, immediately recognizable modern CleanCity logo. One bold, friendly circular C-shaped recycling sweep cradles a compact three-building city silhouette. A single leaf grows naturally from the upper end of the C; a tiny four-point cleanliness sparkle finishes the composition. Make this one cohesive emblem, not a collage.
Style: premium contemporary casual-game branding; precise rounded geometric silhouettes, restrained softly shaded depth, crisp edges, confident thick shapes, very few details. Flat frontal presentation. Readable at 48 pixels.
Palette: bright mint/jade C and leaf, warm ivory city towers with two or three deep evergreen window cutouts, a small sunny yellow sparkle. Designed to be displayed over a deep forest-teal background (#123B32), but the output background itself must be genuinely transparent.
Composition: centered square image, the complete emblem fully contained within the central 64% of width and height, generous transparent padding on all four sides for Android adaptive-icon masks. Buildings, leaf, and sparkle form one balanced centered compact mark.
Text: none. No letters except the implicit C-shaped emblem, no written wordmark.
Avoid: photographic objects, mockup phones, gradients in the background, solid background, rounded-square app-icon frame, white background, small floating debris, thin strokes, stock recycle triangle, trash-bin clipart, excessive ornaments, watermarks, licensed characters.
```
