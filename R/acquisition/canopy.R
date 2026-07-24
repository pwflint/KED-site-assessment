library(sf)
library(terra)
library(httr)

# NLCD Tree Canopy Cover (USFS), 30m resolution, percent canopy per pixel (0-100).
# No auth. Confirmed live 2026-07-24.
# IMPORTANT: 30m native resolution means a typical quarter-acre residential
# parcel spans only a handful of pixels - this is a coarse read, not a
# tree-by-tree map. Same resolution-matching discipline as DEM applies: never
# request more pixels than the bbox supports at 30m, or risk the same kind of
# fake-blocky artifact found there.
TCC_URL <- "https://imagery.geoplatform.gov/iipp/rest/services/Vegetation/USFS_EDW_NLCD_TCC_CONUS/ImageServer/exportImage"
TCC_NATIVE_RES_M <- 30

DEFAULT_CANOPY_HEIGHT_FT <- 55  # midpoint of 50-60ft range; adjustable per field observation
DEFAULT_CANOPY_THRESHOLD_PCT <- 0  # "has any measurable canopy" - not a density cutoff; adjustable

get_canopy_extent <- function(parcel_sf, buffer_ft = 100,
                               threshold_pct = DEFAULT_CANOPY_THRESHOLD_PCT,
                               canopy_height_ft = DEFAULT_CANOPY_HEIGHT_FT) {
  parcel_3857 <- st_transform(parcel_sf, 3857)  # web mercator, meters - matches service's native grid
  bbox <- st_bbox(st_buffer(parcel_3857, buffer_ft * 0.3048))

  width_px  <- max(1, round((bbox[["xmax"]] - bbox[["xmin"]]) / TCC_NATIVE_RES_M))
  height_px <- max(1, round((bbox[["ymax"]] - bbox[["ymin"]]) / TCC_NATIVE_RES_M))

  tmp <- tempfile(fileext = ".tif")
  resp <- GET(TCC_URL, query = list(
    bbox = paste(bbox[["xmin"]], bbox[["ymin"]], bbox[["xmax"]], bbox[["ymax"]], sep = ","),
    bboxSR = 3857, imageSR = 3857,
    size = sprintf("%d,%d", width_px, height_px),
    format = "tiff", pixelType = "U8",
    interpolation = "RSP_NearestNeighbor",  # categorical-ish percent data, not continuous elevation
    f = "image"
  ), write_disk(tmp, overwrite = TRUE))

  r <- rast(tmp)
  crs(r) <- "EPSG:3857"

  canopy_mask <- r > threshold_pct
  canopy_mask[canopy_mask == 0] <- NA
  polys <- as.polygons(canopy_mask, dissolve = TRUE)

  if (nrow(polys) == 0) {
    return(list(has_canopy = FALSE, geometry = NULL, canopy_pct_raster = st_as_sf(as.polygons(r, dissolve = FALSE))))
  }

  canopy_sf <- st_as_sf(polys)
  canopy_sf$assumed_height_ft <- canopy_height_ft
  canopy_sf$threshold_pct_used <- threshold_pct

  list(has_canopy = TRUE, geometry = canopy_sf, canopy_pct_raster = r)
}
