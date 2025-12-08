# Data Acquisition Helper Functions
# Individual functions for acquiring each data source

#' Acquire DEM from USGS 3DEP
#'
#' @param site_boundary sf object with parcel boundary (not a large area)
#' @param resolution DEM resolution: "1m", "3m", "10m", or "30m" (default: "10m")
#' @param cache_dir Directory for cached data
#' @return SpatRaster object with DEM clipped to parcel boundary
acquire_dem <- function(site_boundary, resolution = "10m", cache_dir = "data/raw/dem") {
  
  message("Acquiring DEM from USGS 3DEP...")
  
  # Create cache directory
  dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)
  
  # Generate cache file name
  site_bbox <- sf::st_bbox(site_boundary)
  cache_file <- file.path(
    cache_dir,
    paste0("dem_", resolution, "_",
           round(site_bbox$xmin, 4), "_", round(site_bbox$ymin, 4), ".tif")
  )
  
  # Check cache - but also check if cached DEM has adequate resolution
  if (file.exists(cache_file)) {
    cached_dem <- terra::rast(cache_file)
    # Check if cached DEM has enough pixels (at least 5x5 for small parcels)
    if (terra::ncell(cached_dem) >= 25) {
      message("Loading DEM from cache...")
      return(cached_dem)
    } else {
      message("Cached DEM has insufficient resolution, re-acquiring...")
      # Delete old cache to force re-download
      unlink(cache_file)
    }
  }
  
  # Convert resolution to elevatr format
  # For small parcels (< 1 acre), use higher resolution
  site_area <- as.numeric(sf::st_area(site_boundary))  # in m²
  site_area_acres <- site_area / 4046.86
  
  # Auto-adjust resolution for small parcels
  if (site_area_acres < 1 && resolution == "10m") {
    message("Small parcel detected (", round(site_area_acres, 2), " acres). Using 3m resolution for better detail.")
    resolution <- "3m"
  }
  
  elevatr_res <- switch(
    resolution,
    "1m" = 1,
    "3m" = 3,
    "10m" = 10,
    "30m" = 30,
    10  # default
  )
  
  # Get DEM using elevatr
  tryCatch({
    # Convert site boundary to sf for elevatr (elevatr works with sf objects)
    # Get elevation raster
    dem <- elevatr::get_elev_raster(
      locations = site_boundary,
      z = elevatr_res,
      src = "aws"  # Use AWS source (3DEP)
    )
    
    # Convert to SpatRaster if needed
    if (!inherits(dem, "SpatRaster")) {
      dem <- terra::rast(dem)
    }
    
    # Clip DEM to parcel boundary (elevatr may return larger area)
    # Add small buffer to ensure we get enough pixels for analysis
    # Transform boundary to match DEM CRS
    dem_crs <- terra::crs(dem)
    if (!is.na(dem_crs) && dem_crs != "") {
      site_boundary_proj <- sf::st_transform(site_boundary, dem_crs)
      # Add small buffer (50m) to ensure adequate coverage
      site_boundary_buffered <- sf::st_buffer(site_boundary_proj, dist = 50)
    } else {
      site_boundary_proj <- site_boundary
      # For geographic CRS, use degree buffer (~0.0005 degrees ≈ 50m)
      site_boundary_buffered <- sf::st_buffer(site_boundary_proj, dist = 0.0005)
    }
    
    # Crop and mask to buffered parcel boundary
    dem_clipped <- terra::crop(dem, terra::vect(site_boundary_buffered))
    dem_clipped <- terra::mask(dem_clipped, terra::vect(site_boundary_proj))  # Mask to exact boundary
    
    # If DEM has very few pixels, resample to finer resolution for visualization
    if (terra::ncell(dem_clipped) < 25) {
      message("DEM has few pixels, resampling to 1m resolution for better visualization...")
      # Resample to 1m resolution
      dem_resampled <- terra::disagg(dem_clipped, fact = max(1, round(terra::res(dem_clipped)[1])))
      # Crop again to exact boundary
      dem_resampled <- terra::crop(dem_resampled, terra::vect(site_boundary_buffered))
      dem_resampled <- terra::mask(dem_resampled, terra::vect(site_boundary_proj))
      dem_clipped <- dem_resampled
    }
    
    # Cache the result
    terra::writeRaster(dem_clipped, cache_file, overwrite = TRUE)
    message(paste("DEM clipped to parcel and cached to:", cache_file))
    
    return(dem_clipped)
    
  }, error = function(e) {
    warning(paste("Failed to acquire DEM:", e$message))
    return(NULL)
  })
}

#' Acquire soil data from NRCS SSURGO
#'
#' @param site_boundary sf object with parcel boundary (not a large area)
#' @param cache_dir Directory for cached data
#' @return List with SSURGO spatial data and attribute tables clipped to parcel
acquire_soils <- function(site_boundary, cache_dir = "data/raw/soils") {
  
  message("Acquiring soil data from NRCS SSURGO...")
  
  # Create cache directory
  dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)
  
  # Generate cache file name
  site_bbox <- sf::st_bbox(site_boundary)
  cache_file <- file.path(
    cache_dir,
    paste0("ssurgo_",
           round(site_bbox$xmin, 4), "_", round(site_bbox$ymin, 4), ".rds")
  )
  
  # Check cache
  if (file.exists(cache_file)) {
    message("Loading SSURGO data from cache...")
    return(readRDS(cache_file))
  }
  
  # Get SSURGO data using FedData
  tryCatch({
    # FedData::get_ssurgo() requires a template polygon
    # Create template from site boundary
    template <- site_boundary
    
    # Get SSURGO data
    ssurgo <- FedData::get_ssurgo(
      template = template,
      label = "site",
      raw.dir = file.path(cache_dir, "raw"),
      extraction.dir = file.path(cache_dir, "extracted")
    )
    
    # Cache the result
    saveRDS(ssurgo, cache_file)
    message(paste("SSURGO data cached to:", cache_file))
    
    return(ssurgo)
    
  }, error = function(e) {
    warning(paste("Failed to acquire SSURGO data:", e$message))
    return(NULL)
  })
}

#' Acquire climate data from PRISM
#'
#' @param site_coords Numeric vector with [longitude, latitude] - parcel center point
#' @param variables Climate variables to get (default: c("tmean", "ppt"))
#' @param period Time period: "normals" (1991-2020) or specific year
#' @param cache_dir Directory for cached data
#' @return List with climate rasters for each variable (regional data, not parcel-specific)
acquire_climate <- function(site_coords, variables = c("tmean", "ppt"),
                            period = "normals", cache_dir = "data/raw/climate") {
  
  message("Acquiring climate data from PRISM...")
  
  # Create cache directory
  dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)
  
  # Set PRISM download directory
  prism::prism_set_dl_dir(file.path(cache_dir, "prism"))
  
  # Generate cache file name
  cache_file <- file.path(
    cache_dir,
    paste0("prism_", period, "_",
           round(site_coords[1], 4), "_", round(site_coords[2], 4), ".rds")
  )
  
  # Check cache
  if (file.exists(cache_file)) {
    message("Loading PRISM data from cache...")
    return(readRDS(cache_file))
  }
  
  # Get PRISM data
  climate_data <- list()
  
  tryCatch({
    if (period == "normals") {
      # Get normals (1991-2020)
      for (var in variables) {
        message(paste("Downloading PRISM", var, "normals..."))
        
        # Get annual normals
        prism::get_prism_normals(
          type = var,
          resolution = "4km",
          annual = TRUE,
          keepZip = FALSE
        )
        
        # Get monthly normals (specify months 1-12)
        prism::get_prism_normals(
          type = var,
          resolution = "4km",
          annual = FALSE,
          mon = 1:12,  # All 12 months
          keepZip = FALSE
        )
      }
      
      # Load the data
      for (var in variables) {
        # Annual data
        annual_files <- prism::prism_archive_subset(
          type = var,
          temp_period = "annual normals",
          resolution = "4km"  # Must specify resolution when subsetting
        )
        if (length(annual_files) > 0) {
          climate_data[[paste0(var, "_annual")]] <- prism::pd_stack(annual_files)
        }
        
        # Monthly data
        monthly_files <- prism::prism_archive_subset(
          type = var,
          temp_period = "monthly normals",
          resolution = "4km"  # Must specify resolution when subsetting
        )
        if (length(monthly_files) > 0) {
          climate_data[[paste0(var, "_monthly")]] <- prism::pd_stack(monthly_files)
        }
      }
      
    } else {
      # Get data for specific year
      year <- as.numeric(period)
      for (var in variables) {
        message(paste("Downloading PRISM", var, "for year", year, "..."))
        
        prism::get_prism_annual(
          type = var,
          years = year,
          keepZip = FALSE
        )
        
        prism::get_prism_monthlys(
          type = var,
          years = year,
          keepZip = FALSE
        )
      }
      
      # Load the data
      for (var in variables) {
        annual_files <- prism::prism_archive_subset(
          type = var,
          temp_period = "annual",
          years = year,
          resolution = "4km"  # Must specify resolution
        )
        if (length(annual_files) > 0) {
          climate_data[[paste0(var, "_annual")]] <- prism::pd_stack(annual_files)
        }
        
        monthly_files <- prism::prism_archive_subset(
          type = var,
          temp_period = "monthly",
          years = year,
          resolution = "4km"  # Must specify resolution
        )
        if (length(monthly_files) > 0) {
          climate_data[[paste0(var, "_monthly")]] <- prism::pd_stack(monthly_files)
        }
      }
    }
    
    # Check if we got any data
    if (length(climate_data) == 0) {
      warning("PRISM data downloaded but no data loaded. Check PRISM archive.")
      return(NULL)
    }
    
    # Cache the result
    saveRDS(climate_data, cache_file)
    message(paste("PRISM data cached to:", cache_file))
    message(paste("  Loaded", length(climate_data), "climate datasets"))
    
    return(climate_data)
    
  }, error = function(e) {
    warning(paste("Failed to acquire PRISM data:", e$message))
    return(NULL)
  })
}

#' Acquire wind data from NOAA NCEI Data Service API
#'
#' @param site_coords Numeric vector with [longitude, latitude] - parcel center point
#' @param start_date Start date for data (default: 5 years ago)
#' @param end_date End date for data (default: today)
#' @param cache_dir Directory for cached data
#' @return List with wind data (direction, speed, frequency) - regional data, not parcel-specific
acquire_wind <- function(site_coords, start_date = NULL, end_date = NULL,
                        cache_dir = "data/raw/wind") {
  
  message("Acquiring wind data from NOAA NCEI Data Service API...")
  
  # Set default dates (5 years of data)
  if (is.null(start_date)) {
    start_date <- as.Date(Sys.Date() - lubridate::years(5))
  }
  if (is.null(end_date)) {
    end_date <- Sys.Date()
  }
  
  # Create cache directory
  dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)
  
  # Generate cache file name
  cache_file <- file.path(
    cache_dir,
    paste0("wind_",
           round(site_coords[1], 4), "_", round(site_coords[2], 4), "_",
           format(start_date, "%Y%m%d"), "_", format(end_date, "%Y%m%d"), ".rds")
  )
  
  # Check cache
  if (file.exists(cache_file)) {
    message("Loading wind data from cache...")
    return(readRDS(cache_file))
  }
  
  # Use new NOAA NCEI Data Service API
  base_url <- "https://www.ncei.noaa.gov/access/services/data/v1"
  
  tryCatch({
    # First, find stations near site using bounding box query
    # Create small bounding box around site (0.5 degree = ~50km)
    # Format: North,West,South,East
    bbox_str <- paste(
      site_coords[2] + 0.25,  # North
      site_coords[1] - 0.25,  # West
      site_coords[2] - 0.25,  # South
      site_coords[1] + 0.25,  # East
      sep = ","
    )
    
    # Query for daily summaries
    # Note: NOAA API requires specific station IDs or proper bbox format
    # Try with bbox parameter (not boundingBox) - format: North,West,South,East
    params <- list(
      dataset = "daily-summaries",
      bbox = bbox_str,  # Format: North,West,South,East
      startDate = format(start_date, "%Y-%m-%d"),
      endDate = format(end_date, "%Y-%m-%d"),
      dataTypes = "AWND",  # Average wind speed (more commonly available)
      format = "json",
      limit = 100  # Limit results for testing
    )
    
    # Alternative: Try without bbox first to see available stations
    # If bbox fails, we'll need to find station IDs manually
    
    message("Querying NOAA NCEI Data Service API...")
    response <- httr::GET(base_url, query = params, httr::timeout(30))
    
    if (httr::status_code(response) != 200) {
      warning(paste("NOAA API returned status:", httr::status_code(response)))
      return(NULL)
    }
    
    # Parse JSON response
    content_text <- httr::content(response, as = "text", encoding = "UTF-8")
    api_data <- jsonlite::fromJSON(content_text)
    
    # Check if we got data
    if (is.null(api_data) || length(api_data) == 0) {
      warning("No wind data returned from NOAA API")
      return(NULL)
    }
    
    # Convert to tibble if needed
    if (is.data.frame(api_data)) {
      wind_data <- api_data
    } else if (is.list(api_data) && "results" %in% names(api_data)) {
      wind_data <- api_data$results
    } else {
      wind_data <- tibble::as_tibble(api_data)
    }
    
    # Process wind data
    if (nrow(wind_data) > 0) {
      # Standardize column names (API may vary)
      # Determine date column
      date_col <- if ("DATE" %in% names(wind_data)) "DATE" else 
                  if ("date" %in% names(wind_data)) "date" else
                  if ("Date" %in% names(wind_data)) "Date" else NULL
      
      # Determine wind direction column
      wdir_col <- if ("WIND_DIR" %in% names(wind_data)) "WIND_DIR" else
                   if ("WDIR" %in% names(wind_data)) "WDIR" else
                   if ("wind_direction" %in% names(wind_data)) "wind_direction" else NULL
      
      # Determine wind speed column
      wspd_col <- if ("WIND_SPEED" %in% names(wind_data)) "WIND_SPEED" else
                   if ("WSPD" %in% names(wind_data)) "WSPD" else
                   if ("AWND" %in% names(wind_data)) "AWND" else
                   if ("wind_speed" %in% names(wind_data)) "wind_speed" else NULL
      
      if (is.null(date_col) || is.null(wdir_col) || is.null(wspd_col)) {
        warning("Required columns not found in NOAA API response. Available columns:", 
                paste(names(wind_data), collapse = ", "))
        return(NULL)
      }
      
      wind_processed <- wind_data %>%
        dplyr::mutate(
          date = lubridate::as_date(.data[[date_col]]),
          wind_direction = as.numeric(.data[[wdir_col]]),
          wind_speed = as.numeric(.data[[wspd_col]])
        ) %>%
        dplyr::filter(!is.na(date) & !is.na(wind_direction) & !is.na(wind_speed)) %>%
        dplyr::mutate(
          season = lubridate::quarter(date, fiscal_start = 12),  # Dec=1, Mar=2, Jun=3, Sep=4
          season_name = dplyr::case_when(
            season == 1 ~ "Winter",
            season == 2 ~ "Spring",
            season == 3 ~ "Summer",
            season == 4 ~ "Fall"
          )
        ) %>%
        dplyr::select(date, wind_direction, wind_speed, season, season_name, dplyr::everything())
      
      # Cache the result
      saveRDS(wind_processed, cache_file)
      message(paste("Wind data cached to:", cache_file))
      message(paste("Retrieved", nrow(wind_processed), "records"))
      
      return(wind_processed)
    } else {
      warning("No wind data available for location")
      return(NULL)
    }
    
  }, error = function(e) {
    warning(paste("Failed to acquire wind data:", e$message))
    return(NULL)
  })
}

#' Acquire watershed data from NHDPlus
#'
#' @param site_boundary sf object with site boundary
#' @param cache_dir Directory for cached data
#' @return List with NHDPlus data (streams, waterbodies, watersheds)
acquire_watershed <- function(site_boundary, cache_dir = "data/raw/watersheds") {
  
  message("Acquiring watershed data from NHDPlus...")
  
  # Create cache directory
  dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)
  
  # Generate cache file name
  site_bbox <- sf::st_bbox(site_boundary)
  cache_file <- file.path(
    cache_dir,
    paste0("nhdplus_",
           round(site_bbox$xmin, 4), "_", round(site_bbox$ymin, 4), ".rds")
  )
  
  # Check cache
  if (file.exists(cache_file)) {
    message("Loading NHDPlus data from cache...")
    return(readRDS(cache_file))
  }
  
  # Get NHDPlus data
  tryCatch({
    # Use nhdplusTools to get NHD data
    # Check if get_nhdplus returns data or NULL
    # Note: For very small parcels, NHDPlus may not have data
    nhd_data <- tryCatch({
      result <- nhdplusTools::get_nhdplus(
        AOI = site_boundary,
        realization = "flowline"  # Get flowlines (streams)
      )
      # Check if result is valid
      if (is.null(result) || (inherits(result, "sf") && nrow(result) == 0)) {
        return(NULL)
      }
      return(result)
    }, error = function(e) {
      warning(paste("NHDPlus flowline error:", e$message))
      return(NULL)
    })
    
    # Also get waterbodies if available
    nhd_waterbodies <- tryCatch({
      nhdplusTools::get_nhdplus(
        AOI = site_boundary,
        realization = "waterbody"
      )
    }, error = function(e) {
      return(NULL)
    })
    
    # Check if we got any data
    if (is.null(nhd_data) && is.null(nhd_waterbodies)) {
      warning("No NHDPlus data available for this location")
      return(NULL)
    }
    
    # Compile results
    watershed_data <- list(
      flowlines = nhd_data,
      waterbodies = nhd_waterbodies
    )
    
    # Cache the result
    saveRDS(watershed_data, cache_file)
    message(paste("NHDPlus data cached to:", cache_file))
    
    return(watershed_data)
    
  }, error = function(e) {
    warning(paste("Failed to acquire NHDPlus data:", e$message))
    return(NULL)
  })
}

#' Acquire ecoregion data
#'
#' @param site_boundary sf object with site boundary
#' @param level Ecoregion level: "III" or "IV" (default: "III")
#' @param cache_dir Directory for cached data
#' @return sf object with ecoregion polygons
acquire_ecoregion <- function(site_boundary, level = "III", cache_dir = "data/raw/ecoregions") {
  
  message(paste("Acquiring ecoregion data (Level", level, ")..."))
  
  # Create cache directory
  dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)
  
  # Generate cache file name
  site_bbox <- sf::st_bbox(site_boundary)
  cache_file <- file.path(
    cache_dir,
    paste0("ecoregion_level", level, "_",
           round(site_bbox$xmin, 4), "_", round(site_bbox$ymin, 4), ".rds")
  )
  
  # Check cache
  if (file.exists(cache_file)) {
    message("Loading ecoregion data from cache...")
    return(readRDS(cache_file))
  }
  
  # Try to get ecoregion data using FedData
  tryCatch({
    # FedData may have ecoregion download capability
    # For now, we'll use a manual approach or FedData if available
    # Note: This may need to be implemented based on actual FedData capabilities
    
    # Alternative: Download EPA shapefile and load
    # For now, return NULL and note that manual download may be needed
    warning("Ecoregion data acquisition not fully implemented. May require manual download from EPA.")
    return(NULL)
    
  }, error = function(e) {
    warning(paste("Failed to acquire ecoregion data:", e$message))
    return(NULL)
  })
}

#' Acquire flood zone data from FEMA
#'
#' @param site_boundary sf object with site boundary
#' @param cache_dir Directory for cached data
#' @return sf object with flood zone polygons
acquire_flood_zones <- function(site_boundary, cache_dir = "data/raw/flood_zones") {
  
  message("Acquiring flood zone data from FEMA...")
  
  # Create cache directory
  dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)
  
  # Generate cache file name
  site_bbox <- sf::st_bbox(site_boundary)
  cache_file <- file.path(
    cache_dir,
    paste0("fema_flood_zones_",
           round(site_bbox$xmin, 4), "_", round(site_bbox$ymin, 4), ".rds")
  )
  
  # Check cache
  if (file.exists(cache_file)) {
    message("Loading FEMA flood zone data from cache...")
    return(readRDS(cache_file))
  }
  
  # FEMA provides ArcGIS REST service
  # Try different approaches - FEMA API may require different endpoints
  # First try the main service endpoint
  base_url <- "https://hazards.fema.gov/gis/nfhl/rest/services/public/NFHL/MapServer/0/query"
  
  # Alternative: Try the public service without layer number
  # base_url <- "https://hazards.fema.gov/gis/nfhl/rest/services/public/NFHL/MapServer/query"
  
  tryCatch({
    # Create bounding box for query
    bbox <- sf::st_bbox(site_boundary)
    
    # Query parameters - FEMA API format
    params <- list(
      f = "geojson",
      where = "1=1",  # Get all features in extent
      geometry = paste0(bbox$xmin, ",", bbox$ymin, ",", bbox$xmax, ",", bbox$ymax),
      geometryType = "esriEnvelope",
      inSR = "4326",
      outSR = "4326",
      returnGeometry = "true",
      outFields = "*"  # Get all fields
    )
    
    # Make API request
    response <- httr::GET(base_url, query = params)
    
    if (httr::status_code(response) == 200) {
      # Parse GeoJSON response
      content <- httr::content(response, as = "text", encoding = "UTF-8")
      
      # Check if content is valid
      if (nchar(content) == 0 || content == "{}") {
        warning("FEMA API returned empty response - no flood zone data for this location")
        return(NULL)
      }
      
      flood_zones <- sf::st_read(content, quiet = TRUE)
      
      # Check if we got any features
      if (nrow(flood_zones) == 0) {
        warning("No flood zone features found for this location")
        return(NULL)
      }
      
      # Cache the result
      saveRDS(flood_zones, cache_file)
      message(paste("FEMA flood zone data cached to:", cache_file))
      
      return(flood_zones)
    } else if (httr::status_code(response) == 404) {
      # 404 might mean no data for this location, not necessarily an error
      warning("FEMA flood zone data not available for this location (404)")
      return(NULL)
    } else {
      warning(paste("FEMA API returned status:", httr::status_code(response)))
      return(NULL)
    }
    
  }, error = function(e) {
    warning(paste("Failed to acquire FEMA flood zone data:", e$message))
    return(NULL)
  })
}

#' Acquire canopy height data (if available)
#'
#' @param site_boundary sf object with site boundary
#' @param cache_dir Directory for cached data
#' @return SpatRaster object with canopy height (or NULL if not available)
acquire_canopy <- function(site_boundary, cache_dir = "data/raw/canopy") {
  
  message("Checking for canopy height data...")
  
  # Create cache directory
  dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)
  
  # Generate cache file name
  site_bbox <- sf::st_bbox(site_boundary)
  cache_file <- file.path(
    cache_dir,
    paste0("canopy_height_",
           round(site_bbox$xmin, 4), "_", round(site_bbox$ymin, 4), ".tif")
  )
  
  # Check cache
  if (file.exists(cache_file)) {
    message("Loading canopy height data from cache...")
    return(terra::rast(cache_file))
  }
  
  # Canopy height data availability varies
  # This is a placeholder - implementation depends on data source
  message("Canopy height data not yet implemented. Check USGS 3DEP LiDAR availability.")
  return(NULL)
}

