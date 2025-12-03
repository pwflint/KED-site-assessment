# FedData v4 Important Notes

## Version Information

**FedData v4** has been loaded and is working!

## Breaking Changes in v4

FedData v4 has retired dependencies on:
- `sp` package (replaced with `sf`)
- `raster` package (replaced with `terra`)

### What This Means

1. **All FedData functions now return**:
   - `terra` objects for raster data (instead of `raster`)
   - `sf` objects for vector data (instead of `sp`)

2. **This aligns perfectly with our project**:
   - We're already using `terra` for raster operations
   - We're already using `sf` for vector operations
   - We're following tidy data principles

3. **No need for `raster` package**:
   - We can remove `raster` from our package list
   - Use `terra` for all raster operations
   - `terra` is faster and more modern

## Code Updates Needed

When using FedData functions, expect:
- `terra::SpatRaster` objects (not `raster::RasterLayer`)
- `sf` objects (not `sp::SpatialPolygonsDataFrame`)

Our helper functions in `R/functions/dataHelpers.R` already handle:
- `terra` objects (via `clip_to_site()`)
- `sf` objects (via `clip_to_site()`)

So we're already compatible! ✅

## arcgislayers Status

- **Not installed** (installation failed - requires Rust)
- **Not needed** - FedData works without it
- **No conflict with QGIS** - completely separate systems
- **Can be ignored** - only needed for ArcGIS-specific features

## Recommendations

1. ✅ **Keep using FedData v4** - it's working great
2. ✅ **Remove `raster` from package list** - use `terra` instead
3. ✅ **Ignore `arcgislayers`** - not needed for our use case
4. ✅ **Continue with QGIS** - no conflicts or issues

