---
author: peter
created: '2026-07-28'
modified: '2026-09-19'
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
- [x] Section 01 client-facing set (regional inset, neighborhood orientation map) — first pass 2026-09-18, `R/illustrate/regional_orientation.R`
- [x] Section 04 client-facing set (monthly climate chart, seasonal wind roses) — first pass 2026-09-18, `R/illustrate/climate_wind.R`
- [x] Section 05 client-facing set (neighborhood soil map, map unit soil profiles) — first pass 2026-09-18, `R/illustrate/parcel_soils.R`
- [x] Section 06 client-facing set (summer sun and shade map, hours of building shade on the solstices) — first pass 2026-09-19, `R/illustrate/parcel_microclimate.R`
- [x] Section 07 client-facing set (sun path over the lot, the practitioner's zones as an annotated site plan) — first pass 2026-09-19, `R/illustrate/site_synthesis.R`; see the last section
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

### Review notes, first pass (Peter, 2026-09-18) — held for a later revision pass

1. **Regional inset, color:** good as is.
2. **Regional inset, ecoregion labels:** the leader lines for PIEDMONT and Northern Outer Piedmont do not read as well as the watershed labels do in section 03. Either move those labels outside the state outline with leaders running in, or drop the leaders and set the label inside its polygon, near the centroid, offset toward the bottom-left. Either way, stop leading a label across the interior.
3. **Regional inset, parcel label:** offset "Your parcel" so there is a little clear space between the label box and the marker; the leader should not touch the circle.
4. **Neighborhood orientation map:** a good base map, but it tells the client nothing they do not already know. Make it carry two things the watershed-scale map cannot: **local drainage lines** (the small reaches and ditches, the path water actually takes off the block) and **canopy cover**. Both feed the opportunities and vulnerabilities in section 07, which is the point of putting them here. Open questions to work through: how to extrapolate broken drainage paths that the source data leaves as fragments so the lines read continuously (a judgment call to document, not silent gap-filling), and where parcel-scale canopy comes from, since NLCD is too coarse (the July finding) and this parcel has no canopy data yet. Candidates recorded, not built.
5. **All sections, stat row (applied 2026-09-18, not held):** the stat values were rendering at h2 size and read as peers of the section title; now h3 (`.stat-value`), and the label sits above the value so "Ground drains toward / Southeast" reads in order. Done in `R/report/render_report.R` (label-first markup, plus a CSS override on the vendored design system's `.stat-value`, which still says h2 in the design project; sync that change back to the design system when convenient).

**Handoff note (2026-09-18, earlier session):** Peter intends to work the remaining sections with a different agent, and to run the held revision passes (sections 01, 02, 03) separately. Sections 04 and 05 were built later the same day by that second agent (below); the revision passes are still held, by Peter's call, until the prototype is complete so any global edits can be made in one pass.

---

## Section 04, client-facing set (`R/illustrate/climate_wind.R`)

**Job:** the thirty-year baseline the landscape operates within, and the wind. Built 2026-09-18 on the test parcel from the two acquisition sources validated in July (`R/acquisition/climate.R`, `R/acquisition/wind.R`). First pass, not validated on a second site. No prose.

### The graphics
1. **Seasonal cards** (HTML, the design system's own component): inches in an average month of each season, the season's mean temperature, and now its average daily high and low. Same four-family rotation the design system prescribes (water, canopy, gold, ember).
2. **Climate chart**: two stacked panels, precipitation bars (water-03) above, the average daily high/low band (gold-03) with the mean dashed below. **The year runs November to October**, not January to December, so each of the PRD's seasons (Nov–Jan, Feb–Apr, May–Jul, Aug–Oct) is one contiguous block, tinted with its season family at low alpha and labeled. Annotations use the "name the threshold" device from section 02: wettest and driest month, the warmest month's high, the coldest month's low, and the 32°F freezing line. Two months (Jan, Feb) have an average low below freezing on the test parcel.
3. **Wind roses**, four seasons in a 2×2, each in its season family: how often the day's strongest two-minute wind (NCEI `WDF2`) came from each of eight directions, over ten complete calendar years at Raleigh airport, with the season's average speed in the facet title. Southwest dominates spring and summer (42%, 39%), the northeast takes over in fall (30%), which matches known Piedmont climatology (the July note).

### Stats for the section
Precipitation in a year (47.9 in, matching the July validation figure exactly), the warmest month's average high, the coldest month's average low, the prevailing wind over the whole record. The seasonal values in the cards are means of the three monthly normals per season, so they equal the July test values converted to inches and °F.

### Decisions worth Peter's eye
- **Nov→Oct axis.** Unconventional, chosen so the seasons read as blocks and match the card order. If it confuses readers, the cost of a Jan→Dec axis is that winter splits across both ends.
- **Whole calendar years, not a rolling window** (`get_wind_data()` changed 2026-09-18). Every season gets the same number of days, and the window is stable enough to cache. Previously the window ended yesterday and the summer count drifted through the year.
- **The roses bin the strongest wind of each day, not hourly observations.** GHCN-Daily has no hourly direction; the caption says exactly what is binned. A true prevailing-wind rose would need ISD hourly data, a different source.
- **Dark mode lesson, again.** First render put season labels, the "avg high / avg low" end labels and the wettest/driest text in family-06 steps, all invisible on the dark surface, and tinted the season bands with the near-neutral 01 steps, which read as grey slabs. Text on the surface or in a label box now uses the theme-swapped ink/muted; bands use the hued 02 step at 0.3 alpha. This is the same finding recorded for section 02 on 2026-09-17; it is worth making a rule in the design system: family steps are for marks and for text *on those marks*, never for text on the surface.
- `patchwork` 1.1 fails against ggplot2 3.5's guide layout on this machine; the two panels are stacked with `cowplot::plot_grid` instead.

### Not validated generally
The freezing line only means something where winter lows approach 32°F; a coastal parcel may need a different threshold annotation (or none). The rose scale (0–40%) is fixed by the strongest season; a site with a flatter distribution will show small roses. The nearest `USW` station can be 30+ miles from a rural parcel; the caption names it so the distance is visible, but the report does not yet say how far.

---

## Section 05, client-facing set (`R/illustrate/parcel_soils.R`, additions to `R/acquisition/soil.R`)

**Job:** what lies beneath, as the survey actually describes it. Built 2026-09-18 on the test parcel. First pass, not validated on a second site. No prose; the `implication` column the payload contract sketched stays absent until the writing approach is settled.

### What SSURGO can say at parcel scale, and what this section does about it
The test parcel sits entirely inside one map unit, **BcC, Beltline-Urban land-Cecil complex, 2 to 10 percent slopes**. A *complex* names soils that occur together in a pattern too fine to map at 1:24,000: Beltline 40%, Urban land 35%, Cecil 20%, Chavis 5%. Those shares describe the whole unit across the county, and the survey does not locate them within a lot. So the section is built around that honesty: the stat row names the unit and its largest soil *with its share*; the table is one heading per unit with a row per component and a "share of unit" column; the caption says the survey does not place them. Rendering a single "your soil is Cecil" answer would be false precision of exactly the kind the building mask exists to avoid.

### The graphics
1. **Soil map**, the section 03 frame (2,500 ft radius), map units tinted by the drainage class of their dominant soil on the design system's own gradient (understory-03 well, canopy-02 moderately well, gold-03 somewhat poor, ember-03 poor; excessively drained shares the well-drained step), outlined ochre-05, labeled with the symbol in a label box; roads and the Raleigh reaches as a quiet base; the parcel as a bloom marker with "Your parcel". Buildings were tried and dropped: at 0.45 alpha they barely showed and cost ~540 KB of SVG. Nine units in frame; the frame is 92% BcC, so the map is mostly one tint with the rocky Wake-Rolesville slopes, the Helena unit and the Chewacla-Wehadkee floodplain (somewhat poorly drained, frequently flooded) along Walnut Creek as the differences. That is the true picture and it is why the frame is 2,500 ft, not 900: at 900 ft the map is one polygon.
2. **Soil profiles**: the components of the parcel's map unit side by side as horizon columns to 60 in, **column width proportional to the component's share**, horizon fill by clay content (ochre-02 sandy to ochre-05 clay), horizon name and representative texture in each band that is tall enough, Urban land as a plain block "not mapped as soil". Two annotations: a bracket beside the human-transported fill horizons (SSURGO's `^` prefix; the "^" is stripped from the label and the bracket says "fill"), and a dashed line at the first horizon whose saturated hydraulic conductivity falls below 1 µm/s, labeled "water moves slowly below N in". On the test parcel that is 19 in for Beltline (a buried clay subsoil under 19 in of fill) and 31 in for Cecil.

### Real findings, not just style
- **SDA answers a query with no matching rows with a bare `{}`.** `sda_query()` treated that as a failure; it is a real answer (no restrictive layer, no wet-month water table). Now returns an empty frame; `sda_frame()` re-attaches the column names SDA drops with the rows.
- **Cecil carries hydrologic group D inside this urban complex** while the standalone Cecil unit next door (CeB) is group A and the unit's dominant condition is C. Presented as the source gives it; flagged here because a reader who knows Cecil as a B soil will notice. Not investigated.
- **Units are cm and µm/s.** Horizon depths are converted to inches for display; ksat to in/hr in the payload (`surface_ksat_in_hr`). The slow-water threshold of 1 µm/s is the NRCS boundary between "moderately low" and "moderately high" classes.
- **The neighborhood polygons come through the county cache** (`ssurgo_mupolygon`, with the extent hash), the tabular queries stay live. SSURGO polygons change on the survey's schedule, years, so the 180-day default is conservative.

### Decisions worth Peter's eye
- Drainage class as the map's fill encoding (the design system's gradient) rather than unit identity. With BcC covering the frame, the map is one green sheet with small exceptions; that reads as "your whole neighborhood drains well except the creek bottom", which is the point, but it is a saturated green and the legend must sit right under it.
- The stat "Largest soil in the unit: Beltline, 40%" rather than "Soil: Beltline". The share is load-bearing.
- The profile shows the survey's representative values (`_r`), not ranges. A low/high band per horizon exists in SSURGO and could be a later refinement.
- The `landform` field ("fills on hillslopes on piedmonts") is in the payload but not in the table; it overflowed the table and reads as jargon. It is exactly the kind of thing prose would translate.

### Not validated generally
A parcel that straddles two units gets two headings and a `pct_of_parcel` split; untested. A consociation (one named soil at 85%+) will produce one wide column and the profile will look empty on the right; the width rule may want a floor. Units with `Urban land` at 100% have no horizons at all. The 60 in cut-off truncates the deep Bt horizons (Cecil's go to 79 in); the caption says so.

---

## Section 06, client-facing set (`R/illustrate/parcel_microclimate.R`)

**Job:** heat, shade and air at the lot, from what the validated data can honestly support: the masked DEM (slope, aspect), the building footprints with their placeholder height, and the sun's path at the parcel's latitude. Built 2026-09-19 on the test parcel. First pass, not validated on a second site. No prose.

### The graphics
1. **Summer sun and shade.** The McCune and Keon (2002) heat load index from slope and aspect, relative to level ground, gold-01 (faces away from the sun) through gold-02 (level) to ember-04 (faces the afternoon sun); over it, the ground the buildings shade for two or more hours between 9 and 3 solar time on the summer solstice, in understory-03. On this gentle lot (mean grade 5%) the index varies by under 5% either way, so the map is almost uniform and the building shade is the picture. That is the truth of the lot, and the stats say it (0% of ground notably warmer than level, 6% cooler).
2. **Hours of building shade, winter and summer.** For each solstice, every DEM cell counts the half-hour steps between 9 and 3 it sits in a building's shadow; four classes in understory. Shadows come from plain sun geometry (declination by Spencer's series; altitude and azimuth from the hour angle, solar time, no equation-of-time correction) and each footprint swept along the shadow vector, edge by edge, so an L-shaped house does not get a filled-in hull. **The neighbors' buildings cast shade too**, and that is the finding on the test parcel: the house on the lot to the south shades this lot's southern strip for four-plus hours in winter (sun 31° at noon, a 50 ft shadow from a 30 ft wall); in summer (78°, 7 ft) shade is a thin ring around the house's east and west sides and 60% of the open ground is in full midday sun.

### What is inferred, and said in the captions
- **Building height is the 30 ft placeholder** from the footprint inventory (which carries no height; the July `LIDAR_HAG` finding). Every building gets it. A one-story ranch and a two-story neighbor look the same; a field measurement replaces the number and the graphics regenerate.
- **Tree shade is not drawn.** NLCD is 30 m (the July finding); the section reports the NLCD mean within 300 ft (16% on the test parcel) as a coarse context figure, labeled as including the surrounding lots. Parcel-scale canopy remains the open question from Peter's section 01 review. Candidates recorded, not built: the Meta/WRI 1 m global canopy height raster (an existing computed product, matches the pipeline's "cite, don't derive" rule; hosted on AWS by quadkey tile, ~100 MB a tile); NAIP 4-band NDVI at 60 cm (a derivation, but a simple one); the practitioner's field annotation (the PRD's own answer). None chosen.
- The heat load index is a relative ranking of ground by the sun it faces, not a temperature; the legend words say "cooler" and "warmer", not degrees.
- Solar time, not clock time: the sweep is symmetric about solar noon, which is about 20 minutes off clock noon in Raleigh. The caption says "solar time".

### Decisions worth Peter's eye
- Wind was drafted as arrows on the heat map and dropped: both seasons blow from the southwest on this parcel so the arrows sat on top of each other, and the map is too small for them to say more than the section 04 roses already do. The stat row and section 04 carry wind; the section title still says "air".
- The shade classes (under 1, 1 to 2, 2 to 4, 4 to 6 hours) and the two-hour threshold for the summer overlay are readable divisions of a six-hour window, not a horticultural standard. "Full sun" for plants is usually six-plus hours a day; the six-hour midday window cannot measure that and the report does not claim it.
- The frame is 20 ft beyond the parcel (section 02's slope graphic uses 14) so the STREET label fits; the extra empty ground above the lot is the cost.

### Not validated generally
A north-side neighbor never shades the lot and a west-side one only in the morning, so lots in other orientations will look very different; the geometry handles it but nothing has been checked. A parcel with several buildings or a tall one (three stories) will need the placeholder height per building. Flat lots make the heat index meaningless and the map will be one tint; steep south-facing lots will push it to the ember end. Winter shade from evergreen trees, the other big winter shade source, is absent for the canopy reason above.

---

## Section 07, client-facing set (`R/illustrate/site_synthesis.R`, the practitioner notes file)

**Job:** the one section where interpretation belongs. Peter's call, 2026-09-19, after weighing it against chasing a parcel-scale canopy dataset: build section 07's visuals in the site-analysis idiom of the mood board (`docs/reference/Graphic Mood Board.png`: his own block model with solstice sun arcs and wind arrows, the symbol palettes, the hand-drawn student analysis with sun path and zones), and treat canopy as a field observation for now. First pass, on the test parcel only.

### The words
Section 07's text is the practitioner's. It comes from a **gitignored notes file** (`output/{slug}_notes.json`, or `KED_PRACTITIONER_NOTES`), never from the repo: narrative, vulnerabilities, opportunities, the zone parameters and zone labels. This is the PRD's field-annotation channel made concrete. For the test parcel Peter dictated the content and asked for it edited into clean prose rather than quoted (speech-to-text); the agent edited for grammar and concision only, and the result is his to change. `BUILD_AGENT_PROMPT.md`'s "render verbatim" rule still holds for the renderer: it prints the file as given.

### The graphics
1. **Sun path over the lot.** A plan-view polar diagram around the house: direction around the ring, the sun's height by distance (a low sun far out, a high sun close in), three arcs for the summer solstice, the equinox and the winter solstice with sunrise and sunset points and hour ticks, day length and noon altitude labeled. At this latitude sunrise swings from 61° (June) to 119° (December), 14.4 against 9.6 hours of daylight; Peter's point is that most people have never seen the swing drawn. Pure geometry from `sun_position()`; the same for every lot at the latitude. Solar time, said in the caption.
2. **Annotated site plan.** The section 02 index contours with the practitioner's zones drawn as **schematic** polygons: front and back yards as slabs relative to the house and the street side; a strip along the street for its heat; a strip at the rear for understory; a canopy overhang band by edge and share; a rain garden as a disk off the named corner of the house; swales as dashed lines from the rear line along each side to the rain garden; the prevailing wind as one arrow per direction (summer and winter both blow from the SW here, so one). Each zone gets a boxed label with a leader. Colors follow the families (gold for sun-loving planting, water for the rain garden and swales, understory and canopy for planting and overhang, ember for street heat): six families on one graphic, well past the three-family rule, accepted here because this diagram's job is to name several different things at once and the design system has no synthesis-section rule yet.

### Decisions worth Peter's eye
- **Zones are drafted, not drawn.** Peter chose this over exporting polygons from CAD/QGIS. `draft_zones()` takes a corner, an edge, a share, a depth, and builds axis-aligned shapes; it knows nothing about the actual bed lines. The caption says "schematic, not surveyed". If a zone is wrong, change the parameter in the notes file, not the code.
- The swales are drawn from the rear corners along the sides to the rain garden and cross the back yard diagonally at the end; a real swale follows the grade. The DEM's low spots (the profile's low point behind the house, the back corner tapering to the south edge) are what the notes describe, but the line is not fitted to them.
- The canopy band is a field observation ("about a quarter of the back lot, west side") and is labeled as such on the map.
- The sun-path diagram is data, not judgment, and could live in section 06; it opens 07 because it is the premise for the light-based opportunities that follow.

### Not validated generally
`slab()` and `edge_strip()` are axis-aligned and assume the street side is one of E/W/N/S; a lot on a diagonal street or a flag lot will need rotated slabs. The label repel is tuned for six labels on one small lot. Parcels without a notes file get the sun path and no plan (the renderer omits the optional card), which is the honest state.

---

## Review notes, sections 04 to 08 (Peter, 2026-09-19) — held for the revision pass, except where marked applied

**Product-level, framing every note below:** the prototype has cost roughly $70 of agent time to build; a production assessment cannot cost $8 to $100 of agent build each. Peter's target is $10 to $15 per assessment with the scripts templated and the agent only finding data. Most of what follows should therefore become **automated, not agent-driven**, and any visual that needs site-specific drafting by an agent (the section 07 plan) is out. Record this in `WORKFLOW_SPEC.md`'s business framing when the spec is next touched.

### Section 07
1. **The drafted opportunities plan is rejected, applied 2026-09-19.** This is a site assessment, not a design; drawing swales and beds is designing. As drawn it was also illegible: too busy for a client, and the swale line read as a square in the back yard rather than water carried around the house. Sites differ too much for schematic drafting to scale. The code (`draft_zones`, `render_site_plan_ked`) stays in `site_synthesis.R` as a record; the renderer and build no longer draw it.
2. **The sun-path diagram moves to section 06, applied 2026-09-19.** Understanding the sun's arc is the first step in reading sun and shade through the seasons; it opens section 06 now.
3. The edited prose is good for a prototype.

### Section 06
4. **The summer sun-and-shade map renders grainy.** The heat load raster is drawn with `geom_raster(interpolate = TRUE)` on the 0.78 ft upsampled grid and svglite rasterizes it; the shade overlay is a polygon and is crisp. Candidates: draw the index as smoothed class polygons (as the section 02 slope classes are), or render the raster at higher resolution before embedding.

### Section 05
5. **The soil map mostly says "one soil unit".** Illustrating the surrounding units is of doubtful value to a client; short descriptions of the neighbors' soils in words may serve better than a map.
6. **The horizon profiles are not the right graphic.** Showing Urban land as a block illustrates bad data; the parcel itself is effectively Beltline. Better: go into the details of the soils on the property itself, and describe the surrounding soils briefly. The plan view may not be the right form at all; **more research needed** on how to visualize soils for a layperson.

### Section 04
7. **Climate chart: add extremes.** The averages read as a normalized curve; add a line for record or extreme highs and lows inside the band, ideally as felt temperature (heat index, wind chill): this summer saw heat indexes of 114°F and winters go well below 30°F. Source candidates: the same GHCN-Daily station record already cached (TMAX/TMIN daily extremes are in the same endpoint; heat index needs humidity, which GHCN-Daily lacks and ISD hourly has).
8. **Thirty-year normals will feel irrelevant soon.** Grey out the 1991–2020 normals and foreground the last five years' averages. The product's purpose in 07 is to prepare clients for dry summers, hot summers and shifting microclimate, so the recent record matters more than the normal. Same station record can supply it.
9. Wind roses: good.

### Section 08 and sources throughout
10. **Footnotes per visualization**, with the source link, collected at the bottom of each section; then in section 08 a bibliography in a scientific citation style (APA or similar), with authors where the source has them; links can live in either place.
11. **Methods, briefly, per section 02 to 07** in section 08: say where the report interpolates or infers from hard data (section 02: 0.25 ft contours interpolated from the 3 ft DEM; 06: placeholder building height, no tree shade; 05: complex shares describe the unit, not the lot; and so on). Section 01 needs no method.

---

## Caches moved out of tempdir (2026-09-18)
`PRISM_CACHE_DIR`, `GHCND_STATIONS_CACHE_DIR` and `BUILDING_FOOTPRINTS_CACHE_DIR` defaulted to R's per-session `tempdir()`, so every new session re-downloaded 134 MB of PRISM grids, the 11 MB station list and the 69 MB county footprint file; the handoff note warned about the last one. All three now default under `data/` (gitignored, `KED_DATA_DIR` moves it), beside the county cache. The daily wind record is cached there too, keyed by station and window.
