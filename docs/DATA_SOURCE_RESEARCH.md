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
- [ ] Wind (NOAA)
- [ ] Watershed (HUC 06/12)
- [ ] Ecoregions (EPA Level III)
- [ ] Soils (SSURGO properties)
- [ ] Flood Zones (FEMA)
- [ ] OpenStreetMap (base maps)
- [ ] Canopy Height (LiDAR)

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
- [ ] Verify correct API endpoint and parameters
- [ ] Research how to find nearest station IDs
- [ ] Test wind rose generation from station data
- [ ] Document seasonal wind patterns needed

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
- [ ] Research WBD as alternative to NHDPlus
- [ ] Test HUC boundary acquisition from WBD
- [ ] Research how to get watershed names/hierarchy
- [ ] Update acquisition script if needed

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
- [ ] Research EPA ecoregion data sources
- [ ] Test data acquisition method
- [ ] Implement acquisition function

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
- [ ] Verify correct FEMA API endpoint and parameters
- [ ] Test with known flood zone locations
- [ ] Document 404 handling (not in flood zone vs API error)
- [ ] Research alternative sources if needed

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
- [ ] Research OSM data acquisition methods
- [ ] Test `osmdata` package
- [ ] Research styling options
- [ ] Implement acquisition function

---

## Canopy Height (LiDAR)

### Research Questions
- [ ] Is LiDAR canopy height data available for all locations?
- [ ] What is the best data source? (USGS 3DEP, state-specific)
- [ ] How to extract canopy height from LiDAR?
- [ ] What is the resolution/coverage?
- [ ] Is this data necessary for initial implementation?

### Data Sources to Investigate
- USGS 3DEP LiDAR
- State-specific LiDAR programs
- Other canopy height datasets

### Implementation Notes
- Current implementation is placeholder
- May be optional for initial implementation
- Would be used for `rayshader` 3D visualization

### Status
**Current**: Not implemented (placeholder)
**Target**: Canopy height data for 3D visualization (optional)
**Action Items**:
- [ ] Research LiDAR availability for NC
- [ ] Determine if this is priority for initial implementation
- [ ] Test data acquisition if proceeding
- [ ] Implement if needed

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

