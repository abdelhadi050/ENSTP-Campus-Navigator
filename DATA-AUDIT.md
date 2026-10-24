# Source Data Audit — ENSTP Campus Navigator

This document lists every data-quality issue identified while
extracting the campus map and room data from the original
`enstp-student-guide-v5.zip`. All values are preserved verbatim
per the project brief — **no correction was applied unless it was
supported by a reliable cross-source check.**

## Sources audited

| File                                                    | Purpose                                   |
|---------------------------------------------------------|---------------------------------------------|
| `data/source/mapping-infos.xlsx`                         | Source Excel — 2 sheets                   |
| `data/room-search.js`                                    | Embedded JSON in original project        |
| `data/campus-map.html`                                  | Inline SVG map + JS graph                 |
| `data/rooms-data.json`                                  | Verbatim copy of the JSON in room-search.js |

The Excel workbook contains two sheets:

1. **`Blocs 1 à 30`** — overview, 30 rows + header. Columns:
   `N° du bloc`, `Désignation du bloc`, `Locaux et services`, `Étage(s)`.
2. **`Détail par étage`** — per-floor detail, 67 rows + header. Columns:
   `N° du bloc`, `Désignation du bloc`, `Étage`, `Local / service`.

The embedded JSON in `data/room-search.js` matches the Excel
content row-for-row. We use this JSON verbatim (no transformation).

---

## Issues identified

The audit surfaced **4 issues**, all inherited from the source
Excel workbook. They are flagged in `data/rooms-data.json#dataQuality`
and listed here.

### 1. Likely typo — Block 30, `Détail par étage` row 64

- **Field**: `Local / service`
- **Excel value**: `Salles A à 4`
- **Expected**: `Salles 1 à 4` — the overview sheet (`Blocs 1 à 30`)
  for block 30 says `Salles 1 à 4`.
- **Likely cause**: a single-character typo in the source Excel
  (`A` instead of `1` — they share a keyboard position on French AZERTY).
- **Treatment**: preserved verbatim. **No room numbers were extracted
  for this row** — `roomNumbers` is `[]` instead of `[1,2,3,4]`. The
  local label is shown as-is.
- **User-visible impact**: searching for `Salles 1` returns
  the overview-row match (block 30 entry in `Blocs 1 à 30`) but not the
  detail row, because the detail row's label says `A à 4`. Searching for
  `1` still returns Salle 1 via the cross-floor 1er étage row.
- **Recommended source fix**: replace `Salles A à 4` with
  `Salles 1 à 4` in the source Excel.

### 2. Count mismatch — Block 28

- **Overview (`Blocs 1 à 30`)**: lists 2 locals for block 28
  (`Salles 7, 8 et 9` + `Salles 16, 17 et 18`).
- **Detail (`Détail par étage`)**: 6 rows — one per individual room
  (7, 8, 9, 16, 17, 18).
- **Treatment**: not a data error per se — the detail sheet is a
  proper breakdown of the overview sheet's bundled descriptions. Both
  views are preserved as-is.
- **User-visible impact**: none — the search returns the detail-row
  matches with the correct block/floor/room info.

### 3. Count mismatch — Block 29

- Same pattern as block 28: overview bundles 4 rooms into 2
  locals (`Salles 5 et 6` + `Salles 14 et 15`); detail breaks each
  room out individually (4 rows).
- Same treatment; no user-visible impact.

### 4. Count mismatch — Block 30

- Same pattern: overview bundles 9 rooms into 2 locals
  (`Salles 1 à 4` + `Salles 10 à 13`); detail breaks out 5 rows
  (one for `Salles A à 4` — see issue #1 — plus 4 individual
  rows for 10, 11, 12, 13).
- Same treatment; the typo in the detail row is preserved verbatim.

---

## Implausible floor assignments

The user brief asks to flag any room assigned to an implausible
floor rather than silently correcting it.

**No implausible floor assignments were found.** All 67 detail rows
use one of `1er étage` or `2e étage`. No room is on a `3e étage`
or higher, and no room is on `rez-de-chaussée`. The buildings in
the dataset are at most 2-storey academic blocks, which matches
reality for the ENSTP campus.

---

## Bug found and fixed in the original JS

While extracting the graph data from the original
`data/campus-map.html`, we found a **syntax bug** in the original
`near()` function:

```js
// Original (broken) — invalid `N][0]` and `N][1]`
const near=p=>Object.keys(N).reduce((m,k)=>
  Math.hypot(N[k][0]-p.x,N[k][1]-p.y) <
  Math.hypot(N][0]-p.x,N][1]-p.y)   // ← N][0] is a syntax error
    ? k : m);
```

This would have thrown `SyntaxError: Unexpected token ']'` at parse
time, meaning the entire original page's `<script>` block would have
failed to execute. We did not modify the original project (the file
`extracted/data/campus-map.html` is preserved untouched on disk), but
the new standalone `assets/js/router.js` ships the corrected version:

```js
// New (correct) — in /home/z/my-project/enstp-campus-navigator/assets/js/router.js
export function nearestNode(p) {
  if (!GRAPH_NODES) return null;
  const keys = Object.keys(GRAPH_NODES);
  if (keys.length === 0) return null;
  let best = keys[0];
  let bestD = Infinity;
  for (const k of keys) {
    const [nx, ny] = GRAPH_NODES[k];
    const d = Math.hypot(nx - p.x, ny - p.y);
    if (d < bestD) { bestD = d; best = k; }
  }
  return best;
}
```

---

## Summary

| Issue                              | Source location                       | Severity       | Action       |
|------------------------------------|----------------------------------------|----------------|---------------|
| `Salles A à 4` typo               | mapping-infos.xlsx → Détail par étage | Low            | Preserved; flagged |
| Block 28 overview vs detail count  | mapping-infos.xlsx                    | Informational  | Preserved   |
| Block 29 overview vs detail count  | mapping-infos.xlsx                    | Informational  | Preserved   |
| Block 30 overview vs detail count  | mapping-infos.xlsx                    | Informational  | Preserved   |
| `near()` syntax bug               | campus-map.html (original)            | High (page-breaking) | Fixed in router.js |

No data was fabricated. No coordinates, paths, or floor assignments
were invented. The standalone app preserves the real ENSTP campus
data exactly as it was in the original project, with a single bug fix
applied only to the new copy.


## Verified correction: Block 30 teaching rooms

The uploaded workbook's overview sheet (`Blocs 1 à 30`) lists Block 30 as `Salles 1 à 4; Salles 10 à 13`, with rooms 1–4 on the 1st floor and rooms 10–13 on the 2nd floor. The detailed sheet has a clear typo `Salles A à 4`. The app data now reconciles this against the overview sheet and stores Salle 1, Salle 2, Salle 3, and Salle 4 as individual searchable entries on the 1st floor. Rooms 10–13 remain individual entries on the 2nd floor. No map coordinates or paths were changed.
