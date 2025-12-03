# Data Processing Script
# Processes raw data into tidy, analysis-ready formats

# Source helper functions
source(here::here("R", "functions", "dataHelpers.R"))

#' Process all acquired data into tidy formats
#'
#' @param data_list List of raw data objects from acquisition
#' @param metadata Site metadata list
#' @param output_dir Directory for processed data (default: "data/processed")
#' @return List of processed data objects
process_site_data <- function(data_list, metadata, output_dir = "data/processed") {
  
  message("Starting data processing...")
  
  # Create output directory
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
  
  # Create site boundary
  site_boundary <- create_site_boundary(metadata)
  buffer_distance <- metadata$analysis$buffer_distance %||% 5000
  
  # Initialize processed data list
  processed_list <- list()
  
  # Process DEM
  if (!is.null(data_list$dem)) {
    message("Processing DEM data...")
    # Clip to site extent
    dem_clipped <- clip_to_site(data_list$dem, site_boundary, buffer_distance)
    
    # Calculate derived metrics (slope, aspect, hillshade)
    # TODO: Implement terrain calculations
    # processed_list$dem <- dem_clipped
    # processed_list$slope <- terra::terrain(dem_clipped, v = "slope")
    # processed_list$aspect <- terra::terrain(dem_clipped, v = "aspect")
    # processed_list$hillshade <- terra::shade(...)
  }
  
  # Process soils
  if (!is.null(data_list$soils)) {
    message("Processing soil data...")
    # Clip to site extent
    soils_clipped <- clip_to_site(data_list$soils, site_boundary, buffer_distance)
    
    # Process into tidy format
    # TODO: Extract and organize soil attributes
    # processed_list$soils <- process_soil_data(soils_clipped)
  }
  
  # Process climate data
  if (!is.null(data_list$climate)) {
    message("Processing climate data...")
    # Extract climate data at site location
    # TODO: Aggregate to site coordinates
    # processed_list$climate <- extract_climate_at_site(data_list$climate, site_coords)
  }
  
  # Process wind data
  if (!is.null(data_list$wind)) {
    message("Processing wind data...")
    # Process into tidy format
    # TODO: Aggregate by season, calculate flow fields
    # processed_list$wind <- process_wind_data(data_list$wind)
  }
  
  # Process watershed data
  if (!is.null(data_list$watershed)) {
    message("Processing watershed data...")
    # Clip to site extent
    watershed_clipped <- clip_to_site(data_list$watershed, site_boundary, buffer_distance)
    # processed_list$watershed <- watershed_clipped
  }
  
  # Process ecoregion data
  if (!is.null(data_list$ecoregion)) {
    message("Processing ecoregion data...")
    # Clip to site extent
    ecoregion_clipped <- clip_to_site(data_list$ecoregion, site_boundary, buffer_distance)
    # processed_list$ecoregion <- ecoregion_clipped
  }
  
  # Process canopy data (if available)
  if (!is.null(data_list$canopy)) {
    message("Processing canopy height data...")
    # Clip to site extent
    canopy_clipped <- clip_to_site(data_list$canopy, site_boundary, buffer_distance)
    # processed_list$canopy <- canopy_clipped
  }
  
  # Process flood zones
  if (!is.null(data_list$flood_zones)) {
    message("Processing flood zone data...")
    # Clip to site extent
    flood_clipped <- clip_to_site(data_list$flood_zones, site_boundary, buffer_distance)
    # processed_list$flood_zones <- flood_clipped
  }
  
  # Save site boundary
  processed_list$site_boundary <- site_boundary
  
  # Save processed data
  saveRDS(processed_list, file.path(output_dir, "processed_data.rds"))
  message(paste("Processed data saved to:", file.path(output_dir, "processed_data.rds")))
  
  message("Data processing complete!")
  
  return(processed_list)
}

# If running as script (not sourced)
if (!interactive() && length(commandArgs(trailingOnly = TRUE)) > 0) {
  # Load metadata and raw data
  metadata_path <- commandArgs(trailingOnly = TRUE)[1]
  metadata <- load_site_metadata(metadata_path)
  data_list <- readRDS(here::here("data", "raw", "acquired_data.rds"))
  
  # Process data
  processed_list <- process_site_data(data_list, metadata)
}

