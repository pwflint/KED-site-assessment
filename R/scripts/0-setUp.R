# Three step to loading necessary packages for a project
# Create list of necessary packages

# Tidyverse (core data manipulation and visualization)
# Includes: dplyr, tidyr, readr, purrr, tibble, stringr, forcats, lubridate, ggplot2
tidyverse_packages <- c("tidyverse")

# Core Visualization & Design (beyond ggplot2 in tidyverse)
viz_packages <- c(
  "patchwork", "cowplot", "ggtext", "ggrepel", "scales",
  "grid", "grDevices", "colorspace", "viridis", "RColorBrewer", 
  "rcartocolor", "scico", "ggsci", "ggthemes", "nord", "MetBrewer",
  "ggforce", "ggdist", "ggbeeswarm", "gghalves", "colorblindr",
  "rayshader"  # 3D visualization for canopy heights
)

# Spatial Data & Mapping
spatial_packages <- c(
  "sf", "terra", "stars", "rnaturalearth", "rmapshaper", 
  "ggspatial", "maps", "mapdata", "elevatr"  # elevatr for USGS 3DEP DEM access
)

# Climate & Weather Data
climate_packages <- c(
  "rnoaa", "prism", "rWind", "circular"
)

# Soil Data
soil_packages <- c(
  "FedData", "soilDB", "aqp"
)

# Hydrology
hydro_packages <- c(
  "nhdplusTools", "whitebox"
  # Note: 'raster' removed - FedData v4 uses 'terra' instead
  # 'raster' kept as optional if needed for legacy code, but prefer 'terra'
)

# Additional Data Management (beyond tidyverse)
data_packages <- c(
  "readxl", "here", "yaml"
)

# Document Generation (Quarto workflow)
doc_packages <- c(
  "quarto", "gridExtra", "gt", "kableExtra", "magick"
)

# Shiny Application Framework
shiny_packages <- c(
  "shiny",                    # Core Shiny framework
  "bslib",                    # Modern Bootstrap-based UI (or shinydashboard)
  "shinycssloaders",          # Loading spinners
  "shinyjs",                  # Enhanced JavaScript functionality
  "shinyWidgets",             # Enhanced input widgets
  "DT",                       # Interactive data tables
  "leaflet",                  # Interactive maps for site selection
  "tidygeocoder",            # Address geocoding (address → coordinates)
  "shinybusy",               # Busy indicators
  "waiter"                    # Loading screens
)

# API & Web Data Access
api_packages <- c(
  "httr", "jsonlite", "xml2"  # For REST API access
)

# Utilities
util_packages <- c(
  "devtools", "usethis", "config"
)

# Combine all packages
libs <- c(
  tidyverse_packages, viz_packages, spatial_packages, climate_packages, 
  soil_packages, hydro_packages, data_packages, doc_packages, 
  api_packages, util_packages, shiny_packages
)

# Remove duplicates and sort
libs <- unique(sort(libs))

# Query whether packages are installed
installed_libs <- libs %in% rownames(
  installed.packages()
)

if(any(installed_libs == FALSE)){
  install.packages(
    libs[!installed_libs]
  )
}

# Load packages in R-session
invisible(lapply(libs, 
                 library, 
                 character.only = TRUE)
)

