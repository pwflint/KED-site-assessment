# Data Sources & API Authentication Guide

**Last Updated**: 2025-12-05  
**Primary Region**: North Carolina, USA

This document lists all data sources, their API endpoints, authentication requirements, and implementation notes.

---

## 1. Elevation & Topography

### USGS 3D Elevation Program (3DEP)

**Source**: USGS National Map  
**Format**: Digital Elevation Model (DEM)  
**Resolutions**: 1m, 3m, 10m, 30m  
**Coverage**: Nationwide (USA)

**API Access**:
- **Base URL**: `https://tnmaccess.nationalmap.gov/api/v1/products`
- **Documentation**: https://apps.nationalmap.gov/downloader/
- **Authentication**: **NO API KEY REQUIRED** (public access)
- **Rate Limits**: None specified, but be respectful

**R Packages**:
- `elevatr` - Simple wrapper for 3DEP API
- `FedData` - Comprehensive federal data access (includes 3DEP)
- Direct REST API via `httr`

**Implementation Notes**:
- Use `elevatr::get_elev_raster()` for simple access
- Or `FedData::get_3dep_dem()` for more control
- Direct API: Query product list, then download tiles

**North Carolina Coverage**: Full coverage available at multiple resolutions

---

## 2. Soils Data

### NRCS SSURGO (Soil Survey Geographic Database)

**Source**: USDA Natural Resources Conservation Service  
**Format**: Spatial polygons with attribute tables  
**Coverage**: Nationwide (USA)

**API Access**:
- **Base URL**: `https://sdmdataaccess.nrcs.usda.gov/Spatial/SDMNAD83Geographic.wfs`
- **Documentation**: https://www.nrcs.usda.gov/wps/portal/nrcs/detail/soils/survey/geo/?cid=nrcs142p2_053631
- **Authentication**: **NO API KEY REQUIRED** (public access)
- **Alternative**: Soil Data Access (SDA) REST API

**R Packages**:
- `FedData::get_ssurgo()` - Recommended (handles API calls)
- `soilDB` - Direct Soil Data Access API wrapper
- `aqp` - Soil profile analysis

**Implementation Notes**:
- `FedData::get_ssurgo()` requires bounding box or polygon
- Returns spatial data with comprehensive attribute tables
- Key attributes: texture, drainage, hydrologic group, permeability

**North Carolina Coverage**: Full SSURGO coverage available

---

## 3. Climate Data

### PRISM Climate Group

**Source**: Oregon State University PRISM Climate Group  
**Format**: Raster grids (monthly/annual normals)  
**Coverage**: Contiguous USA

**API Access**:
- **Base URL**: `http://services.nacse.org/prism/data`
- **Documentation**: https://prism.oregonstate.edu/
- **Authentication**: **NO API KEY REQUIRED** (public access)
- **Rate Limits**: None specified

**R Packages**:
- `prism` - Official PRISM R package (recommended)
- Direct REST API via `httr` (if needed)

**Implementation Notes**:
- Use `prism::get_prism_normals()` for climate normals
- Variables: temperature, precipitation, min/max temps
- Data period: 1991-2020 normals (or other periods)
- Returns raster files that need to be downloaded

**North Carolina Coverage**: Full coverage

**Setup**:
```r
# Set PRISM download directory
prism_set_dl_dir(here::here("data", "raw", "climate", "prism"))
```

---

## 4. Wind Data

### NOAA NCEI (National Centers for Environmental Information)

**Source**: NOAA National Centers for Environmental Information  
**Format**: Time series data (hourly/daily)  
**Coverage**: Global (USA stations)

**API Access**:
- **Base URL**: `https://www.ncei.noaa.gov/access/services/data/v1`
- **API Documentation**: https://www.ncei.noaa.gov/support/access-data-service-api-user-documentation
- **Authentication**: **NO API TOKEN REQUIRED** (public access)
- **Datasets**: `daily-summaries`, `global-marine`, `global-summary-of-the-year`, etc.

**R Packages**:
- Direct REST API via `httr` and `jsonlite` (recommended for new API)
- `rnoaa` - May still work for some functions, but new API is preferred

**Implementation Notes**:
- Use the new Data Service API endpoint
- Query by dataset, stations, dates, and data types
- Find nearest weather station to site coordinates using bounding box queries
- Get wind direction, speed, frequency by season
- Data types for wind: `WIND_DIR`, `WIND_SPEED`, `AWND` (average wind speed)

**North Carolina Stations**: Multiple stations available (ASHEVILLE, RALEIGH, etc.)

**Example API Call**:
```r
base_url <- "https://www.ncei.noaa.gov/access/services/data/v1"
params <- list(
  dataset = "daily-summaries",
  stations = "USC00457180",  # Station ID
  startDate = "2020-01-01",
  endDate = "2020-12-31",
  dataTypes = "WIND_DIR,WIND_SPEED,AWND",
  format = "json"
)
response <- httr::GET(base_url, query = params)
```

---

## 5. Watershed & Hydrology

### USGS NHDPlus (National Hydrography Dataset Plus)

**Source**: USGS  
**Format**: Vector (streams, waterbodies, watersheds)  
**Coverage**: Contiguous USA

**API Access**:
- **Base URL**: `https://hydro.nationalmap.gov/arcgis/rest/services/nhd/MapServer`
- **Documentation**: https://www.usgs.gov/national-hydrography/nhdplus-high-resolution
- **Authentication**: **NO API KEY REQUIRED** (public access)
- **Alternative**: NHDPlus High Resolution REST API

**R Packages**:
- `nhdplusTools` - NHDPlus data access and processing
- `FedData` - Alternative access method
- Direct REST API via `httr`

**Implementation Notes**:
- Use `nhdplusTools::get_nhdplus()` to get NHD data
- Can also use `FedData::get_ned()` for elevation-derived streams
- Watershed delineation: Use `whitebox` or `terra` with DEM

**North Carolina Coverage**: Full NHDPlus coverage

---

## 6. Ecoregions

### EPA Ecoregions

**Source**: US Environmental Protection Agency  
**Format**: Spatial polygons  
**Coverage**: USA (Levels I-IV)

**API Access**:
- **Base URL**: Direct download (no official REST API)
- **Download URL**: https://www.epa.gov/eco-research/ecoregion-download-files-state-region
- **Authentication**: **NO API KEY REQUIRED** (public download)
- **Alternative**: Use `FedData` package

**R Packages**:
- `FedData` - Can download ecoregion data
- Direct download via `httr` or manual download

**Implementation Notes**:
- EPA provides shapefiles for download (not true REST API)
- Use `FedData::get_ecoregion()` if available
- Or download shapefile and load with `sf::st_read()`
- Focus on Level III or IV ecoregions

**North Carolina Coverage**: Full coverage (Level III: Piedmont, Coastal Plain, Mountains)

---

## 7. Flood Zones

### FEMA Flood Map Service Center

**Source**: FEMA (Federal Emergency Management Agency)  
**Format**: Spatial polygons  
**Coverage**: USA (where flood maps exist)

**API Access**:
- **Base URL**: `https://hazards.fema.gov/gis/nfhl/rest/services/public/NFHL/MapServer`
- **Documentation**: https://www.fema.gov/flood-maps/national-flood-hazard-layer
- **Authentication**: **NO API KEY REQUIRED** (public access)
- **Alternative**: FEMA Flood Map Service Center (web interface)

**R Packages**:
- Direct REST API via `httr` (ArcGIS REST service)
- `arcgislayers` (optional, requires Rust)
- Manual download from FEMA website

**Implementation Notes**:
- FEMA provides ArcGIS REST service
- Query by location (lat/long) or bounding box
- Returns flood zone polygons (A, AE, X, etc.)
- May need to handle multiple map panels

**North Carolina Coverage**: Varies by county (coastal areas well covered)

---

## 8. Canopy Height / LiDAR

### USGS 3DEP LiDAR

**Source**: USGS 3D Elevation Program  
**Format**: Point clouds or rasterized canopy height models  
**Coverage**: Varies (not complete nationwide)

**API Access**:
- **Base URL**: Same as 3DEP DEM (`https://tnmaccess.nationalmap.gov/api/v1/products`)
- **Documentation**: https://www.usgs.gov/3d-elevation-program
- **Authentication**: **NO API KEY REQUIRED** (public access)

**R Packages**:
- `FedData` - May have LiDAR access
- Direct REST API via `httr`
- `lidR` - For processing point clouds (if needed)

**Implementation Notes**:
- LiDAR data availability varies by location
- Check 3DEP product catalog for available data
- May need to process point clouds to create canopy height models
- Optional feature - may not be available for all sites

**North Carolina Coverage**: Partial (urban areas and some rural areas)

---

## 9. Base Maps & Reference Data

### OpenStreetMap

**Source**: OpenStreetMap  
**Format**: Vector data  
**Coverage**: Global

**API Access**:
- **Base URL**: `https://overpass-api.de/api/interpreter`
- **Documentation**: https://wiki.openstreetmap.org/wiki/Overpass_API
- **Authentication**: **NO API KEY REQUIRED** (public access)
- **Rate Limits**: Be respectful (use public servers sparingly)

**R Packages**:
- `osmdata` - OSM data access
- Direct Overpass API via `httr`

**Implementation Notes**:
- Use for roads, buildings, water features
- Can extract building footprints for wind flow analysis
- Use `osmdata::opq()` to build queries

---

### Natural Earth

**Source**: Natural Earth  
**Format**: Vector/raster  
**Coverage**: Global

**R Packages**:
- `rnaturalearth` - Natural Earth data access

**Implementation Notes**:
- Use for base maps, country/state boundaries
- No API key required
- Data included in package

---

## Authentication Summary

### Required API Keys/Tokens

**NONE REQUIRED** - All data sources are publicly accessible without authentication!

### No Authentication Required

- ✅ USGS 3DEP (DEM & LiDAR)
- ✅ NRCS SSURGO (Soils)
- ✅ PRISM Climate
- ✅ **NOAA NCEI (Wind Data)** - New API is public, no token needed
- ✅ USGS NHDPlus (Watersheds)
- ✅ EPA Ecoregions
- ✅ FEMA Flood Zones
- ✅ OpenStreetMap
- ✅ Natural Earth

---

## Environment Variables Setup

**No environment variables required!** All data sources are publicly accessible.

If you need to store any configuration in the future, you can use a `.Renviron` file, but it's not currently needed.

---

## Rate Limiting & Best Practices

1. **Cache all downloads** - Use `R/functions/apiHelpers.R` caching functions
2. **Respect rate limits** - Add delays between requests if needed
3. **Use appropriate resolutions** - Don't download 1m DEM for large areas
4. **Check data availability** - Some data may not be available for all locations
5. **Handle errors gracefully** - Some APIs may be temporarily unavailable

---

## North Carolina Specific Notes

- **DEM**: Full 3DEP coverage available (1m, 3m, 10m)
- **Soils**: Complete SSURGO coverage
- **Climate**: Full PRISM coverage
- **Wind**: Multiple NOAA stations (ASHEVILLE, RALEIGH, CHARLOTTE, etc.)
- **Watersheds**: Full NHDPlus coverage
- **Ecoregions**: Level III includes: Piedmont, Coastal Plain, Blue Ridge Mountains
- **Flood Zones**: Varies by county (coastal areas well mapped)
- **Canopy Height**: Partial LiDAR coverage (check availability per site)

---

## Next Steps

1. ✅ No API registration needed - all sources are public!
2. Test each data source with sample North Carolina location
3. Implement data acquisition functions in `R/scripts/1-dataAcquisition.R`
4. Verify all API endpoints are accessible

