library(sf)
library(terra)
library(httr)

# NC OneMap DEM03 - 3.125ft (~1m) resolution, public, no auth. Likely bare-earth
# (sourced from the NC Floodplain Mapping Program) - see DATA_SOURCE_RESEARCH.md
# for the building-footprint-artifact caveat.
DEM_URL <- "https://services.nconemap.gov/secure/rest/services/Elevation/DEM03/ImageServer/exportImage"
DEM_NATIVE_RES_FT <- 3.125

# CRITICAL: always request size at (or near) native resolution. Requesting a pixel
# size much larger than the bbox supports forces server-side oversampling, which
# produces a false grid-patterned artifact in any derived slope calculation. See
# DATA_SOURCE_RESEARCH.md 2026-07-22 findings for how this went wrong once already.
get_dem_clip <- function(parcel_sf, buffer_ft = 20) {
  parcel_2264 <- st_transform(parcel_sf, 2264)
  bbox <- st_bbox(st_buffer(parcel_2264, buffer_ft))

  width_px  <- max(1, round((bbox[["xmax"]] - bbox[["xmin"]]) / DEM_NATIVE_RES_FT))
  height_px <- max(1, round((bbox[["ymax"]] - bbox[["ymin"]]) / DEM_NATIVE_RES_FT))

  tmp <- tempfile(fileext = ".tif")
  resp <- GET(DEM_URL, query = list(
    bbox = paste(bbox[["xmin"]], bbox[["ymin"]], bbox[["xmax"]], bbox[["ymax"]], sep = ","),
    bboxSR = 2264, imageSR = 2264,
    size = sprintf("%d,%d", width_px, height_px),
    format = "tiff", pixelType = "F32",
    noDataInterpretation = "esriNoDataMatchAny",
    interpolation = "RSP_BilinearInterpolation",
    f = "image"
  ), write_disk(tmp, overwrite = TRUE))

  r <- rast(tmp)
  crs(r) <- "EPSG:2264"
  r
}

get_slope_aspect <- function(dem) {
  list(
    elevation = dem,
    slope_deg = terrain(dem, v = "slope", unit = "degrees"),
    aspect_deg = terrain(dem, v = "aspect", unit = "degrees")
  )
}

# summary stats masked to the parcel boundary itself (not the buffer) - the buffer
# exists to give terrain() enough neighboring cells for accurate gradients at the
# parcel edge, not to be included in the reported values.
summarize_topography <- function(topo, parcel_sf) {
  parcel_native <- st_transform(parcel_sf, crs(topo$elevation))
  parcel_vect <- vect(parcel_native)

  mask_to_parcel <- function(r) mask(crop(r, parcel_vect), parcel_vect)
  elev_m   <- mask_to_parcel(topo$elevation)
  slope_m  <- mask_to_parcel(topo$slope_deg)
  aspect_m <- mask_to_parcel(topo$aspect_deg)

  grade_20pct_deg <- atan(0.20) * 180 / pi

  list(
    elevation_range_ft = range(values(elev_m), na.rm = TRUE),
    slope_range_deg = range(values(slope_m), na.rm = TRUE),
    slope_mean_deg = mean(values(slope_m), na.rm = TRUE),
    pct_area_over_20pct_grade = mean(values(slope_m) > grade_20pct_deg, na.rm = TRUE) * 100,
    aspect_mean_deg = mean(values(aspect_m), na.rm = TRUE),
    pct_south_facing = mean(values(aspect_m) >= 135 & values(aspect_m) <= 225, na.rm = TRUE) * 100
  )
}
