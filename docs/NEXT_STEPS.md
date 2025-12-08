# Next Development Steps

**Current Priority**: Data Source Research & Implementation  
**Last Updated**: 2025-12-05

## Immediate Next Steps

### 1. Data Source Research ⚠️ PRIORITY

**Goal**: Investigate data sources, API endpoints, data availability, and implementation details for all required data sources.

**Status**: Planning session completed - ready to research data sources independently.

**Planning Document**: See `docs/DATA_ACQUISITION_PLANNING.md` (completed)

**Key Decisions from Planning Session**:
- **Acquisition Strategy**: Option A - By Data Type
  - `1-spatialData.R` - DEM (1m), soils, watersheds (HUC 06/12), flood zones
  - `2-climateData.R` - Climate (PRISM), wind (NOAA)
  - `3-contextData.R` - Ecoregions (EPA Level III), OpenStreetMap base maps
- **Processing Strategy**: Option C - By Section (process data as needed for each report section)
- **Visualization Strategy**: Documented for all 6 sections (see planning document)
- **Units**: Use miles and feet in document (can work in metric for raw data, translate to imperial on front end)

**Research Tasks** (see `docs/DATA_SOURCE_RESEARCH.md`):
- [ ] DEM (1m resolution) - locate appropriate data source
- [ ] Climate (PRISM) - fix data loading issues
- [ ] Wind (NOAA) - verify API endpoint and parameters
- [ ] Watershed (HUC 06/12) - research WBD as alternative to NHDPlus
- [ ] Ecoregions (EPA Level III) - implement data acquisition
- [ ] Soils (SSURGO) - research available properties (infiltration rates, run-off coefficients)
- [ ] Flood Zones (FEMA) - verify API endpoint and parameters
- [ ] OpenStreetMap - research data acquisition for base maps

**Next Step**: Complete data source research, then implement findings into data acquisition scripts

---

### 2. Data Acquisition Implementation (NEXT - after research)

**Goal**: Implement automated API-based data retrieval based on research findings.

**Goal**: Implement automated API-based data retrieval based on planning session decisions.

**Tasks**:
- [ ] Implement DEM acquisition (1m resolution)
  - Locate appropriate data source (research needed)
  - Acquire all tiles that intersect parcel boundary
  - Clip to parcel boundary + small buffer
  - Cache downloaded data
  
- [ ] Implement soil data acquisition from NRCS SSURGO API
  - Use `FedData::get_ssurgo()` or `soilDB` package
  - Extract required attributes (texture, drainage, hydrologic group)
  
- [ ] Implement climate data acquisition from PRISM API
  - Fix data loading issues (research needed)
  - Get seasonal normals (Spring, Summer, Fall, Winter) for temperature and precipitation
  - Extract point values or use regional averages
  
- [ ] Implement wind data acquisition from NOAA API
  - Verify API endpoint and parameters (research needed)
  - Get wind rose data from nearest station
  - Seasonal averages for wind direction and speed
  
- [ ] Implement watershed data acquisition (HUC 06/12)
  - Research WBD as alternative to NHDPlus (research needed)
  - Get HUC 06 for regional context, HUC 12 for parcels
  - Extract watershed names for hierarchy (HUC-12 → local creek → HUC-06)
  
- [ ] Implement ecoregion data acquisition (EPA Level III)
  - Research data source and acquisition method (research needed)
  - Get all ecoregions for state (for state inset map)
  - Identify parcel's ecoregion
  
- [ ] Implement flood zone data acquisition (FEMA)
  - Verify API endpoint and parameters (research needed)
  - Handle 404 responses gracefully (not in flood zone)
  
- [ ] Implement OpenStreetMap base map acquisition
  - Research data acquisition method (research needed)
  - Get major roads, creeks, and landmarks (no building footprints)
  - Support styling to match document

- [ ] Implement canopy height data acquisition (optional - deferred)
  - Check USGS 3DEP or NASA GEDI APIs
  - Low priority for initial implementation
  
- [ ] Add comprehensive error handling
- [ ] Add data validation
- [ ] Test with sample site

**Key Functions to Use**:
- `R/functions/apiHelpers.R` - `fetch_with_cache()`, `api_request()`
- `R/functions/dataHelpers.R` - `load_site_metadata()`, `create_site_boundary()`

**Testing**:
- Test with a known site location
- Verify all data sources are accessible
- Check caching works correctly
- Validate data formats

### 2. Data Processing (`R/scripts/2-dataProcessing.R`)

**Goal**: Process raw data into tidy, analysis-ready formats.

**Tasks**:
- [ ] Implement site boundary processing from YAML metadata
- [ ] Implement spatial data clipping to site extent + buffer
- [ ] Implement DEM processing (slope, aspect, hillshade)
- [ ] Implement flow accumulation calculations
- [ ] Implement climate data aggregation to site location
- [ ] Implement soil data processing to tidy format
- [ ] Implement wind flow field calculations (combine wind + structures)
- [ ] Implement canopy height processing (if data available)
- [ ] Add data validation checks
- [ ] Test data processing pipeline end-to-end

**Key Functions to Use**:
- `R/functions/dataHelpers.R` - `clip_to_site()`, `raster_to_tibble()`, `save_tidy_data()`

## Development Order (REVISED)

1. ✅ **Data Acquisition Planning** (COMPLETED 2025-12-05) - Workflow redesigned, visualization strategy documented
2. **Data Source Research** (Current Priority) - Investigate data sources independently
3. **Data Acquisition Implementation** - Implement findings from research into acquisition scripts
4. **Data Processing** - Process data into tidy formats (by section)
5. **Visualization Development** - Create appropriate visualizations for each section
6. **Section Generation** - Build report sections
7. **Report Assembly** - Master script and Quarto template
8. **Shiny Integration** (Future) - User interface

## Testing Strategy

- **Comprehensive Test First**: Run `source("R/utils/testPackageLoading.R")` before starting
- **Component Testing**: Test packages in context as we build each component
- **End-to-End Testing**: Test full workflow with sample site after each major component

## Reference Documents

- **Planning**: `docs/DATA_ACQUISITION_PLANNING.md` (completed planning session)
- **Data Source Research**: `docs/DATA_SOURCE_RESEARCH.md` (independent research tasks)
- **Architecture**: `docs/planning/PLANNING_SiteAssessment.md`
- **Testing**: `docs/TESTING_NOTES.md`
- **Development Rules**: `docs/DEVELOPMENT_RULES.md`

