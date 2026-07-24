library(sf)
library(httr)
library(jsonlite)
library(rvest)
library(xml2)

sda_query <- function(sql) {
  resp <- POST(
    "https://sdmdataaccess.nrcs.usda.gov/Tabular/post.rest",
    body = list(query = sql, format = "JSON"),
    encode = "json"
  )
  txt <- content(resp, as = "text", encoding = "UTF-8")
  parsed <- tryCatch(fromJSON(txt, simplifyVector = FALSE), error = function(e) NULL)
  if (is.null(parsed) || is.null(parsed$Table)) {
    stop("SDA query failed or returned no Table: ", substr(txt, 1, 300))
  }
  rows <- parsed$Table
  row_to_vec <- function(r) vapply(r, function(x) if (is.null(x)) NA_character_ else as.character(x), character(1))
  as.data.frame(do.call(rbind, lapply(rows, row_to_vec)), stringsAsFactors = FALSE)
}

# --- 1. map units + components intersecting the parcel polygon, via SDA ---
get_soil_mapunits <- function(parcel_sf) {
  parcel_wgs84 <- st_transform(parcel_sf, 4326)
  wkt <- st_as_text(st_geometry(parcel_wgs84)[[1]])

  mukey_sql <- sprintf(
    "SELECT DISTINCT mukey FROM SDA_Get_Mukey_from_intersection_with_WktWgs84('%s')",
    wkt
  )
  mukeys <- sda_query(mukey_sql)
  if (is.null(mukeys) || nrow(mukeys) == 0) stop("No map units found intersecting parcel.")
  mukey_list <- paste(mukeys[[1]], collapse = ",")

  comp_sql <- sprintf(
    "SELECT mu.mukey, mu.muname, c.cokey, c.compname, c.comppct_r, c.drainagecl, c.hydgrp, c.taxclname
     FROM mapunit mu INNER JOIN component c ON mu.mukey = c.mukey
     WHERE mu.mukey IN (%s) ORDER BY mu.mukey, c.comppct_r DESC",
    mukey_list
  )
  comp <- sda_query(comp_sql)
  names(comp) <- c("mukey", "muname", "cokey", "compname", "comppct_r", "drainagecl", "hydgrp", "taxclname")
  comp
}

# --- 2. SoilWeb enrichment: geomorphic position, AWC, farmland class, flood freq, series links ---
get_soilweb_context <- function(lat, lon) {
  url <- sprintf("https://casoilresource.lawr.ucdavis.edu/gmap/get_mapunit_data.php?lat=%f&lon=%f", lat, lon)
  page <- read_html(GET(url))

  mudata_text <- page |> html_elements(".mudata") |> html_text2()
  compdata_rows <- page |> html_elements(".compdata")

  list_components_href <- page |> html_elements("a") |> html_attr("href")
  list_components_href <- list_components_href[grepl("list_components", list_components_href)]

  list(
    mudata_raw = mudata_text,
    compdata_raw = compdata_rows |> html_text2(),
    list_components_url = if (length(list_components_href) > 0)
      paste0("https://casoilresource.lawr.ucdavis.edu/gmap/", list_components_href[1]) else NA
  )
}

# --- 3b. per-component structured data (taxonomy, hydraulic/erosion, forest productivity,
#          land classification, suitability, ecological site) - keyed directly by cokey from SDA ---
get_component_data <- function(cokey) {
  url <- sprintf("https://casoilresource.lawr.ucdavis.edu/gmap/get_component_data.php?cokey=%s", cokey)
  page <- read_html(GET(url))
  txt <- function(cls) {
    el <- page |> html_elements(sprintf(".%s", cls))
    if (length(el) == 0) return(NA_character_)
    paste(el |> html_text2(), collapse = " | ")
  }
  list(
    cokey = cokey,
    url = url,
    soil_taxonomy = txt("soiltax"),
    hydraulic_erosion = txt("hyderosratings"),
    forest_productivity = txt("forestprod"),
    land_classification = txt("landclass"),
    suitability_ratings = txt("suitabilityratings"),
    details = txt("compdetails")
  )
}

# --- 3. per-series structured data from the Series Data Explorer ---
get_series_data <- function(series_name) {
  url <- sprintf("https://casoilresource.lawr.ucdavis.edu/sde/?series=%s", URLencode(series_name))
  page <- read_html(GET(url))

  sections_present <- c("osd", "water-balance", "lab-data", "block-diagrams",
                          "map-units", "competing-series", "extent") |>
    sapply(function(id) length(page |> html_elements(sprintf("#%s", id))) > 0)

  block_diagrams <- page |> html_elements("#block-diagrams a.bd-image")
  bd_df <- if (length(block_diagrams) > 0) {
    data.frame(
      url = paste0("https://casoilresource.lawr.ucdavis.edu", block_diagrams |> html_attr("href")),
      label = block_diagrams |> html_text2()
    )
  } else NULL

  list(
    series = series_name,
    url = url,
    sections_present = sections_present,
    block_diagrams = bd_df,
    water_balance_url = paste0(url, "#water-balance"),
    lab_data_url = paste0(url, "#lab-data")
  )
}

# --- orchestrator ---
get_soil_data <- function(parcel_sf) {
  centroid <- st_transform(st_centroid(parcel_sf), 4326) |> st_coordinates()
  lon <- centroid[1, "X"]; lat <- centroid[1, "Y"]

  components <- get_soil_mapunits(parcel_sf)
  soilweb_ctx <- get_soilweb_context(lat, lon)

  is_named_soil <- !grepl("urban|water|pits|dump", components$compname, ignore.case = TRUE)

  # component-level detail: keyed directly by cokey, specific to this map unit's instance
  component_data <- setNames(
    lapply(components$cokey[is_named_soil], get_component_data),
    components$compname[is_named_soil]
  )

  # series-level detail: aggregated across the whole geographic range of the series
  named_series <- unique(components$compname[is_named_soil])
  series_data <- setNames(lapply(named_series, get_series_data), named_series)

  list(
    mukeys = unique(components$mukey),
    components = components,
    soilweb_context = soilweb_ctx,
    component_data = component_data,
    series_data = series_data
  )
}
