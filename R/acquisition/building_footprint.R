library(sf)

# NC's own per-county building footprint polygons (Hazus-schema structure
# inventory, built for hazard/flood modeling) - confirmed exact-match geometry
# against the test parcel via PID == parcel's parno. NOT a reliable height
# source: LIDAR_LAG/LIDAR_HAG are ground-elevation references (Lowest/Highest
# Adjacent Grade, standard Hazus terms), not building height, and RISE (which
# might hold real height) was NA on both buildings checked. Use footprint
# geometry only; height is a placeholder, adjustable from field observation.
#
# Source catalog: https://sdd.nc.gov/staticdownloads/listbuildingfootprints/2020-2022
# Files are large (per-county .gdb inside a zip, tens to hundreds of MB) -
# this downloads/caches the whole county file once, same pattern as PRISM's
# CONUS-wide grids: expensive per-county the first time, free after.
BUILDING_FOOTPRINTS_CATALOG_URL <- "https://sdd.nc.gov/staticdownloads/listbuildingfootprints/2020-2022"
BUILDING_FOOTPRINTS_CACHE_DIR <- Sys.getenv("BUILDING_FOOTPRINTS_CACHE_DIR", file.path(tempdir(), "nc_building_footprints"))

DEFAULT_BUILDING_HEIGHT_FT <- 30
DEFAULT_CANOPY_HEIGHT_FT <- 55  # midpoint of the 50-60ft range; must stay > building height

get_county_building_footprints_url <- function(county) {
  catalog <- jsonlite::fromJSON(BUILDING_FOOTPRINTS_CATALOG_URL, simplifyVector = TRUE)
  match_row <- catalog[grepl(paste0("^", county, "_"), catalog$fileName, ignore.case = TRUE), ]
  if (nrow(match_row) == 0) stop("No building footprint file found for county: ", county)
  if (nrow(match_row) > 1) match_row <- match_row[order(match_row$timestamp, decreasing = TRUE), ][1, ]
  match_row$url
}

get_building_footprints <- function(parcel_sf, county, buffer_ft = 30,
                                     default_height_ft = DEFAULT_BUILDING_HEIGHT_FT) {
  dir.create(BUILDING_FOOTPRINTS_CACHE_DIR, showWarnings = FALSE, recursive = TRUE)
  zip_path <- file.path(BUILDING_FOOTPRINTS_CACHE_DIR, paste0(county, ".zip"))
  extract_dir <- file.path(BUILDING_FOOTPRINTS_CACHE_DIR, county)

  if (!dir.exists(extract_dir)) {
    url <- get_county_building_footprints_url(county)
    download.file(url, zip_path, quiet = TRUE, mode = "wb")
    unzip(zip_path, exdir = extract_dir)
  }

  gdb_path <- list.files(extract_dir, pattern = "\\.gdb$", full.names = TRUE)[1]

  parcel_2264 <- st_transform(parcel_sf, 2264)
  bb <- st_bbox(st_buffer(parcel_2264, buffer_ft))
  bbox_wkt <- sprintf(
    "POLYGON((%f %f, %f %f, %f %f, %f %f, %f %f))",
    bb["xmin"], bb["ymin"], bb["xmax"], bb["ymin"],
    bb["xmax"], bb["ymax"], bb["xmin"], bb["ymax"], bb["xmin"], bb["ymin"]
  )

  bldgs <- st_read(gdb_path, layer = "S_BUILDING_FP", quiet = TRUE, wkt_filter = bbox_wkt)
  bldgs$assumed_height_ft <- default_height_ft  # placeholder - adjust per field observation

  bldgs[, c("BLDG_ID", "PID", "assumed_height_ft")]
}
