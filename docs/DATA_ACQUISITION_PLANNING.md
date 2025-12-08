# Data Acquisition Planning Session

**Purpose**: Review data sources, understand data usage in each report section, and redesign acquisition workflow

**Date**: Next session  
**Status**: Planning needed

---

## Issues Encountered Today

### 1. DEM Resolution & Scale
- **Issue**: DEM showing as 1x1 pixel for small parcels
- **Cause**: Resolution too coarse (10m) for small parcels, clipping too aggressive
- **Learning**: Need different approaches for:
  - Parcel-level analysis (high resolution, clipped to boundary)
  - Regional context (lower resolution, larger extent)

### 2. Data Scale Mismatch
- **Issue**: Some data sources return watershed/regional scale, not parcel scale
- **Examples**: 
  - DEM from elevatr may be too large
  - NHDPlus may not have data for very small parcels
- **Learning**: Need to distinguish between:
  - **Parcel-level data**: DEM, soils (clipped to parcel)
  - **Regional data**: Climate, wind (point/area data, not clipped)
  - **Context data**: Watersheds, ecoregions (for regional maps, not parcel analysis)

### 3. Visualization Needs
- **Issue**: Plots lack context and legends
- **Learning**: Need different visualization strategies:
  - **Parcel maps**: High detail, parcel boundary, legend, scale bar
  - **Regional maps**: Lower detail, showing parcel in context
  - **Data tables**: Climate/soil properties (not spatial plots)

### 4. API Limitations
- **Issue**: Some APIs don't work well for small parcels or require different approaches
- **Examples**:
  - NOAA wind data needs station IDs, not bounding box
  - FEMA 404 may mean "no flood zone" (expected, not error)
  - NHDPlus may not intersect small parcels
- **Learning**: Need fallback strategies and better error handling

---

## Questions to Answer in Planning Session

### 1. Data Usage by Report Section

**Section 1: Regional Orientation and Context**
- **What data is needed?**
  - Base map: OpenStreetMap data (roads, city features) - **stylable to match document**
  - Parcel location (point/outline)
  - State-level inset map
  - EPA Level III Ecoregions: **All ecoregions for state**, with parcel's ecoregion emphasized
  - Note: NO climate summary needed - this is spatial orientation only
- **What scale/extent?**
  - Main map: City/regional context showing parcel relation to city center (extent TBD)
  - Inset map: State-level showing location within state with all Level III ecoregions
- **How is it visualized?**
  - Main map: Parcel in relation to city/landmarks (OpenStreetMap base, styled)
  - Inset: State map with all Level III ecoregions, parcel's ecoregion emphasized/highlighted

**Section 2: Topography & Landform**
- **What data is needed?**
  - DEM at **1m resolution** (need to locate appropriate data source)
  - Slope: Derived from DEM
  - Aspect: Derived from DEM
- **What scale/extent?**
  - Acquisition: Include all tiles that intersect parcel boundary (for accurate clipping)
  - Visualization: Parcel boundary only
- **How is it visualized?**
  - Parcel-only visualization
  - May use labels or simple lines outside parcel boundaries for context

**Section 3: Hydrology & Drainage**
- **What data is needed?**
  - Watershed boundaries:
    - **HUC 06** for regional context (cover sheet)
    - **HUC 12** for parcel-level
    - May need intermediate HUC levels (HUC 08, HUC 10) to show hierarchy (HUC-12 → local creek → HUC-06)
  - DEM-derived flow analysis:
    - Flow accumulation calculated from DEM at parcel level
    - Site contours extracted from DEM
    - Slope values for flow volume indication
  - NHDPlus: May be useful in analysis stage as baseline to compare against DEM-derived flow
- **What scale/extent?**
  - Regional: HUC 06 (cover sheet)
  - Parcel: HUC 12 + DEM analysis
- **How is it visualized?**
  - **Regional scale (cover sheet)**: Show parcel location within HUC-06 basin outline
    - If no stream on parcel: Indicate parcel's relationship to HUC-06 basin in regional context inset
  - **Site scale (parcel plot)**:
    - Extract site contours from DEM
    - Show arrows perpendicular to contour lines to indicate drainage direction
    - Use gradients and arrow size to indicate flow volume based on slope values
    - If no stream on parcel: Show general direction of drainage toward HUC-12 basin

**Section 4: Climate & Wind**
- **What data is needed?**
  - **Temperature**: Most refined averages available (nearest weather station or triangulated set of stations)
    - Purpose: Analyze runoff volumes and pan evaporation rates
  - **Precipitation**: Most refined averages available (nearest weather station or triangulated set of stations)
    - Purpose: Analyze runoff volumes and pan evaporation rates
  - **Wind**: Wind rose from nearest station to determine seasonal averages
    - Purpose: Generate flow-form map of property
    - Note: May need to decide on scenario to visualize for airflow diagram
  - Note: Point data may not be consistently available, so may need station data or interpolated
- **What scale/extent?**
  - Regional: Weather station data (nearest or triangulated)
  - Parcel: Applied to parcel for analysis
- **How is it visualized?**
  - **Wind flow**: Parcel with structures outlined + vector field showing wind/airflow around structures
  - **Precipitation/Temperature**: Simple tables displaying seasonal averages
  - **Microclimate analysis** (optional): Parcel with heat maps showing:
    - Air temperature
    - Aspect
    - Material and color
    - Canopy coverage
    - All informing thermal comfort in each season

**Section 5: Soils & Infiltration**
- **What data is needed?**
  - Soil series/type(s) and properties table
  - Most relevant properties:
    - Infiltration rates
    - Run-off coefficients
    - Water balance (if available from data source)
  - Note: Need to research what properties are available from SSURGO/soilDB
- **What scale/extent?**
  - Parcel-level: Soil types present on parcel
- **How is it visualized?**
  - **Table only**: Outline soil series/type(s) and their properties
  - **No spatial visualization** of soils on parcel

**Section 6: Vulnerabilities & Opportunities**
- **What data is needed?**
  - **Derived analysis** from previous sections (not separate data acquisition)
  - Examples:
    - Large tree in path of major wind flows → vulnerability for home
    - Very hot southwest corner → opportunity to plant shade tree
  - Flood zones: If 404 response (no data), property is not in flood zone → no vulnerability, no need to consider
- **What scale/extent?**
  - Parcel-level analysis using data already acquired/analyzed
- **How is it visualized?**
  - TBD - deferred for later development
- **Note**: Leave this section for development at a later stage once we have successful acquisition and visualization output for previous sections. This section will use datasets specific to the parcel that we generate from earlier analysis, so no missing data issues anticipated.

### 2. Data Acquisition Strategy

**Current Approach**: One script acquires all data sources
**Decision**: Split into logical groups

**For Acquisition: Option A - By Data Type**
- `1-spatialData.R` - DEM, soils, watersheds, flood zones (spatial, clipped)
- `2-climateData.R` - Climate, wind (point/regional, not clipped)
- `3-contextData.R` - Ecoregions, base maps (for regional context)

**For Processing: Option C - By Section**
- Process data as needed for each report section
- More modular workflow aligned with report structure
- Section-by-section processing for visualization

### 3. Visualization Strategy

**Section 1: Regional Orientation and Context**
- **Main map**: 
  - Extent: 10km radius from parcel (for visual context)
  - Base: OpenStreetMap with major roads, creeks, and landmarks (no building footprints)
  - Styled to match document
  - Parcel location indicated
- **Inset (state map)**:
  - State boundary
  - Level III ecoregion boundaries (colored, semi-transparent)
  - Major watershed basin boundary (HUC-06) layered on top of ecoregion polylines
  - Parcel location indicated on top of watershed boundary
- **Regional scale (cover sheet)**: Parcel location within HUC-06 basin outline
- **If no stream on parcel**: Show parcel's relationship to HUC-06 basin in regional context inset
- **Note**: Use miles and feet as standard dimensions in document. Can work in metric for raw data, translate to imperial on front end.

**Section 2: Topography & Landform**
- **DEM**: 1m resolution, parcel-only visualization
- **Contours**:
  - 1' intervals, labeled
  - Gray short dashed linetype
  - Emphasis every 5' (darker gray, larger lineweight)
  - High points and low points marked with cross and elevation label
- **Slope map**: Separate visualization, derived from DEM
- **Aspect map**: Separate visualization, derived from DEM
- **Context**: Nearby street names shown as labels/lines outside parcel boundaries
- **Orientation**: May include parameter to orient parcel so front-facing street is on bottom (not necessarily north-up)
- **Standard elements**: Parcel boundary, legend, scale bar, north arrow (if north-up orientation)

**Section 3: Hydrology & Drainage**
- **Site scale (parcel plot)**:
  - **Contours**: Same as Section 2 (1' intervals, emphasis every 5')
  - **Drainage arrows**: 
    - Perpendicular to contour lines indicating drainage direction
    - Arrow size related to interpolated run-off volume (slope is a variable)
    - Generally larger arrows for steeper slopes
    - Gradients and arrow size indicating flow volume
  - **Streams/drainage features**:
    - If stream or drainage basin on parcel: Illustrate with blue line or small polygon boundary
    - If no stream on parcel: Indicate general direction of drainage toward nearest local creek
    - Need to extract watershed names between HUC codes (HUC-12 → local creek → HUC-06) for labeling

**Section 4: Climate & Wind**
- **Wind flow**: 
  - Parcel with structures outlined + vector field showing wind/airflow around structures
  - Structures need: Footprints and approximate heights (heights input manually)
  - Separate visualization
- **Precipitation/Temperature**: Simple tables displaying seasonal averages
  - Seasons: Meteorological seasons (Spring, Summer, Fall, Winter) following conventional solstice-equinox markers
- **Microclimate analysis (optional)**: Parcel with heat maps showing air temperature, aspect, material/color, canopy coverage for thermal comfort in each season
  - Separate visualization from wind flow
  - May combine with wind flow in Section 6 (Vulnerabilities & Opportunities)

**Section 5: Soils & Infiltration**
- Table only: Outline soil series/type(s) and their properties (infiltration rates, run-off coefficients, water balance if available)
- No spatial visualization of soils on parcel

**Section 6: Vulnerabilities & Opportunities**
- TBD - deferred for later development

### 4. Data Source Research Needed

**DEM**:
- Is 3m/1m resolution available for all locations?
- Should we use different sources for different regions?
- How to handle resampling for visualization?

**Climate**:
- PRISM: Why is data structure empty after download?
- Should we extract point values or use regional averages?
- How to visualize monthly/annual patterns?

**Wind**:
- NOAA API: How to find nearest station IDs?
- Should we use historical data or current observations?
- How to create wind roses/flow fields?

**Watersheds**:
- What to do when NHDPlus has no data for small parcels?
- Should we derive watersheds from DEM instead?
- How to show regional watershed context?

**Soils**:
- How to extract and display soil properties?
- Should we create soil maps or just tables?
- What properties are most relevant for landscape design?

**Flood Zones**:
- How to handle "no flood zone" gracefully?
- Should 404 be treated as "not in flood zone"?
- How to visualize if data exists?

---

## Proposed Workflow Redesign

### Phase 1: Spatial Data Acquisition
**Script**: `1-spatialData.R`
- Acquire DEM (with appropriate resolution for parcel size)
- Clip to parcel boundary + small buffer
- Acquire soils (SSURGO)
- Clip to parcel boundary
- Acquire watershed data (if available)
- Acquire flood zones (if available)
- **Output**: Spatial data clipped to parcel scale

### Phase 2: Climate & Regional Data
**Script**: `2-climateRegionalData.R`
- Acquire climate data (PRISM) - point extraction or regional
- Acquire wind data (NOAA) - find station, get data
- Acquire ecoregion data (for context maps)
- **Output**: Tabular data and regional context layers

### Phase 3: Data Processing
**Script**: `3-dataProcessing.R` (existing, needs revision)
- Process DEM (slope, aspect, hillshade)
- Extract soil properties to tables
- Process climate data (summaries, seasonal patterns)
- Process wind data (seasonal summaries, wind roses)
- **Output**: Analysis-ready data structures

### Phase 4: Visualization
**Script**: `4-visualizations.R` (new)
- Create parcel-level maps (DEM, soils, topography)
- Create regional context maps (watershed, ecoregion)
- Create data visualizations (climate graphs, wind roses)
- **Output**: Figure files for report

---

## Research Tasks

1. **PRISM Data Loading** ⚠️ HIGH PRIORITY
   - Investigate why `prism_archive_subset()` returns empty
   - Files download successfully but structure is empty
   - Test alternative loading methods (`pd_stack()` directly on file paths?)
   - Verify file locations and formats
   - Check if files need to be unzipped or processed differently

2. **DEM Resolution Strategy** ⚠️ HIGH PRIORITY
   - Current: 1x1 pixel even with 3m resolution
   - Issue: Cached DEM is old version, or clipping too aggressive
   - Test: Clear cache and re-download
   - Research: Is 1m resolution available for all locations?
   - Consider: Different data sources for different regions?

3. **NOAA Wind Data**
   - Research how to find nearest weather station IDs
   - Test alternative API endpoints
   - Consider using `rnoaa` package functions if they work better
   - Current 400 error suggests API format issue

4. **Watershed Data**
   - Research alternative sources if NHDPlus fails
   - Test DEM-based watershed delineation
   - Determine when to use regional vs parcel-level data

5. **Soil Visualization**
   - Research best practices for soil map visualization
   - Determine which properties to highlight
   - Test soil property extraction from SSURGO
   - Current: Soils working well, just need visualization strategy

6. **Visualization Color Scales**
   - Fix: `viridis` option "terrain" doesn't exist (use "viridis", "plasma", "inferno", "magma", or "cividis")
   - Research: Appropriate color scales for elevation, slope, aspect
   - Consider: Custom color palettes for different data types

---

## Next Session Agenda

1. **Review Report Sections** (30 min)
   - Go through each section of Site Assessment Report
   - Identify what data is needed
   - Determine appropriate scales/extents

2. **Research Data Sources** (30 min)
   - Test PRISM data loading
   - Research NOAA station finding
   - Test DEM resolution options

3. **Design New Workflow** (30 min)
   - Decide on script organization
   - Define data structures
   - Plan visualization approach

4. **Revise Scripts** (remaining time)
   - Split acquisition into logical groups
   - Fix known issues
   - Add proper error handling

---

## Files to Review

- `Site Assessment Report.md` - Understand data needs per section
- `docs/planning/PLANNING_SiteAssessment.md` - Original planning
- `R/scripts/1-dataAcquisition.R` - Current implementation
- `R/functions/dataAcquisitionHelpers.R` - Individual functions
- Test outputs and error messages

---

## Key Decisions Needed

1. **Script Organization**: How to split data acquisition?
2. **Scale Strategy**: Parcel vs regional data handling
3. **Visualization Approach**: Maps vs tables vs graphs
4. **Error Handling**: How to handle missing data gracefully
5. **Data Caching**: What to cache, when to refresh

---

**Status**: Ready for planning session  
**Priority**: High - Foundation for all subsequent work

