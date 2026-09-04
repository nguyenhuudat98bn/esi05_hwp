# HWP Viewer / Editor – Figma design notes

Source file: Figma `QIwa0h1cVfjXzYQdbGuAYD`. All frames are 360×800 (Android-ish artboard). Treat px = pt.
Screenshots: `docs/figma-refs/<nodeId>.png`. Exported assets: `docs/figma-assets/` (see "Assets" at the end).

Layout convention used below: `[x,y w×h]` = absolute frame inside the 360×800 artboard. "Content top = 100" means the scrollable content starts 100pt from top (status bar 34 + nav 40 + 16 gap + 10).

---

## Global tokens

### Colors
| Token | Hex | Usage |
|---|---|---|
| Blue/500 (primary) | `#2E90FA` | primary buttons, FAB, active segment tab + underline, links, toast bg, "HWP" in logo, checkbox |
| Blue/100 | `#D1E9FF` | active toolbar-button bg, text-selection highlight |
| Blue light/500 | `#0BA5EC` | 2pt ring around selected color swatch |
| Blue light/50 | `#F0F9FF` | selected plan card bg (paywall) |
| Accent blue (tab bar) | `#0088FF` | active tab label in new floating tab bar |
| Neutral/900 | `#181D27` | primary text, titles |
| Neutral/800 | `#252B37` | inactive segment-tab text |
| Neutral/700 | `#414651` | (in palette; rarely used) |
| Neutral/600 | `#535862` | editor toolbar labels & icons |
| Neutral/500 | `#717680` | secondary text (date/size, subtitles), inactive old-tab-bar label |
| Neutral/400 | `#94979C` | placeholders, "No result", viewer page background, paywall fine print |
| Neutral/300 | `#CECFD2` | input border, radio border, unselected plan border |
| Neutral/200 | `#ECECED` | secondary button bg, search field bg, hairline dividers, header bottom borders |
| Neutral/100 | `#F0F0F1` | More-sheet action icon circle bg, viewer bottom-bar top border |
| Card gray | `#F3F3F3` | convert-result file card bg |
| Text dark | `#1C2A33` | More-sheet labels, search typed text; `rgba(28,42,51,0.5)` empty-state text |
| Doc text | `#000D1A` | editor document body text |
| Sheet title | `#333333` | import sheet title |
| Paywall list text | `#363A4E` | feature list, PRO/BASIC |
| Tab bar label | `#1A1A1A` | inactive tab label (new tab bar), context menu text |
| Red | `#F03F39` | Delete label; `#FFEBEB` delete icon circle bg |
| Error red | `#FF3B30` | rename input error text |
| Context-menu red | `#FF383C` | "Delete" in Cut/Copy/Paste menu |
| Drag handle | `#BFC3C6` | bottom-sheet grabber |
| Overlay | `rgba(0,0,0,0.65)` | dim behind sheets/popups |
| Page badge | `rgba(0,0,0,0.6)` | "1/2" page indicator |

### Gradients (all top→bottom unless noted)
| Where | Start | End | "Go" pill solid |
|---|---|---|---|
| Edit HWP card | `#357DF8` | `#91C8FE` | `#337BF2` |
| PDF to HWP card | `#34B68F` | `#95F3D1` | `#2FB389` |
| DOC to HWP card | `#3B34B6` | `#A5D1FB` | `#3B35B6` |
| Print card | `#9226EF` | `#95BEF3` | `#7523D8` |
| Premium banner (Settings) left→right | `#56CCF2` | `#2F80ED` | – |
| Paywall CONTINUE left→right | `#1673FF` | `#69C5FB` | – |
| Paywall "Best Offer" ribbon left→right | `#FF9966` | `#FF5E62` | – |
| Paywall header fade (image → white) | `rgba(255,255,255,0)` @65.7% | `#FFFFFF` @92.3% | – |
| Ad "CÀI ĐẶT" button left→right | `#0072FF` | `#00C6FF` | – |

Cards also have a glossy "Rect Light" overlay (white radial/linear light masked to bottom 66pt) – optional; assets `card_rect_light_*.svg`.

### Typography
Design uses SF Pro (weights: Regular 400, Medium 510, Semibold 590, Bold 700, Condensed Bold 760). A few labels are Inter/Roboto in Figma – map everything to `UIFont.systemFont` with the listed weight.

| Style | Size / weight / line height | Used for |
|---|---|---|
| App title | 22 / Bold / 24 | "HWP Editor", "Tools", "Settings" |
| Sheet/popup title | 18 / Semibold / 26 (popup: normal) | "Import or convert…", "You're Offline", "Save Changes?", "Convert HWP Successfully" |
| Dialog title | 20 / Medium / 28 | "Rename" |
| Nav title | 18 / Medium / 26, tracking 0.2 | "Select File" |
| Card title | 16 / Semibold / 24 | "Edit HWP", "PDF to HWP" |
| Card subtitle | 10 / Regular / 12 | "Edit HWP files easily" |
| "Go" pill | 14 / Semibold / 20 | |
| Cell title | 16 / Medium / normal(≈24) | "Filename.hwp" |
| Cell meta | 12 / Regular / 18 | "05/28/2026 12:00 • 145 MB" |
| Segment tab | 15.36 / Medium / 23.04 (use 15/Medium) | My File / Recent / Bookmark |
| Button | 16 / Semibold / 22 (Rename dialog + convert use Medium/24) | |
| Body | 14 / Regular / 20 | popup body, search text |
| Settings row | 16 / Medium / 22, tracking 0.15 | |
| Settings value | 14 / Medium / 18, tracking 0.1 | "Tiếng Việt" |
| Toolbar label | 10 / Regular | Undo, Bold… |
| Toolbar font size | 14 / Medium / 24 | "12" |
| Tab bar label (new) | 10 / Semibold / 12, tracking -0.1 | |
| Tab bar label (old) | 12 / Medium / 18 | |
| Toast | 14 / Medium | "Press and hold to select text" |
| Paywall title | 28 / Condensed Bold(760) / 45, width 60% | "Go Premium with HWP Pro" |
| Paywall list | 14 / Medium / 18, tracking 0.1 | |
| Paywall fine print | 12 / Medium / 18 | |
| Paywall legal | 11 / Regular / 16 | Terms of Use / Privacy Policy |

### Header (Home/Tools/Settings)
- Status bar row: padding 16h/6v, height 34.
- Nav row `[0,50 360×40]`: padding 16h. Left title 22 Bold. Right: icons 24×24, gap 12 – `iconoir:search` then `crown (4) 1` (gold crown, premium).
- "HWP Editor" logo: "HWP" `#2E90FA` + " Editor" `#181D27`, both 22 Bold.
- Content starts y=100.

### Tab bar (two variants in file – use the NEW one)
NEW (nodes 18618:*, "Bottom Nav"): floating pill `[29,702 302×58]` (bottom inset 40), corner radius 296 (fully round). Fill: white 65% + `#F7F7F7`/`#DDD` blend layers ≈ render as `UIColor.white.withAlphaComponent(0.65)` over a blur (system material thin). Shadow `0 8 40 rgba(0,0,0,0.12)`. Three tabs each 102×50 at x=6/100/194, y=4; padding top 6, bottom 7. Selected tab has pill bg `#EDEDED` radius 100 (102×49.5). Icon 24, label 10 Semibold; active label `#0088FF` (icon tinted blue), inactive `#1A1A1A`. Items: "All File" (`fluent:home-20-filled`), "Tools" (`dashicons:admin-tools`), "Settings" (`reicon:setting-filled`).
OLD (node 17781:59925 "Bottom Nav/Home"): 328 wide, bottom 35, bg `rgba(0,0,0,0.1)` + blur 12.5, radius 60, padding 16h/8v; items 80 wide, radius 93, selected has white bg; icon 24 + gap 2 + label 12 Medium (`#2E90FA` active / `#717680` inactive). Seen on Import-sheet, Offline, More, Tools(18423), Settings(18461) frames – those are older frames.

### Buttons
- Primary: height 48, radius 100 (50), bg `#2E90FA`, text white 16 Semibold. (Editor "Save" small: 68×32, radius 50, 12 Medium.)
- Secondary: same shape, bg `#ECECED`, text `#181D27`.
- Dialog buttons (Rename/Convert result): height 44/48, radius 100, padding 24h/12v, text 16 Medium; two buttons in a row, gap 16 (popups: gap 12).
- FAB: 48×48 circle `#2E90FA` at `[296,593]` (right 16, bottom 159 → sits 100 above tab-bar top), icon `ic:round-plus` 32 white, padding 8.
- "Go" pill on cards: bg per-card solid, radius 36, padding 8h/2v, "Go" 14 Semibold + `weui:arrow-filled` 8×16, gap 2. Positioned at card x=14, y≈54 (inside "Rect Light" y 22+32).

### Feature card (Home/Tools)
156×88, radius 12, vertical gradient, clipped. Title 16 Semibold white at (13, 8) baseline-top 8; subtitle 10 Regular white at (12, 34); "Go" pill at (14,54). Big icon bottom-right, rotated: Edit HWP → `Vector` (pencil/doc) 52×52 rot -17.74° at (101,37); PDF → `streamline-flex:pdf-reader-application-remix` 51×51 at (114,34); DOC → `word (3) 1` 61.6×61.6 rot -17.35° at (95,31); Print → `ic:sharp-print` ~80×80 rot -13.47° at right edge. Two cards per row, gap 16, row width 328 (16 margins). Rows gap 12/16.

### File cell (component `File` 17421:118569)
360×62, white, radius 10, padding 16h. Leading: file icon 33.5×40 (`Icon` HWP: blue doc w/ folded corner + "HWP" glyph; PDF variant red). Gap 16. Text column (height 56, gap 4): title 16 Medium `#181D27` (ellipsis), meta row gap 4: "05/28/2026 12:00" 12 Regular `#717680`, 2×2 dot `#717680`, "145 MB". Trailing: `Bookmark` 24 (outline gray / filled orange `#FF9C66` when bookmarked) + `ri:more-2-line` 24 (vertical ⋮), gap 8. Cells stacked with gap 12 (search results: 16).

### Popup (center modal) pattern
328 wide, white, radius 16, padding top 32 / bottom 24 / sides 15, content gap 32; close `iconoir:cancel` 24 inside 28×28 hit area at top-right (x 290, y 10). Illustration + title 18 Semibold black + body 14 Regular `#717680` (gap 12, group gap 16). Buttons row gap 12: secondary `#ECECED` + primary blue, h48, radius 50, 16 Semibold.

### Bottom sheet pattern
Full-width white, top radius 16 (import sheet 20), overlay `rgba(0,0,0,0.65)`. Grabber 32×4 `#BFC3C6` radius 100 at y16 in a 24pt header.

---

## 17421-116659 Home – My File
Screenshot `figma-refs/17421-116659.png`.
1. Header (see global) – logo "HWP Editor", search + crown.
2. `[16,100]` Feature cards row: **Edit HWP** (blue) + **PDF to HWP** (green). Texts: "Edit HWP" / "Edit HWP files easily" / "Go"; "PDF to HWP" / "Convert PDF to HWP" / "Go".
3. `[0,204]` Segment tabs row: padding 16h/8v, items gap 36, each item height 25.92: label 15.36 Medium + underline 1.92 high radius 19.2 full label width. Active = `#2E90FA` (label + underline), inactive label `#252B37`, no underline. Items: "My File", "Recent", "Bookmark".
4. `[0,~254]` File list: `File` cells full width (360×62) gap 12; 6 × "Filename.hwp / 05/28/2026 12:00 • 145 MB", bookmark outline, more ⋮.
5. FAB 48 blue `+` at `[296,593]`.
6. New floating tab bar, "All File" selected.
Colors: white bg. Icons: `iconoir:search`, `crown (4) 1`, `Bookmark` (17421:118507), `ri:more-2-line`, `ic:round-plus`, `fluent:home-20-filled`, `dashicons:admin-tools`, `reicon:setting-filled`, file icon `Icon` (18183:97710).

## 17768-44246 Home – No File (empty)
Same header, cards row, NO segment tabs (design omits them in empty state), no FAB.
Center group (centered, offset +10 y): illustration `image 2014` 165×140 (folder/empty docs PNG → `img_empty_no_files.png`), gap 12, text "No files yet. " 14 Regular `rgba(28,42,51,0.5)` centered; gap 24; button "Import File" 252×48 radius 100 `#2E90FA`, leading icon `uil:upload` 24 white, gap 8, label 16 Semibold `#FCFDFD`, padding 70h/10v.
Tab bar new variant, "All File" selected.

## 17787-80823 Import sheet
Overlay `rgba(0,0,0,0.65)` over empty Home. Bottom sheet (white, top radius 20, padding 24h/32v, items gap 16):
1. Title "Import or convert your files to HWP" 18 Semibold `#333` centered, line 26.
2. Wide card **Import file** 328×80 radius 12, gradient `#357DF8→#91C8FE`: left decorative `clarity:import-solid` 81×81 rot 10.94° at (-28,4) (semi-transparent white), right-aligned text block (right 16, v-center, width 241): "Import file" 18 Semibold white / "Select a file from your device" 12 Regular white (gap 2); trailing round button 36×36 `#337BF2` with `basil:arrow-right-outline` 31 white; gap 40.
3. Row: **PDF to HWP** card (green) + **DOC to HWP** card (purple `#3B34B6→#A5D1FB`, pill `#3B35B6`, "DOC to HWP" / "Convert DOC to HWP", icon `word (3) 1`).
4. Below sheet: native ad block bg `#FCFCFC`, top border `#EEE`, padding 16 – app icon 52, title 15 `#000D1A`, desc 13 `#717680`, media placeholder `rgba(148,163,184,0.12)` radius 8, CTA gradient button h48 radius 100 "CÀI ĐẶT" 18 Bold white, "Ad" badge `#FFCC00` 11 Semibold white radius br 4. (Implement with your ad SDK; use these dims.)
Tab bar old variant visible under overlay.

## 17525-119793 Home – Recent
Identical to My File; segment "Recent" active (`#2E90FA` + underline), others `#252B37`. 6 cells, no FAB shown (design), new tab bar. (Keep FAB behavior consistent with My File.)

## 17525-120056 Home – Bookmark
Identical; "Bookmark" active. 4 cells, all with **filled bookmark** icon (color `#FF9C66`, Orange dark/300). New tab bar.

## 17787-102548 Tools tab
Header title "Tools" 22 Bold `#181D27` + search + crown. Content `[0,100]` gap 12: row 1 Edit HWP + PDF to HWP; row 2 **DOC to HWP** (purple) + **Print** (`#9226EF→#95BEF3`, pill `#7523D8`, "Print" / "Print document", icon `ic:sharp-print` rotated -13.47°). New tab bar, "Tools" selected (selection pill `#EDEDED`, label `#2E90FA`).

## 17787-102729 Settings tab
Header title "Settings" (no right icons). Content `[16,100 328]` gap 16:
1. Premium banner 328×72 radius 12, gradient left→right `#56CCF2→#2F80ED`, bg texture `image 1963` (light waves, rotated), right illustration `image 2028` 112×114 at (238,-7) (crown/badge), sparkles `image 2051` 15 @(226,44) & 34 @(204,3), `image 2046` 24 @(177,32). Text left 16, v-center(-4): "Upgrade to Premium" 16 Bold white, "Unlock all features " 12 Regular white, gap 4.
2. Card white radius 16, padding 16h, rows gap 8. Row "Item Settings": height 52 (padding 14v), icon 24 + gap 12 + label 16 Medium `#181D27` tracking 0.15; Language row trailing "Tiếng Việt" 14 Medium + `caret/down` 16, gap 2.
   Rows: Language (`Icon/Language`), Rate app (`star`), Share app (`share`), Manage Subscriptions (`wallet`), Privacy Policy (`shield-check`), Terms of Use (`shield-user`), EU Consent (`certificate`). Icons are blue `#2E90FA` line icons.
New tab bar, "Settings" selected.

## 18018-46805 Search empty
White. Top bar (white, gap 10): status row; then row `[16,44]` gap 16: `angle-left` 24 back chevron + search field 288×40 radius 20 bg `#ECECED`, padding 12h: `iconoir:search` 24 `#94979C` + gap 8 + placeholder "Search files..." 14 Regular `#94979C`. Body empty. System keyboard shown at bottom (y 551).

## 18018-46641 Search result
Same bar; field content: `Search--Streamline-Carbon` 20 + gap 12 + typed text "Filename" 14 Regular `#1C2A33` + caret line (blue) + trailing `Icon/Close2` 24 (clear, gray circle-x). Results `[0,100]`: `File` cells gap 16 (4 shown). Keyboard visible.

## 18018-46743 Search no result
Same bar (text "Hâhhahah"). Center group (center y −80, gap 20): illustration `no-result-found (2) 1` 120×120 (magnifier + doc, exported `img_no_result_found@3x.png`) + "No result" 14 Regular `#94979C`. Keyboard visible.

## 18183-8744 Popup You're Offline
Overlay `rgba(0,0,0,0.65)` over empty Home. Center popup 328 wide (see popup pattern): illustration `image 2016` 104×80 (`img_offline.png`), title "You're Offline" 18 Semibold black, body "Check your network and try again." 14 Regular `#717680`, close `iconoir:cancel`. Buttons: "Later" (secondary `#ECECED`, text `#181D27`) / "Try Again" (primary). Both h48 radius 50, 16 Semibold.

## 18183-97357 More sheet (file actions)
Overlay over Home. Bottom sheet white, top radius 16, bottom padding 8:
1. `BottomSheetTitle` (border-bottom `#ECECED`, pb 4): grabber 32×4 `#BFC3C6` (header 24 high, handle at y16); then a `File` cell (62 high, padding 16h/8v) showing the file (icon, "Filename.hwp", meta) with only the bookmark icon trailing (no ⋮).
2. Actions list `[20, …] 320 wide`, padding 16v, gap 16, separators 0.5 `#ECECED` between rows. Row = 40×40 circle bg `#F0F0F1` radius 90 containing 24 icon + gap 8 + label 14 Medium `#1C2A33`.
   - Rename – `iconamoon:edit-fill` (dark)
   - Share – `material-symbols:share`
   - Print – `gridicons:print`
   - Delete – circle bg `#FFEBEB`, `material-symbols:delete` red, label `#F03F39`.
Tab bar old variant under overlay.

## 18183-97100 Rename dialog
Standalone dialog 328×220, white, radius 28 (`figma-refs/18183-97100.png`).
1. Title area padding 16h / top 24 / bottom 16: "Rename" 20 Medium `#181D27` line 28.
2. Input 296×48 (16 margins), border 1 `#CECFD2`, radius 12, padding 8h: text "PDF_Pro_Split_20240516_162411" 14 Medium `#181D27` tracking 0.1 (selected text bg `#D1E9FF` 217×20 behind it), caret, trailing `Icon/Close2` 24 clear button. Below: error label 12 Regular `#FF3B30` tracking 0.2 (empty by default), gap 8.
3. Buttons row padding 16, gap 16: "Cancel" `#ECECED` h44 radius 100 text 16 Medium `#181D27`; "OK" `#2E90FA` text white 16 Medium.

## 18387-57821 Viewer view mode
Screen bg `#94979C` (gray canvas). 
1. Header white: status row; nav `PageHeader_ViewMode` padding 16h/6v, height 56 incl. divider `rc_ScrollDivider` (hairline `#ECECED`) at bottom: `angle-left` 24 back (left), right actions: search `iconoir:search` 24 in 40×40 touch area (8 padding) + `fi_5368596` (⋮ vertical more) 24 in 40×40.
2. Pages `[0,94]` vertical list gap 8: page image 360×468 (A4 ratio 816:1061) white pages rendered.
3. Page indicator "1/2" pill bg `rgba(0,0,0,0.6)` radius 4, padding 16h/4v, 14 Medium white, centered horizontally at y 676 (≈ 26 above bottom bar).
4. Bottom bar white, top border `#F0F0F1`, padding 16: primary button "Edit HWP" full width h48 radius 48, 16 Medium white (Roboto in Figma → system Semibold OK).

## 18387-57912 Editor edit mode
Screen bg `#94979C`.
1. Header white, bottom border `#E4E5EC`: status row; nav row height 56, padding 16h, border-bottom `#ECECED`: `iconoir:cancel` 24 (X) left; right "Save" button 68×32 radius 50 `#2E90FA`, 12 Medium white.
2. Toolbar `List` `[0,90]` white, border-bottom `#ECECED`, padding 12h/4v, horizontal scroll, item gap 8 (first group gap 6): each item = 20×20 icon + gap 2 + label 10 Regular `#535862`, padding 8h/2v, radius 4. Items in order: Undo (`iconoir:redo` flipped), Redo, divider (1×25 `#CECFD2`), font size stepper [`ic:round-minus` 15 in 20 | "12" 14 Medium | `ic:round-plus`] gap 12, Bold, Italic, Underline, Strike through (2-line label), Text Color, Highlight, Align right, Align left. Active state: bg `#D1E9FF` radius 4, icon+label `#2E90FA`.
3. Document `[0,154]` white page 360×468, padding 11h / 19 top / 49 bottom; text starts (24,28) width 312, 12 Medium `#000D1A`, paragraphs separated by blank line; sample text (UX research…), links same color.
4. Toast "Press and hold to select text": bg `#2E90FA`, radius 68, padding 12h/8v, 14 Medium white + `ic:sharp-cancel` 16 white, gap 16, centered at y 586 (above keyboard).
5. Keyboard (system) from y 551.

## 18387-121316 Toolbar states
Four rows (same `List` component, variants Default / Bold / highlight / Text Color) – `figma-refs/18387-121316.png`.
- Default: all `#535862`, Redo dimmed when nothing to redo.
- Bold variant: Bold + Italic active (bg `#D1E9FF` radius 4, tint `#2E90FA`).
- Highlight variant: Highlight active; after it an inline color strip (replaces Align until scrolled): divider, then `slash` 17 (no color), swatches 15.8 ø gap 8: **orange `#FEB43F` selected** (2pt ring `#0BA5EC`), pink `#F5A3D9`-ish, light pink, light blue `#9EC9FF`, cyan `#8EE3F5`, rainbow gradient picker (`Picker Button` – `ic_tb_color_picker_gradient.png`); then Align right / Align left.
- Text Color variant: Text Color active; strip: `slash`, black, **red `#FF320B` selected** (ring `#0BA5EC`, `ic:sharp-check` inside), orange `#FF6B1A`-ish, magenta `#D74BE8`-ish, blue `#2E90FA`-ish, gradient picker; then Highlight, Align right, Align left.
Exact swatch SVGs are in assets `ic_tb_swatch_hl_1..4.svg`, `ic_tb_swatch_tc_1..4.svg` (read fill from SVG).

## 18387-124560 Highlight row (actually: text selection + context menu)
Editor with Bold+Italic active. Selected text rendered Bold Italic with selection bg `#D1E9FF` (rows 311×31 and 260×15 at x22) and blue selection handles (dots `#2E90FA`). Floating context menu (iOS style, `figma-refs/18387-124560.png`): pill radius 34, fill `rgba(245,245,245,0.6)` + blur (material), shadow `0 8 40 rgba(0,0,0,0.12)`; actions gap 16, padding-right 16 each, separators 1×18 `#CCC`: "Cut", "Copy", "Paste" 15 Regular `#1A1A1A` tracking -0.6; "Delete" `#FF383C`. Use `UIMenuController`/`UIEditMenuInteraction` natively.

## 18387-124323 Text color row
Editor with **Highlight** active and highlight color strip (orange selected); first paragraph highlighted orange `#FEB43F` (bg behind text). Toolbar as in "highlight" variant above. Header/keyboard same as editor.

## 18387-126166 Save Changes popup
Editor (Text Color state, first paragraph red text) dimmed by `rgba(0,0,0,0.65)`; center popup 328 (popup pattern): illustration `image 1936` 132×120 (blue folder w/ arrow → `img_save_changes_folder.png`), title "Save Changes?" 18 Semibold black, body "Do you want to save your changes before leaving?" 14 Regular `#717680` width 246, close X top-right. Buttons gap 12: "Cancel" `#ECECED` / "Save" `#2E90FA`, h48 radius 50, 16 Semibold.

## 18423-128151 Tools (older frame)
Same as 17787-102548 (Edit HWP, PDF to HWP, DOC to HWP, Print) but with the OLD tab bar (rgba(0,0,0,0.1) blur pill, "Tools" white pill + blue label). Use new tab bar for consistency.

## 18423-128348 Select File (pdf)
White. Header with bottom border `#ECECED`: status row; nav padding 16h/6v height 56: `angle-left` 24 + gap 12 + title "Select File" 18 Medium `#181D27` tracking 0.2; right actions hidden (opacity 0). List `[0,102]` `File` cells gap 12 (6×): PDF icon variant (`Icon` 18423:128516 – red doc w/ fold + white "PDF"-style glyph `Vector` 21 wide), "Filename.pdf", meta; trailing icons hidden.

## 18423-129336 Convert successfully
White. Header (editor style): X `iconoir:cancel` 24 left, right "Save" hidden (opacity 0), row 56 border-bottom `#ECECED`.
Content `[16,74 328]` gap 24, centered:
1. Illustration `Success 1` 217×218 (GIF – `img_convert_success.gif`, green check burst), margin-bottom -16; title "Convert HWP Successfully" 18 Semibold `#181D27` centered line 26.
2. Card 328 bg `#F3F3F3` radius 16 padding 12, gap 16: HWP file icon 33.5×40 + text column (12pt, gap 4): "**Name:** Filename bleble", "**Size:** 3.00 B", "**Path:** /storage/emulated/0/Download/…" – labels Semibold, values Regular, `#181D27`.
3. Buttons row gap 16: "Back Home" `#ECECED` text `#181D27` 16 Medium; "Open" `#2E90FA` white 16 Semibold; padding 24h/12v radius 100 (h48).

## 18461-130823 Settings (older frame)
Identical content to 17787-102729 with OLD tab bar ("Settings" selected white pill). Use 17787-102729 spec + new tab bar.

## 18540-121412 Paywall
White. `figma-refs/18540-121412.png`.
1. Header art: `5403942_391 1` (light blue wave image, `img_paywall_header_bg.jpg`) 360×350 at y -111 with bottom fade to white (gradient stops 65.7%→92.3%). Hero illustration `ChatGPT Image…` 167.5×149 centered at y 41 (`img_paywall_hero.png`).
2. Nav `[0,28 360×44]` padding 8h: `times` 24 close (gray) in 40×40 touch area left; right "Restore" 12 Regular `#94979C` tracking 0.2 in touch area.
3. Title "Go Premium with HWP Pro" 28 Condensed Bold `#181D27` centered at y 217 width 330.
4. Feature table `[15,272 330]` rows gap 18: header row right-aligned 100 wide "PRO" / "BASIC" 14 Bold `#363A4E`; 6 rows: bullet label 14 Medium `#363A4E` ("Open & Read HWP/HWPX", "Edit HWP Files with Ease", "Convert PDF or DOC to HWP", "Unlock All Premium Features", "Faster Processing Speed", "Enjoy an Ad-Free Experience") + two 20×20 icons gap 30: PRO = green check circle (`Group` 18555:8341), BASIC = green check for row 1, red X circle (`Group` 18555:8354) for others.
5. Bottom block (anchored bottom, gap 8): fine print "Free for 3 days, then ₫1,159,000 per year." 12 Medium `#94979C` centered; plans (padding 24h, gap 16):
   - Plan 1: 312×~48 radius 500, bg `rgba(255,255,255,0.6)`, border 1.5 `#CECFD2`, padding 12h/6v; radio 24 ø border 1.5 `#CECFD2`; text "đ99,000 for the first month" 14 Regular `#181D27` (centered via padding 9h/5v).
   - Plan 2 (selected): bg `#F0F9FF`, border 1.5 `#2E90FA`; leading `CheckBox` 24 ø `#2E90FA` with white check; "Free trial enabled" 14 Medium; "Best Offer" ribbon 100×20 at top-right (x 186.5, y -12.5): gradient `#FF9966→#FF5E62`, top radius 20, text 10 Semibold white capitalized.
   - CONTINUE button 312×46 radius 50 gradient `#1673FF→#69C5FB`, padding 12h: left `arrow-right` 24 (transparent placeholder), center "CONTINUE" 16 Bold white, right `arrow-right` 24 white.
   - Legal row gap 19: "Terms of Use" | "Privacy Policy" 11 Regular `#181D27` tracking 0.1, separator 1×13.
   - Home indicator area 24.

---

## Assets

All exported into `/Users/datnguyendev/Documents/Work/esi05_hwp/docs/figma-assets/` (96 files). SVGs are the raw vector layers from Figma (colored as designed) – import into `Assets.xcassets` as **Template** images and tint in code where the design uses one glyph in several colors (tab bar icons, toolbar icons, bookmark). PNG/GIF/JPG are raster illustrations; `@3x` PNGs are 3× exports of composite nodes.

| File | Figma layer (node) | Used in |
|---|---|---|
| ic_search.svg | iconoir:search | headers, search field |
| ic_search_small_20.svg | Search--Streamline-Carbon | search field (typed state) |
| ic_crown.svg | crown (4) 1 | header premium |
| ic_bookmark_outline.svg / ic_bookmark_filled.svg | Bookmark (17421:118507) | file cell |
| ic_more_2_line.svg | ri:more-2-line | file cell ⋮ |
| ic_viewer_more_vertical.svg | fi_5368596 (14906:30765) | viewer nav ⋮ |
| ic_round_plus.svg | ic:round-plus | FAB |
| ic_tab_home_filled.svg / ic_tab_tools.svg / ic_tab_settings_filled.svg | fluent:home-20-filled / dashicons:admin-tools / reicon:setting-filled | tab bar (tint) |
| ic_arrow_filled_right.svg | weui:arrow-filled | card "Go" pill |
| ic_card_edit_hwp_vector.svg | Vector (17421:119267) | Edit HWP card art |
| ic_card_pdf_reader.svg | streamline-flex:pdf-reader-application-remix | PDF card art |
| ic_card_word_doc.svg | word (3) 1 | DOC card art |
| ic_card_print.svg | ic:sharp-print (18178:8406) | Print card art |
| card_rect_light_mask.svg / card_rect_light_fill.svg (+ _wide) | Rect Light 1 / Mask group | card gloss overlay |
| ic_file_dot.svg | dot | cell meta separator |
| hwp_file_icon@3x.png (+ hwp_file_icon_body/fold/glyph.svg) | Icon HWP (18183:97710) | file cell |
| pdf_file_icon@3x.png (+ pdf_file_icon_glyph.svg) | Icon PDF (18423:128516) | Select File |
| img_empty_no_files.png | image 2014 | empty state |
| ic_upload.svg | uil:upload | Import File button |
| ic_import_solid.svg | clarity:import-solid | import sheet card |
| ic_arrow_right_outline.svg | basil:arrow-right-outline | import sheet card |
| ic_import_sheet_word_badge@3x.png | word (3) 1 rotated (17787:102319) | import sheet card |
| img_premium_banner_bg.png / _crown.png / _sparkle.png / _sparkle2.png | image 1963 / 2028 / 2051 / 2046 | settings banner |
| ic_settings_language/star/share/wallet/shield_check/shield_user/certificate.svg | Icon/Language, star, share, wallet, shield-check, shield-user, certificate | settings rows |
| ic_caret_down.svg | System icon/fill/directions/caret/down | language value |
| ic_angle_left.svg | angle-left | back |
| ic_close_circle.svg | Icon/Close2 | clear text |
| ic_cancel_x.svg / ic_editor_close_x.svg | iconoir:cancel | popup close, editor X |
| img_offline.png | image 2016 | offline popup |
| img_no_result_found@3x.png / img_no_result_found_main.svg | no-result-found (2) 1 | search empty |
| ic_more_rename_edit.svg / ic_more_share.svg / ic_more_print.svg / ic_more_delete.svg | iconamoon:edit-fill, material-symbols:share, gridicons:print, material-symbols:delete | More sheet |
| img_viewer_page_sample.png | image 2017 | viewer sample page (dev only) |
| ic_tb_undo/redo/divider/font_minus/font_plus/bold/italic/underline/strikethrough/text_color/highlight/align_right.svg (+ `_active` blue variants) | toolbar `List` children | editor toolbar |
| ic_tb_color_none_slash.svg, ic_tb_swatch_hl_1..4.svg, ic_tb_swatch_tc_1..4.svg, ic_tb_color_picker_gradient.png | slash, Color 10, Group 28184-28187, Color 1, Picker Button/Gradient | color strips |
| ic_toast_cancel_16.svg | ic:sharp-cancel | editor toast |
| img_save_changes_folder.png | image 1936 | save changes popup |
| img_convert_success.gif | Success 1 | convert result |
| img_paywall_header_bg.jpg / img_paywall_hero.png | 5403942_391 1 / ChatGPT Image… | paywall |
| ic_paywall_arrow_right.svg / _2.svg | arrow-right | CONTINUE |
| ic_paywall_check_white.svg | Interface, Essential/Done, Check | selected plan checkbox |
| ic_paywall_feature_check.svg / ic_paywall_feature_cross.svg | Group 18555:8341 / 18555:8354 | feature table |
| ic_paywall_close_times.svg | times | paywall close |
| ic_paywall_best_offer_ribbon.svg | Rectangle 150003 | ribbon shape |

### Assets to export manually (not downloaded)
- Align-left toolbar icon: Figma uses `elements` (align right) mirrored – flip `ic_tb_align_right.svg` horizontally.
- Underline / Strikethrough active (blue) variants – tint the default SVGs.
- Ad placeholder `image 171` (17787:97773) – not needed (ad SDK).
- iOS status bar / keyboard – system.
- Feature-card gloss is optional; if wanted, export node `Rect Light 1` (17525:119725) as PNG.

---

## Added 2026-09-04 — Convert error (G7) & Delete confirm (E3)

### G7 Convert error — Figma `19108-24632` ("Lỗi")
- White screen, header 56pt: X (`ic_editor_close_x`) at left inset 16, 1pt `#ECECED` divider under the header (same header as G5).
- Column centered horizontally, centerY − 40: illustration 100×100 (`App/img_convert_error`, PNG @3x export of node 19108-24635,
  white background baked in — fine on the white screen), gap 24, "Oops! Something went wrong" 14/Regular `#717680` in a 224pt box,
  gap 28, pill **Back to Home** 252×48 radius 100 `#2E90FA`, 16/Semibold white.
- Flow: `ConvertingViewController` failure → replaces itself with `ConvertErrorViewController` (X = pop to Select File,
  Back to Home = pop to root). Engine stub `ConvertError.notAvailable` still uses the info popup (coming soon).

### E3 Delete File? popup — Figma `19108-24877`
- Card radius 16, padding top 32 / sides 15 / bottom 24, close X 28pt at top-right inset 10.
- 60pt circle `#FFEBEB` with 36pt material delete glyph tinted `#F03F39` (`App/ic_more_delete`, same path as the More sheet icon).
- Gap 16 → title "Delete File?" 18/Semibold black, gap 12 → "Are you sure you want to delete this file?" 14/Regular `#717680`, gap 32 →
  buttons Cancel (`#ECECED`, text `#181D27`) / Delete (`#F03F39`, white), 48pt, radius 50, gap 12.
- Implemented via `AppAlertViewController(iconCircleColor:)` in `DeleteConfirmPopup`.
