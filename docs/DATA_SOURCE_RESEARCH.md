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

- [ ] DEM (1m resolution)
- [ ] Climate (PRISM)
- [ ] Wind (NOAA)
- [ ] Watershed (HUC 06/12)
- [ ] Ecoregions (EPA Level III)
- [ ] Soils (SSURGO properties)
- [ ] Flood Zones (FEMA)
- [ ] OpenStreetMap (base maps)
- [ ] Canopy Height (LiDAR)

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
- [ ] Test alternative data sources
- [ ] Update acquisition script if needed

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
- [ ] Debug PRISM data loading issue
- [ ] Test alternative methods for extracting PRISM data
- [ ] Research NOAA station data as alternative/complement

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

