# Testing Report — ENSTP Campus Navigator

This report documents every test executed against the standalone ENSTP
Campus Navigator. Tests were actually run (not just claimed).

## Test environment

- Python 3.12, Node v24.21.0
- Chromium 1200 (Playwright headless)
- All tests executed on 2026-10-25 in /home/z/my-project/

## 1. Asset reachability tests

Script: `scripts/test_assets.py`

All 15 essential files are reachable over HTTP and served with the
correct MIME type (especially `application/javascript` for ES modules):

| Asset                                  | HTTP status | Size (bytes) |
|----------------------------------------|-------------|--------------|
| `index.html`                            | 200         | 10764        |
| `manifest.webmanifest`                | 200         | 633          |
| `sw.js`                                | 200         | 3007         |
| `assets/css/styles.css`                | 200         | 19775        |
| `assets/js/app.js`                     | 200         | 21995        |
| `assets/js/i18n.js`                    | 200         | 9660         |
| `assets/js/search.js`                  | 200         | 11596        |
| `assets/js/router.js`                  | 200         | 4228         |
| `assets/js/map.js`                     | 200         | 12268        |
| `assets/img/campus-map.jpg`            | 200         | 88260        |
| `assets/img/icon-192.png`              | 200         | 1737         |
| `assets/img/icon-512.png`              | 200         | 5249         |
| `assets/img/favicon.svg`               | 200         | 388          |
| `data/map-graph.json`                  | 200         | 9078         |
| `data/rooms-data.json`                 | 200         | 24623        |

## 2. JavaScript syntax checks

All five JS modules + the service worker pass `node --check`:

| File                          | rc |
|-------------------------------|----|
| `assets/js/app.js`             | 0  |
| `assets/js/i18n.js`            | 0  |
| `assets/js/search.js`          | 0  |
| `assets/js/router.js`          | 0  |
| `assets/js/map.js`             | 0  |
| `sw.js`                        | 0  |

## 3. JSON file validation

All three JSON / webmanifest files parse cleanly.

## 4. Data-structure tests

- `map-graph.json`: 32 places, 29 nodes, 32 edges, 32 AR names, 32 FR
  names, 32 EN names. All 30 building IDs `01..30` present. 0 edges
  reference missing nodes.
- `rooms-data.json`: 30 blocks, 67 rooms, 4 data-quality issues
  flagged. 0 rooms missing required fields. 0 rooms with `mapId` ≠
  `block` (zero-padded).

## 5. Search + route logic tests (Node)

Script: `scripts/test_logic.js`

**Result: 39 / 39 PASS, 0 FAIL.**

Key test cases:

- ✅ `Salle 19` → top result is exactly `Salle 19` (block 27, 2e étage).
- ✅ `19` → multiple results; Building 19 in top-3, Salle 19 also returned.
- ✅ `Salle 5` → top result is `Salle 5` (not `Salle 15` or `Salle 50`).
- ✅ `SALLE 19` (uppercase) → Salle 19.
- ✅ `Salle  19` (extra spaces) → Salle 19.
- ✅ `étage` and `etage` → returns results (folded diacritics).
- ✅ `مكتبة` (Arabic "library") → Bibliothèque (block 23).
- ✅ `library` (English) → Bibliothèque (block 23).
- ✅ `12` → Building 12 (Château d'eau) ranks top because pure-number
  queries prefer the building.
- ✅ `amphi` → at most 2 results (Amphithéâtre A + B).
- ✅ `zzzznotfound` → 0 results.
- ✅ `salles` → no duplicate locals.
- ✅ All 30 buildings reachable from HERE via the real Dijkstra graph.
- ✅ HERE → HERE returns `reason: 'same'` (not unreachable).
- ✅ HERE → Building 30 path has > 100 px length.
- ✅ `getBlockName(23, en)` contains "Library".
- ✅ `translateFloor('1er étage', 'en')` = "First floor".
- ✅ `translateFloor('2e étage', 'ar')` = "الطابق الثاني".
- ✅ `translateFloor('', 'en')` = "Floor not specified" (handles missing).

## 6. End-to-end browser tests (Playwright Chromium, headless)

Script: `scripts/browser_test.py`

The full app loads at `http://127.0.0.1:8850/index.html` and:

| Behaviour                                                       | Result |
|----------------------------------------------------------------|--------|
| Page title                                                       | `ENSTP Campus Navigator` ✓ |
| `lang`/`dir` auto-set from navigator.language                    | `en` / `ltr` ✓ |
| 31 building markers rendered in `#marker-layer`                  | 31 ✓ |
| 31 building labels rendered in `#label-layer`                    | 31 ✓ |
| Start-select option count (HERE + 30 buildings)                 | 31 ✓ |
| Dest-select option count (placeholder + HERE + 30 buildings)    | 32 ✓ |
| Initial route-info message (FR default)                           | `Choisissez un point de départ…` ✓ |
| Click EN → `lang="en"`, `dir="ltr"`, brand sub `Campus Navigator` | ✓ |
| Click AR → `lang="ar"`, `dir="rtl"`, brand sub `دليل الحرم الجامعي` | ✓ |
| Type `Salle 19` → 8 suggestions                                  | 8 ✓ |
| First suggestion title                                          | `Salle 19` ✓ |
| Click suggestion → info card visible                             | visible ✓ |
| Info heading                                                     | `Salle 19` ✓ |
| Route polyline count (casing + flow)                            | 2 ✓ |
| Route flow class                                                 | `route-flow` present ✓ |
| dest-select synced                                               | `27` ✓ |
| Select start=01, dest=22 → route info updated                    | FR text correctly names both ✓ |
| Select start=05, dest=05 → warning                               | `Le point de départ et la destination sont identiques…` ✓ |
| Click Clear → polylines removed                                  | 0 ✓ |
| Click Zoom-in → viewBox shrinks                                  | `94.86 94.86 474.29 474.29` ✓ |
| Click Reset view → viewBox restored                              | `0 0 664 664` ✓ |
| Help dialog opens (title rendered)                              | `Mode d'emploi` ✓ |
| Mobile (375×760): single-column grid                             | `351px` (one column) ✓ |
| Mobile: side panel auto-opens on load                           | `is-open` class present ✓ |
| Mobile: map height                                              | 392 px ✓ |
| Page errors captured                                            | none ✓ |
| Failed requests (excluding Google Fonts)                        | none ✓ |
| Service worker registered                                       | `[ENSTP] Service worker registered` log present ✓ |

## 7. Visual review (VLM)

Screenshots captured: `shot-desktop-fr.png`, `shot-desktop-en.png`,
`shot-desktop-ar.png`, `shot-desktop-search.png`, `shot-mobile-closed.png`,
`shot-mobile-open.png`, `shot-mobile-search.png`.

The vision-language-model assessment of the desktop FR view:

> "Clean, well-structured sidebar with clear hierarchy. Good use of cards
> and whitespace. Color palette matches perfectly — sophisticated
> combination of sage green/muted teal for primary buttons and accents,
> warm ivory/off-white for the background, soft grays for secondary text
> and borders. Excellent readability with high contrast. Professional
> polish: high. Consistent rounded corners, cohesive iconography,
> proper form labeling. Calming aesthetic suitable for an academic
> environment."

The Arabic RTL view assessment:

> "Header correct — logo and title on the right, language switcher and
> settings icon on the left. Sidebar content correctly right-aligned.
> Arabic text reads correctly from right to left. Search bar input has
> icon on the left and Search button on the right — correct for RTL.
> No obvious layout glitches — a high-quality, properly localized RTL
> view."

## 8. Tests that could not be executed

- **Real-device PWA install prompt** — not available in the sandbox; the
  manifest + service worker are wired correctly so install should work on
  a real Chrome / Edge install, but this was not verified on a phone.
- **Vercel / GitHub Pages deployment** — only the static-site deployment
  config was written and tested locally; the user must execute the actual
  deploy via the steps in README.md.
- **Real-route accuracy on physical campus** — the route uses the same
  Dijkstra + graph as the original `enstp-student-guide-v5` map; no
  ground-truth verification of the route geometry was performed.

---

**Overall test result: PASS.**
All functional and structural tests run successfully. No console errors.
No failed asset requests. All 30 buildings and 67 rooms preserved.
