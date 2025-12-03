# Package Installation and Dependency Check Script
# Verifies all required packages are installed and checks for issues

# Load here package first (needed for paths)
if (!requireNamespace("here", quietly = TRUE)) {
  install.packages("here")
}
library(here)

# Function to check if a package is installed
check_package <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    return(list(installed = FALSE, loaded = FALSE, error = "Not installed"))
  }
  
  # Try to load the package
  result <- tryCatch({
    suppressPackageStartupMessages(library(pkg, character.only = TRUE))
    list(installed = TRUE, loaded = TRUE, error = NULL)
  }, error = function(e) {
    list(installed = TRUE, loaded = FALSE, error = e$message)
  })
  
  return(result)
}

# Get package list from setup script
source(here::here("R", "scripts", "0-setUp.R"), local = TRUE)

# Since 0-setUp.R defines libs, we need to extract it
# Let's read it directly to get the package list
setup_lines <- readLines(here::here("R", "scripts", "0-setUp.R"))

# Extract package lists (this is a bit hacky but works)
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
  # Note: 'raster' removed - FedData v4 uses 'terra' instead
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

# Combine all packages
all_packages <- unique(sort(c(
  tidyverse_packages, viz_packages, spatial_packages, climate_packages,
  soil_packages, hydro_packages, data_packages, doc_packages,
  shiny_packages, api_packages, util_packages
)))

cat("Checking", length(all_packages), "packages...\n\n")

# Check each package
results <- list()
missing <- character()
failed_load <- character()

for (pkg in all_packages) {
  cat("Checking", pkg, "... ")
  result <- check_package(pkg)
  results[[pkg]] <- result
  
  if (!result$installed) {
    cat("❌ NOT INSTALLED\n")
    missing <- c(missing, pkg)
  } else if (!result$loaded) {
    cat("⚠️  INSTALLED BUT FAILED TO LOAD:", result$error, "\n")
    failed_load <- c(failed_load, pkg)
  } else {
    cat("✅ OK\n")
  }
}

# Summary
cat("\n" , "=", rep("=", 50), "\n", sep = "")
cat("SUMMARY\n")
cat("=", rep("=", 50), "\n", sep = "")

cat("\nTotal packages checked:", length(all_packages), "\n")
cat("✅ Installed and loaded:", length(all_packages) - length(missing) - length(failed_load), "\n")

if (length(missing) > 0) {
  cat("❌ Missing packages (", length(missing), "):\n", sep = "")
  cat("  ", paste(missing, collapse = ", "), "\n\n")
  
  # Special handling for packages that may need source installation
  special_packages <- c("FedData", "arcgislayers")
  regular_packages <- setdiff(missing, special_packages)
  
  if (length(regular_packages) > 0) {
    cat("To install regular packages, run:\n")
    cat("  install.packages(c(", paste0('"', regular_packages, '"', collapse = ", "), "))\n\n")
  }
  
  if (any(special_packages %in% missing)) {
    cat("⚠️  Special installation needed for:\n")
    if ("FedData" %in% missing) {
      cat("  - FedData: May need to install from source or GitHub\n")
      cat("    Try: install.packages('FedData', type = 'source')\n")
      cat("    Or:  devtools::install_github('ropensci/FedData')\n\n")
    }
    if ("arcgislayers" %in% missing) {
      cat("  - arcgislayers: Dependency of FedData\n")
      cat("    Will be installed when FedData is installed\n\n")
    }
  }
}

if (length(failed_load) > 0) {
  cat("⚠️  Failed to load (", length(failed_load), "):\n", sep = "")
  for (pkg in failed_load) {
    cat("  -", pkg, ":", results[[pkg]]$error, "\n")
  }
  cat("\n")
}

# Check for common dependency issues
cat("\nChecking for common dependency issues...\n")

# Check if here package is available (needed for paths)
if (!requireNamespace("here", quietly = TRUE)) {
  cat("⚠️  'here' package not available - using getwd() instead\n")
  # Define here::here as a fallback
  if (!exists("here")) {
    here <- list(here = function(...) file.path(getwd(), ...))
  }
}

# Check R version (some packages require newer R)
r_version <- R.version.string
cat("R version:", r_version, "\n")

# Check if quarto is available
if (requireNamespace("quarto", quietly = TRUE)) {
  tryCatch({
    quarto_version <- quarto::quarto_path()
    cat("✅ Quarto found at:", quarto_version, "\n")
  }, error = function(e) {
    cat("⚠️  Quarto package installed but quarto binary not found\n")
    cat("   Install Quarto from: https://quarto.org/docs/get-started/\n")
  })
} else {
  cat("❌ Quarto package not installed\n")
}

cat("\n" , "=", rep("=", 50), "\n", sep = "")

if (length(missing) == 0 && length(failed_load) == 0) {
  cat("✅ All packages are installed and loading correctly!\n")
} else {
  cat("⚠️  Some packages need attention. See details above.\n")
}

