# Data Helper Functions
# Tidy data processing utilities following tidyverse principles

#' Load site metadata from YAML file
#'
#' @param yaml_path Path to YAML metadata file
#' @return List containing site metadata
load_site_metadata <- function(yaml_path) {
  if (!file.exists(yaml_path)) {
    stop(paste("Metadata file not found:", yaml_path))
  }
  
  metadata <- yaml::read_yaml(yaml_path)
  
  # Validate required fields
  required_fields <- c("project", "site")
  missing_fields <- setdiff(required_fields, names(metadata))
  
  if (length(missing_fields) > 0) {
    stop(paste("Missing required metadata sections:", paste(missing_fields, collapse = ", ")))
  }
  
  return(metadata)
}

#' Create site boundary from coordinates or bbox
#'
#' @param metadata Site metadata list
#' @param crs Coordinate reference system (default: EPSG:4326)
#' @return sf object representing site boundary
create_site_boundary <- function(metadata, crs = "EPSG:4326") {
  site <- metadata$site
  
  # Check if boundary coordinates are provided
  if (!is.null(site$boundary_coords)) {
    # Create polygon from coordinates
    coords <- do.call(rbind, site$boundary_coords)
    boundary <- sf::st_polygon(list(coords))
    boundary_sf <- sf::st_sf(geometry = sf::st_sfc(boundary), crs = crs)
    
  } else if (!is.null(site$bbox)) {
    # Create rectangle from bounding box
    bbox <- site$bbox
    boundary <- sf::st_bbox(
      c(xmin = bbox$xmin, ymin = bbox$ymin, 
        xmax = bbox$xmax, ymax = bbox$ymax),
      crs = crs
    )
    boundary_sf <- sf::st_as_sfc(boundary) %>%
      sf::st_sf()
    
  } else if (!is.null(site$boundary_shapefile)) {
    # Load from shapefile
    boundary_sf <- sf::st_read(site$boundary_shapefile, quiet = TRUE)
    
  } else {
    # Create default buffer around point
    point <- sf::st_point(c(site$longitude, site$latitude))
    point_sf <- sf::st_sf(geometry = sf::st_sfc(point), crs = crs)
    
    # Use default buffer distance (500m if not specified)
    buffer_dist <- metadata$analysis$buffer_distance %||% 500
    
    boundary_sf <- sf::st_buffer(point_sf, dist = buffer_dist)
  }
  
  return(boundary_sf)
}

#' Clip spatial data to site extent with buffer
#'
#' @param data Spatial data (sf or SpatRaster object)
#' @param site_boundary Site boundary sf object
#' @param buffer_distance Buffer distance in meters (default: 5000)
#' @return Clipped spatial data
clip_to_site <- function(data, site_boundary, buffer_distance = 5000) {
  # Create buffered boundary
  # Ensure site_boundary is in a projected CRS for buffer
  if (sf::st_is_longlat(site_boundary)) {
    # Transform to appropriate UTM zone
    site_centroid <- sf::st_centroid(site_boundary)
    utm_zone <- floor((sf::st_coordinates(site_centroid)[1] + 180) / 6) + 1
    utm_crs <- paste0("EPSG:", 32600 + utm_zone)  # Northern hemisphere
    
    site_boundary_proj <- sf::st_transform(site_boundary, utm_crs)
    buffered <- sf::st_buffer(site_boundary_proj, dist = buffer_distance)
    buffered <- sf::st_transform(buffered, sf::st_crs(site_boundary))
  } else {
    buffered <- sf::st_buffer(site_boundary, dist = buffer_distance)
  }
  
  # Clip based on data type
  if (inherits(data, "sf")) {
    clipped <- sf::st_intersection(data, buffered)
  } else if (inherits(data, "SpatRaster")) {
    buffered_bbox <- sf::st_bbox(buffered)
    clipped <- terra::crop(data, terra::ext(buffered_bbox))
    clipped <- terra::mask(clipped, terra::vect(buffered))
  } else {
    stop("Unsupported data type for clipping")
  }
  
  return(clipped)
}

#' Convert raster to tidy data frame
#'
#' @param raster SpatRaster object
#' @param xy_names Names for x and y columns (default: c("x", "y"))
#' @param value_name Name for value column (default: "value")
#' @return Tibble with x, y, and value columns
raster_to_tibble <- function(raster, xy_names = c("x", "y"), value_name = "value") {
  df <- terra::as.data.frame(raster, xy = TRUE, na.rm = TRUE)
  df <- tibble::as_tibble(df)
  
  # Rename columns
  if (length(xy_names) == 2) {
    names(df)[1:2] <- xy_names
  }
  
  # If only one layer, rename value column
  if (ncol(df) == 3 && value_name != names(df)[3]) {
    names(df)[3] <- value_name
  }
  
  return(df)
}

#' Validate tidy data structure
#'
#' @param data Data to validate (tibble, sf, or SpatRaster)
#' @param expected_type Expected data type ("tibble", "sf", "SpatRaster")
#' @param required_cols Required column names (for tibble/sf)
#' @return Logical: TRUE if valid, FALSE otherwise
validate_tidy_data <- function(data, expected_type = NULL, required_cols = NULL) {
  if (is.null(data)) {
    return(FALSE)
  }
  
  if (!is.null(expected_type)) {
    if (expected_type == "tibble" && !tibble::is_tibble(data)) {
      return(FALSE)
    }
    if (expected_type == "sf" && !inherits(data, "sf")) {
      return(FALSE)
    }
    if (expected_type == "SpatRaster" && !inherits(data, "SpatRaster")) {
      return(FALSE)
    }
  }
  
  if (!is.null(required_cols)) {
    if (inherits(data, "sf")) {
      missing_cols <- setdiff(required_cols, names(data))
    } else if (tibble::is_tibble(data) || is.data.frame(data)) {
      missing_cols <- setdiff(required_cols, names(data))
    } else {
      return(FALSE)
    }
    
    if (length(missing_cols) > 0) {
      warning(paste("Missing required columns:", paste(missing_cols, collapse = ", ")))
      return(FALSE)
    }
  }
  
  return(TRUE)
}

#' Save processed data in tidy format
#'
#' @param data Data to save (tibble, sf, or SpatRaster)
#' @param file_path Path to save file
#' @param format File format ("rds", "csv", "geojson", "tif")
save_tidy_data <- function(data, file_path, format = "rds") {
  dir.create(dirname(file_path), showWarnings = FALSE, recursive = TRUE)
  
  if (format == "rds") {
    saveRDS(data, file_path)
  } else if (format == "csv" && (tibble::is_tibble(data) || is.data.frame(data))) {
    readr::write_csv(data, file_path)
  } else if (format == "geojson" && inherits(data, "sf")) {
    sf::st_write(data, file_path, delete_dsn = TRUE, quiet = TRUE)
  } else if (format == "tif" && inherits(data, "SpatRaster")) {
    terra::writeRaster(data, file_path, overwrite = TRUE)
  } else {
    stop(paste("Unsupported format/type combination:", format, class(data)[1]))
  }
  
  message(paste("Data saved to:", file_path))
}

