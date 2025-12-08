# API Setup Guide

**Quick reference for setting up API authentication**

---

## NOAA NCEI Data Service API

### New API System (2024+)

NOAA has migrated to a new Data Service API system. The new API:
- **Base URL**: `https://www.ncei.noaa.gov/access/services/data/v1`
- **Documentation**: https://www.ncei.noaa.gov/support/access-data-service-api-user-documentation
- **Authentication**: **NO API TOKEN REQUIRED** (public access)
- Uses dataset-based queries (e.g., `daily-summaries`, `global-marine`)

### API Usage

The new API uses HTTP GET requests with parameters:
- `dataset` - Select dataset (required)
- `stations` - Station identifiers (comma-separated)
- `startDate` / `endDate` - Date range (ISO 8601 format)
- `dataTypes` - Data types/variables (comma-separated)
- `bbox` - Bounding box (North,West,South,East)
- `format` - Output format (csv, json, pdf, netcdf)

### Example API Call

```r
# Example: Get daily summaries for a station
base_url <- "https://www.ncei.noaa.gov/access/services/data/v1"
params <- list(
  dataset = "daily-summaries",
  stations = "USC00457180",
  startDate = "2020-01-01",
  endDate = "2020-12-31",
  dataTypes = "WIND_DIR,WIND_SPEED",
  format = "json"
)

response <- httr::GET(base_url, query = params)
data <- jsonlite::fromJSON(httr::content(response, as = "text"))
```

### R Package Support

The `rnoaa` package may still work for some functions, but the new API can be accessed directly via `httr` and `jsonlite` packages (already included in our setup).

---

## No Authentication Required

These data sources don't require API keys:

- ✅ USGS 3DEP (DEM & LiDAR)
- ✅ NRCS SSURGO (Soils)
- ✅ PRISM Climate
- ✅ USGS NHDPlus (Watersheds)
- ✅ EPA Ecoregions
- ✅ FEMA Flood Zones
- ✅ OpenStreetMap

---

## Testing API Access

Test the new NOAA API with:

```r
# Test NOAA NCEI Data Service API
library(httr)
library(jsonlite)

base_url <- "https://www.ncei.noaa.gov/access/services/data/v1"

# Example: Get daily summaries for North Carolina
params <- list(
  dataset = "daily-summaries",
  bbox = "36.5,-84.5,33.5,-75.5",  # North Carolina bounding box
  startDate = "2023-01-01",
  endDate = "2023-01-31",
  dataTypes = "WIND_DIR,WIND_SPEED",
  format = "json",
  limit = 10  # Limit results for testing
)

response <- httr::GET(base_url, query = params)
if (httr::status_code(response) == 200) {
  data <- jsonlite::fromJSON(httr::content(response, as = "text"))
  print(paste("API working! Retrieved", nrow(data$results), "records"))
} else {
  print(paste("API error:", httr::status_code(response)))
}
```

---

## Troubleshooting

### API Not Responding

1. Check internet connection
2. Verify the API endpoint URL is correct
3. Check that dataset name is valid (see NOAA documentation)
4. Verify date format is ISO 8601 (YYYY-MM-DD)

### Rate Limiting

- NOAA API may have rate limits
- If you hit limits, wait a few minutes and try again
- Our caching system helps avoid repeated calls

### Finding Station IDs

To find weather station IDs:
1. Use NOAA's station search tools
2. Or query the API with bounding box to find nearby stations
3. Station IDs are typically in format like `USC00457180` or `ASN00084027`

---

**See `docs/DATA_SOURCES.md` for detailed information on all data sources.**

