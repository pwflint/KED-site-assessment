library(sf)

# Local county data cache. Decision 2026-09-18, see docs/DATA_SOURCE_RESEARCH.md,
# "Local county data cache": bulky, slowly changing context layers (roads,
# hydrology reaches, buildings) are downloaded once and reused; per-parcel
# queries stay live. This is the template; the building-footprint cache in
# building_footprint.R predates it and still manages its own download.
#
# Every cached layer gets a manifest entry with the source URL, the source's
# own stated vintage, the download date, and the feature count. Vintage is
# the honest number: a fresh download of a 2020 dataset is still 2020 data.
#
# KED_DATA_DIR overrides the location (default "data/", gitignored).

KED_DATA_DIR <- Sys.getenv("KED_DATA_DIR", "data")

#' Read a layer from the county cache, or fetch it and cache it.
#'
#' @param county county name, becomes the directory
#' @param layer short layer name, becomes the file name
#' @param fetch function() returning an sf object
#' @param source_url where it came from, for the manifest and the report
#' @param vintage the source's own publication date or version, as a string
#' @param extent optional sf object; for layers fetched per display extent
#'   rather than county-wide, a hash of the rounded bbox is added to the file
#'   name so different extents don't overwrite each other
#' @param max_age_days re-fetch when the cached copy is older than this
#' @param refresh TRUE forces a re-fetch
cached_layer <- function(county, layer, fetch, source_url, vintage, extent = NULL,
                         max_age_days = 180, refresh = FALSE) {
  key <- layer
  if (!is.null(extent)) {
    bb <- round(st_bbox(st_transform(extent, 4326)), 3)
    key <- paste0(layer, "_", substr(digest_bbox(bb), 1, 8))
  }
  dir <- file.path(KED_DATA_DIR, tolower(county))
  path <- file.path(dir, paste0(key, ".gpkg"))
  man_path <- file.path(dir, "manifest.json")
  manifest <- if (file.exists(man_path)) jsonlite::fromJSON(man_path, simplifyVector = FALSE) else list()
  entry <- manifest[[key]]
  fresh <- !is.null(entry) &&
    as.numeric(Sys.Date() - as.Date(entry$downloaded)) <= max_age_days
  if (file.exists(path) && fresh && !refresh) {
    x <- st_read(path, quiet = TRUE)
    attr(x, "manifest") <- entry
    return(x)
  }
  x <- fetch()
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  st_write(x, path, delete_dsn = TRUE, quiet = TRUE)
  entry <- list(layer = layer, source = source_url, vintage = vintage,
                downloaded = format(Sys.Date()), features = nrow(x),
                extent = if (is.null(extent)) "county" else as.list(bb))
  manifest[[key]] <- entry
  jsonlite::write_json(manifest, man_path, auto_unbox = TRUE, pretty = TRUE)
  attr(x, "manifest") <- entry
  x
}

# Stable short id for a rounded bbox without pulling in a hashing package.
digest_bbox <- function(bb) {
  s <- paste(sprintf("%.3f", as.numeric(bb)), collapse = ",")
  paste(sprintf("%02x", utf8ToInt(s) %% 256), collapse = "")
}
