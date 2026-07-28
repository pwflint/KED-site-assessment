library(sf)
library(httr)
library(jsonlite)

# OpenStreetMap, via the public Overpass API. No auth, but Overpass's usage
# policy expects a real User-Agent and non-abusive call volume - confirmed
# live 2026-07-24, but this is not built for high-frequency production
# traffic without a caching plan (see docs/DATA_SOURCE_RESEARCH.md).
#
# Retrieves raw road-network features (highway=*) only - the substrate for
# self-styled rendering, one of the two paths Peter's stated
# grayscale/orientation-not-navigation styling preference could take.
# Pre-rendered OSM tiles (tile.openstreetmap.org) are a documented
# alternative not implemented here. Which path (or both), and all styling
# decisions, are a visualization-stage decision - not resolved here.
OVERPASS_URL <- "https://overpass-api.de/api/interpreter"
OVERPASS_USER_AGENT <- "KED-site-assessment (https://github.com/pwflint/KED-site-assessment)"

get_basemap_roads <- function(parcel_sf, buffer_ft = 1000) {
  parcel_2264 <- st_transform(parcel_sf, 2264)  # NC State Plane, feet - same buffer-in-feet pattern as building_footprint.R
  bbox <- st_bbox(st_transform(st_buffer(parcel_2264, buffer_ft), 4326))

  query <- sprintf(
    '[out:json][timeout:25];way["highway"](%f,%f,%f,%f);out geom;',
    bbox[["ymin"]], bbox[["xmin"]], bbox[["ymax"]], bbox[["xmax"]]
  )

  resp <- POST(OVERPASS_URL, body = list(data = query), encode = "form",
               add_headers(`User-Agent` = OVERPASS_USER_AGENT))
  parsed <- fromJSON(content(resp, as = "text", encoding = "UTF-8"), simplifyVector = FALSE)

  if (length(parsed$elements) == 0) {
    return(st_sf(name = character(0), highway = character(0),
                  geometry = st_sfc(crs = 4326)))
  }

  roads <- lapply(parsed$elements, function(el) {
    coords <- do.call(rbind, lapply(el$geometry, function(pt) c(pt$lon, pt$lat)))
    list(
      name = if (!is.null(el$tags$name)) el$tags$name else NA_character_,
      highway = if (!is.null(el$tags$highway)) el$tags$highway else NA_character_,
      geometry = st_linestring(coords)
    )
  })

  st_sf(
    name = vapply(roads, function(r) r$name, character(1)),
    highway = vapply(roads, function(r) r$highway, character(1)),
    geometry = st_sfc(lapply(roads, function(r) r$geometry), crs = 4326)
  )
}
