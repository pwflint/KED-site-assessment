# Comprehensive Package Loading Test
# Tests all required packages load correctly with their dependencies

cat("=", rep("=", 60), "\n", sep = "")
cat("COMPREHENSIVE PACKAGE LOADING TEST\n")
cat("=", rep("=", 60), "\n\n")

# Load here package first (needed for paths)
if (!requireNamespace("here", quietly = TRUE)) {
  stop("'here' package is required. Install with: install.packages('here')")
}
library(here)

# Get package list from setup script
# Read setup script and extract package lists
setup_file <- here::here("R", "scripts", "0-setUp.R")
setup_env <- new.env()
source(setup_file, local = setup_env)

# Get the libs vector (defined in 0-setUp.R)
all_packages <- setup_env$libs

# If libs not found, define package lists directly
if (is.null(all_packages)) {
  tidyverse_packages <- c("tidyverse")
  viz_packages <- c(
    "patchwork", "cowplot", "ggtext", "ggrepel", "scales",
    "grid", "grDevices", "colorspace", "viridis", "RColorBrewer", 
    "rcartocolor", "scico", "ggsci", "ggthemes", "nord", "MetBrewer",
    "ggforce", "ggdist", "ggbeeswarm", "gghalves", "colorblindr",
    "rayshader"
  )
  spatial_packages <- c(
    "sf", "terra", "stars", "rnaturalearth", "rmapshaper", 
    "ggspatial", "maps", "mapdata"
  )
  climate_packages <- c(
    "rnoaa", "prism", "rWind", "circular"
  )
  soil_packages <- c(
    "FedData", "soilDB", "aqp"
  )
  hydro_packages <- c(
    "nhdplusTools", "whitebox"
  )
  data_packages <- c(
    "readxl", "here", "yaml"
  )
  doc_packages <- c(
    "quarto", "gridExtra", "gt", "kableExtra", "magick"
  )
  shiny_packages <- c(
    "shiny", "bslib", "shinycssloaders", "shinyjs", "shinyWidgets",
    "DT", "leaflet", "tidygeocoder", "shinybusy", "waiter"
  )
  api_packages <- c(
    "httr", "jsonlite", "xml2"
  )
  util_packages <- c(
    "devtools", "usethis", "config"
  )
  
  all_packages <- unique(sort(c(
    tidyverse_packages, viz_packages, spatial_packages, climate_packages,
    soil_packages, hydro_packages, data_packages, doc_packages,
    shiny_packages, api_packages, util_packages
  )))
}

cat("Testing", length(all_packages), "packages...\n\n")

# Track results
results <- list()
failed_packages <- character()
warnings_packages <- character()

# Test loading each package
for (pkg in all_packages) {
  cat("Testing", pkg, "... ")
  
  # Check if installed
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat("❌ NOT INSTALLED\n")
    failed_packages <- c(failed_packages, pkg)
    results[[pkg]] <- list(status = "not_installed", error = "Package not installed")
    next
  }
  
  # Try to load
  load_result <- tryCatch({
    suppressPackageStartupMessages({
      library(pkg, character.only = TRUE)
    })
    list(status = "success", error = NULL)
  }, warning = function(w) {
    list(status = "warning", error = w$message)
  }, error = function(e) {
    list(status = "error", error = e$message)
  })
  
  results[[pkg]] <- load_result
  
  if (load_result$status == "success") {
    cat("✅ OK\n")
  } else if (load_result$status == "warning") {
    cat("⚠️  WARNING\n")
    warnings_packages <- c(warnings_packages, pkg)
  } else {
    cat("❌ FAILED\n")
    failed_packages <- c(failed_packages, pkg)
  }
}

# Test key package combinations (common dependency issues)
cat("\n", "=", rep("=", 60), "\n", sep = "")
cat("TESTING KEY PACKAGE COMBINATIONS\n")
cat("=", rep("=", 60), "\n\n")

# Test spatial packages together
cat("Testing spatial packages (sf, terra)... ")
tryCatch({
  if (requireNamespace("sf", quietly = TRUE) && requireNamespace("terra", quietly = TRUE)) {
    library(sf)
    library(terra)
    # Test basic functionality
    test_point <- st_point(c(0, 0))
    test_raster <- rast(nrows = 10, ncols = 10)
    cat("✅ OK\n")
  } else {
    cat("⚠️  Some packages missing\n")
  }
}, error = function(e) {
  cat("❌ FAILED:", e$message, "\n")
})

# Test tidyverse
cat("Testing tidyverse... ")
tryCatch({
  library(tidyverse)
  # Test basic functionality
  test_df <- tibble(x = 1:5, y = 6:10)
  test_df %>% filter(x > 2)
  cat("✅ OK\n")
}, error = function(e) {
  cat("❌ FAILED:", e$message, "\n")
})

# Test FedData
cat("Testing FedData... ")
tryCatch({
  library(FedData)
  cat("✅ OK\n")
}, error = function(e) {
  cat("❌ FAILED:", e$message, "\n")
})

# Test Quarto
cat("Testing Quarto... ")
tryCatch({
  if (requireNamespace("quarto", quietly = TRUE)) {
    library(quarto)
    quarto_path <- tryCatch(quarto::quarto_path(), error = function(e) NULL)
    if (!is.null(quarto_path)) {
      cat("✅ OK (found at:", quarto_path, ")\n")
    } else {
      cat("⚠️  Package loaded but quarto binary not found\n")
    }
  } else {
    cat("❌ NOT INSTALLED\n")
  }
}, error = function(e) {
  cat("❌ FAILED:", e$message, "\n")
})

# Summary
cat("\n", "=", rep("=", 60), "\n", sep = "")
cat("SUMMARY\n")
cat("=", rep("=", 60), "\n\n")

cat("Total packages tested:", length(all_packages), "\n")
cat("✅ Successfully loaded:", length(all_packages) - length(failed_packages) - length(warnings_packages), "\n")

if (length(warnings_packages) > 0) {
  cat("⚠️  Loaded with warnings:", length(warnings_packages), "\n")
  for (pkg in warnings_packages) {
    cat("   -", pkg, ":", results[[pkg]]$error, "\n")
  }
  cat("\n")
}

if (length(failed_packages) > 0) {
  cat("❌ Failed to load:", length(failed_packages), "\n")
  for (pkg in failed_packages) {
    cat("   -", pkg, ":", results[[pkg]]$error, "\n")
  }
  cat("\n")
  cat("To fix failed packages:\n")
  cat("  source('R/utils/installSpecialPackages.R')\n")
  cat("  # Or manually: install.packages(c(", 
      paste0('"', failed_packages, '"', collapse = ", "), "))\n\n")
} else {
  cat("\n✅ ALL PACKAGES LOADED SUCCESSFULLY!\n")
  cat("   Ready to proceed with core workflow development.\n\n")
}

# Check for common issues
cat("=", rep("=", 60), "\n", sep = "")
cat("ADDITIONAL CHECKS\n")
cat("=", rep("=", 60), "\n\n")

# Check R version
cat("R version:", R.version.string, "\n")

# Check if here package is working
cat("Project root:", here::here(), "\n")

# Check if key directories exist
key_dirs <- c("R/functions", "R/scripts", "data/raw", "data/processed", "output")
cat("\nChecking project structure...\n")
for (dir in key_dirs) {
  if (dir.exists(here::here(dir))) {
    cat("  ✅", dir, "\n")
  } else {
    cat("  ⚠️ ", dir, "(missing)\n")
  }
}

cat("\n", "=", rep("=", 60), "\n", sep = "")
cat("TEST COMPLETE\n")
cat("=", rep("=", 60), "\n\n")

if (length(failed_packages) == 0) {
  cat("✅ All packages are ready for development!\n")
} else {
  cat("⚠️  Fix failed packages before proceeding.\n")
}

