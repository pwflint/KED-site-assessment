library(sf)
library(httr)

# USGS/NRCS Watershed Boundary Dataset (WBD), served via the National Map.
# No auth. Confirmed live 2026-07-24; field names and returned values checked
# live against a real point (not assumed from docs) - see
# docs/DATA_SOURCE_RESEARCH.md for the full HUC digit-level/layer-ID table
# (2-digit through 16-digit). Only HUC06 (regional/basin context) and HUC12
# (parcel-level subwatershed) are implemented here, per the PRD's targets.
#
# Query returns the single intersecting HUC polygon itself - not a buffered
# region or neighboring HUCs for context. Whether/how to widen that for
# display is a visualization-stage decision, deferred per Peter, not made
# here.
WBD_URL <- "https://hydro.nationalmap.gov/arcgis/rest/services/wbd/MapServer"
WBD_HUC06_LAYER <- 3
WBD_HUC12_LAYER <- 6

get_huc_layer <- function(parcel_sf, layer_id, out_fields) {
  centroid <- st_transform(st_centroid(parcel_sf), 4326) |> st_coordinates()

  resp <- GET(sprintf("%s/%d/query", WBD_URL, layer_id), query = list(
    geometry = sprintf("%f,%f", centroid[1, "X"], centroid[1, "Y"]),
    geometryType = "esriGeometryPoint", inSR = 4326,
    spatialRel = "esriSpatialRelIntersects",
    outFields = out_fields, returnGeometry = "true", f = "geojson"
  ))

  tmp <- tempfile(fileext = ".geojson")
  writeLines(content(resp, as = "text", encoding = "UTF-8"), tmp)
  huc_sf <- st_read(tmp, quiet = TRUE)

  if (nrow(huc_sf) == 0) stop("No HUC boundary found intersecting parcel at layer ", layer_id)
  huc_sf
}

get_watershed <- function(parcel_sf) {
  list(
    huc06 = get_huc_layer(parcel_sf, WBD_HUC06_LAYER, "huc6,name"),
    huc12 = get_huc_layer(parcel_sf, WBD_HUC12_LAYER, "huc12,name,tohuc")
  )
}
