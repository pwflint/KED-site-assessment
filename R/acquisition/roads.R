library(sf)
library(httr)

# Road centerlines for the self-rendered neighborhood base map. Source today:
# OpenStreetMap via the public Overpass API (validated 2026-07-24 for exactly
# this use; wrong for parcels, right for base-map roads). One query per
# assessment, self-identifying User-Agent, well within the public instance's
# usage policy.
#
# This is the function to swap when the county cache moves to a state or
# county roads layer with provenance (docs/DATA_SOURCE_RESEARCH.md, "Local
# county data cache"): keep the return shape (sf LINESTRING, columns
# highway, name) and nothing downstream changes.
OVERPASS_URL <- "https://overpass-api.de/api/interpreter"
KED_USER_AGENT <- "KED-site-assessment/0.1 (kaleiope.design; prototype, one query per assessment)"

# Road classes drawn on the base, darkest first. Everything else (service
# roads, footways, driveways) is dropped: quiet base, not a street atlas.
ROAD_CLASSES <- c("motorway", "trunk", "primary", "secondary", "tertiary",
                  "residential", "unclassified", "living_street")

get_osm_roads <- function(area_sf, timeout_s = 60) {
  bb <- st_bbox(st_transform(area_sf, 4326))
  q <- sprintf('[out:json][timeout:%d];way["highway"](%f,%f,%f,%f);out geom;',
               timeout_s, bb["ymin"], bb["xmin"], bb["ymax"], bb["xmax"])
  resp <- POST(OVERPASS_URL, body = list(data = q), encode = "form",
               user_agent(KED_USER_AGENT), timeout(timeout_s + 15))
  stop_for_status(resp)
  els <- jsonlite::fromJSON(content(resp, as = "text", encoding = "UTF-8"), simplifyVector = FALSE)$elements
  ways <- Filter(function(e) identical(e$type, "way") && length(e$geometry) >= 2, els)
  if (length(ways) == 0) {
    return(st_sf(highway = character(), name = character(), geometry = st_sfc(crs = 4326)))
  }
  geoms <- lapply(ways, function(w) {
    m <- do.call(rbind, lapply(w$geometry, function(p) c(p$lon, p$lat)))
    st_linestring(m)
  })
  roads <- st_sf(
    highway = vapply(ways, function(w) w$tags$highway %||% NA_character_, character(1)),
    name = vapply(ways, function(w) w$tags$name %||% NA_character_, character(1)),
    geometry = st_sfc(geoms, crs = 4326)
  )
  roads[roads$highway %in% ROAD_CLASSES, ]
}

`%||%` <- function(a, b) if (is.null(a)) b else a
