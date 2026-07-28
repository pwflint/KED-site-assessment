---
author: peter
created: '2026-07-28'
modified: '2026-07-28'
status: development
tags:
  - domain/gis
  - domain/data-science
  - language/r
title: Site Assessment — Illustration Notes
type: project
---
# Illustration Notes

This document tracks design decisions, judgment calls, and rejected approaches for the translate/illustrate steps (`docs/WORKFLOW_SPEC.md` steps 3-5) — the layer above `docs/DATA_SOURCE_RESEARCH.md`, which covers data *sources*, not how they're rendered.

**Guiding principle, stated explicitly by Peter and worth repeating before every session that touches this work:** the images described here are prototypes, not finished products. They are sketches testing whether a specific translation idea — shifting a client's frame of reference from social space (streets, neighbors) to ecological space (watershed, ecoregion, geomorphology) — actually works, before any Quarto/production design work begins. Do not treat settled parameters (buffer sizes, thresholds, color choices) as final; they are what worked for one test parcel (7 Hill St, Raleigh, Wake County), not validated defaults.

**Current focus has shifted to parcel-scale illustration** (not neighborhood/regional scale) — see `docs/WORKFLOW_SPEC.md` step 5. The two artifacts below are paused, not abandoned.

**Output format, flagged 2026-07-28, not resolved:** every artifact described here is a static raster PNG, produced by base R/`terra` plotting. That was the right choice for fast prototyping and critique, but it is not the production format. The final deliverable renders on a web page (HTML/Quarto), and Peter's stated reference for output quality (the `cursor.com/insights` report reviewed at the start of this work) is a scroll-telling, vector-native format, not a stack of embedded images. Whether these R-generated graphics become SVG output, get rebuilt as web-native (JS/Observable/D3, per the Quarto direction already agreed), or something else is explicitly deferred to production/application-build time — do not assume PNG carries forward, and do not let "it looks right as a PNG" stand in for "it will look right in the actual deliverable."

---

## Status

- [x] Regional-scale inset (state-scale ecoregion + river context) — prototype settled, `R/illustrate/regional_inset.R`
- [x] Neighborhood-scale main image (contours + local hydrology + watershed boundary) — prototype settled, `R/illustrate/neighborhood_context.R`
- [ ] Parcel-scale illustration — not started, next focus
- [ ] Prose for any of the above — explicitly deferred by Peter until the writing approach itself is validated; do not draft unprompted

---

## Regional-scale inset (`R/illustrate/regional_inset.R`)

**Job:** the first "reorientation" visual — shift the client from "my address is near these streets" to "my property sits in this ecological/hydrological system," using facts they're likely to already recognize (state outline, the named region "Piedmont," the named river "Neuse") as anchors before narrowing to specifics (Level IV ecoregion, the property's own point).

### Settled composition
- State outline (via `tigris::states()`, not cached — fetched fresh per render)
- EPA Level III ecoregion, clipped to the state boundary, light gray fill + label
- EPA Level IV ecoregion, clipped to the state boundary, darker gray fill + label
- The parcel's HUC06 river (NHD "Flowline - Small Scale" layer), highlighted blue
- Parcel as a point (at this scale, a 0.14-acre parcel is sub-pixel regardless of styling)
- Labels via `ggrepel::geom_label_repel` — white-halo, leader-lined, not manually positioned

### Real findings that shaped this, not just style preferences
- **The true EPA Level III polygon is not state-clipped.** "Piedmont" as an ecoregion runs from Alabama to New Jersey. Rendered at full extent it's an unrecognizable diagonal sliver — this was caught by actually rendering it (v1), not assumed. Clipping to the state boundary is required for the "recognizable region" premise to hold at all.
- **Watershed *boundary polygons* don't read as intuitive to a layperson.** Peter's call, after seeing an early HUC6-basins-as-fill version: replaced with actual named river *linework* instead — a concrete, nameable thing, not an abstract drainage-area shape.
- **A curated "other major rivers for context" set was attempted and explicitly dropped, not solved.** Rivers with major reservoir chains (confirmed: Catawba, suspected but untested: Yadkin) return only fragments under a naive `GNIS_NAME` query, because long dammed stretches are classified as lake/reservoir features in NHD, not river reaches. See `docs/DATA_SOURCE_RESEARCH.md`'s Hydrography section for the full finding. Current script only renders the parcel's own HUC06 river.
- **Label placement needs `ggrepel`, not manual coordinate offsets.** Two manual-offset attempts either collided with the state border or landed in the wrong region entirely (a label reading "Northern Outer Piedmont" appeared over the wrong ecoregion). `geom_label_repel` with a white background and leader line solved this correctly on the first real attempt.

### Known limitation in the script, not yet fixed
`river_name_override` defaults to `paste(huc06_name, "River")` — held for "Neuse" → "Neuse River" but is a naming heuristic, not a guarantee. A "Pamlico" HUC06 is arguably "Tar-Pamlico" in practice. Verify against real NHD `GNIS_NAME` values before trusting the default on a new basin.

### Explicitly deferred (Peter's instruction, not oversight)
- Caching the state-clipped ecoregion/river shapes as a reusable static asset (currently re-fetched wide-extent data on every call) — worth doing once this moves past prototyping, same principle as the PRISM cache.
- Deciding on a real basemap-tile provider for this specific image (it doesn't currently use one — the neighborhood image below does).

---

## Neighborhood-scale main image (`R/illustrate/neighborhood_context.R`, `R/illustrate/basemap_tiles.R`)

**Job:** ground the same reorientation at a scale where the client can recognize their actual street/neighborhood, but with topography and drainage as the dominant signal, not the streets.

### Settled composition
- Basemap: real tile imagery (see Basemap Tile Provider below), not self-rendered street data
- Contours: 2 ft interval, 10 ft index lines, both thin, index distinguished by darker gray only (not weight) — generated from the parcel's own DEM (`get_dem_clip`), not sourced from an existing contour product
- Local hydrology: City of Raleigh Hydrology (see `docs/DATA_SOURCE_RESEARCH.md`), reduced to only "major" reaches (grouped by `RCH_CODE`, total length above a threshold) with a directional arrow and "flows to `<HUC12 name>`" label — all the shorter, scattered minor segments are dropped entirely as visual clutter, not just de-emphasized
- Watershed (HUC12) boundary: dashed, labeled, clipped correctly (see bug below)
- Parcel: drawn as its real cadastral boundary (a small rectangle at this scale), not a point — in red

### Real findings and a real bug, not just style preferences
- **A real correctness bug, not a styling issue:** the watershed boundary line was originally derived by clipping the HUC12 *polygon* to the display extent and taking the result's boundary. That silently pulled in the display box's own edges as if they were real watershed edge — a fake boundary segment hugging the frame. Fixed by extracting the true boundary line from the *unclipped* polygon first, then clipping that line. `neighborhood_context.R` does it the correct way; if this pattern is reused elsewhere for any other boundary-as-line rendering, use the same order of operations.
- **DEM raster shading was tried and rejected for this scale, not just simplified.** Three raster attempts (plain hillshade, percentile-corrected hillshade, hillshade + a blue topographic-position-index tint for local lows) were built and shown before Peter redirected entirely to vector contours. The percentile-stretch fix was real (a naive min/max stretch let a few outlier pixels — almost certainly the DEM's known building-void-fill artifact — crush real terrain signal into invisibility), but even after fixing it, continuous raster shading read as "busy" and didn't help a layperson understand geomorphology at this scale. DEM raster work (hillshade, slope, TPI) is reserved for a separate, more zoomed-in **parcel-scale** image — not built yet, the current focus per Peter.
- **NHD does not cover neighborhood-scale drainage near this parcel at all**, checked directly (not assumed) via NHD's large-scale flowline layer returning zero features in a tight envelope around the parcel. This is what motivated using City of Raleigh's hydrology data instead once Peter supplied it.
- **Contour lines still faintly echo the DEM's building-void artifact** even after aggregating the DEM to ~25ft cells before contouring (done specifically to suppress this) — much less visible than in the raw raster attempts, but not eliminated. Worth knowing if contours ever look suspiciously boxy near a structure.
- **The 2,500 ft display extent is not a validated "standard extent."** It was chosen because this specific test parcel sits ~1,039 ft from its HUC12 boundary — checked directly, not guessed — so a modest buffer would actually show the boundary crossing. Untested against a parcel that sits well inside its watershed with nothing to show at this radius. Open research question, explicitly deferred by Peter to a session after the translate phase.
- **The "major reach" length threshold (1,000 ft) came from a real gap in one parcel's data** (1,932 ft / 1,598 ft reaches vs. 601 ft / 214 ft ones) — not a validated general rule.

### Basemap tile provider — risk, not settled
Three providers were evaluated for a "quiet, no-label" tile backdrop:

| Provider | Format | Result |
|---|---|---|
| Esri `Canvas/World_Light_Gray_Base` | Raster | Live, stable (Esri-backed), but **confirmed by direct pixel inspection to have street/place labels baked into the tiles** despite the Base/Reference naming convention implying label-free Base tiles. Structurally a fused tile cache — no way to toggle labels off. Rejected for failing the "no labels" requirement. |
| Esri `OpenStreetMap_v2` / `World_Basemap_v2` | Vector (`.pbf`) | Both use non-standard relative style paths and (for `World_Basemap_v2`) a vector source definition that a generic MapLibre GL client can't resolve without real adaptation work. Not integrated - not a static-image-pipeline-compatible path without significant additional effort. |
| Carto `light_nolabels` (Positron) | Raster | **Currently in use.** Confirmed live, confirmed genuinely label-free by direct tile inspection. **Risk, explicitly flagged by Peter and not resolved:** Carto is a smaller/earlier-stage provider than Esri; free tile terms have shifted before. |

**Provider choice is explicitly deferred to when this project starts testing additional parcels/geographies** (Peter's instruction, 2026-07-28) — use Carto for now to produce working prototypes, revisit then. Do not silently swap providers without re-flagging this same tradeoff.

### Explicitly deferred (Peter's instruction, not oversight)
- Standard extent sizing (see above)
- Promoting `fetch_raleigh_hydrology()` out of `neighborhood_context.R` into a proper `R/acquisition/` function once a second (non-Raleigh) source is found and the pattern is proven across more than one city
- Label orientation — all labels currently render horizontally rather than following the geometry they annotate (a road, the watershed boundary). Known, named as acceptable for a prototype.
