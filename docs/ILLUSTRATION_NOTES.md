---
author: peter
created: '2026-07-28'
modified: '2026-09-17'
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

**Parcel-scale illustration (step 5) is now also prototyped** — see the section below. Regional and neighborhood scale (below) remain paused, not abandoned.

**Output format, flagged 2026-07-28, not resolved:** every artifact described here is a static raster PNG, produced by base R/`terra` plotting. That was the right choice for fast prototyping and critique, but it is not the production format. The final deliverable renders on a web page (HTML/Quarto), and Peter's stated reference for output quality (the `cursor.com/insights` report reviewed at the start of this work) is a scroll-telling, vector-native format, not a stack of embedded images. Whether these R-generated graphics become SVG output, get rebuilt as web-native (JS/Observable/D3, per the Quarto direction already agreed), or something else is explicitly deferred to production/application-build time — do not assume PNG carries forward, and do not let "it looks right as a PNG" stand in for "it will look right in the actual deliverable."

---

## Status

- [x] Regional-scale inset (state-scale ecoregion + river context) — prototype settled, `R/illustrate/regional_inset.R`
- [x] Neighborhood-scale main image (contours + local hydrology + watershed boundary) — prototype settled, `R/illustrate/neighborhood_context.R`
- [x] Parcel-scale illustration, two graphics — prototypes settled, `R/illustrate/parcel_base_map.R`, `parcel_slope_drainage.R`, `parcel_building_mask.R`
- [x] Section 02 client-facing set (base map, slope/drainage, ground profile, aspect rose) styled to the design system — first pass 2026-09-17, `R/illustrate/parcel_topography.R`; see the section at the end of this document
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

---

## Parcel-scale illustration (`R/illustrate/parcel_base_map.R`, `parcel_slope_drainage.R`, `parcel_building_mask.R`)

**Job:** two paired graphics, per Peter's explicit split — one factual, one interpretive. Graphic 1 shows real, attributable ground data (topography as contours, the building as a flat shape, the parcel line) with no derived judgment calls. Graphic 2 layers interpretation on top (slope, drainage direction, an erosion-risk zone) computed from the same DEM but never rendered as raw pixels.

### The finding that shaped everything else here: the DEM lies under buildings
Peter's original concern going in was resolution (a 15ft buffer gives only ~26×48 native pixels). That's real, but a bigger problem was found while checking it: DEM slope/aspect/hillshade computed across a building footprint traces a fabricated elevated-slope "ring" that **exactly matches the real building footprint's perimeter** (confirmed by overlaying the two, not assumed from the shape alone) — the DEM's bare-earth void-fill under a structure is a flat interpolated surface with a sharp edge, and any terrain derivative computed across that edge reads as fake slope. At neighborhood scale this was background texture among thousands of similar artifacts; at parcel scale, with a building covering a large share of a tiny frame, it can dominate the result. `parcel_building_mask.R`'s `mask_dem_to_exclude_building()` exists specifically to prevent this — mask before any terrain computation, not after.

**A second, related finding:** `get_building_footprints()` can return a neighboring parcel's building too (anything in the search buffer, not just the subject parcel). Confirmed by comparing `PID` against the parcel's own `parno` — one of the two buildings returned for the test parcel belonged to a neighbor. `get_own_building_footprint()` filters to the real match; don't assume the first/only result returned is the subject parcel's.

### Graphic 1 (actual data) — settled composition
- Contours from the parcel's own DEM, **masked to exclude the building footprint before contouring** (not after) — this alone removed the fake artifact ring entirely, confirmed by direct comparison
- **0.25 ft interval / 1 ft index**, both grayscale, index distinguished by darker gray only (not weight) — chosen by comparing 1ft/0.5ft/0.25ft/0.1ft renders on the same DEM: 1ft was too sparse to show real shape (Peter's original complaint, correct), 0.1ft started looking like amplified noise or a raster-edge artifact rather than real ground (no documented vertical-accuracy figure for this DEM exists to confirm exactly where that line is - a visual judgment call, not a measured one)
- Building footprint: flat 40% gray fill, no attempt to show what's under the roof
- Parcel boundary: black dashed line
- **Canopy deliberately omitted**, not just forgotten: NLCD Tree Canopy Cover is 30m native resolution, and a parcel-scale display extent (~150ft) is smaller than one native pixel. The canopy polygon technically returns `has_canopy = TRUE` but covers the entire frame edge-to-edge — a single coarse pixel's yes/no answer, not real tree-crown geometry. Rendering it as a shape would repeat the exact false-precision mistake the building masking exists to avoid. Not resolved with a workaround, correctly left out.

### Graphic 2 (interpretive) — settled composition
- Arrows on a sample grid across the open-ground portion of the parcel (masked around the building, same DEM): direction from DEM aspect (downslope), length scaled to slope %, labeled with slope % rounded to the nearest whole number
- An "area of particular risk" zone: ground over the same 20%-grade NRCS-style erosion threshold already established in `dem.R`'s `summarize_topography()` — translucent orange fill, real threshold reused, not a new one invented for this graphic
- Same building fill and dashed parcel boundary as Graphic 1, for visual consistency between the pair

### Real bugs found building Graphic 2, in order
1. **Arrows and labels drifting outside the parcel boundary** — the first grid spanned the full display buffer (fetched wide so `terrain()` has valid neighbors at the parcel edge, per the same principle already documented in `dem.R`), not just the parcel itself. A client-facing "your parcel" graphic showing data past the property line is a real content error. Fixed by restricting the sample grid to points actually inside the parcel polygon.
2. **A label landing on the building fill, and a real coverage gap on the whole right side of the building** — traced precisely, not guessed: overlaying the valid-data raster against the parcel and building confirmed real slope data exists everywhere outside the footprint, including the ~23ft gap to the right of the building. The gap was a pure grid-alignment artifact (spacing + building-clearance buffer just didn't happen to place a column in that strip), not a data limitation.
3. **Tightening the grid to fix the gap reintroduced label collisions** that simple point-to-point distance thinning couldn't catch, because the collisions came from variable label-arrow *length* (steeper slope → longer arrow → label pushed further, into a neighbor's space), not from sample points being too close together. Manual spacing heuristics were tried twice and each fix traded one problem for another. Resolved by rebuilding the graphic in `ggplot2` + `ggrepel` (`geom_label_repel`) instead of base R `text()` — the same tool `regional_inset.R` already uses for exactly this class of problem. Real collision-aware placement, not another round of hand-tuned offsets.

### Explicitly deferred / not validated generally
- All grid/threshold parameters (`grid_spacing_ft`, `bldg_clearance_ft`, the focal smoothing window, the 0.25ft contour interval) were tuned against one small (0.14 acre), rectangular, one-building parcel. Untested on a larger or irregularly-shaped lot, or one with multiple structures.
- The canopy-at-parcel-scale question isn't solved for cases where it matters more (e.g., a heavily wooded lot) — it's just correctly absent here, not designed around yet.

---

## Section 02, client-facing set (`R/illustrate/parcel_topography.R`, `R/report/build_site_report.R`)

**Job:** turn the two settled parcel-scale prototypes into report graphics that follow `docs/DESIGN_SYSTEM.md`, and add the two topography graphics the PRD names that had no prototype yet (elevation profile, aspect rose). Built 2026-09-17 against the test parcel, first pass, not validated on a second site. The prototype scripts stay untouched as the plain-R record of what was validated; this file is the styled version and reads the same data.

**Output format, now decided for this section:** inline SVG via `svglite`, one string per graphic, embedded by `R/report/render_report.R`. `ggplot_to_svg()` strips the fixed size (so CSS `width:100%` scales it), makes the background transparent (the `.viz-card` surface shows through), removes svglite's `textLength` attributes (otherwise the browser stretches every label to R's font metrics), and swaps the chrome hex values (ink, muted, line, surface, accent) for the design system's CSS variables so the SVG follows light/dark mode. Data-family colors (ochre, ember, water, gold, material) stay literal, per the design system's rule that the paper-tier steps hold in both themes. All SVG text is Poppins; Cabin is reserved for HTML headings so R never needs it installed.

### The four graphics, and what each interpolates

1. **Base map** — contours over a hypsometric tint (ochre-01 to 03), index contours labeled, own building material-warm-04, neighbors material-warm-02, parcel line dashed ink, "STREET" label on the street side, A to A′ transect marker, scale bar and north arrow. The DEM is masked around the building first (unchanged rule), then upsampled 4x bilinear and smoothed with a 5-cell mean before contouring. That is the interpolation: it makes 0.25 ft contours read as ground instead of 3 ft pixel edges. It adds no information and the parcel relief it reports (4.8 ft) matches the raw masked DEM exactly (checked, not assumed).
2. **Slope and drainage** — slope-class fill (ochre-01 flat to ochre-04 steep, from a 7-cell smoothed slope with polygon corners rounded by an open/close buffer), downhill arrows in water-05 with local grade labels, erosion-risk zone (over 20%, same threshold as `dem.R`) in ember-03/05. Legend lives in the HTML under the card, not in the SVG. The class fill is for reading; the stats use the less-smoothed slope.
3. **Ground profile** — elevation sampled every 1 ft along a straight transect from the street edge through the parcel centroid to the back edge, relative to its low point. The run under the house is a straight-line interpolation between the ground at the two walls, drawn dashed with a translucent house block over it, and the caption says so. **Real finding on the test parcel:** the low point of this line sits directly behind the house at its back wall, and the back yard rises 2.3 ft from there to the rear line. The back yard drains toward the house. That is the kind of thing this graphic exists to surface; prose about it stays deferred.
4. **Aspect rose** — share of sloping ground (over 1.5% grade, so flat cells with meaningless aspect are excluded) in each of eight compass octants, gold-04 for the three south-facing octants, gold-02 otherwise. Test parcel: 39% faces SE, 30% E, 18% S.

### Numbers that changed from the earlier notes, and why

- **Parcel relief is 4.8 ft (316.3 to 321.1 ft), not the 2.3 ft recorded in `DATA_SOURCE_RESEARCH.md`.** The earlier figure came from a tighter 20 ft clip in the first DEM session; the parcel's SW corner rises to 321 ft and is inside the parcel line. Confirmed on the raw, unsmoothed, building-masked DEM before trusting the smoothed value.
- **"Steepest grade" in the stat row is the 99th percentile of on-parcel slope (19%), not the maximum.** A single spiky cell at the curb or a wall base should not headline the section. The erosion-risk share (0.7% of the parcel over 20%) still uses every cell.

### Decisions made here that deserve Peter's eye

- **Street side is an input, not a detection.** `KED_STREET_SIDE` (E/W/N/S) orients the transect and the label. For the test parcel it was read off OpenStreetMap by hand (Hill St runs north-south along the east edge). A road lookup could automate it later; guessing it from terrain would be wrong.
- **Label text uses `--ink`, not the family's 07 step.** The design system rule is for labels on data fills; these labels sit on a label box that flips with the theme, and the 07 step went invisible in dark mode. Caught in the browser, not in R.
- **The slope graphic is framed tight (14 ft) and the base map wide (30 ft).** The base map carries neighborhood context; the slope graphic only says something about the parcel.
- Canopy is still absent at this scale, for the reason recorded above (30 m NLCD pixels).

### Not validated generally

Same caveat as the prototypes: every parameter (buffers, smoothing windows, grid spacing, contour interval, the 1.5% aspect cutoff) was tuned on one small rectangular parcel with one building on a 4.8 ft relief. A larger, wooded, or irregular lot, or one with 20 ft of relief, will need the transect, the contour interval, and the profile's vertical scale revisited.
