---
name: figma-icon-export
description: MANDATORY workflow for exporting ALL image/icon assets from a Figma design into an iOS project's Assets.xcassets when implementing UI from Figma. Trigger whenever the user says "implement this Figma design", "build this screen from Figma", shares a figma.com URL for iOS work, or any time `get_design_context` / `get_screenshot` returns asset URLs that belong on screen. This skill FORBIDS the shortcut of substituting SF Symbols or solid-color placeholders for real Figma assets — every icon/image referenced in the returned code MUST be downloaded and wired into the project before declaring the task done.
---

# figma-icon-export — Mandatory Figma → iOS asset pipeline

This skill exists because Figma MCP asset URLs have a **7-day expiry** and it is tempting to skip the download step and substitute SF Symbols. That shortcut is NOT allowed for production work — the design must ship with the designer's exact pixels.

## Hard rules (do not violate)

1. **Download every asset URL** returned by `get_design_context` / `get_screenshot` that is used on screen. No SF Symbol fallbacks, no `Color`-filled placeholders, no "designer will swap later" comments.
2. **All assets MUST be PNG.** Figma MCP often serves icons as SVG — convert them to PNG at @1x / @2x / @3x before staging into `Assets.xcassets`. Reasons: (a) Xcode's SVG support has historical edge-cases (color-rendering bugs, `preserves-vector-representation` ignored under tinting), (b) PNG renders identically across iOS versions, (c) downstream tools (UI snapshot tests, native-ad templates, push-notification rich media) assume raster. The only exception is template/symbol SVGs explicitly produced by the design system as monochrome glyphs — and even then prefer PNG unless there is a specific reason.
3. **Commit the downloaded PNGs** into `Assets.xcassets` so the project is reproducible after the 7-day MCP-URL expiry.
4. **Run SwiftGen** so `Assets-Constants.swift` picks up the new names.
5. **Reference via `Asset.*`** — never hardcode `Image("img_foo")` string literals.
6. Ask the user ONCE at the start which asset namespace to use (e.g., `Home`, `Settings`). Default: derive from the Figma frame's top-level name.

If the user explicitly says "use placeholders" or "skip assets, I'll add them later" — respect that and skip this skill. Otherwise the workflow below is mandatory.

---

## Workflow

### Step 1 — Enumerate assets

From the `get_design_context` response, every line of the form

```
const imgFoo = "https://www.figma.com/api/mcp/asset/<uuid>";
```

is an asset you must download. Collect them into a mapping:

| Figma variable | Proposed asset name (snake_case) | Usage on screen |
| -------------- | -------------------------------- | --------------- |
| `imgFi11518112` | `ic_edit_beauty` | Quick action icon |
| `imgRectangle34624272` | `img_hot_trend_1` | Hot-trend thumbnail 1 |
| ... | ... | ... |

Rename to **semantic** names, not Figma's layer IDs. Icons prefix `ic_`, photos/illustrations prefix `img_`, backgrounds `bg_`.

### Step 2 — Create the imageset directory structure

For each asset, under `Resources/Assets.xcassets/<Namespace>/<asset_name>.imageset/`:

```
Resources/Assets.xcassets/
└── Home/
    ├── Contents.json                      # folder-level, namespace marker
    └── ic_edit_beauty.imageset/
        ├── Contents.json                  # references ic_edit_beauty.png
        └── ic_edit_beauty.png
```

**Folder Contents.json** (when `forceProvidesNamespaces: true` in swiftgen.yml, this lets the folder become a nested enum):

```json
{
  "info" : { "author" : "xcode", "version" : 1 },
  "properties" : { "provides-namespace" : true }
}
```

**Imageset Contents.json** (universal, all THREE scale slots filled — see "PNG conversion" below for how to render @1x/2x/3x from a single Figma source):

```json
{
  "images" : [
    { "filename" : "ic_edit_beauty.png",    "idiom" : "universal", "scale" : "1x" },
    { "filename" : "ic_edit_beauty@2x.png", "idiom" : "universal", "scale" : "2x" },
    { "filename" : "ic_edit_beauty@3x.png", "idiom" : "universal", "scale" : "3x" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
```

### PNG conversion

When Figma MCP serves SVG (detected via `file -b --mime-type → image/svg+xml`), convert to PNG before placing in the imageset. Use `cairosvg` (Python) — it's the most reliable headless SVG → PNG renderer on macOS:

```bash
# one-time install
DYLD_FALLBACK_LIBRARY_PATH=/opt/homebrew/lib pip3 install --user cairosvg
```

Render script (per asset, three scales):

```bash
DYLD_FALLBACK_LIBRARY_PATH=/opt/homebrew/lib python3 - <<'PY'
import cairosvg, pathlib, re
src = pathlib.Path("ic_edit_beauty.svg").read_text()
# extract intrinsic width from viewBox or width attr; fall back to 32
m = re.search(r'viewBox="[^"]*\s(\d+(?:\.\d+)?)\s+(\d+(?:\.\d+)?)"', src) \
    or re.search(r'width="(\d+(?:\.\d+)?)"', src)
w = int(round(float(m.group(2 if m.lastindex == 2 else 1)))) if m else 32
for scale, suffix in [(1, ""), (2, "@2x"), (3, "@3x")]:
    cairosvg.svg2png(bytestring=src.encode(),
                     output_width=w * scale,
                     write_to=f"ic_edit_beauty{suffix}.png")
PY
```

Verify each output:
```bash
file ic_edit_beauty*.png   # all three must be "PNG image data, WxH, ..."
rm ic_edit_beauty.svg      # delete the source SVG once PNGs exist
```

Photos / illustrations that already arrive as JPG or PNG: keep as-is for the 1x slot, leave 2x / 3x slots empty (Apple will scale up); don't fabricate higher-density variants from a low-res raster.

### Step 3 — Download with curl

Parallelize when possible. One download per asset:

```bash
curl -sSL -o "Resources/Assets.xcassets/Home/ic_edit_beauty.imageset/ic_edit_beauty.png" \
  "https://www.figma.com/api/mcp/asset/<uuid>"
```

Verify each download:

```bash
file Resources/Assets.xcassets/Home/ic_edit_beauty.imageset/*.png
# must print "PNG image data, WxH, ..."
```

A 0-byte file or HTML output means the URL expired — re-run `get_design_context` to mint fresh URLs before giving up.

### Step 4 — Run SwiftGen

From the iOS target folder (wherever `swiftgen.yml` lives):

```bash
swiftgen
```

Check that `Generated/Assets-Constants.swift` now contains `Asset.Assets.Home.icEditBeauty` (or equivalent). If not, verify the folder has a `provides-namespace` Contents.json and re-run.

### Step 5 — Wire into views

Replace every placeholder in the SwiftUI / UIKit layer:

```swift
// before
Image(systemName: "sparkles")

// after
Asset.Assets.Home.icEditBeauty.swiftUIImage
  .resizable()
  .aspectRatio(contentMode: .fit)
```

For UIKit:

```swift
imageView.image = Asset.Assets.Home.icEditBeauty.image
```

### Step 6 — Verify

- Build: `xcodebuild -scheme <scheme> -destination 'generic/platform=iOS Simulator' build`
- Launch in a sim and visually compare against the Figma screenshot returned alongside the MCP response.
- If an asset's aspect ratio looks wrong, inspect the Figma frame for `overflow: hidden` + scaled `img` offsets — often the asset is cropped in the design and must be clipped in the view too, not scaled differently.

---

## Namespace & naming guidance

- One folder per feature: `Home/`, `Purchase/`, `Onboarding/`.
- Icons in `ic_*.png`, illustrations in `img_*.png`, backgrounds in `bg_*.png`.
- Decorative vectors that are stroke-only and can be replicated in SwiftUI (e.g., a 1px line, a plain circle) — OK to skip and draw with `Shape`. Anything with raster detail (photos, illustrations, gradients baked into the PNG, complex vectors) — must be downloaded.
- Status-bar icons (battery, wifi, cellular), simulated keyboard, iOS home indicator — these are Figma mockup chrome, NOT app assets. Skip them.

## Common mistakes

- Downloading the asset but forgetting the `provides-namespace` Contents.json → SwiftGen emits flat names and the existing enum structure breaks.
- Using `Image("ic_foo")` with a string literal → silently broken when SwiftGen renames later. Always go through `Asset.*`.
- Skipping the `file` verification → a stale URL serves HTML and the imageset silently contains a broken "PNG".
- Naming the asset after the Figma node ID (`imgFi11518112`) → unreadable. Always rename semantically.

## Exit criteria

Task is not done until:

1. Every non-chrome raster asset from the Figma response lives in `Assets.xcassets`.
2. SwiftGen has been re-run and `Assets-Constants.swift` is updated and committed.
3. No `Image(systemName:)` or `Color`-filled placeholder remains where the design calls for a bitmap.
4. The build passes.

---

## Pitfalls learned on ESI05 HWP Editor (Sept 2026)

- **`download_assets` PNG export of a composite node can bake in a background** (opaque #444 or
  white where the design has transparency). Always check the corner pixels of every exported PNG
  (alpha must be 0) before adding it; if it is opaque, take the `svgAssets` parts of the node instead
  and compose them in code (e.g. file icon = body SVG tinted + fold SVG + glyph SVG).
- **Vector layers that exist as SVG parts beat rasters** for anything tinted or reused (file-type
  icons, toolbar glyphs, tab icons). Put them in the catalog with `preserves-vector-representation`
  and `template` rendering when they need tinting.
- **Do not fall back to emoji / SF Symbols for flags or radio icons.** Shared icon sets (flags,
  select/deselect, check) must be the exact design set and live in SPNComponent
  (`SPNOnboarding/Resources/Assets.xcassets`), keyed by language code, so apps cannot diverge.
- **Frames that include mock status bars** (Intro_BG, splash export): crop the fake "9:41" band
  before using the art; for the package intro cell (full-bleed image with overlaid title) compose a
  tall page image (art on top, white below, ~360×610pt @3x) instead of the raw 360×408 art.
- **Replacing pixels in an existing `.imageset` needs a new filename** (`name_v2@3x.png`), otherwise
  the simulator keeps showing the cached image.
- **GIF exports arrive as an empty first frame** — draw simple illustrations (success badge) in code.

- **Composite illustrations must be exported as ONE asset, never as one of their parts.** When
  `get_design_context` returns several `imgGroupN` URLs for a single illustration node (empty
  states, hero art), each URL is only a fragment (the search "no result" art came back as 8 groups;
  taking only the magnifier lost the documents and blobs). Call `download_assets` on the
  illustration node itself (`defaultFormat: "svg"` for flat vector art, PNG otherwise) and use the
  whole-node `export`. Render the result and compare it with the `get_design_context` screenshot
  before committing.
- **Whole-node SVG exports leak the parent frame/section backgrounds.** Expect a `<rect>` the size
  of the node plus page-sized `<path>`s (huge negative coordinates, e.g. `M-6900 -3273`) from the
  section and screen frames, and a screen-sized `<rect width="360" height="800">`. Strip every
  full-canvas rect and every path whose first point lies far outside the viewBox, recursively,
  until the rendered corners are transparent (alpha 0). Never ship an asset whose corners are
  opaque unless the design really has a background.
- **Mirrored / rotated instances: bake the transform into the file.** Figma often reuses one glyph
  with `rotate-180` + `-scale-y-100` (= horizontal mirror) for Undo vs Redo, Align left vs right,
  etc. The exported SVG is the *unflipped* source for both; wrap the group in
  `transform="translate(<width> 0) scale(-1 1)"` for the mirrored one, and render both side by
  side against the design screenshot before adding them. Two imagesets with identical bytes for
  "different" icons is a red flag (`md5 -q a.svg b.svg`).
- **Icon state variants (enabled/disabled, filled/outline) export from the *component* node, not
  the list row.** Exporting the row instance returned the outline bookmark for the "enabled"
  state; `get_design_context` on the icon node itself (`I<row>;<icon>`) returned the filled
  orange vector.

