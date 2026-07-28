library(sf)
library(httr)

# EPA Level III/IV Ecoregions. No auth. Confirmed live 2026-07-24; field
# names and returned values checked live against a real point (not assumed
# from docs).
#
# Layer 11 = Level III polygons - also carries Level II/I names on the same
# feature, so one query gets all three. Layer 7 = Level IV polygons (finer
# detail; also carries the Level III code/name redundantly, not requested
# here since layer 11 already has it).
#
# STATE_NAME on the Level III layer is NOT reliable for state attribution -
# ecoregions cross state boundaries, so a single polygon's STATE_NAME is a
# leftover/summary label from wherever that polygon record originated, not a
# real per-point spatial answer (confirmed: returned "Alabama" for a
# Raleigh, NC point). State comes from parcel data instead - deliberately
# not requested here.
ECOREGION_URL <- "https://gispub.epa.gov/arcgis/rest/services/ORD/USEPA_Ecoregions_Level_III_and_IV/MapServer"
ECOREGION_L3_LAYER <- 11
ECOREGION_L4_LAYER <- 7

get_ecoregion_layer <- function(parcel_sf, layer_id, out_fields) {
  centroid <- st_transform(st_centroid(parcel_sf), 4326) |> st_coordinates()

  resp <- GET(sprintf("%s/%d/query", ECOREGION_URL, layer_id), query = list(
    geometry = sprintf("%f,%f", centroid[1, "X"], centroid[1, "Y"]),
    geometryType = "esriGeometryPoint", inSR = 4326,
    spatialRel = "esriSpatialRelIntersects",
    outFields = out_fields, returnGeometry = "true", f = "geojson"
  ))

  tmp <- tempfile(fileext = ".geojson")
  writeLines(content(resp, as = "text", encoding = "UTF-8"), tmp)
  eco_sf <- st_read(tmp, quiet = TRUE)

  if (nrow(eco_sf) == 0) stop("No ecoregion boundary found intersecting parcel at layer ", layer_id)
  eco_sf
}

get_ecoregion <- function(parcel_sf) {
  list(
    level3 = get_ecoregion_layer(parcel_sf, ECOREGION_L3_LAYER, "US_L3CODE,US_L3NAME,NA_L2NAME,NA_L1NAME"),
    level4 = get_ecoregion_layer(parcel_sf, ECOREGION_L4_LAYER, "US_L4CODE,US_L4NAME")
  )
}
