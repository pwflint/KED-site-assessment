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
- [x] Section 02 client-facing set (base map, slope/drainage, ground profile, aspect rose) styled to the design system — first pass 2026-09-17, `R/illustrate/parcel_topography.R`; see the section near the end of this document
- [x] Section 03 client-facing set (parcel flow arrows, self-rendered neighborhood subwatershed map) — first pass 2026-09-18, `R/illustrate/parcel_hydrology.R`
- [x] Section 01 client-facing set (regional inset, neighborhood orientation map) — first pass 2026-09-18, `R/illustrate/regional_orientation.R`; see the last section
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

**Decision 2026-09-18 (Peter): self-rendered vector base, no raster tile, for the client-facing neighborhood graphic.** Reopened deliberately, not silently. What changed since July: (1) the design system now exists and a raster tile cannot participate in it — it is a fixed picture of someone else's palette, cannot follow dark mode, and reads as foreign inside an ochre card, while the system's own direction for this section (water linework, material-warm structure, bloom parcel marker) describes a self-drawn map; (2) the delivered report is a self-contained file with SVG inlined, so a tile provider vanishing breaks future builds, not delivered reports — a smaller risk than it looked when the delivery format was undecided; (3) commercial use of free tile sets is the sharper question than stability (Carto's terms not verified; treat as a check, not a finding). Stock-tile fallback, if vector rendering proves too slow to get right: keep Carto as a faint desaturated underlay at low opacity, cache tiles per assessment, accept the dark-mode mismatch. `basemap_tiles.R` stays in the repo for that. Data-sourcing consequences (county cache, vintage in the manifest) are in `docs/DATA_SOURCE_RESEARCH.md`, "Local county data cache".

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

### Review notes, first pass (Peter, 2026-09-18) — to be worked in a separate revision pass

Verdict: good first iteration, minor edits. Recorded here so the revision pass has a checklist and the reasoning behind each item.

1. **Base map — white halo around the building footprint.** A pale boundary rings the house and interrupts the tint. Not visually pleasing. Likely cause, not yet confirmed: the smoothing pass (`focal` with `na.policy = "omit"`) leaves NA cells at the mask edge and the re-mask widens them, so the card surface shows through the raster. Fix candidates: fill the tint under the building from the unmasked (interpolated) surface and only mask the *contours*, or grow the tint one cell into the footprint before drawing the building on top.
2. **Base map — second building footprint at the bottom of the frame.** It is the neighbor's house (PID differs from the parcel's parno; confirmed, not erroneous), but as drawn it reads as an error: cut off by the frame edge, opaque, unlabeled. Either drop neighbor footprints from this graphic or keep them clipped to the raster extent, more transparent, and labeled ("neighboring residence").
3. **Slope graphic — keep, but simplify.** The class fill is good. The per-cell arrow field is too busy for section 02 and is really hydrology. For section 02: three to five arrows showing the general direction of fall, no per-arrow labels. **The busy version is not thrown away:** flow arrows over the contours from the base map become the localized-hydrology graphic for section 03 (not yet built). Tabled until section 03 exists.
4. **Ground profile — feels exaggerated, and the house block does not read.** The vertical exaggeration may be an artifact of the profile being squeezed into the 3:2 pair column; test it at full card width before changing the scale. The grey rectangle with the gap beneath it is not something a layperson can read. Redraw the house as a simple outline that sits on the interpolated ground line, or shade the span without a block.
5. **Aspect rose — keep.** Unexpected and useful.
6. **Slope distribution bars — keep.**

7. **(Added 2026-09-18) Label buildings with their addresses.** When the neighbor footprint is cropped to the map, label it with its street address; label the subject parcel's building with its own address too. Applies to the section 02 base map and the section 03 parcel flow map alike (same base).

Not changed yet: the code still produces the first-pass versions. The revision pass should re-verify in the browser at desktop and phone widths, light and dark, as before.

---

## Section 03, client-facing set (`R/illustrate/parcel_hydrology.R`)

**Job (Peter, 2026-09-18):** show the immediate micro-context of water on the lot, then zoom out to the neighborhood. The whole report moves zoom out, zoom in, zoom out; this section is the first zoom-in after section 02, then the step back out. First pass, built on the test parcel, not validated on a second site.

### Graphic 1, parcel flow
The section 02 base map (hypsometric tint, 0.25 ft contours, buildings, parcel line) with downhill flow arrows over it, no slope labels, no class fill, no transect. Same arrow field as the slope graphic (`downhill_arrows()`, now shared), water-05, longer = steeper. Peter's review of section 02 moves the busy arrow field here; the section 02 slope graphic will be simplified to a handful of arrows in the revision pass. The contour labels are off on this one so the arrows are the only annotation.

### Graphic 2, neighborhood subwatershed
The self-rendered base, per the 2026-09-18 decision above (no raster tile). Layers, bottom to top: the parcel's own HUC12 tinted water-01 (neighbors untinted, so the tint reads as "your watershed"); flood polygon in ember-02 if FEMA returned one; contours 2 ft / 10 ft from the DEM aggregated to 25 ft cells (ochre-02/03, very light); buildings material-warm-02; roads in three weights by OSM class (residential and below thin, tertiary, primary/secondary); minor reaches water-02, major reaches (grouped by RCH_CODE, over 1,000 ft total) water-04 with one flow arrow each labeled "to {HUC12 name}"; the HUC12 boundary dashed in the accent, extracted from the unclipped polygon (the July bug); watershed names as labels on both sides of the boundary; three named through-roads labeled along their line; the parcel as a bloom-05 fill with a ring and "your parcel". Scale bar, north arrow.

**Real bug caught building it:** flow direction is decided by comparing DEM elevation along the reach, and the clipped reach ends sit exactly on the frame edge where the DEM sample is NA, so no arrows were produced at first. Now elevation is compared a little way in from each end and the arrow is drawn at 80% of the way toward the downstream end so it stays in frame.

**Second real finding:** the state footprint GDB stores some buildings as MULTISURFACE (curved edges). GEOS cannot intersect those; everything is cast to MULTIPOLYGON before clipping. Section 02 never hit this because it only intersects with the parcel's own rectangular building.

### Stats for the section
Watershed (HUC12), river basin (HUC06), FEMA zone plus subtype, and "ground drains toward", which is the dominant octant of the section 02 aspect rose (southeast on the test parcel). `downstream_huc12_name` (from `tohuc`) is only populated when the downstream HUC12 happens to be in the frame; on the test parcel it is not.

### Not validated generally
The 2,500 ft extent (still chosen for this parcel's distance to its boundary), the 1,000 ft major-reach threshold, the three-road label limit, and the Raleigh-only hydrology source. A parcel outside Raleigh has no reach layer yet. A parcel deep inside its HUC12 will show a tinted frame with no boundary, which may need a wider extent or a different device.

### Review notes, first pass (Peter, 2026-09-18) — held for a later revision pass

1. **Parcel flow map:** same two issues as the section 02 base map (it is the same base): the white halo around the building footprint, and the neighbor's footprint overlapping the crop. Fix once in the shared base: crop neighbor footprints to the map, label them with their address, label the subject building with its address.
2. **Neighborhood map, parcel marker:** the ring around the parcel is not clear. Either a larger radius, a different color (plain black/ink is fine), or drop the ring entirely. The "your parcel" label then needs to sit offset above whatever the marker becomes, and read "Your parcel" (capitalized, good grammar throughout).
3. **Neighborhood map, flow label:** "to Walnut Creek" overlays the arrow and is unclear. Offset it to the end of the arrow, clear of the line.
4. **Neighborhood map, road labels:** the major-road labels collide with the reach linework and other lines. Give every label a surface-colored background (label box, not bare text), including the second major road above.
5. **Neighborhood map, label hierarchy:** the watershed labels should be bigger. They are the point of the graphic.
6. **General:** line work interferes with labels throughout. Every label on a busy map gets a background box; placement must avoid lines, not just other labels.

Carry these into section 01 as it is built (Peter's instruction): label boxes on busy maps, offset labels off their anchors, address labels on buildings, marker clarity.


---

## Section 01, client-facing set (`R/illustrate/regional_orientation.R`)

**Job:** the report's opening zoom-out and its first step in. Built 2026-09-18 with Peter's section 03 labeling notes applied from the start: every label on a busy map in a surface-colored box, labels offset from their anchors with leaders, the subject labeled with its address, a solid parcel marker rather than a thin ring.

### Graphic 1, regional inset
The July composition (`regional_inset.R`), restyled: state outline material-warm-03 on the card surface; Level III ecoregion canopy-01 with canopy-03 edge; Level IV canopy-02 with canopy-04 edge; the HUC06 river water-04; the parcel a bloom-05 dot with an ink outline. All four labels (PIEDMONT, Northern Outer Piedmont, Neuse River, Your parcel) sit in one repelled layer with directional nudges so they clear each other and the marker. The state outline and the river are now cached under `data/nc/` with provenance (the July notes asked for exactly this); the ecoregion polygons are still a per-parcel query (small) and clipped to the state at render time. `get_principal_river()` in `R/acquisition/hydrography.R` promotes the ad hoc NHD query; the "HUC06 name + River" heuristic and the reservoir-fragment limitation carry over unchanged.

### Graphic 2, neighborhood orientation
New. The block the client recognizes, at a 900 ft radius: named streets (every named street with a run over 250 ft, label in a box, repelled), buildings material-warm-02, the parcel outlined and tinted in bloom with its own building darker, and a two-line label "Your parcel / {address}" offset above on a leader. No data display at all: its only job is "yes, this is your parcel" (`WORKFLOW_SPEC.md` step 4). It reuses the section 03 road and building caches, so it costs no new fetch. The July neighborhood prototype (contours + hydrology + HUC12) is now section 03's second graphic, not this one.

### Real bug caught
`KED$canopy` did not exist: the token list in `parcel_topography.R` only carried the families sections 02 and 03 used, so the ecoregion label colors were NULL and the data frame failed with a misleading "differing number of rows" error. Canopy and understory added; the design system's other families (groundcover, chicory, coneflower, bloom scale) are still not in the list and should be added when a section needs them.

### Not validated generally
The 900 ft orientation radius and the 250 ft minimum street run are tuned on a dense urban grid; a rural parcel may need a wider frame and fewer labels. The regional inset's label nudges are tuned to a parcel in the eastern Piedmont; a coastal or mountain parcel will put the marker near a state edge and the nudges may push labels off the map.
