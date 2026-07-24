library(sf)
library(httr)

# FEMA National Flood Hazard Layer (NFHL), layer 28 = Flood Hazard Zones.
# No auth. Confirmed live 2026-07-24.
#
# IMPORTANT: the old repo's notes treated a 404/empty response as "not in a
# flood zone." That's wrong. NFHL's coverage is comprehensive - a point query
# almost always returns A feature, including "Zone X" (minimal hazard) areas.
# The real check-first boolean is the SFHA_TF field ("T"/"F" - is this a
# Special Flood Hazard Area), not whether a feature came back at all. A truly
# empty response means something different: this location isn't covered by
# any flood study - handle that as "unknown," not as a safe "F".
NFHL_URL <- "https://hazards.fema.gov/arcgis/rest/services/public/NFHL/MapServer/28/query"

# "Zone X" is not one risk picture - SFHA_TF="F" covers several genuinely
# different cases filed under the same top-level zone code (confirmed against
# the real distinct (FLD_ZONE, ZONE_SUBTY, SFHA_TF) combinations occurring in
# NC, not assumed). Only ONE subtype is a true negative:
#   - "AREA OF MINIMAL FLOOD HAZARD"              <- the real "minimal risk" case
# Every other observed F-subtype represents real risk information, just not
# the specific "Special Flood Hazard Area" designation:
#   - "0.2 PCT ANNUAL CHANCE FLOOD HAZARD"         <- 500-yr floodplain, real risk
#   - "AREA WITH REDUCED FLOOD RISK DUE TO LEVEE"  <- risk suppressed by infrastructure, not absent
#   - "1 PCT FUTURE CONDITIONS" (+ floodway/encroachment variants) <- FEMA's own
#     forward-looking, development/climate-adjusted 100-yr floodplain
#   - "1 PCT CONTAINED IN STRUCTURE" (+ variants)  <- real 1% flow, currently
#     managed by an engineered culvert/channel - maintenance-dependent, not absent
# Treating all of FLD_ZONE=="X" as "minimal hazard, skip geometry" would
# silently flatten all of these into "safe." Checking ZONE_SUBTY specifically,
# not just the top-level code, is the actual check-first condition.
MINIMAL_HAZARD_SUBTYPES <- c("AREA OF MINIMAL FLOOD HAZARD")

check_flood_zone <- function(parcel_sf) {
  centroid <- st_transform(st_centroid(parcel_sf), 4326) |> st_coordinates()
  geom_json <- sprintf('{"x":%f,"y":%f,"spatialReference":{"wkid":4326}}', centroid[1, "X"], centroid[1, "Y"])

  # pass 1: attributes only - cheap, always done, decides whether pass 2 is worth it
  resp <- GET(NFHL_URL, query = list(
    geometry = geom_json, geometryType = "esriGeometryPoint", inSR = 4326,
    spatialRel = "esriSpatialRelIntersects",
    outFields = "OBJECTID,FLD_ZONE,ZONE_SUBTY,SFHA_TF,STATIC_BFE",
    returnGeometry = "false", f = "json"
  ))
  parsed <- jsonlite::fromJSON(content(resp, as = "text", encoding = "UTF-8"), simplifyVector = FALSE)

  if (length(parsed$features) == 0) {
    return(list(status = "unstudied", in_special_flood_hazard_area = NA, needs_geometry = NA, geometry = NULL,
                message = "No NFHL study coverage found for this location - not the same as 'not in a flood zone'."))
  }

  attrs <- parsed$features[[1]]$attributes
  in_sfha <- identical(attrs$SFHA_TF, "T")
  is_true_minimal_hazard <- !in_sfha && !is.null(attrs$ZONE_SUBTY) && attrs$ZONE_SUBTY %in% MINIMAL_HAZARD_SUBTYPES
  needs_geometry <- !is_true_minimal_hazard

  # pass 2: only when actually needed - fetch the specific feature's polygon by
  # OBJECTID (not a fresh point query) so it's unambiguously the same record
  geometry_sf <- NULL
  if (needs_geometry) {
    geom_resp <- GET(NFHL_URL, query = list(
      objectIds = attrs$OBJECTID, outFields = "FLD_ZONE,ZONE_SUBTY",
      returnGeometry = "true", f = "geojson"
    ))
    tmp <- tempfile(fileext = ".geojson")
    writeLines(content(geom_resp, as = "text", encoding = "UTF-8"), tmp)
    geometry_sf <- st_read(tmp, quiet = TRUE)
  }

  list(
    status = "studied",
    in_special_flood_hazard_area = in_sfha,
    flood_zone = attrs$FLD_ZONE,
    zone_subtype = attrs$ZONE_SUBTY,
    # skip geometry only for the confirmed true-negative subtype; everything
    # else (including other SFHA_TF="F" subtypes) carries real risk information
    needs_geometry = needs_geometry,
    geometry = geometry_sf,
    base_flood_elevation_ft = if (!is.null(attrs$STATIC_BFE) && attrs$STATIC_BFE != -9999) attrs$STATIC_BFE else NA
  )
}
