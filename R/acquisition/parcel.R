library(sf)
library(httr)

# NC1Map_Parcels (NC OneMap) - statewide, public, no auth despite "secure" in the URL path.
# Practitioner always has an exact, confirmed address (PRD workflow) - exact match on
# siteadd + scity, never szip (confirmed empty/unreliable on real records).
PARCELS_URL <- "https://services.gis.nc.gov/secure/rest/services/NC1Map_Parcels/FeatureServer/1/query"

get_parcel <- function(site_address, city, county = NULL) {
  where_parts <- c(
    sprintf("UPPER(siteadd) = UPPER('%s')", site_address),
    sprintf("UPPER(scity) = UPPER('%s')", city)
  )
  if (!is.null(county)) where_parts <- c(where_parts, sprintf("UPPER(cntyname) = UPPER('%s')", county))

  resp <- GET(PARCELS_URL, query = list(
    where = paste(where_parts, collapse = " AND "),
    outFields = "parno,siteadd,scity,ownname,gisacres,parusedesc,cntyname",
    returnGeometry = "true",
    f = "geojson"
  ))
  geojson_text <- content(resp, as = "text", encoding = "UTF-8")

  tmp <- tempfile(fileext = ".geojson")
  writeLines(geojson_text, tmp)
  parcel_sf <- st_read(tmp, quiet = TRUE)

  if (nrow(parcel_sf) == 0) stop("No parcel found for: ", site_address, ", ", city)
  if (nrow(parcel_sf) > 1) warning(nrow(parcel_sf), " parcels matched; returning all - caller should disambiguate.")

  parcel_sf  # GeoJSON output from ArcGIS REST is always WGS84 (EPSG:4326) regardless of source SRS
}
