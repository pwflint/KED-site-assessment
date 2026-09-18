library(sf)
library(httr)

# Cartographic river linework: the parcel's own principal river (by HUC06
# name) from the USGS National Hydrography Dataset "Flowline - Small Scale"
# layer, which is purpose-built for state-wide display. Promoted 2026-09-18
# from the ad hoc query in R/illustrate/regional_inset.R; findings in
# docs/DATA_SOURCE_RESEARCH.md, Hydrography section.
#
# KNOWN LIMITATION: a general "other major rivers" set is NOT provided.
# Rivers with reservoir chains (Catawba, likely Yadkin) return only fragments
# under a GNIS_NAME query because dammed stretches are lake features. Only
# the parcel's own river is fetched, and its name is a heuristic:
# paste(huc06_name, "River") held for "Neuse" but must be verified per basin.
NHD_FLOWLINE_SMALLSCALE_URL <- "https://hydro.nationalmap.gov/arcgis/rest/services/nhd/MapServer/4/query"

#' @param river_name exact GNIS name, e.g. "Neuse River"
#' @param area_sf polygon the river must intersect (the state outline); the
#'   result is clipped to it
get_principal_river <- function(river_name, area_sf) {
  bb <- st_bbox(st_transform(area_sf, 4326))
  resp <- GET(NHD_FLOWLINE_SMALLSCALE_URL, query = list(
    geometry = sprintf("%f,%f,%f,%f", bb["xmin"], bb["ymin"], bb["xmax"], bb["ymax"]),
    geometryType = "esriGeometryEnvelope", inSR = 4326, spatialRel = "esriSpatialRelIntersects",
    where = sprintf("GNIS_NAME = '%s'", gsub("'", "''", river_name)),
    outFields = "GNIS_NAME", returnGeometry = "true", f = "geojson"
  ))
  tmp <- tempfile(fileext = ".geojson")
  writeLines(content(resp, as = "text", encoding = "UTF-8"), tmp)
  river <- st_read(tmp, quiet = TRUE)
  if (nrow(river) == 0) {
    warning("No NHD flowline named '", river_name, "'. The HUC06-to-river name guess may be wrong for this basin.")
    return(river)
  }
  suppressWarnings(st_intersection(st_transform(river, 4326), st_transform(area_sf, 4326)))
}
