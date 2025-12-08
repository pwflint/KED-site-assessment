# Testing Notes

**Last Updated**: 2025-12-05  
**Status**: Active testing, issues documented for planning session

## Known Issues & Solutions

### DEM Resolution Issue

**Problem**: DEM showing as 1x1 pixel for small parcels.

**Cause**: 
- Old cached DEM files were created before buffer/resampling fixes
- 10m resolution may be too coarse for very small parcels (< 1 acre)

**Solution**:
1. **Delete old cache**: Remove `data/raw/dem/dem_10m_*.tif` files to force re-download
2. **Auto-resolution**: Code now automatically uses 3m resolution for parcels < 1 acre
3. **Resampling**: If DEM still has < 25 pixels, it will be resampled to 1m for visualization

**To clear DEM cache**:
```r
# Delete old DEM cache files
unlink(list.files("data/raw/dem", pattern = "dem_10m_.*\\.tif", full.names = TRUE))
```

### Expected API Errors

Some 400/404 errors are **expected** and not failures:

- **FEMA 404**: Site is not in a flood zone (no data = correct result)
- **NHDPlus 404**: Very small parcels may not intersect with NHDPlus features
- **NOAA 400**: API may require station IDs rather than bounding box queries (needs refinement)

### Climate Data Empty List

**Problem**: PRISM data shows as empty list even though files are downloaded.

**Cause**: `prism_archive_subset()` may not find files if they're in a different location or format.

**Solution**: Check PRISM download directory and verify files exist:
```r
prism::prism_get_dl_dir()  # Check download directory
list.files(prism::prism_get_dl_dir(), recursive = TRUE)  # List downloaded files
```

### DEM Visualization

**Improvements Made**:
- ✅ Added elevation legend with color scale
- ✅ Added site address as subtitle for context
- ✅ Added scale bar and north arrow
- ✅ Added data source citation
- ✅ Uses ggplot2 for better control

**Future Enhancements**:
- Add regional context map (inset showing city/region)
- Add street/road context from OpenStreetMap
- Add building footprints for urban context

## Testing Workflow

1. **Clear old cache** (if needed):
   ```r
   # Delete specific cache files
   unlink("data/raw/dem/dem_10m_-78.6383_35.7795.tif")
   ```

2. **Run test**:
   ```r
   source("R/utils/testDataAcquisition.R")
   ```

3. **Check results**:
   - DEM should have > 25 pixels
   - Climate data should have > 0 elements
   - Soils should have spatial and tabular data

## Data Source Status

| Source | Status | Notes |
|--------|--------|-------|
| DEM | ✅ Working | Auto-adjusts resolution for small parcels |
| Soils | ✅ Working | Full SSURGO data with attributes |
| Climate | ⚠️ Partial | Downloads but may not load correctly |
| Wind | ❌ Needs work | API format issue |
| Watershed | ⚠️ Partial | May not have data for small parcels |
| Ecoregion | ❌ Not implemented | Needs manual download or FedData enhancement |
| Flood Zones | ⚠️ Partial | 404 may mean no flood zone (expected) |
| Canopy | ❌ Not implemented | Optional feature |

---

**Next Steps**: Focus on getting DEM, soils, and climate working reliably before moving to other sources.

