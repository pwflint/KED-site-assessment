---
author: claude
created: '2026-09-16'
status: research
tags:
  - domain/design
  - domain/data-science
title: Data Visualization Reference Gallery
type: research
---
# Data Visualization Reference Gallery

Curated reference examples for the report visualizations required by `docs/PRD.md` section 5
("Report Sections and Visualization Requirements") and shaped by the constraints already
established in `docs/ILLUSTRATION_NOTES.md` and `docs/DESIGN_SYSTEM.md`. This extends the
single ad-hoc reference already in this directory (`dataViz_temp.jpg`, a Cédric Scherer polar
chart used as inspiration for the regional/neighborhood illustration prototypes).

**Use:** internal design reference only, for the practitioner/build-agent team while prototyping
report visuals. Not for redistribution or publication as-is — these are other people's/agencies'
work, credited below, studied for technique.

**Not settled parameters or a design system.** Same caveat as `ILLUSTRATION_NOTES.md`: these are
examples to study and borrow technique from, not a locked visual language for this project.

Each category folder pairs with a report section from `PRD.md` §5. Full attribution and license
for every downloaded file is in [`SOURCES.md`](SOURCES.md).

---

## Regional orientation → `regional-orientation/`

**PRD requirement:** "NC state inset map showing ecoregion with parcel highlighted." This is the
same EPA Level III/IV ecoregion data already used in `R/illustrate/regional_inset.R`.

- **`nc-level-iv-ecoregions.pdf`** — EPA's own North Carolina Level IV ecoregion map. Worth
  studying for how EPA itself handles the problem this project already solved once
  (`ILLUSTRATION_NOTES.md`'s note on clipping Level III polygons to the state boundary): dense
  category count, a legend that has to hold ~60 named subregions, and label placement at a scale
  where regions get visually small. Useful as a "what the source agency considers legible" check
  against the simplified, ggrepel-labeled version this project already produces — not as a style
  to copy (it's a technical reference map, not an editorial one; this project's target register is
  closer to `cursor.com/insights`, per `ILLUSTRATION_NOTES.md`).

## Topography and landform → `topography-hillshade/`

**PRD requirement:** "Hillshade map of parcel and immediate context," slope/aspect maps,
elevation profile. Directly feeds `docs/WORKFLOW_SPEC.md` step 5 (parcel-scale illustration,
the current focus branch) — DEM raster work reserved for this step after being rejected at
neighborhood scale (`ILLUSTRATION_NOTES.md`).

- **`qgis-hillshade-azimuth-example.jpg`** — a QGIS-generated hillshade demonstrating how light
  azimuth/altitude parameters change the read of the same terrain. Relevant because the
  neighborhood-scale prototype's DEM raster attempts were rejected for reading "busy" even after
  fixing a percentile-stretch artifact (`ILLUSTRATION_NOTES.md`) — this is a reminder that
  azimuth/altitude choice, not just color-stretch correction, is a real lever worth testing before
  the next parcel-scale hillshade attempt.
- **`lidar-conservation-hillshade-sd.jpg`** — USDA NRCS LiDAR-derived hillshade used for
  conservation planning (public communication, not a GIS specialist audience). Closer to this
  project's actual audience constraint than the QGIS technical example above: a hillshade meant
  to explain *terrain and drainage behavior to a landowner*, the same job description as this
  project's parcel-scale step.

## Soils and infiltration → `soils-infiltration/`

**PRD requirement:** "Soil profile section showing horizons for dominant map unit(s), labeled in
plain language." Also requests an isometric block diagram — no suitably licensed example was
found; see the note at the bottom of this file.

- **`soil-horizons.svg`** — a clean, generically labeled O/A/B/C/R horizon diagram. Directly
  relevant as a *technique* reference for the plain-language soil-profile section: the labeling
  approach (short horizon names + one-line description per layer) is close to what
  `PRD.md`'s "Plain Language Requirement" (§5) calls for — technical indices like K-factor or
  infiltration rate translated to a sentence, not shown as a number.

## Climate and wind → `climate-wind/`

**PRD requirement:** seasonal temperature/precipitation bar charts and "wind rose diagram by
season." The existing `dataViz_temp.jpg` in the parent folder already covers the
seasonal-temperature side (polar daily-temperature chart, Cédric Scherer) — these two add the
wind-rose side, which had no existing reference.

- **`wind-rose-python-example.svg`** — a clean, minimal wind-rose generated with Python's
  `windrose` library. Useful as the "plain, reproducible-from-code" end of the wind-rose spectrum
  — closest in spirit to this project's R/ggplot2 pipeline (`docs/PRD.md` §10 lists `ggplot2`/
  `tmap` as the visualization stack), i.e. something an R equivalent (`ggplot2` + `geom_bar` in
  polar coordinates, or the `openair` package's `windRose()`) could realistically reproduce.
- **`wind-rose-plot-breeze.jpg`** — a denser, more technical wind-rose (stability-class banding,
  finer directional bins) from environmental-consulting software. Useful as a contrast case:
  shows how much information a wind rose *can* carry, against which to judge how much this
  project's client-facing, plain-language version (§5's "Plain Language Requirement") should
  actually keep.

## Microclimate → `microclimate-heat/`

**PRD requirement:** "Plan-view heat accumulation map derived from aspect and canopy cover" with
a plain-language interpretive sentence ("This section of the property accumulates heat in summer
due to...").

- **`atlanta-thermal-heat-island.jpg`** — NASA's 1997 airborne thermal survey of Atlanta, the
  canonical public urban-heat-island image. Relevant less for its rendering (it's a raw thermal
  scan, false-color, no interpretive layer) than as a reminder of the gap this project's
  microclimate section has to close: PRD explicitly requires the *plain-language interpretation*
  layered on top, which this NASA image doesn't attempt — a useful "what not to ship on its own"
  reference as much as a positive example.

---

## Not covered: isometric soil block diagram

`PRD.md` §5 asks for an "isometric block diagram of parcel showing soil map units in plan view."
No openly-licensed example was found during this research pass (Wikimedia Commons search
returned only historical/technical-drawing scans, nothing resembling the contemporary
landscape-architecture site-diagram style this likely wants). Worth a follow-up research pass
against landscape-architecture portfolios and USGS "fence diagram" hydrogeology reports (a
related, real technique: stacked block diagrams showing subsurface layers) rather than Commons,
which skews toward historical public-domain scans and doesn't have much contemporary editorial
data-viz work.

## Suggested next step

Per `docs/WORKFLOW_SPEC.md`'s human-in-the-loop discipline, none of this should be treated as
settled direction — it's raw material for whoever picks up parcel-scale illustration or the
climate/wind/soils sections next to react to, the same way `cursor.com/insights` was reviewed
before shaping the regional/neighborhood prototypes.
