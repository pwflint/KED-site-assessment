# Next Development Steps

**Current Priority**: Data Acquisition Implementation  
**Last Updated**: 2025-12-03

## Immediate Next Steps

### 1. Data Acquisition (`R/scripts/1-dataAcquisition.R`)

**Goal**: Implement automated API-based data retrieval for all required data sources.

**Tasks**:
- [ ] Implement DEM acquisition from USGS 3DEP API
  - Use `elevatr` or `FedData` package
  - Support multiple resolutions (1m, 3m, 10m)
  - Cache downloaded data
  
- [ ] Implement soil data acquisition from NRCS SSURGO API
  - Use `FedData::get_ssurgo()` or `soilDB` package
  - Extract required attributes (texture, drainage, hydrologic group)
  
- [ ] Implement climate data acquisition from PRISM API
  - Use `prism` package
  - Get monthly/annual normals (temperature, precipitation)
  
- [ ] Implement wind data acquisition from NOAA API
  - Use `rnoaa` package
  - Get direction, speed, frequency by season
  
- [ ] Implement watershed data acquisition from NHDPlus API
  - Use `nhdplusTools` or `FedData`
  - Get watershed boundaries and streams
  
- [ ] Implement ecoregion data acquisition
  - Use `FedData` or direct download
  - Get EPA Level III/IV ecoregions
  
- [ ] Implement flood zone data acquisition (FEMA)
  - Check for FEMA API or use `FedData` if available
  - Fallback to manual download instructions
  
- [ ] Implement canopy height data acquisition (if available)
  - Check USGS 3DEP or NASA GEDI APIs
  - Optional feature
  
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

## Development Order

1. **Data Acquisition** (Current) - Get all data sources working
2. **Data Processing** - Process data into tidy formats
3. **Section Generation** (3-11) - Build visualizations
4. **Report Assembly** (99) - Master script and Quarto template
5. **Shiny Integration** (Future) - User interface

## Testing Strategy

- **Comprehensive Test First**: Run `source("R/utils/testPackageLoading.R")` before starting
- **Component Testing**: Test packages in context as we build each component
- **End-to-End Testing**: Test full workflow with sample site after each major component

## Reference Documents

- **Architecture**: `docs/planning/PLANNING_SiteAssessment.md`
- **Troubleshooting**: `docs/TROUBLESHOOTING.md`
- **Testing**: `docs/TESTING_STRATEGY.md`
- **Development Rules**: `docs/DEVELOPMENT_RULES.md`

