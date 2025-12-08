# Test Data Acquisition Workflow
# Tests the complete data acquisition process with a test site

cat("=", rep("=", 60), "\n", sep = "")
cat("DATA ACQUISITION WORKFLOW TEST\n")
cat("=", rep("=", 60), "\n\n")

# Load required packages
if (!requireNamespace("here", quietly = TRUE)) {
  stop("'here' package is required")
}
library(here)

# Source setup script
source(here::here("R", "scripts", "0-setUp.R"))

# Source helper functions and main acquisition script
cat("Loading helper functions...\n")
source(here::here("R", "functions", "apiHelpers.R"))
source(here::here("R", "functions", "dataHelpers.R"))
source(here::here("R", "functions", "dataAcquisitionHelpers.R"))
source(here::here("R", "functions", "mapHelpers.R"))  # For visualization helpers
source(here::here("R", "scripts", "1-dataAcquisition.R"))  # Contains acquire_site_data()

# Load test site metadata
cat("\nLoading test site metadata...\n")
test_metadata_path <- here::here("data", "siteInfo", "siteMetadata_test_NC.yaml")

if (!file.exists(test_metadata_path)) {
  stop(paste("Test metadata file not found:", test_metadata_path))
}

metadata <- load_site_metadata(test_metadata_path)
cat("✅ Metadata loaded\n")
cat("  Site:", metadata$site$address, "\n")
cat("  Coordinates:", metadata$site$latitude, ",", metadata$site$longitude, "\n\n")

# Test data acquisition
cat("=", rep("=", 60), "\n", sep = "")
cat("STARTING DATA ACQUISITION TEST\n")
cat("=", rep("=", 60), "\n\n")
cat("Note: This may take several minutes depending on data source availability.\n")
cat("Data will be cached for future use.\n\n")

# Run data acquisition
tryCatch({
  data_list <- acquire_site_data(metadata, cache_dir = "data/raw")
  
  cat("\n", "=", rep("=", 60), "\n", sep = "")
  cat("DATA ACQUISITION TEST RESULTS\n")
  cat("=", rep("=", 60), "\n\n")
  
  # Summary of acquired data
  for (i in seq_along(data_list)) {
    data_name <- names(data_list)[i]
    data_obj <- data_list[[i]]
    
    if (is.null(data_obj)) {
      cat("  ❌", data_name, ": Not acquired\n")
    } else {
      # Get data type and size info
      if (inherits(data_obj, "SpatRaster")) {
        cat("  ✅", data_name, ": SpatRaster", 
            paste0("(", terra::nrow(data_obj), "x", terra::ncol(data_obj), ")\n"))
      } else if (inherits(data_obj, "sf")) {
        cat("  ✅", data_name, ": sf object", 
            paste0("(", nrow(data_obj), " features)\n"))
      } else if (tibble::is_tibble(data_obj) || is.data.frame(data_obj)) {
        cat("  ✅", data_name, ": Data frame", 
            paste0("(", nrow(data_obj), " rows, ", ncol(data_obj), " cols)\n"))
      } else if (is.list(data_obj)) {
        cat("  ✅", data_name, ": List", 
            paste0("(", length(data_obj), " elements)\n"))
      } else {
        cat("  ✅", data_name, ": Acquired (type:", class(data_obj)[1], ")\n")
      }
    }
  }
  
  cat("\n✅ Data acquisition test complete!\n")
  cat("   Check data/raw/ directory for cached data files.\n\n")
  
  # Optional: Create quick visualization of acquired data (parcel-scale)
  cat("=", rep("=", 60), "\n", sep = "")
  cat("DATA SUMMARY\n")
  cat("=", rep("=", 60), "\n\n")
  
  tryCatch({
    # Create site boundary for reference
    site_boundary <- create_site_boundary(metadata)
    
    # DEM summary and plot (parcel-scale)
    if (!is.null(data_list$dem) && inherits(data_list$dem, "SpatRaster")) {
      cat("DEM Summary:\n")
      cat("  Extent:", paste(round(terra::ext(data_list$dem)[1:4], 4), collapse = ", "), "\n")
      cat("  Dimensions:", terra::nrow(data_list$dem), "x", terra::ncol(data_list$dem), "\n")
      cat("  Resolution:", paste(round(terra::res(data_list$dem), 2), collapse = " x "), "m\n")
      cat("  Elevation range:", round(terra::minmax(data_list$dem)[1], 1), "-", 
          round(terra::minmax(data_list$dem)[2], 1), "m\n")
      
      # Plot DEM with proper visualization using ggplot2
      cat("\nPlotting DEM (parcel-scale with context)...\n")
      
      # Convert DEM to data frame for ggplot
      dem_df <- raster_to_tibble(data_list$dem, value_name = "elevation")
      
      # Create base map with context
      dem_plot <- ggplot2::ggplot() +
        ggplot2::geom_raster(data = dem_df, 
                            ggplot2::aes(x = x, y = y, fill = elevation)) +
        ggplot2::scale_fill_viridis_c(name = "Elevation\n(meters)", 
                                     option = "viridis",  # Changed from "terrain" (not available)
                                     guide = ggplot2::guide_colorbar(
                                       title.position = "top",
                                       barwidth = unit(0.5, "cm"),
                                       barheight = unit(3, "cm")
                                     )) +
        ggplot2::geom_sf(data = site_boundary, 
                        fill = NA, 
                        color = "red", 
                        linewidth = 1.5,
                        linetype = "dashed") +
        ggplot2::coord_sf(crs = sf::st_crs(site_boundary), expand = FALSE) +
        ggplot2::labs(
          title = "Digital Elevation Model (DEM)",
          subtitle = paste0("Site: ", metadata$site$address),
          x = "Longitude",
          y = "Latitude",
          caption = "Data Source: USGS 3DEP"
        ) +
        ggplot2::theme_minimal() +
        ggplot2::theme(
          plot.title = ggplot2::element_text(size = 14, face = "bold"),
          plot.subtitle = ggplot2::element_text(size = 10, color = "gray40"),
          legend.position = "right",
          legend.title = ggplot2::element_text(size = 10),
          axis.text = ggplot2::element_text(size = 8),
          plot.caption = ggplot2::element_text(size = 8, color = "gray60", hjust = 1)
        )
      
      # Add scale bar and north arrow
      dem_plot <- add_scale_bar(dem_plot, location = "bl")
      dem_plot <- add_north_arrow(dem_plot, location = "tr")
      
      print(dem_plot)
      cat("  ✅ DEM plot created with legend and context\n\n")
    }
    
    # Soils summary (no spatial plot - just data)
    if (!is.null(data_list$soils)) {
      cat("Soils Summary:\n")
      if (is.list(data_list$soils) && "spatial" %in% names(data_list$soils)) {
        soils_spatial <- data_list$soils$spatial
        cat("  Map units found:", length(unique(soils_spatial$MUKEY %||% soils_spatial$mukey %||% "unknown")), "\n")
        if ("tabular" %in% names(data_list$soils)) {
          cat("  Soil data tables available:", length(data_list$soils$tabular), "\n")
        }
        cat("  (Soil properties will be extracted for analysis, not plotted)\n\n")
      } else {
        cat("  Soil data structure:", class(data_list$soils), "\n\n")
      }
    }
    
    # Watershed summary
    if (!is.null(data_list$watershed) && is.list(data_list$watershed)) {
      cat("Watershed Summary:\n")
      if (!is.null(data_list$watershed$flowlines)) {
        cat("  Flowlines:", nrow(data_list$watershed$flowlines), "\n")
      }
      if (!is.null(data_list$watershed$waterbodies)) {
        cat("  Waterbodies:", nrow(data_list$watershed$waterbodies), "\n")
      }
      cat("\n")
    }
    
    # Climate summary
    if (!is.null(data_list$climate) && is.list(data_list$climate)) {
      cat("Climate Summary:\n")
      if (length(data_list$climate) > 0) {
        cat("  Climate datasets loaded:", length(data_list$climate), "\n")
        cat("  Variables:", paste(names(data_list$climate), collapse = ", "), "\n")
      } else {
        cat("  ⚠️  Climate data structure empty - may need to check PRISM archive\n")
      }
      cat("\n")
    }
    
    cat("✅ Data summary complete!\n")
    cat("   Note: Visualization focuses on parcel-scale data.\n")
    cat("   Soil properties will be extracted for analysis, not spatial plotting.\n")
    cat("   Some data sources may not have data for this location (e.g., FEMA if not in flood zone).\n\n")
    
  }, error = function(e) {
    cat("⚠️  Summary failed (non-critical):", e$message, "\n")
    cat("   Data acquisition was successful, but summary could not be created.\n\n")
  })
  
}, error = function(e) {
  cat("\n❌ Data acquisition test failed:\n")
  cat("   Error:", e$message, "\n")
  cat("   Check error messages above for details.\n\n")
})

