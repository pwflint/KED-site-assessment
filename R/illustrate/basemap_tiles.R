library(terra)
library(sf)
library(httr)

# Shared raster-tile basemap fetcher for illustration prototypes. NOT a data
# source in the acquisition sense (no analytical content) - this is a
# cartographic backdrop, fetched fresh per image rather than cached, since
# these prototypes render one parcel at a time.
#
# RISK, not yet resolved (flagged 2026-07-28, see docs/ILLUSTRATION_NOTES.md):
# default provider is Carto's "light_nolabels" tile set. Confirmed live and
# genuinely label-free by direct tile inspection, but Carto's free tile
# terms have shifted before and Peter has explicitly flagged them as a
# smaller/earlier-stage provider than Esri. Esri's equivalent raster product
# (Canvas/World_Light_Gray_Base) was tried first and rejected: despite the
# Base/Reference naming convention implying label-free tiles, the live Base
# tiles have street/place labels baked in (confirmed by direct pixel
# inspection, not assumed from the product name) - Esri's vector tile
# services (OpenStreetMap_v2, World_Basemap_v2) were also tried and are not
# straightforward to composite into this static-image R pipeline (Esri uses
# non-standard relative style paths and, for World_Basemap_v2, a vector
# source definition that a generic MapLibre client can't resolve at all).
# Provider choice is explicitly deferred to when this project starts testing
# additional parcels/geographies, not decided here - do not silently swap
# providers without flagging the same tradeoff again.
CARTO_NOLABELS_URL <- "https://basemaps.cartocdn.com/light_nolabels"

# Standard Web Mercator (EPSG:3857) slippy-map tile pyramid - the same grid
# used by Esri, Google, and OSM-derived tile services, so this math is
# reusable if the provider ever changes.
WEBMERCATOR_ORIGIN <- c(x = -20037508.342789244, y = 20037508.342789244)
WEBMERCATOR_RES0 <- 156543.033928041

#' Fetch and mosaic basemap tiles covering an sf polygon, reprojected to
#' match that polygon's own CRS.
#'
#' @param area_sf sf polygon defining the extent to cover (any CRS)
#' @param zoom tile zoom level (16 is the max native resolution for Esri's
#'   equivalent NA coverage; used here for parity, not verified as Carto's
#'   own max)
#' @param tile_url_template base URL, appended with "/{z}/{x}/{y}.png"
get_basemap_tiles <- function(area_sf, zoom = 16, tile_url_template = CARTO_NOLABELS_URL) {
  target_crs <- st_crs(area_sf)
  area_3857 <- st_transform(area_sf, 3857)
  bb <- st_bbox(area_3857)

  res <- WEBMERCATOR_RES0 / 2^zoom
  tile_m <- res * 256
  tx_range <- floor((c(bb["xmin"], bb["xmax"]) - WEBMERCATOR_ORIGIN["x"]) / tile_m)
  ty_range <- floor((WEBMERCATOR_ORIGIN["y"] - c(bb["ymax"], bb["ymin"])) / tile_m)

  tile_rasters <- list()
  for (tx in tx_range[1]:tx_range[2]) {
    for (ty in ty_range[1]:ty_range[2]) {
      url <- sprintf("%s/%d/%d/%d.png", tile_url_template, zoom, tx, ty)
      tmp <- tempfile(fileext = ".png")
      resp <- GET(url, write_disk(tmp, overwrite = TRUE))
      if (status_code(resp) != 200) next

      r <- rast(tmp)
      if (has.colors(r)) r <- colorize(r, "rgb")  # palette PNG -> real RGB bands

      xmin <- WEBMERCATOR_ORIGIN["x"] + tx * tile_m
      ymax <- WEBMERCATOR_ORIGIN["y"] - ty * tile_m
      ext(r) <- c(xmin, xmin + tile_m, ymax - tile_m, ymax)
      crs(r) <- "EPSG:3857"
      tile_rasters[[length(tile_rasters) + 1]] <- r
    }
  }
  if (length(tile_rasters) == 0) stop("No basemap tiles could be fetched for this extent.")

  mosaic_r <- if (length(tile_rasters) > 1) do.call(terra::merge, tile_rasters) else tile_rasters[[1]]
  basemap <- project(mosaic_r, target_crs$wkt, method = "bilinear")
  crop(basemap, vect(area_sf))
}
