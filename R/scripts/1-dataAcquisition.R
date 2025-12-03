# Data Acquisition Script
# Downloads and caches all required data sources via APIs

# Source helper functions
source(here::here("R", "functions", "apiHelpers.R"))
source(here::here("R", "functions", "dataHelpers.R"))

#' Acquire all data sources for site assessment
#'
#' @param metadata Site metadata list
#' @param cache_dir Directory for cached data (default: "data/raw")
#' @return List of acquired data objects
acquire_site_data <- function(metadata, cache_dir = "data/raw") {
  
  message("Starting data acquisition...")
  
  site <- metadata$site
  site_coords <- c(site$longitude, site$latitude)
  
  # Create cache directory structure
  cache_dirs <- list(
    dem = file.path(cache_dir, "dem"),
    soils = file.path(cache_dir, "soils"),
    climate = file.path(cache_dir, "climate"),
    wind = file.path(cache_dir, "wind"),
    watershed = file.path(cache_dir, "watersheds"),
    ecoregion = file.path(cache_dir, "ecoregions"),
    canopy = file.path(cache_dir, "canopy"),
    flood = file.path(cache_dir, "flood_zones")
  )
  
  lapply(cache_dirs, function(x) dir.create(x, showWarnings = FALSE, recursive = TRUE))
  
  # Initialize data list
  data_list <- list()
  
  # TODO: Implement data acquisition for each source
  # 1. DEM (Digital Elevation Model) - USGS 3DEP
  message("Acquiring DEM data...")
  # data_list$dem <- acquire_dem(site_coords, cache_dirs$dem)
  
  # 2. Soils - NRCS SSURGO
  message("Acquiring soil data...")
  # data_list$soils <- acquire_soils(site_coords, cache_dirs$soils)
  
  # 3. Climate - PRISM
  message("Acquiring climate data...")
  # data_list$climate <- acquire_climate(site_coords, cache_dirs$climate)
  
  # 4. Wind - NOAA
  message("Acquiring wind data...")
  # data_list$wind <- acquire_wind(site_coords, cache_dirs$wind)
  
  # 5. Watershed - NHDPlus
  message("Acquiring watershed data...")
  # data_list$watershed <- acquire_watershed(site_coords, cache_dirs$watershed)
  
  # 6. Ecoregions - EPA
  message("Acquiring ecoregion data...")
  # data_list$ecoregion <- acquire_ecoregion(site_coords, cache_dirs$ecoregion)
  
  # 7. Canopy Height (if available)
  message("Checking for canopy height data...")
  # data_list$canopy <- acquire_canopy(site_coords, cache_dirs$canopy)
  
  # 8. Flood Zones - FEMA
  message("Acquiring flood zone data...")
  # data_list$flood_zones <- acquire_flood_zones(site_coords, cache_dirs$flood)
  
  message("Data acquisition complete!")
  
  return(data_list)
}

# If running as script (not sourced)
if (!interactive() && length(commandArgs(trailingOnly = TRUE)) > 0) {
  # Load metadata
  metadata_path <- commandArgs(trailingOnly = TRUE)[1]
  metadata <- load_site_metadata(metadata_path)
  
  # Acquire data
  data_list <- acquire_site_data(metadata)
  
  # Save acquired data
  saveRDS(data_list, here::here("data", "raw", "acquired_data.rds"))
}

