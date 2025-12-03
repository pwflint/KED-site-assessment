# Geocoding Helper Functions
# Address to coordinates conversion using tidygeocoder

#' Geocode address to coordinates
#'
#' @param address Character string with address
#' @param method Geocoding service to use (default: "osm" for OpenStreetMap)
#' @param return_type Return type: "coords" (list), "sf" (sf point), or "tibble" (tibble)
#' @return Coordinates as specified by return_type
geocode_address <- function(address, method = "osm", return_type = "coords") {
  if (is.null(address) || address == "") {
    stop("Address cannot be empty")
  }
  
  # Geocode using tidygeocoder
  result <- tidygeocoder::geocode(
    .tbl = tibble::tibble(address = address),
    address = address,
    method = method
  )
  
  if (is.na(result$lat) || is.na(result$long)) {
    stop(paste("Geocoding failed for address:", address))
  }
  
  # Return in requested format
  if (return_type == "coords") {
    return(list(
      latitude = result$lat,
      longitude = result$long,
      address = result$address
    ))
  } else if (return_type == "sf") {
    point <- sf::st_point(c(result$long, result$lat))
    point_sf <- sf::st_sf(
      address = result$address,
      geometry = sf::st_sfc(point),
      crs = "EPSG:4326"
    )
    return(point_sf)
  } else if (return_type == "tibble") {
    return(result)
  } else {
    stop("Invalid return_type. Use 'coords', 'sf', or 'tibble'")
  }
}

#' Reverse geocode coordinates to address
#'
#' @param latitude Numeric latitude
#' @param longitude Numeric longitude
#' @param method Geocoding service to use (default: "osm")
#' @return Character string with address
reverse_geocode <- function(latitude, longitude, method = "osm") {
  result <- tidygeocoder::reverse_geocode(
    .tbl = tibble::tibble(lat = latitude, long = longitude),
    lat = lat,
    long = long,
    method = method
  )
  
  if (is.na(result$address)) {
    warning(paste("Reverse geocoding failed for coordinates:", latitude, longitude))
    return(NA_character_)
  }
  
  return(result$address)
}

#' Validate coordinates
#'
#' @param latitude Numeric latitude
#' @param longitude Numeric longitude
#' @return Logical: TRUE if valid, FALSE otherwise
validate_coordinates <- function(latitude, longitude) {
  if (is.null(latitude) || is.null(longitude)) {
    return(FALSE)
  }
  
  if (!is.numeric(latitude) || !is.numeric(longitude)) {
    return(FALSE)
  }
  
  if (latitude < -90 || latitude > 90) {
    return(FALSE)
  }
  
  if (longitude < -180 || longitude > 180) {
    return(FALSE)
  }
  
  return(TRUE)
}

#' Create site metadata from address or coordinates
#'
#' @param address Character string with address (optional)
#' @param latitude Numeric latitude (optional if address provided)
#' @param longitude Numeric longitude (optional if address provided)
#' @param project_name Character string with project name
#' @param client_name Character string with client name (optional)
#' @return List with site metadata structure
create_site_metadata <- function(address = NULL, latitude = NULL, longitude = NULL,
                                project_name, client_name = NULL) {
  
  # Geocode if address provided
  if (!is.null(address) && address != "") {
    coords <- geocode_address(address, return_type = "coords")
    latitude <- coords$latitude
    longitude <- coords$longitude
  } else {
    # Validate coordinates if provided directly
    if (!validate_coordinates(latitude, longitude)) {
      stop("Either address or valid coordinates must be provided")
    }
  }
  
  # Create metadata structure
  metadata <- list(
    project = list(
      name = project_name,
      client = client_name %||% "Unknown",
      date_assessment = as.character(Sys.Date()),
      prepared_by = Sys.getenv("USER") %||% "Unknown",
      firm_name = "Unknown"
    ),
    site = list(
      address = address %||% reverse_geocode(latitude, longitude),
      latitude = latitude,
      longitude = longitude,
      crs = "EPSG:4326"
    ),
    analysis = list(
      buffer_distance = 5000,
      dem_resolution = "10m"
    ),
    output = list(
      format = c("pdf", "html"),
      size = "11x17",
      dpi = 300,
      output_dir = "output/reports"
    )
  )
  
  return(metadata)
}

