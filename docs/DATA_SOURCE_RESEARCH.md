---
author: peter
created: '2025-12-09'
modified: '2026-05-14'
status: development
tags:
  - domain/gis
  - domain/data-science
  - language/r
title: Site Assessment — Data Source Research
type: project
---
# Data Source Research

This document tracks research tasks for data sources, API endpoints, data availability, and implementation details.

## Research Status

- [x] Parcel / base map ✅ 2026-07-22
- [x] DEM (1m resolution) ✅ 2026-07-22
- [x] Climate (PRISM) ✅ 2026-07-24
- [x] Wind (NOAA) ✅ 2026-07-24
- [x] Watershed (HUC 06/12) ✅ 2026-07-24 — source located and retrievable; extent logic deferred to visualization stage
- [x] Ecoregions (EPA Level III) ✅ 2026-07-24 — source located and retrievable; extent logic deferred to visualization stage
- [x] Soils (SSURGO properties) ✅ 2026-07-24 — validated via SDA + UC Davis SoilWeb, see Soils section (checklist item missed being marked when this was originally done)
- [x] Flood Zones (FEMA) ✅ 2026-07-24
- [x] OpenStreetMap (base maps) ✅ 2026-07-24 — source located and retrievable; extent logic deferred to visualization stage
- [x] Building Footprints (new, not in original PRD) ✅ 2026-07-24 — 2D geometry only, placeholder height; see Canopy Height section
- [x] Canopy Height (LiDAR) ✅ 2026-07-24 — reconsidered: 2D extent + placeholder height, not LiDAR-derived height; see section below

---

## Parcel / Base Map

Not in the original research list below, but Tier 1 per the PRD and validated 2026-07-22 as the first slice of the fresh-start rebuild.

### Finding: PRD's stated source (`osmdata`/OSM Overpass) is wrong

OSM is not authoritative for cadastral parcel boundaries — it's not built for that. The correct source is NC OneMap's statewide parcels layer, `NC1Map_Parcels`, which aggregates all 100 counties' tax parcel data (via the Integrated Cadastral Data Exchange project) into one standardized feature service.

- **FeatureServer:** `https://services.gis.nc.gov/secure/rest/services/NC1Map_Parcels/FeatureServer/1` (layer 1 = polygons; layer 0 = centroids)
- Also served from `services.nconemap.gov` — same underlying NC OneMap system as the DEM
- **Public, no auth required**, despite "secure" appearing in the URL path
- 71 fields per parcel: owner name, mailing/site address, GIS acres, tax use code + description, structure count/year, sale date, legal description, county, etc.

### Query pattern

Practitioner always has an exact, unambiguous address (confirmed with the client before the assessment runs) — no fuzzy matching needed. Exact match on `siteadd` (Full Site Address) + `scity` (Site Address City). **Do not scope by `szip`** — confirmed empty on a real test record, not reliably populated statewide. `cntyname` is a useful additional filter if the county is already known.

### Data quality caveats (per-county — do not assume uniform)

- `szip` empty on the one Wake County record tested
- `parusedesc` (Tax Parcel Use Code Description) returned as a raw code (`"R"`) rather than spelled-out text on that same record — completeness of this field likely varies by county's source contribution
- Treat every field as needing a per-county spot check the first time a new county (Orange, Durham, Harnett, etc.) is brought online — log findings here as each one is tested

### Test case

`7 Hill St, Raleigh, NC 27610` (Wake County) — exact match returned one feature: parcel `1713393228`, 0.14 acres, single-family residential, polygon geometry. Confirmed end-to-end.

---

## DEM (1m Resolution)

### Research Questions
- [x] Is 1m resolution DEM available for all locations in North Carolina? ✅ 2025-12-09
	- Yes. Available as WCS or WMS in 3ft grid (~1m). The URL is https://services.gis.nc.gov/secure/services/Elevation/DEM03/ImageServer/WCSServer?request=getcapabilities&service=wcs or as an imageserver https://services.nconemap.gov/secure/rest/services/Elevation/DEM03/ImageServer
- [x] What is the best data source for 1m DEM? (USGS 3DEP, state-specific sources, etc.) ✅ 2025-12-09
	- For NC it is NCOneMap https://www.nconemap.gov/. This is derived from LiDAR data. 
- [x] Should we use different sources for different regions? ✅ 2025-12-09
	- For now we should focus on North Carolina data
- [x] How to handle resampling for visualization if source resolution varies? ✅ 2025-12-09
	- A statewide DEM is available so this should not be an issue. 
- [x] What is the coverage area for 1m vs 3m vs 10m DEMs? ✅ 2025-12-09
	- NC OneMap uses 3ft grid (~1m) exclusively for all its DEM products.

### Data Sources to Investigate
- USGS 3DEP (current source - check 1m availability)
- State-specific LiDAR programs 
- Other federal/state sources

### Implementation Notes
- Current implementation uses `elevatr` package
- May need to switch to direct API calls or different package
- Need to handle tile acquisition that intersect parcel boundary

### Status
**Current**: Using 10m/3m from USGS 3DEP via `elevatr`
**Target**: 1m resolution for all parcels
**Action Items**:
- [x] Research 1m DEM availability for NC ✅ 2025-12-09
- [x] Test alternative data sources ✅ 2026-07-22 — see findings below
- [ ] Update acquisition script if needed

### 2026-07-22 findings — endpoint validated, real gotchas found

**Endpoint confirmed live:** `https://services.nconemap.gov/secure/rest/services/Elevation/DEM03/ImageServer` (also on `services.gis.nc.gov`). Public, no auth. Resolution 3.125 ft (~0.95m) — matches the "1m" target. Same NC OneMap system as parcels, so acquisition can share auth/access patterns across both.

**Likely bare-earth, not confirmed in so many words.** The service's own metadata abstract states it was "created by the NC Floodplain Mapping Program and processed by NC Department of Public Safety – Division of Emergency Management." Floodplain/hydraulic modeling requires bare-earth elevation — you cannot run FEMA-compliant flood models with buildings and canopy in the surface — so this is strong circumstantial evidence of bare-earth intent. The metadata text does not use the words "bare earth" explicitly.

**Building footprints are visible in hillshade renders as flat, sharp-edged rectangular blocks.** Working theory (Peter's, and it fits the floodplain-program provenance): LiDAR can't return a valid ground hit under a roofline, so bare-earth processing has to interpolate/fill that void — a flat, sharp-edged fill is exactly what void-filling under a footprint looks like. A retaining wall showed a real graded shadow in the same render; the building blocks didn't. Not fully confirmed against explicit product documentation.

**NC's `DEM03_slope` / `DEM03_aspect` / `DEM03_Contours*_raster` ImageServer endpoints exist but are not usable for numeric analysis via a plain `exportImage` call.** They return pre-styled RGB display images (meant for rendering in an ArcGIS map client), not raw slope-degree or aspect-degree pixel values, even when an explicit `renderingRule` is passed. **Use case:** compute slope/aspect yourself from the raw bare-earth `DEM03` raster via `terra::terrain()` — this is the reliable, auditable path, not a fallback.

**Critical methodology rule — always match `exportImage` `size` to native resolution.** Requesting a raster export with a pixel `size` much larger than what the bbox supports at native resolution (3.125 ft/px) forces the server to oversample — with nearest-neighbor interpolation this stretches each real grid cell into a block of identical fake sub-pixels. Slope computed on that stair-stepped surface produces a **false grid-patterned "erosion risk" artifact** — real terrain doesn't erode in perfect right angles; a rectilinear pattern in a derived slope/risk map is the tell that this bug has recurred. Compute `size` from `bbox extent ÷ 3.125 ft` before every export; never default to a fixed large size on a small bbox. (This bug produced a false "11.3% of parcel at erosion risk" reading in-session; corrected to 0.9% at native resolution.)

**Clip strategy — two different scales, don't conflate them.** Analysis rasters (slope, aspect, drainage) should be clipped tight — just outside the parcel boundary (~10-20 ft buffer, matching the old Site Data Extraction Model's design). Wider buffers are only appropriate for regional/neighborhood *context* visuals, which the PRD's Topography section doesn't actually call for ("hillshade map of parcel and immediate context," not neighborhood) — Regional Orientation context comes from ecoregion/parcel data, not the 1m DEM.

**Test case (7 Hill St, Raleigh, Wake County), native-resolution results:**
- Parcel elevation range: 316.7–319.0 ft (2.3 ft relief — flat lot)
- Max slope on parcel: 13.8° (25% grade), localized to the front corner near the street — plausible driveway/curb transition, not an artifact
- Erosion-risk area (>20% grade, an NRCS-style threshold): 0.9% of parcel
- 36.9% of parcel faces S/SE/SW (highest solar exposure band) — a real input for microclimate/heat framing

**A one-variable exploratory sketch** (slope classified into low/moderate/erosion-risk, masked to the parcel) was produced in-session to prove this concept end-to-end. It is **not** a product-ready visualization, was not requested as a design deliverable, and represents only slope — no aspect, drainage, canopy, or the plain-language translation layer the client-facing report needs. Kept out of the tracked repo; useful as a reference for what the Topography/Microclimate sections are working toward, not as a spec.

---

## Climate (PRISM)

### Research Questions
- [x] Why is PRISM data structure empty after download? ✅ 2025-12-09
	- We need to isolate this script and make a few test runs to pinpoint this issue. I suspect this will resolve itself as we refine what type of data we are looking for. 
- [x] Should we extract point values or use regional averages? ✅ 2025-12-09
	- Regional precipitation and temperature averages should be sufficient to suit our purposes. We will need 30 year monthly averages for the specific grid cell and average them across 4 seasons: Nov-Jan for Winter, Feb-Apr for Spring, May-Jul for Summer, Aug-Oct for fall
- [x] How to visualize monthly/annual patterns? ✅ 2025-12-09
	- I envision a plot of each season on the section page, with some way of illustrating rainfall and temperature using color gradients. We may need to research visualization examples when we approach data processing. 
- [x] What is the best way to get nearest station data vs PRISM grid? ✅ 2025-12-09
	- I think PRISM grid is best option. The `prism` package should suffice.
- [x] How to handle triangulation of multiple stations if needed? ✅ 2025-12-09
	- This step not necessary if using PRISM grid

### Data Sources to Investigate
- PRISM (current source - investigate empty structure issue)
- NOAA weather stations (for point data)
- Other climate data sources

### Implementation Notes
- Current implementation uses `prism` package
- Issue: `prism_archive_subset()` returns empty structure
- Need to investigate `get_prism_normals()` vs `prism_archive_subset()`

### Status
**Current**: PRISM package, but data structure is empty after download
**Target**: Reliable temperature and precipitation data (seasonal averages)
**Action Items**:
- [x] Debug PRISM data loading issue ✅ 2026-07-24 — see findings below
- [x] Test alternative methods for extracting PRISM data ✅ 2026-07-24
- [ ] Research NOAA station data as alternative/complement

### 2026-07-24 findings — root cause found, direct download validated, no package needed

**Root cause of the "empty structure" bug:** `prism_archive_subset()` targets 30-year normals specifically, but normals were never served on PRISM's modern REST API (`services.nacse.org/prism/data/get/...`) — confirmed that service only carries recent monthly/daily "AN" (all-networks) data. Normals only ever lived on the direct file-distribution path. This wasn't a bug to fix in our code; the `prism` package (or our use of it) was pointed at the wrong distribution.

**Validated direct-download path, no auth, no R package dependency:**
```
https://data.prism.oregonstate.edu/normals/us/4km/{element}/monthly/prism_{element}_us_25m_2020{month}_avg_30y.zip
```
- `{element}`: confirmed working for `ppt`, `tmax`, `tmin`, `tmean` (directory listing also shows `tdmean`, `vpdmax`, `vpdmin` at the same path, untested)
- `{month}`: two-digit `01`–`12`
- Each zip contains a GeoTIFF (~2.8MB) plus `.stn.csv` (station list used) and `.info.txt` (metadata) — loads directly into `terra`

**Caching matters for production economics.** These are CONUS-wide grids, not parcel-clippable via the distribution service — every parcel in the same state hits the same file. Cache each element/month grid once (~2.8MB × 4 elements × 12 months ≈ 134MB total) and reuse across every future site; this is a one-time infrastructure cost, not a per-assessment cost, which matters for the $200–250 price point in `WORKFLOW_SPEC.md`.

**Test case (7 Hill St, Raleigh, Wake County) — seasonal normals, Winter/Spring/Summer/Fall per the PRD's Nov-Jan/Feb-Apr/May-Jul/Aug-Oct grouping:**

| | Winter | Spring | Summer | Fall |
|---|---|---|---|---|
| Precip (mm) | 89.4 | 89.5 | 110.7 | 116.1 |
| Tmax (°C) | 13.4 | 17.6 | 29.4 | 26.9 |
| Tmin (°C) | 0.9 | 3.9 | 17.6 | 15.3 |
| Tmean (°C) | 7.2 | 10.7 | 23.5 | 21.1 |

Sanity-checked: tmax > tmin every month, summer > winter, annual precipitation total (1,217mm ≈ 47.9in) is a close match to Raleigh's known ~46in annual average.

---

## Wind (NOAA)

### Research Questions
- [ ] How to find nearest weather station IDs?
	- Lets explore using the `rWind` package instead of using station IDs. This is GFS data on a 50km grid at 10m elevation. 
- [ ] What is the best API endpoint for wind data?
	- The `rWind` package should be able to directly access the GFS wind data, no API needed.
- [ ] How to get seasonal wind patterns (wind rose data)?
	- We would interpolate this from the downloaded dataset.
- [ ] What wind parameters are needed? (speed, direction, frequency)
	- Yes, these three to produce a wind rose.
- [ ] How to handle missing or incomplete station data?
	- I think the real question is how to deduce averages using `rWind`. It looks like it only downloads daily data. 

### Data Sources to Investigate
- NOAA NCEI Data Service API (current - new system)
- NOAA Historical Weather Data
- Other wind data sources

### Implementation Notes
- Current implementation uses NOAA NCEI Data Service API
- Issue: 400 error suggests API parameters may be incorrect
- Need to verify API endpoint and parameters

### Status
**Current**: NOAA NCEI Data Service API (new system, no token required)
**Target**: Wind rose from nearest station with seasonal averages
**Action Items**:
- [x] Verify correct API endpoint and parameters ✅ 2026-07-24
- [x] Research how to find nearest station IDs ✅ 2026-07-24
- [x] Test wind rose generation from station data ✅ 2026-07-24
- [x] Document seasonal wind patterns needed ✅ 2026-07-24

### 2026-07-24 findings — station-based daily data, no wind-rose product exists, build it ourselves

**Went with NCEI daily-summaries + our own binning, not `rWind`.** The two approaches in the research questions above point in different directions: `rWind` pulls GFS gridded model output (real-time-ish, 50km), while the Implementation Notes describe a station-based NCEI attempt. Station data is the better fit — it's an actual observed record at a real point, matching how PRISM/soils/DEM already tie back to specific, citable sources, rather than a coarse model grid. No wind-rose product exists anywhere in NOAA's catalog; every path here means binning many years of raw observations into direction/frequency counts ourselves, which is what the old notes were gesturing at ("interpolate this from the downloaded dataset").

**Endpoint confirmed live, no token:** `https://www.ncei.noaa.gov/access/services/data/v1?dataset=daily-summaries&stations={id}&startDate=...&endDate=...&dataTypes=AWND,WSF2,WDF2&units=metric&format=json`. The old "400 error" was very likely a parameter-naming issue, not a dead endpoint — this works cleanly once the params match the current docs.

**Station selection needs a real filter, not just "nearest."** GHCND's station list (`https://www.ncei.noaa.gov/pub/data/ghcn/daily/ghcnd-stations.txt`, ~132K stations, fixed-width format) includes CoCoRaHS volunteer rain-gauge stations (`US1` prefix) that are often geographically closer to a given parcel than any real weather station, but **only measure precipitation, never wind.** Naively picking the nearest US-prefixed station picked one of these first and returned an empty wind column. Restricting to `USW` (Weather-Bureau-Army-Navy — airport/NWS sites with full instrumentation) fixes it. `USC` (COOP) stations have inconsistent wind reporting and are also worth avoiding for this purpose.

**Test case (7 Hill St, Wake County):** nearest `USW` station is `USW00013722`, Raleigh-Durham International Airport — confirmed by name in the API response, not assumed. 10 years of daily data (2016-07-25 to 2026-07-21), 3,649 records, only 3 missing direction values.

**Seasonal wind rose (8-point compass, % of days from each direction, mean speed m/s):**

Southwest is the dominant direction in all four seasons (30–43%), strongest in summer (43% frequency, 3.69 m/s mean speed), with northeast as the consistent secondary direction. This matches known Piedmont NC climatology — summertime subtropical-ridge flow from the SW, more NE representation in cold-season frontal passages.

---

## Watershed (HUC 06/12)

### Research Questions
- [ ] What is the best data source for HUC boundaries?
- [ ] How to get HUC 06, HUC 08, HUC 10, and HUC 12 boundaries?
- [ ] How to extract watershed names for hierarchy (HUC-12 → local creek → HUC-06)?
- [ ] What if NHDPlus returns 404 (no data)?
- [ ] Are there alternative sources if NHDPlus fails?

### Data Sources to Investigate
- NHDPlus (current source via `nhdplusTools`)
- USGS Watershed Boundary Dataset (WBD)
- Other federal/state watershed data

### Implementation Notes
- Current implementation uses `nhdplusTools::get_nhdplus()`
- Issue: 404 errors and "subscript out of bounds" errors
- May need to use WBD directly instead of NHDPlus

### Status
**Current**: NHDPlus via `nhdplusTools` (unreliable)
**Target**: HUC 06 for regional context, HUC 12 for parcels, intermediate HUCs for hierarchy
**Action Items**:
- [x] Research WBD as alternative to NHDPlus ✅ 2026-07-24
- [x] Test HUC boundary acquisition from WBD ✅ 2026-07-24
- [x] Research how to get watershed names/hierarchy ✅ 2026-07-24 — name comes directly on each HUC layer
- [ ] Update acquisition script if needed — deferred; extent/clipping logic depends on visualization-stage decisions, not built yet

### 2026-07-24 findings — WBD confirmed, NHDPlus's replacement works cleanly

**Source:** USGS/NRCS Watershed Boundary Dataset, served live at `https://hydro.nationalmap.gov/arcgis/rest/services/wbd/MapServer` (no auth). One MapServer, one layer per HUC digit-level:

| Layer ID | Level |
|---|---|
| 1 | 2-digit (Region) |
| 2 | 4-digit (Subregion) |
| 3 | 6-digit (Basin) — **HUC06, target for regional context** |
| 4 | 8-digit (Subbasin) |
| 5 | 10-digit (Watershed) |
| 6 | 12-digit (Subwatershed) — **HUC12, target for parcel-level** |
| 7 | 14-digit |
| 8 | 16-digit |

Standard ArcGIS REST point-intersection query against each layer (`geometryType=esriGeometryPoint`, `spatialRel=esriSpatialRelIntersects`) returns the HUC code and name directly — no separate hierarchy lookup needed, each level is queryable independently at the same point.

**Test case (7 Hill St):** HUC06 = "Neuse" (030202) — correct, Raleigh is in the Neuse River basin. HUC12 = "Walnut Creek" (030202011101) — correct, Walnut Creek is the actual local stream running through Raleigh. Both values checked against known real geography, not just "the API responded."

**Scope note:** only point-intersection was tested (confirms the source exists and is retrievable). Actual extent to acquire/render (just the intersecting polygon vs. a buffered region vs. neighboring HUCs for context) is a visualization-stage decision per Peter, not decided here.

---

## Ecoregions (EPA Level III)

### Research Questions
- [ ] What is the best data source for EPA Level III ecoregions?
- [ ] How to get all ecoregions for a state (for state inset map)?
- [ ] How to identify which ecoregion a parcel is in?
- [ ] Is there an API or do we need to download shapefiles?
- [ ] What is the file size/coverage area?

### Data Sources to Investigate
- EPA Ecoregions (official source)
- USGS or other federal sources
- State-specific sources

### Implementation Notes
- Current implementation is not fully implemented
- May require manual download or direct API calls

### Status
**Current**: Not implemented
**Target**: All Level III ecoregions for state, with parcel's ecoregion emphasized
**Action Items**:
- [x] Research EPA ecoregion data sources ✅ 2026-07-24
- [x] Test data acquisition method ✅ 2026-07-24
- [ ] Implement acquisition function — deferred; extent logic (state-wide inset vs. local only) is a visualization-stage decision, not built yet

### 2026-07-24 findings — confirmed, plus one field that isn't trustworthy

**Source:** EPA ArcGIS REST, `https://gispub.epa.gov/arcgis/rest/services/ORD/USEPA_Ecoregions_Level_III_and_IV/MapServer` (no auth). Layer 11 = Level III Ecoregion Polygons, layer 7 = Level IV Ecoregion Polygons. Same point-intersection query pattern as watershed/parcels.

**Test case (7 Hill St):** Level III = "Piedmont" (code 45), Level IV = "Northern Outer Piedmont" (45f), Level II = "Southeastern USA Plains", Level I = "Eastern Temperate Forests" — all correct for this location.

**Data quality catch:** the same Level III response includes a `STATE_NAME` field that returned **"Alabama"** for a Raleigh, NC point. Wrong, and not a fluke of this one query — ecoregions cross state boundaries, so a single polygon feature's `STATE_NAME` attribute is likely just a leftover/summary label from whichever state that polygon record originated in, not a real per-point spatial answer. **Do not use this field for state attribution.** State is already reliably available from the parcel data (`cntyname`/state via NC1Map_Parcels).

**Scope note:** only point-intersection tested, matching the watershed source above — confirms retrievability, not final extent.

---

## Soils (SSURGO Properties)

### Research Questions
- [ ] What soil properties are available from SSURGO/soilDB?
- [ ] How to extract infiltration rates from SSURGO?
- [ ] How to extract run-off coefficients from SSURGO?
- [ ] Is water balance data available?
- [ ] What other properties might be useful for analysis?

### Data Sources to Investigate
- NRCS SSURGO (current source via `soilDB`)
- `FedData` package (current implementation)
- `soilDB` package for property extraction

### Implementation Notes
- Current implementation uses `FedData` to get SSURGO spatial data
- Need to use `soilDB` to extract properties
- Properties needed: infiltration rates, run-off coefficients, water balance (if available)

### Status
**Current**: SSURGO spatial data acquired, properties not extracted
**Target**: Table with soil series/types and properties (infiltration rates, run-off coefficients)
**Action Items**:
- [ ] Research available SSURGO properties
- [ ] Test property extraction using `soilDB`
- [ ] Document which properties are available
- [ ] Implement property extraction function

---

## Flood Zones (FEMA)

### Research Questions
- [ ] What is the correct FEMA API endpoint?
- [ ] What layer number should we use? (tried 0, 28)
- [ ] How to handle 404 responses (not in flood zone)?
- [ ] What flood zone data is available? (100-year, 500-year, etc.)
- [ ] Are there alternative sources if FEMA API is unreliable?

### Data Sources to Investigate
- FEMA National Flood Hazard Layer (current source)
- FEMA REST API
- State-specific flood data

### Implementation Notes
- Current implementation uses FEMA ArcGIS REST service
- Issue: 404 errors (may mean "not in flood zone" or API issue)
- Tried layer 0 and 28, geometryType changes

### Status
**Current**: FEMA ArcGIS REST API (unreliable, 404 errors)
**Target**: Flood zone data if parcel is in flood zone, gracefully handle if not
**Action Items**:
- [x] Verify correct FEMA API endpoint and parameters ✅ 2026-07-24
- [x] Test with known flood zone locations ✅ 2026-07-24
- [x] Document 404 handling (not in flood zone vs API error) ✅ 2026-07-24 — the premise was wrong, see below
- [ ] Research alternative sources if needed — not needed, this source works

### 2026-07-24 findings — the old "404 = not in flood zone" assumption was wrong

**Endpoint confirmed live:** `https://hazards.fema.gov/arcgis/rest/services/public/NFHL/MapServer/28` (Flood Hazard Zones — layer 28 was already the right guess in the old notes; something else was wrong, likely query parameters or geometryType). No auth.

**The real design point, and this changes the check-first logic:** NFHL's coverage is comprehensive. A point-intersection query almost always returns a real feature — including "Zone X" (minimal hazard) areas — so **"did a feature come back" is not the check.** The actual boolean is the `SFHA_TF` field (Special Flood Hazard Area, `"T"`/`"F"`). A genuinely empty response means something different again: no flood study covers this location at all — that's an "unknown," not a safe "not in a flood zone," and should be surfaced as such rather than silently treated as a negative.

**Both cases validated with real data:**
- 7 Hill St (test parcel): `FLD_ZONE: "X"`, `ZONE_SUBTY: "AREA OF MINIMAL FLOOD HAZARD"`, `SFHA_TF: "F"` — a real feature, correctly not a hazard area.
- A location ~5mi away near Raleigh: `FLD_ZONE: "AE"`, `SFHA_TF: "T"` — a real 100-year floodplain designation, confirming the field semantics work both directions, not just the negative case that happened to match our test parcel.

**`R/acquisition/flood.R`** implements exactly the check-first-then-retrieve pattern: check `SFHA_TF` first; if true, return zone code, subtype, and base flood elevation (watch for `-9999` as FEMA's null sentinel, converted to `NA`); if false, return the zone code for reference without further detail; if no feature at all, return `status: "unstudied"` rather than assuming safe. Validated against the test parcel.

### 2026-07-24 correction — "Zone X" is not one risk picture; don't skip geometry on the top-level code alone

Peter's framing: "not in a flood zone" is pre-climate-change language, and FEMA's own "minimal hazard" designation should be reported as "not likely," not a flat safe/unsafe binary. His assumption was that Zone X shouldn't need geometry retrieval — checked this against the real distinct `(FLD_ZONE, ZONE_SUBTY, SFHA_TF)` combinations occurring in NC (not assumed), and it only holds for one specific subtype:

**Complete list — all 11 distinct `ZONE_SUBTY` values occurring under `FLD_ZONE='X'` in NC** (re-verified directly, not grouped for presentation):

```
0.2 PCT ANNUAL CHANCE FLOOD HAZARD
1 PCT CONTAINED IN STRUCTURE, COMMUNITY ENCROACHMENT
1 PCT CONTAINED IN STRUCTURE, FLOODWAY
1 PCT FUTURE CONDITIONS
1 PCT FUTURE CONDITIONS CONTAINED IN STRUCTURE
1 PCT FUTURE CONDITIONS, COMMUNITY ENCROACHMENT
1 PCT FUTURE CONDITIONS, FLOODWAY
1 PCT FUTURE IN STRUCTURE, COMMUNITY ENCROACHMENT
1 PCT FUTURE IN STRUCTURE, FLOODWAY
AREA OF MINIMAL FLOOD HAZARD
AREA WITH REDUCED FLOOD RISK DUE TO LEVEE
```

Only **AREA OF MINIMAL FLOOD HAZARD** is a true negative. Everything else is real risk information (500-year floodplain, levee-dependent, engineered-containment, or FEMA's own forward-looking "future conditions" floodplain) filed under the same top-level "X" code.

**No bare "1 PCT ANNUAL CHANCE FLOOD HAZARD" appears under X, and that's expected, not a gap.** A plain, current, effective 100-year floodplain isn't an X-zone subtype at all — it's a different top-level `FLD_ZONE` (`AE` or `A`) with `ZONE_SUBTY = NULL`. The "1 PCT..." strings that do appear under X are only the special-cased ones (future-conditions projection, or currently engineered-contained); the baseline 1% designation lives under AE/A, not as an X subtype.

**All top-level `FLD_ZONE` codes occurring in NC:** `A, AE, AH, AO, OPEN WATER, VE, X` — no `D` (undetermined/unstudied) found, no `AR`/`A99`. Scoped to NC (`DFIRM_ID LIKE '37%'`), matching the product's current geography — not a claim about the full national FEMA taxonomy.

Checking `FLD_ZONE == "X"` alone would have silently flattened all of these into "safe." `check_flood_zone()` now checks `ZONE_SUBTY` against a `MINIMAL_HAZARD_SUBTYPES` list (currently just the one confirmed true-negative subtype) and returns `needs_geometry` accordingly. Validated on a real, confirmed-interior point in a 500-year floodplain near the test parcel: `in_special_flood_hazard_area: FALSE` (same as the test parcel) but `needs_geometry: TRUE` — the case the fix exists for.

### For the visualization planning session

Flood risk will be a variable in the property overview. Peter's expectation: most properties will fall in the true minimal-hazard subtype and won't need geometry rendered at all — just the plain-language "not likely" framing. The other ten subtypes need their own handling (whether that's rendering geometry, what language each one gets, how "reduced risk due to levee" or "future conditions" get communicated without either alarming or falsely reassuring a homeowner) — not decided here, flagged for that session specifically.

---

## OpenStreetMap (Base Maps)

### Research Questions
- [ ] What is the best way to get OpenStreetMap data for base maps?
- [ ] How to style OSM data to match document style?
- [ ] What OSM features are needed? (roads, city features, landmarks)
- [ ] Should we use `osmdata` package or direct API calls?
- [ ] How to handle large area requests?

### Data Sources to Investigate
- OpenStreetMap Overpass API (via `osmdata` package)
- OpenStreetMap Nominatim API (for geocoding)
- Other OSM data sources

### Implementation Notes
- Not yet implemented
- Need to acquire OSM data for city/regional context maps
- Need to be able to style for document consistency

### Status
**Current**: Not implemented
**Target**: Styled OSM base map for regional orientation section
**Action Items**:
- [x] Research OSM data acquisition methods ✅ 2026-07-24
- [x] Test `osmdata`/direct API access ✅ 2026-07-24 — tested direct Overpass calls, not the R package specifically
- [ ] Research styling options — deferred to visualization stage
- [ ] Implement acquisition function — deferred; extent/styling decisions not made yet

### 2026-07-24 findings — confirmed on two levels: raw feature data and pre-rendered tiles

**This is the one case where OSM is the right call, not the wrong one.** Parcels needed authoritative cadastral boundaries (OSM isn't built for that — see the Parcel section above). Base maps need roads, place names, and general context, which is exactly OSM's strength.

**Two ways to get it, both confirmed live:**
1. **Raw feature data** via Overpass API (`overpass-api.de/api/interpreter`), no auth. Standard Overpass QL query by bounding box. Test query for roads near 7 Hill St returned real, correct streets (Poole Road, Sunnybrook Road, South Wilmington Street).
2. **Pre-rendered map tiles** via the standard OSM tile server (`tile.openstreetmap.org/{z}/{x}/{y}.png`), standard slippy-map tile math, no auth (identify with a User-Agent per their usage policy — this isn't for high-volume production use, worth a real tile-serving/caching plan before that). A 3×3 tile grid centered on the parcel rendered correctly: real streets, parks, schools, and place names for the actual neighborhood around 7 Hill St.

Pre-rendered tiles are the faster path to a usable regional-context image if OSM's default cartographic style is acceptable as-is; raw Overpass data is the path if the report needs custom styling (matching KED's visual identity) rather than the standard OSM look. Which one (or both) gets used is a visualization-stage decision, not resolved here.

### Open discussion for the visualization stage: base map styling, all scales

**Peter's stated preference: grayscale.** The base map's job is orientation, not navigation — it answers "where is this parcel in its surroundings," not "how do I drive there." Every default OSM style (the standard tile rendering shown above included) is built for the opposite job: turn-by-turn navigation, which means it's color-heavy by design (road-class colors, land-use fills, POI icons). That's exactly the wrong visual weight for a base layer that's supposed to sit quietly behind the actual data — parcel boundary, slope, soils, whatever the section is illustrating. Color-heavy base map competes with color-coded data on top of it; the data gets lost in the noise.

This needs to be resolved for every scale the report uses a base map at (state/ecoregion inset, watershed/neighborhood context, parcel-and-immediate-surroundings), not just one. Not solving it now — flagging it so it's a deliberate visualization-stage decision rather than something that defaults to "whatever the tile server gives you" by accident. Worth having in view when that conversation happens, not researched here: self-styled grayscale rendering of raw Overpass vector data (full control, matches our existing R-based pipeline), versus an existing grayscale/minimal tile provider (e.g., CartoDB Positron or similar "light"/monochrome basemap styles) as a faster but less controllable starting point.

---

## Canopy Height (LiDAR) — and Building Footprints (new, not in original PRD)

Not in the original PRD, but relevant to the sun/shade/wind illustration goal in `WORKFLOW_SPEC.md` — a 2-story building casts a different shadow than a 1-story one, and canopy height/extent matters for shade and wind behavior.

### 2026-07-24: reconsidered the approach mid-session — worth recording why

First attempt was deriving real height from raw LiDAR point clouds (Peter provided a sample `.las` file for the test parcel, classified into building/vegetation returns with ground removed). **Decided against this for v1.** The reasoning: every other source in this pipeline (parcel, DEM, soils, PRISM, wind, flood) is the same shape of work — retrieve an existing, authoritative, already-computed product and cite it. Point-cloud classification/normalization would have been us performing primary geospatial analysis ourselves, a different and bigger claim of correctness than citing a source, and it would have needed login-gated data access and new processing tooling (`lidR`) for a single data point. The PRD already has a simpler answer: structure height is a field-input variable, captured via practitioner site visit (phone LiDAR scan is one way to do that) — not something public data needs to supply. Point cloud processing stays a later step, not v1 acquisition.

**Revised approach: 2D geometry (footprint/extent) from an authoritative existing source, paired with a placeholder height that field observation can adjust.** Same shape as everything else in this pipeline — acquire what's real and already computed (footprint/extent), don't fabricate precision (height) the data doesn't actually give us.

### Building Footprints

**Source:** NC's own per-county building footprint polygons, `https://sdd.nc.gov/staticdownloads/listbuildingfootprints/2020-2022` (catalog API) → per-county `.zip` containing an Esri File Geodatabase, readable via GDAL's OpenFileGDB driver (no proprietary driver needed). Confirmed exact match against the test parcel via `PID` == parcel's `parno`.

**A field name looked promising and turned out not to be what it seemed — worth flagging as a caught mistake, not a clean win.** The schema (`OCCUP_TYPE`, `FLD_ZONE`, `STATIC_BFE`, `WIND_ZONE`, `FFE`, `NUM_STORY`, `LIDAR_LAG`, `LIDAR_HAG`...) is FEMA's Hazus building-inventory model, built for hazard/risk modeling. `LIDAR_HAG` looked like it might be real LiDAR-derived building height. Checked the actual values instead of assuming: `LIDAR_LAG` (315.3ft) and `LIDAR_HAG` (316.7-317.4ft) are only ~1.4-2.1ft apart — far too close together to be a building height. These are **Lowest/Highest Adjacent Grade**, standard Hazus terms for *ground* elevation around a building's base (used for flood-depth-above-grade calculations), not building height. `RISE` — the field that might have held real height — was `NA` on both buildings checked. `NUM_STORY` values (6010) are Hazus-coded, not literal story counts, and weren't decoded (no lookup table on hand, not needed for the footprint-only approach). **Conclusion: this source gives real, confirmed footprint geometry — genuinely useful — but not reliable building height.** That's not a gap in this approach; it's confirmation that the placeholder-height plan is the right one, not a shortcut around data that was actually available.

`R/acquisition/building_footprint.R`: given a parcel and county, downloads (and caches) the county's footprint file, spatially filters to the parcel's buffered area, and attaches a configurable `assumed_height_ft` (default 30ft). Validated: 2 buildings found near the test parcel (the matched one at 1,237 sq ft footprint, plausible against its recorded 1,668 heated sq ft).

### Land Cover / Canopy Extent

**Source:** NLCD Tree Canopy Cover (USFS), confirmed live at `https://imagery.geoplatform.gov/iipp/rest/services/Vegetation/USFS_EDW_NLCD_TCC_CONUS/ImageServer` (no auth; the older `apps.fs.usda.gov` endpoint has been migrated, returns a clear redirect message rather than a silent failure). 30m resolution, percent canopy cover per pixel (0-100), current through 2024.

**Real limitation worth being upfront about: 30m native resolution is coarse relative to a residential parcel.** A typical quarter-acre lot spans only a handful of pixels total — this is a coarse "how much canopy roughly here" read, not a tree-by-tree map. Same resolution-matching discipline as DEM applies (compute pixel size from the bbox, never oversample) — got this right from the start this time, no repeat of the DEM artifact.

**Test case (7 Hill St, 100ft buffer):** real values (16-55% canopy cover across a 4×3 pixel grid), genuine local variation, plausible for a lot with mixed tree cover.

`R/acquisition/canopy.R`: given a parcel, retrieves the raw percent-canopy raster (kept, not discarded — same "raw values in retrieval" principle as flood zones), thresholds it to a "has canopy" extent polygon at a configurable `threshold_pct` (default 0 — any measurable canopy, not a density cutoff), and attaches a configurable `assumed_height_ft` (default 55ft, the midpoint of the 50-60ft range Peter specified — adjustable to anything above the 30ft building-height placeholder for test runs).

### NC OneMap Landcover — checked, stale, not usable

NC OneMap does have `NC1Map_Landcover` (Feature and MapServer, plus a raster variant) — but it's dated **1996**. Thirty years old, from a one-time EarthSat-contracted statewide mapping project. Not usable for a current assessment. Ruled out, not pursued further.

---

## Research Workflow

1. **Prioritize**: Which data sources are blocking progress?
2. **Research**: Document findings for each source
3. **Test**: Try different approaches/methods
4. **Document**: Update this document with findings
5. **Implement**: Update acquisition scripts based on research
6. **Verify**: Test with real parcel data

## Notes

- Research should be done independently by user
- Document findings in this document
- Update implementation scripts after research is complete
- Test with real North Carolina parcel data

