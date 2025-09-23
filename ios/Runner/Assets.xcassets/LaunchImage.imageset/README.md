# Launch Screen Assets — JFlutter Branding

The iOS launch storyboard centers a single raster image view (`LaunchImage`) with a base size of **168 × 185 pt**.
Provide all three universal scales listed in `Contents.json` so the storyboard can resolve retina variants without
runtime warnings.

## Required export set

| Scale | Filename              | Pixel dimensions | Usage |
| :---: | --------------------- | ---------------- | ----- |
|  1×   | `LaunchImage.png`     | 168 × 185 px     | Base asset referenced by the storyboard. |
|  2×   | `LaunchImage@2x.png`  | 336 × 370 px     | Retina (@2×) devices. |
|  3×   | `LaunchImage@3x.png`  | 504 × 555 px     | Retina HD (@3×) devices. |

> ℹ️ The repository currently ships placeholder 1 × 1 px files for each scale. Replace them with the brand-compliant
> renders described below before releasing.

## Visual direction

* **Logomark** — Reuse the current JFlutter logomark exported for the application icon. Start from the master vector that
  produced `Icon-App-1024x1024@1x.png` to preserve the geometry and glow. Avoid redrawing or flattening the layered
  gradients.
* **Color palette** — Maintain the deep cosmic teal background (#162631 ≈ RGB 22 / 38 / 49) with the soft cyan glow that
  peaks around RGB 208 / 240 / 246 near the logomark’s highlights to stay aligned with the current app icon and favicon
  treatments.
* **Safe area** — Keep at least 32 pt of padding around the symbol inside the 168 × 185 pt artboard so it remains fully
  visible on compact devices. The icon should stay centered; avoid adding extra artwork or gradients outside the
  logomark.

## Typography guidance

The launch experience is **imagery-only**. Do not typeset the wordmark or taglines on the splash screen—only the centered
logomark should appear, matching the storyboard configuration (image view only, no labels).

## Delivery checklist

1. Export 1×/2×/3× PNGs following the table above (sRGB, no transparency trimming).
2. Replace the files in this directory with the updated renders while keeping the existing filenames.
3. Open the project in Xcode (`open ios/Runner.xcworkspace`) and verify that *LaunchImage* resolves to the new artwork in
   the asset catalog preview.
4. Run the Flutter app on an iOS simulator to confirm the launch screen matches the brand reference screenshot.
