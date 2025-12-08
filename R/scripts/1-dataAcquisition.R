# Data Acquisition Script
# Downloads and caches all required data sources via APIs

# Source helper functions
source(here::here("R", "functions", "apiHelpers.R"))
source(here::here("R", "functions", "dataHelpers.R"))
source(here::here("R", "functions", "dataAcquisitionHelpers.R"))

#' Acquire all data sources for site assessment
#'
#' @param metadata Site metadata list
#' @param cache_dir Directory for cached data (default: "data/raw")
#' @return List of acquired data objects
acquire_site_data <- function(metadata, cache_dir = "data/raw") {
  
  message("=", rep("=", 60), "\n", sep = "")
  message("STARTING DATA ACQUISITION\n")
  message("=", rep("=", 60), "\n")
  
  # Load site metadata and create boundary
  # Note: site_boundary represents the actual parcel boundary (not a large area)
  # Climate data uses coordinates only (regional data, not parcel-specific)
  site <- metadata$site
  site_coords <- c(site$longitude, site$latitude)  # For climate/wind (regional)
  site_boundary <- create_site_boundary(metadata)   # For spatial data (parcel-level)
  
  # Get resolution from metadata or use default
  dem_resolution <- metadata$data_sources$dem$resolution %||% "10m"
  
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
  
  # 1. DEM (Digital Elevation Model) - USGS 3DEP
  # Spatial data: clipped to parcel boundary
  message("\n[1/8] Acquiring DEM data (parcel-level)...")
  data_list$dem <- acquire_dem(site_boundary, resolution = dem_resolution, cache_dir = cache_dirs$dem)
  
  # 2. Soils - NRCS SSURGO
  # Spatial data: clipped to parcel boundary
  message("\n[2/8] Acquiring soil data (parcel-level)...")
  data_list$soils <- acquire_soils(site_boundary, cache_dir = cache_dirs$soils)
  
  # 3. Climate - PRISM
  # Regional data: uses coordinates only (not parcel-specific)
  message("\n[3/8] Acquiring climate data (regional)...")
  climate_period <- metadata$data_sources$climate$period %||% "normals"
  data_list$climate <- acquire_climate(site_coords, period = climate_period, cache_dir = cache_dirs$climate)
  
  # 4. Wind - NOAA
  # Regional data: uses coordinates only (not parcel-specific)
  message("\n[4/8] Acquiring wind data (regional)...")
  data_list$wind <- acquire_wind(site_coords, cache_dir = cache_dirs$wind)
  
  # 5. Watershed - NHDPlus
  # Spatial data: clipped to parcel boundary
  message("\n[5/8] Acquiring watershed data (parcel-level)...")
  data_list$watershed <- acquire_watershed(site_boundary, cache_dir = cache_dirs$watershed)
  
  # 6. Ecoregions - EPA
  # Spatial data: clipped to parcel boundary
  message("\n[6/8] Acquiring ecoregion data (parcel-level)...")
  ecoregion_level <- metadata$data_sources$ecoregion$level %||% "III"
  data_list$ecoregion <- acquire_ecoregion(site_boundary, level = ecoregion_level, cache_dir = cache_dirs$ecoregion)
  
  # 7. Canopy Height (if available)
  # Spatial data: clipped to parcel boundary
  message("\n[7/8] Checking for canopy height data (parcel-level)...")
  data_list$canopy <- acquire_canopy(site_boundary, cache_dir = cache_dirs$canopy)
  
  # 8. Flood Zones - FEMA
  # Spatial data: clipped to parcel boundary
  message("\n[8/8] Acquiring flood zone data (parcel-level)...")
  data_list$flood_zones <- acquire_flood_zones(site_boundary, cache_dir = cache_dirs$flood)
  
  message("\n", "=", rep("=", 60), "\n", sep = "")
  message("DATA ACQUISITION COMPLETE\n")
  message("=", rep("=", 60), "\n")
  
  # Summary of acquired data
  message("\nAcquisition Summary:")
  for (i in seq_along(data_list)) {
    data_name <- names(data_list)[i]
    if (is.null(data_list[[i]])) {
      message("  - ", data_name, ": ❌ Not acquired")
    } else {
      message("  - ", data_name, ": ✅ Acquired")
    }
  }
  
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

