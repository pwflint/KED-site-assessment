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
  # SDA answers a query with no matching rows with a bare "{}" (no Table key).
  # That is a real answer (e.g. a component with no restrictive layer), not a
  # failure: return an empty frame and let the caller decide. Added 2026-09-18.
  if (!is.null(parsed) && is.null(parsed$Table) && identical(trimws(txt), "{}")) {
    return(data.frame())
  }
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

# --- 4. section 05 additions (2026-09-18): geometry and tabular properties ---
# Raw SSURGO fields, named as in the source. Nothing is classified or
# translated here; that happens in R/illustrate/parcel_soils.R.

# Named columns for a query whose result may be empty (SDA drops the header
# with the rows), so callers always get the columns they asked for.
sda_frame <- function(sql, cols) {
  x <- sda_query(sql)
  if (nrow(x) == 0) return(as.data.frame(setNames(replicate(length(cols), character(0), simplify = FALSE), cols),
                                         stringsAsFactors = FALSE))
  names(x) <- cols
  x
}

#' Map unit polygons intersecting an extent, as sf in EPSG:4326.
#' SDA returns WKT; a 2,500 ft frame in urban Wake County is ~13 polygons.
get_soil_polygons <- function(extent_sf) {
  wkt <- st_as_text(st_geometry(st_transform(extent_sf, 4326))[[1]])
  x <- sda_frame(sprintf(
    "SELECT mupolygonkey, mukey, mupolygongeo.STAsText() AS wkt FROM mupolygon
     WHERE mupolygonkey IN (SELECT * FROM SDA_Get_Mupolygonkey_from_intersection_with_WktWgs84('%s'))", wkt),
    c("mupolygonkey", "mukey", "wkt"))
  if (nrow(x) == 0) stop("No soil map unit polygons intersect the extent.")
  st_as_sf(x, wkt = "wkt", crs = 4326)
}

#' Map unit level aggregates (muaggatt): the dominant-condition summaries
#' NRCS publishes per map unit. drclassdcd/hydgrpdcd are dominant condition;
#' aws0100wta is available water storage 0-100 cm, weighted average, in cm.
get_mapunit_aggregates <- function(mukeys) {
  cols <- c("mukey", "musym", "muname", "mukind", "slopegraddcp", "brockdepmin", "wtdepannmin",
            "wtdepaprjunmin", "flodfreqdcd", "pondfreqprs", "aws0100wta", "drclassdcd",
            "drclasswettest", "hydgrpdcd", "hydclprs")
  x <- sda_frame(sprintf(
    "SELECT mu.mukey, mu.musym, mu.muname, mu.mukind, a.slopegraddcp, a.brockdepmin, a.wtdepannmin,
            a.wtdepaprjunmin, a.flodfreqdcd, a.pondfreqprs, a.aws0100wta, a.drclassdcd,
            a.drclasswettest, a.hydgrpdcd, a.hydclprs
     FROM mapunit mu INNER JOIN muaggatt a ON mu.mukey = a.mukey WHERE mu.mukey IN (%s)",
    paste(mukeys, collapse = ",")), cols)
  for (n in c("slopegraddcp", "brockdepmin", "wtdepannmin", "wtdepaprjunmin", "aws0100wta")) x[[n]] <- as.numeric(x[[n]])
  x
}

#' Components of the given map units with the fields the soils section
#' reads: share of the unit (comppct_r), drainage class, hydrologic group,
#' runoff, slope range, hydric rating, taxonomy, landform (geomdesc).
get_mapunit_components <- function(mukeys) {
  cols <- c("mukey", "cokey", "compname", "comppct_r", "majcompflag", "drainagecl", "hydgrp", "runoff",
            "slope_l", "slope_r", "slope_h", "hydricrating", "taxorder", "taxsubgrp", "taxpartsize", "geomdesc")
  x <- sda_frame(sprintf(
    "SELECT c.mukey, c.cokey, c.compname, c.comppct_r, c.majcompflag, c.drainagecl, c.hydgrp, c.runoff,
            c.slope_l, c.slope_r, c.slope_h, c.hydricrating, c.taxorder, c.taxsubgrp, c.taxpartsize, c.geomdesc
     FROM component c WHERE c.mukey IN (%s) ORDER BY c.mukey, c.comppct_r DESC",
    paste(mukeys, collapse = ",")), cols)
  for (n in c("comppct_r", "slope_l", "slope_r", "slope_h")) x[[n]] <- as.numeric(x[[n]])
  x
}

#' Horizons of the given components (chorizon), top to bottom, with the
#' representative texture (chtexturegrp, rvindicator = Yes). Depths in cm,
#' ksat in micrometers per second, awc in cm/cm, kffact/kwfact as published.
get_component_horizons <- function(cokeys) {
  cols <- c("cokey", "chkey", "hzname", "hzdept_r", "hzdepb_r", "sandtotal_r", "silttotal_r", "claytotal_r",
            "om_r", "ksat_r", "awc_r", "kffact", "kwfact", "ph1to1h2o_r", "dbthirdbar_r")
  x <- sda_frame(sprintf(
    "SELECT h.cokey, h.chkey, h.hzname, h.hzdept_r, h.hzdepb_r, h.sandtotal_r, h.silttotal_r, h.claytotal_r,
            h.om_r, h.ksat_r, h.awc_r, h.kffact, h.kwfact, h.ph1to1h2o_r, h.dbthirdbar_r
     FROM chorizon h WHERE h.cokey IN (%s) ORDER BY h.cokey, h.hzdept_r",
    paste(cokeys, collapse = ",")), cols)
  num <- setdiff(cols, c("cokey", "chkey", "hzname"))
  for (n in num) x[[n]] <- as.numeric(x[[n]])
  if (nrow(x) > 0) {
    tx <- sda_frame(sprintf(
      "SELECT chkey, texture, texdesc FROM chtexturegrp WHERE rvindicator = 'Yes' AND chkey IN (%s)",
      paste(x$chkey, collapse = ",")), c("chkey", "texture", "texdesc"))
    x$texture <- tx$texture[match(x$chkey, tx$chkey)]
    x$texdesc <- tx$texdesc[match(x$chkey, tx$chkey)]
  }
  x
}

#' Restrictive layers (bedrock, fragipan, ...) per component; often none.
get_component_restrictions <- function(cokeys) {
  x <- sda_frame(sprintf(
    "SELECT cokey, reskind, reshard, resdept_r, resdepb_r FROM corestrictions WHERE cokey IN (%s) ORDER BY cokey, resdept_r",
    paste(cokeys, collapse = ",")), c("cokey", "reskind", "reshard", "resdept_r", "resdepb_r"))
  for (n in c("resdept_r", "resdepb_r")) x[[n]] <- as.numeric(x[[n]])
  x
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
