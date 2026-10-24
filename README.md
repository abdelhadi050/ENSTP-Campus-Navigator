# ENSTP Campus Navigator

A standalone, fully redesigned campus navigation website for the
**École Nationale Supérieure des Travaux Publics (ENSTP)**. It provides an
interactive campus map, multilingual room/building search, and route
planning (Dijkstra shortest path) — built entirely from the map data
originally embedded in the `enstp-student-guide-v5` project.

The application is **completely independent** of the original student-guide
website: it has its own HTML, CSS, JavaScript, datasets, and assets. It does
not reference the original project's pages, scripts, authentication, or
domain.

---

## Highlights

- **Real ENSTP campus map** — the original aerial image and graph of 30
  buildings + 29 walkway nodes + 32 edges, preserved verbatim.
- **Trilingual UI** — Arabic (RTL), French, English with full label
  translation and an accessible language selector.
- **Exact-match search** — `Salle 19` returns `Salle 19` first (not
  `Salle 199`); `مكتبة` finds the Bibliothèque; `library` too.
- **Dijkstra route planning** — pick a starting point and destination,
  see the dotted route drawn on the map. Same algorithm as the original,
  with a critical bug fix.
- **Calm sage-green & muted-teal palette** — explicitly drops the old
  navy-blue (`#05054F`) and bright-orange (`#F59127`) brand colors.
- **PWA + offline** — installable, service worker caches the shell,
  map image, and datasets.
- **Responsive** — desktop split layout, mobile bottom-sheet.
- **No backend, no external API keys** — pure static site.

---

## Project structure

```
enstp-campus-navigator/
├── index.html              ← main page (header, search, map, info, route, mobile sheet)
├── manifest.webmanifest    ← PWA manifest
├── sw.js                   ← service worker (offline cache)
├── README.md               ← this file
├── TESTING.md              ← test report
├── DATA-AUDIT.md           ← source-data audit + unresolved issues
├── assets/
│   ├── css/
│   │   └── styles.css      ← sage/teal/ivory palette, responsive layout
│   ├── img/
│   │   ├── campus-map.jpg  ← the original ENSTP aerial map (preserved)
│   │   ├── icon-192.png    ← sage-green PWA icon (192×192)
│   │   ├── icon-512.png    ← sage-green PWA icon (512×512)
│   │   └── favicon.svg     ← inline SVG favicon
│   └── js/
│       ├── app.js          ← top-level orchestration
│       ├── i18n.js         ← AR/FR/EN strings + applyLangToDocument
│       ├── search.js       ← room/building search (exact-match priority)
│       ├── router.js       ← Dijkstra + nearestNode (bug-fixed)
│       └── map.js          ← SVG map, zoom/pan, route drawing
└── data/
    ├── map-graph.json      ← 32 places, 29 nodes, 32 edges + AR/FR/EN names
    └── rooms-data.json    ← 30 blocks + 67 rooms (from mapping-infos.xlsx)
```

---

## Quick start on Windows

1. Extract the ZIP completely into a normal folder.
2. Double-click `START-WINDOWS.bat`.
3. Your browser should open `http://127.0.0.1:8000/`.
4. Keep the PowerShell window open while using the website. Press Ctrl+C in that window to stop the server.

This package uses the Windows PowerShell HTTP server script (`serve.ps1`), so Python or Node.js is not required. Do not open `index.html` directly with `file://`; the app loads JavaScript modules and JSON data and must run through HTTP.

## Running locally

The app uses ES modules and `fetch()` for its data, so it must be served
over HTTP — `file://` will not work for the data files.

```bash
# from inside the enstp-campus-navigator/ directory
python3 -m http.server 8000
# then open http://127.0.0.1:8000/
```

Or with Node:

```bash
npx serve .
# or
npx http-server -p 8000
```

---

## Deployment

### GitHub Pages

1. Create a new GitHub repository (e.g. `enstp-campus-navigator`).
2. Push the contents of this folder to the `main` branch (or `gh-pages`).
3. In the repo settings → **Pages**:
   - Source: `Deploy from a branch`
   - Branch: `main` / root
4. Save. The site will be live at
   `https://<your-username>.github.io/enstp-campus-navigator/` within a
   minute or two.

### Vercel

Two equivalent options:

**Option A — drag-and-drop**
1. Visit <https://vercel.com/new>.
2. Drag the entire `enstp-campus-navigator/` folder onto the page.
3. Click **Deploy**.

**Option B — CLI**
```bash
npm i -g vercel
cd enstp-campus-navigator
vercel        # follow prompts; default settings are fine (framework: "Other")
vercel --prod # promote to production
```

Vercel will detect the static structure automatically. No
`vercel.json` configuration is required.

### Sub-path deployment

If you deploy under a sub-path (e.g.
`https://example.com/enstp/`), set `start_url` and `scope` in
`manifest.webmanifest` to `"./"` (already the default — relative).
All asset references in `index.html` use relative paths.

---

## Source data fidelity

The map and room data were extracted verbatim from the original project:

| Source (original)                              | Used here as          | Verified by            |
|------------------------------------------------|------------------------|-------------------------|
| `data/campus-map.html` (inline SVG + base64 image) | `assets/img/campus-map.jpg` + `data/map-graph.json` | byte-for-byte base64 decode |
| `data/campus-map.html` (NAMES / NL / L / N / E)   | `data/map-graph.json`  | json.loads + structure check |
| `data/room-search.js` (DATA constant)             | `data/rooms-data.json` | json.loads + 67 rows match |
| `data/source/mapping-infos.xlsx`                  | cross-checked against `rooms-data.json` | openpyxl — 2 sheets, 30 + 67 rows |

No room/building/coordinate was invented. No floor was guessed. See
`DATA-AUDIT.md` for the small list of source-data quirks inherited
verbatim from the Excel workbook.

---

## Bug fixes inherited

| Bug (original)                                                                | Fix (this project)                                                                 |
|--------------------------------------------------------------------------------|-------------------------------------------------------------------------------------|
| `near()` had a syntax error: `Math.hypot(N][0]-p.x,N][1]-p.y)` (invalid `N][0]`) | Rewritten correctly as `Math.hypot(N[k][0]-p.x, N[k][1]-p.y)` in `router.js`        |
| Search prioritised partial over exact matches                                   | Exact-match scoring (1000 for local-exact, 900 for block-exact) in `search.js`     |
| Search was case- and diacritic-sensitive                                       | `fold()` strips accents + quotes + dashes; "cafe" matches "café"                    |
| Floor names were not searchable                                                | Added `floorFr` to the searchable fields                                            |
| Map was an Arabic-only page (`<html lang="ar" dir="rtl">`)                       | Language-agnostic HTML, `dir`/`lang` set dynamically on language change             |
| PWA cached only the original student-guide's shell                            | New `sw.js` caches only this app's shell + data (cache-bust by version)             |

---

## Customising

- **Palette** — see the CSS variables at the top of
  `assets/css/styles.css`.
- **Labels** — see `STRINGS` in `assets/js/i18n.js`.
- **Building names** — see `data/map-graph.json` →
  `namesByLang.{fr,en}` and `namesAr`. These come from the original
  source data — do not translate proper names that change their identity.

---

## License & attribution

The map image (`campus-map.jpg`) and the room data
(`rooms-data.json`) come from the original `enstp-student-guide-v5`
project. The standalone application code in this folder is original
work for the ENSTP Campus Navigator.


## Recent visual adjustments

- Added the supplied ENSTP logo to the header (`assets/img/enstp-logo.webp`).
- Removed duplicate numeric text labels from the interactive overlay. Official building numbers remain visible on the original campus map image; the interactive circles and accessible tooltips remain.
