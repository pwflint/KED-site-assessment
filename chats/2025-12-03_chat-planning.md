# Planning site assessment product details
_Exported on 12/3/2025 at 10:44:34 EST from Cursor (2.1.46)_

---

**User**

Let's begin planning a site assessment product for my landscape design business. @Site Assessment Report.md  provides an overview of the product. The rest of the codebase contains the basic directory structure and some examples of the code and processes I would like to use, but we will need to refine which packages we will be using in the planning process,

---

**Cursor**


Reviewing the codebase to understand the current structure and examples, then drafting a plan for the site assessment product.



Reviewing additional files to understand the project structure:



Creating a planning document for the site assessment product, outlining package requirements, data sources, and technical architecture.


```markdown
# Site Assessment Report - Technical Planning Document

## Overview

This document outlines the technical architecture, package requirements, and implementation strategy for generating professional site assessment reports for landscape design projects.

**Output Format:** 11x17 document or interactive tablet landscape document  
**Primary Tool:** R with ggplot2 for visualization  
**Design Philosophy:** Clean, professional, data-transparent environmental records

---

## 1. Package Requirements by Report Section

### Core Visualization & Design
- **ggplot2** - Primary plotting engine
- **patchwork** - Multi-panel layout composition
- **cowplot** - Advanced plot arrangement and annotations
- **ggtext** - Rich text formatting in plots
- **ggrepel** - Smart label placement
- **scales** - Axis formatting and transformations
- **colorspace** / **viridis** / **RColorBrewer** / **scico** - Color palettes
- **systemfonts** - Custom font management (Boska, Cabinet Grotesk, Pally, Tabular)

### Spatial Data & Mapping
- **sf** - Spatial data handling (CRS, geometries, spatial operations)
- **terra** - Raster data (DEM, slope, aspect calculations)
- **stars** - Alternative raster package (if needed)
- **rnaturalearth** - Base maps (countries, states, coastlines)
- **rmapshaper** - Spatial data simplification
- **tmap** - Thematic mapping (alternative/complement to ggplot2)
- **ggspatial** - Spatial annotations (scale bars, north arrows, inset maps)
- **maps** / **mapdata** - Additional base map data

### Climate & Weather Data
- **rnoaa** - NOAA climate data access
- **prism** - PRISM climate data (temperature, precipitation)
- **rWind** - Wind data processing and wind rose creation
- **circular** - Circular statistics for wind direction

### Soil Data
- **FedData** - Access to SSURGO soil data
- **soilDB** - Soil Survey Database queries
- **aqp** - Soil profile analysis and visualization

### Hydrology
- **nhdplusTools** - NHD Plus data and watershed delineation
- **whitebox** - Advanced terrain analysis (flow accumulation, watersheds)
- **raster** - Raster operations (may complement terra)

### Data Management
- **readr** / **readxl** - Data import
- **dplyr** / **tidyr** - Data manipulation
- **tibble** - Modern data frames
- **here** - Project path management
- **lubridate** - Date handling
- **stringr** - String manipulation
- **forcats** - Factor management

### Document Generation
- **rmarkdown** - Report generation
- **knitr** - Code execution in documents
- **grid** / **gridExtra** - Advanced layout (tables, complex arrangements)
- **gt** / **kableExtra** - Professional table formatting
- **magick** - Image manipulation and composition

### Utilities
- **devtools** - Package development and installation
- **usethis** - Project setup utilities
- **config** - Configuration management
- **yaml** - YAML parsing for metadata

---

## 2. Data Sources & Acquisition Strategy

### Required Data Types

#### 2.1 Elevation & Topography
- **Source:** USGS 3D Elevation Program (3DEP)
- **Format:** Digital Elevation Model (DEM)
- **Resolution:** 1m, 3m, or 10m depending on site size
- **Access Methods:**
  - `elevatr` package - Direct download
  - `FedData` package - USGS data access
  - Manual download from USGS National Map

#### 2.2 Watershed & Hydrology
- **Source:** USGS National Hydrography Dataset (NHD)
- **Format:** Vector (streams, waterbodies)
- **Access:** `nhdplusTools` or `FedData`
- **Watershed Delineation:** Calculate from DEM using `whitebox` or `raster`

#### 2.3 Ecoregions
- **Source:** EPA Ecoregions (Level III/IV)
- **Format:** Shapefile
- **Access:** Download from EPA website or use `FedData`

#### 2.4 Soils
- **Source:** NRCS SSURGO (Soil Survey Geographic Database)
- **Format:** Spatial polygons with attribute tables
- **Access:** `FedData::get_ssurgo()` or `soilDB` package
- **Required Attributes:**
  - Map unit name
  - Texture class
  - Drainage class
  - Hydrologic group
  - Permeability

#### 2.5 Climate Data
- **Source:** PRISM Climate Group (Oregon State)
- **Format:** Raster grids (monthly/annual normals)
- **Access:** `prism` package
- **Variables:**
  - Mean temperature (monthly/annual)
  - Precipitation (monthly/annual)
  - Potential evapotranspiration (if available)

#### 2.6 Wind Data
- **Source:** NOAA NCEI (National Centers for Environmental Information)
- **Format:** Time series data
- **Access:** `rnoaa` package or manual download
- **Required:** Direction, speed, frequency by season

#### 2.7 Flood Zones
- **Source:** FEMA Flood Map Service Center
- **Format:** Shapefile
- **Access:** Manual download or `FedData` (if available)

#### 2.8 Base Maps
- **Source:** OpenStreetMap, USGS, Natural Earth
- **Format:** Vector/raster tiles
- **Access:** `osmdata`, `rnaturalearth`, `ggmap` (if needed)

---

## 3. Script Architecture & Workflow

### Proposed Directory Structure

```
ggplot-GraphicDesign/
├── scripts/
│   ├── 0-setUp.R                    # Package installation & loading
│   ├── 1-dataAcquisition.R          # Download & cache all data sources
│   ├── 2-dataProcessing.R           # Process raw data into analysis-ready formats
│   ├── 3-coverSheet.R               # Generate cover sheet
│   ├── 4-regionalContext.R           # Section 1: Regional orientation
│   ├── 5-topography.R               # Section 2: Topography & landform
│   ├── 6-hydrology.R                # Section 3: Hydrology & drainage
│   ├── 7-climate.R                  # Section 4: Climate & wind
│   ├── 8-soils.R                    # Section 5: Soils & infiltration
│   ├── 9-vulnerabilities.R          # Section 6: Vulnerabilities & opportunities
│   ├── 10-dataTables.R              # Section 7: Supporting data tables
│   ├── 11-summary.R                 # Section 8: Summary & next steps
│   └── 99-renderReport.R             # Master script to generate full report
├── data/
│   ├── raw/                         # Raw downloaded data
│   │   ├── dem/
│   │   ├── soils/
│   │   ├── climate/
│   │   ├── watersheds/
│   │   └── ecoregions/
│   ├── processed/                   # Processed/analysis-ready data
│   └── siteInfo/                    # Site-specific metadata (YAML/CSV)
├── functions/
│   ├── mapHelpers.R                 # Reusable mapping functions
│   ├── themeCustom.R                # Custom ggplot themes
│   ├── dataHelpers.R                # Data processing utilities
│   └── tableHelpers.R               # Table formatting functions
├── templates/
│   ├── reportTemplate.Rmd           # R Markdown template
│   └── layoutTemplates.R            # Layout specifications
└── output/
    ├── reports/                     # Generated reports
    ├── figures/                     # Individual figure exports
    └── cache/                       # Cached computations
```

### Workflow Process

1. **Site Information Input**
   - Create site metadata file (YAML or CSV)
   - Contains: client name, address, lat/long, parcel boundary, project date

2. **Data Acquisition** (`1-dataAcquisition.R`)
   - Check cache for existing data
   - Download missing datasets
   - Validate data completeness

3. **Data Processing** (`2-dataProcessing.R`)
   - Clip all spatial data to site extent + buffer
   - Calculate derived metrics (slope, aspect, flow accumulation)
   - Aggregate climate data to site location
   - Process soil data into analysis-ready format

4. **Section Generation** (Scripts 3-11)
   - Each section script generates its visualizations
   - Saves individual figures to `output/figures/`
   - Returns plot objects for final composition

5. **Report Assembly** (`99-renderReport.R` or R Markdown)
   - Combines all sections
   - Applies consistent styling
   - Generates final PDF/document

---

## 4. Technical Considerations

### 4.1 Coordinate Reference Systems
- **Standard:** Use appropriate UTM zone for site location
- **Transformations:** All data must be in same CRS before analysis
- **Display:** May use geographic (lat/long) for regional context maps

### 4.2 Data Caching Strategy
- Cache downloaded data to avoid repeated API calls
- Use `here::here()` for path management
- Implement cache validation (check data freshness)

### 4.3 Performance Optimization
- Use `terra` for large raster operations (faster than `raster`)
- Simplify complex geometries for display (`rmapshaper`)
- Consider `data.table` for large tabular operations

### 4.4 Reproducibility
- Set random seeds where needed
- Version control data sources (record download dates)
- Document all package versions
- Use `renv` for package management (optional but recommended)

### 4.5 Custom Themes & Styling
- Create consistent theme based on existing examples
- Define color palettes for each map type
- Establish typography hierarchy (using installed fonts)
- Create reusable annotation functions (scale bars, north arrows)

---

## 5. Section-Specific Implementation Notes

### Cover Sheet
- **Layout:** `grid` or `patchwork` for precise positioning
- **Text:** `ggtext` for formatted text blocks
- **Map:** Small inset using `ggspatial` or `cowplot::draw_plot()`

### Regional Context (Section 1)
- **Maps:** Multi-scale with `patchwork` or `cowplot`
- **Ecoregions:** Color-coded polygons from `sf`
- **Watershed:** Overlay boundary on base map
- **Text:** Side panel with `gridExtra::tableGrob()` or `gt` tables

### Topography (Section 2)
- **DEM Visualization:** `terra::plot()` or convert to `sf` for ggplot2
- **Hillshade:** Calculate using `terra::shade()` or `raster::hillShade()`
- **Slope/Aspect:** Calculate with `terra::terrain()`
- **Cross-section:** Extract profile line, plot with `ggplot2`

### Hydrology (Section 3)
- **Flow Direction:** Calculate with `whitebox` or `terra`
- **Flow Accumulation:** Derived from DEM
- **Streams:** Overlay NHD data
- **Flood Zones:** Overlay FEMA polygons

### Climate (Section 4)
- **Wind Rose:** Use `rWind` or custom `ggplot2` polar coordinates
- **Time Series:** `ggplot2` with dual y-axes (`sec.axis`)
- **Data:** Extract from PRISM rasters at site coordinates

### Soils (Section 5)
- **Soil Map:** `sf` polygons with `ggplot2::geom_sf()`
- **Profile Diagram:** Custom `ggplot2` or `grid` drawing
- **Tables:** `gt` or `kableExtra` for professional formatting

### Vulnerabilities (Section 6)
- **Composite Map:** Overlay multiple `sf` layers with transparency
- **Zones:** Create risk/opportunity polygons from analysis
- **Callouts:** `ggrepel` for annotations

### Data Tables (Section 7)
- **Formatting:** `gt` package for publication-quality tables
- **Layout:** `gridExtra` or `patchwork` for multi-table pages

---

## 6. Next Steps

1. **Update `0-setUp.R`** with complete package list
2. **Create site metadata template** (YAML format)
3. **Develop data acquisition functions** with caching
4. **Create custom theme** based on existing examples
5. **Build reusable mapping functions** (scale bar, north arrow, inset maps)
6. **Implement first section** (Cover Sheet) as proof of concept
7. **Iterate on design** based on output quality
8. **Documentation** - Create user guide for generating reports

---

## 7. Package Installation Priority

### Phase 1: Core Spatial & Visualization (Essential)
- sf, terra, ggplot2, patchwork, ggspatial, scales, systemfonts

### Phase 2: Data Acquisition (Essential)
- FedData, prism, rnoaa, nhdplusTools

### Phase 3: Advanced Analysis (Important)
- whitebox, soilDB, aqp, rWind

### Phase 4: Document & Tables (Important)
- rmarkdown, gt, gridExtra, magick

### Phase 5: Utilities & Polish (Nice to have)
- renv, config, tmap (alternative mapping)

---

## 8. Questions to Resolve

1. **Data Access:**
   - Do you have API keys for NOAA/PRISM or will we use public access?
   - Preferred method for parcel boundary input (shapefile, coordinates, drawing)?

2. **Workflow:**
   - Interactive R script workflow or R Markdown document?
   - Batch processing for multiple sites or single-site focus?

3. **Styling:**
   - Finalize color palette preferences
   - Typography hierarchy decisions
   - Logo/branding integration method

4. **Output:**
   - PDF only or also HTML/interactive?
   - Standard 11x17 or also support other sizes?

5. **Automation:**
   - Level of automation desired (fully automated vs. manual review steps)?
   - Integration with other tools (GIS software, design software)?

---

*Document created: 2025-01-02*  
*Last updated: 2025-01-02*

```


Updating the setup script with the additional packages identified in the planning document:



Updating the setup script with the additional packages needed for the site assessment product:


```r
# Three step to loading necessary packages for a project
# Create list of necessary packages

# Core Visualization & Design
viz_packages <- c(
  "ggplot2", "patchwork", "cowplot", "ggtext", "ggrepel", "scales",
  "grid", "grDevices", "colorspace", "viridis", "RColorBrewer", 
  "rcartocolor", "scico", "ggsci", "ggthemes", "nord", "MetBrewer",
  "ggforce", "ggdist", "ggbeeswarm", "gghalves", "colorblindr"
)

# Spatial Data & Mapping
spatial_packages <- c(
  "sf", "terra", "stars", "rnaturalearth", "rmapshaper", 
  "ggspatial", "maps", "mapdata"
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
  "nhdplusTools", "whitebox", "raster"
)

# Data Management
data_packages <- c(
  "readr", "readxl", "dplyr", "tidyr", "tibble", "here",
  "lubridate", "stringr", "forcats"
)

# Document Generation
doc_packages <- c(
  "rmarkdown", "knitr", "gridExtra", "gt", "kableExtra", "magick"
)

# Utilities
util_packages <- c(
  "devtools", "usethis", "config", "yaml"
)

# Combine all packages
libs <- c(
  viz_packages, spatial_packages, climate_packages, soil_packages,
  hydro_packages, data_packages, doc_packages, util_packages
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


```


Creating a site metadata template for inputting site information:


```yaml
# Site Assessment Metadata Template
# Copy this file and fill in site-specific information
# File should be named: siteMetadata_[projectName].yaml

# Project Information
project:
  name: "Project Name"
  client: "Client Name"
  date_assessment: "2025-01-02"  # YYYY-MM-DD format
  prepared_by: "Your Name"
  firm_name: "Firm Name"
  logo_path: "path/to/logo.png"  # Optional: path to logo file

# Site Location
site:
  address: "123 Main Street, City, State ZIP"
  parcel_id: "Parcel ID if available"  # Optional
  latitude: 40.7128  # Decimal degrees
  longitude: -74.0060  # Decimal degrees
  crs: "EPSG:4326"  # Coordinate reference system (WGS84 default)
  
  # Parcel boundary options:
  # Option 1: Provide bounding box (will create rectangular boundary)
  bbox:
    xmin: -74.02
    xmax: -73.99
    ymin: 40.70
    ymax: 40.73
  
  # Option 2: Provide path to shapefile
  # boundary_shapefile: "path/to/parcel.shp"
  
  # Option 3: Provide coordinates as list of [lon, lat] pairs
  # boundary_coords:
  #   - [-74.02, 40.70]
  #   - [-74.01, 40.70]
  #   - [-74.01, 40.73]
  #   - [-74.02, 40.73]
  #   - [-74.02, 40.70]  # Close polygon

# Data Sources (will be auto-populated, but can be manually specified)
data_sources:
  dem:
    source: "USGS 3DEP"
    resolution: "10m"  # or "3m", "1m"
    year: "2024"
  
  soils:
    source: "NRCS SSURGO"
    year: "2023"
  
  climate:
    source: "PRISM Climate Group"
    period: "1991-2020"
  
  watershed:
    source: "USGS NHD"
    year: "2023"
  
  ecoregion:
    source: "EPA Ecoregions"
    level: "III"  # or "IV"
  
  flood_zones:
    source: "FEMA"
    year: "2023"  # Check for most recent FEMA maps

# Analysis Parameters
analysis:
  buffer_distance: 5000  # Meters: buffer around site for regional context
  dem_resolution: "10m"  # Preferred DEM resolution
  slope_classes:
    - [0, 5, "Gentle"]
    - [5, 15, "Moderate"]
    - [15, 999, "Steep"]
  
  # Custom notes or requirements
  notes: |
    Any site-specific notes or requirements
    Can be multi-line text

# Output Settings
output:
  format: "pdf"  # "pdf", "html", or both
  size: "11x17"  # "11x17", "8.5x11", or custom dimensions
  dpi: 300
  output_dir: "output/reports"

```


## Planning complete

### 1. **Planning document** (`PLANNING_SiteAssessment.md`)
   - Package requirements organized by report section
   - Data sources and acquisition strategies
   - Proposed script architecture and workflow
   - Technical considerations (CRS, caching, performance)
   - Section-specific implementation notes
   - Questions to resolve

### 2. **Updated setup script** (`scripts/0-setUp.R`)
   - Organized packages by category (visualization, spatial, climate, soils, hydrology, etc.)
   - Added packages needed for site assessment:
     - Spatial: `terra`, `stars`, `ggspatial`, `whitebox`
     - Climate: `rnoaa`, `prism`, `rWind`, `circular`
     - Soils: `FedData`, `soilDB`, `aqp`
     - Hydrology: `nhdplusTools`, `whitebox`, `raster`
     - Documents: `rmarkdown`, `gt`, `kableExtra`

### 3. **Site metadata template** (`data/siteInfo/siteMetadata_template.yaml`)
   - Template for site-specific information
   - Includes project info, location, data sources, and analysis parameters

## Next steps

1. Review the planning document and refine package choices
2. Decide on workflow preference (R scripts vs. R Markdown)
3. Answer the questions in Section 8 of the planning document
4. Begin implementation with a proof-of-concept section (e.g., Cover Sheet)

## Key decisions needed

- Data access: API keys or public access for climate/NOAA data?
- Parcel boundaries: How will you provide site boundaries (shapefile, coordinates, drawing tool)?
- Workflow: Interactive R scripts or R Markdown document?
- Output format: PDF only, or also HTML/interactive?

The planning document provides a roadmap. Should I start implementing a specific section, or refine the plan first?

---

**User**

1. I think project structure and workflow looks good. In general, I would like to adhere to tidy data priniciples as much as possible. It looks like we are using most of the tidyverse packages, so lets go ahead and call the `tidyverse` in our initial set-up call. I also know that I would like to combine wind data with the spatial data to create a visualization of a flow field based on the structures within the built environment. And I would like to explore using rayshader to visualize canopy heights if the data is available.

2. I want to set up the site parameters and automate the data collection and analysis process as much as possible. Scripts seems to me the best way to this. If we need to use a markdown flavor, I think it will need to be `.qmd` to make it an interactive quarto document. 

3. Section 8 Questions:

- Ideally all data retrieved via an API from designated sources. Including spatial data from a REST server or similar.

- See response to (2) above. Prefer a scripted workflow that exports a PDF document and publishes an interactive quarto page. Open to alternatives if this is not feasible.

- I'd like to focus on data acquisition, analysis, Visualization, and layout before approaching styling.

- PDF and interactive output. The PDF is can be exclusively 11x17.

- As automated as possible. I would like to input the site data and press "go". Ideally run fully in Rstudio.



Lets refine this plan based on my comments.

---

**Cursor**


Refining the plan based on your feedback. Updating the setup script and planning document accordingly.



Updating the setup script and planning document to reflect your requirements:


```r
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
  "ggspatial", "maps", "mapdata"
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
  "nhdplusTools", "whitebox", "raster"
)

# Additional Data Management (beyond tidyverse)
data_packages <- c(
  "readxl", "here", "yaml"
)

# Document Generation (Quarto workflow)
doc_packages <- c(
  "quarto", "gridExtra", "gt", "kableExtra", "magick"
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
  api_packages, util_packages
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


```

```markdown
# Site Assessment Report - Technical Planning Document

## Overview

This document outlines the technical architecture, package requirements, and implementation strategy for generating professional site assessment reports for landscape design projects.

**Output Format:** 
- PDF: 11x17 document (exclusively)
- Interactive: Quarto (.qmd) document for web/tablet viewing

**Primary Tool:** R with tidyverse and ggplot2 for visualization  
**Workflow:** Fully automated script-based workflow - input site data and run  
**Design Philosophy:** Focus on data acquisition, analysis, visualization, and layout first; styling refinement later  
**Data Principles:** Adhere to tidy data principles throughout

---

## 1. Package Requirements by Report Section

### Core Visualization & Design
- **ggplot2** - Primary plotting engine
- **patchwork** - Multi-panel layout composition
- **cowplot** - Advanced plot arrangement and annotations
- **ggtext** - Rich text formatting in plots
- **ggrepel** - Smart label placement
- **scales** - Axis formatting and transformations
- **colorspace** / **viridis** / **RColorBrewer** / **scico** - Color palettes
- **systemfonts** - Custom font management (Boska, Cabinet Grotesk, Pally, Tabular)

### Spatial Data & Mapping
- **sf** - Spatial data handling (CRS, geometries, spatial operations)
- **terra** - Raster data (DEM, slope, aspect calculations)
- **stars** - Alternative raster package (if needed)
- **rnaturalearth** - Base maps (countries, states, coastlines)
- **rmapshaper** - Spatial data simplification
- **tmap** - Thematic mapping (alternative/complement to ggplot2)
- **ggspatial** - Spatial annotations (scale bars, north arrows, inset maps)
- **maps** / **mapdata** - Additional base map data

### Climate & Weather Data
- **rnoaa** - NOAA climate data access
- **prism** - PRISM climate data (temperature, precipitation)
- **rWind** - Wind data processing and wind rose creation
- **circular** - Circular statistics for wind direction

### Soil Data
- **FedData** - Access to SSURGO soil data
- **soilDB** - Soil Survey Database queries
- **aqp** - Soil profile analysis and visualization

### Hydrology
- **nhdplusTools** - NHD Plus data and watershed delineation
- **whitebox** - Advanced terrain analysis (flow accumulation, watersheds)
- **raster** - Raster operations (may complement terra)

### Data Management
- **readr** / **readxl** - Data import
- **dplyr** / **tidyr** - Data manipulation
- **tibble** - Modern data frames
- **here** - Project path management
- **lubridate** - Date handling
- **stringr** - String manipulation
- **forcats** - Factor management

### Document Generation
- **rmarkdown** - Report generation
- **knitr** - Code execution in documents
- **grid** / **gridExtra** - Advanced layout (tables, complex arrangements)
- **gt** / **kableExtra** - Professional table formatting
- **magick** - Image manipulation and composition

### Utilities
- **devtools** - Package development and installation
- **usethis** - Project setup utilities
- **config** - Configuration management
- **yaml** - YAML parsing for metadata

---

## 2. Data Sources & Acquisition Strategy

### Required Data Types

#### 2.1 Elevation & Topography
- **Source:** USGS 3D Elevation Program (3DEP)
- **Format:** Digital Elevation Model (DEM)
- **Resolution:** 1m, 3m, or 10m depending on site size
- **Access Methods:**
  - `elevatr` package - Direct download
  - `FedData` package - USGS data access
  - Manual download from USGS National Map

#### 2.2 Watershed & Hydrology
- **Source:** USGS National Hydrography Dataset (NHD)
- **Format:** Vector (streams, waterbodies)
- **Access:** `nhdplusTools` or `FedData`
- **Watershed Delineation:** Calculate from DEM using `whitebox` or `raster`

#### 2.3 Ecoregions
- **Source:** EPA Ecoregions (Level III/IV)
- **Format:** Shapefile
- **Access:** Download from EPA website or use `FedData`

#### 2.4 Soils
- **Source:** NRCS SSURGO (Soil Survey Geographic Database)
- **Format:** Spatial polygons with attribute tables
- **Access:** `FedData::get_ssurgo()` or `soilDB` package
- **Required Attributes:**
  - Map unit name
  - Texture class
  - Drainage class
  - Hydrologic group
  - Permeability

#### 2.5 Climate Data
- **Source:** PRISM Climate Group (Oregon State)
- **Format:** Raster grids (monthly/annual normals)
- **Access:** `prism` package
- **Variables:**
  - Mean temperature (monthly/annual)
  - Precipitation (monthly/annual)
  - Potential evapotranspiration (if available)

#### 2.6 Wind Data
- **Source:** NOAA NCEI (National Centers for Environmental Information)
- **Format:** Time series data
- **Access:** `rnoaa` package or manual download
- **Required:** Direction, speed, frequency by season

#### 2.7 Flood Zones
- **Source:** FEMA Flood Map Service Center
- **Format:** Shapefile
- **Access:** Manual download or `FedData` (if available)

#### 2.8 Base Maps
- **Source:** OpenStreetMap, USGS, Natural Earth
- **Format:** Vector/raster tiles
- **Access:** `osmdata`, `rnaturalearth`, `ggmap` (if needed)

---

## 3. Script Architecture & Workflow

### Proposed Directory Structure

```
ggplot-GraphicDesign/
├── scripts/
│   ├── 0-setUp.R                    # Package installation & loading
│   ├── 1-dataAcquisition.R          # Download & cache all data sources
│   ├── 2-dataProcessing.R           # Process raw data into analysis-ready formats
│   ├── 3-coverSheet.R               # Generate cover sheet
│   ├── 4-regionalContext.R           # Section 1: Regional orientation
│   ├── 5-topography.R               # Section 2: Topography & landform
│   ├── 6-hydrology.R                # Section 3: Hydrology & drainage
│   ├── 7-climate.R                  # Section 4: Climate & wind
│   ├── 8-soils.R                    # Section 5: Soils & infiltration
│   ├── 9-vulnerabilities.R          # Section 6: Vulnerabilities & opportunities
│   ├── 10-dataTables.R              # Section 7: Supporting data tables
│   ├── 11-summary.R                 # Section 8: Summary & next steps
│   └── 99-renderReport.R             # Master script to generate full report
├── data/
│   ├── raw/                         # Raw downloaded data
│   │   ├── dem/
│   │   ├── soils/
│   │   ├── climate/
│   │   ├── watersheds/
│   │   └── ecoregions/
│   ├── processed/                   # Processed/analysis-ready data
│   └── siteInfo/                    # Site-specific metadata (YAML/CSV)
├── functions/
│   ├── mapHelpers.R                 # Reusable mapping functions
│   ├── themeCustom.R                # Custom ggplot themes
│   ├── dataHelpers.R                # Data processing utilities
│   └── tableHelpers.R               # Table formatting functions
├── templates/
│   ├── reportTemplate.Rmd           # R Markdown template
│   └── layoutTemplates.R            # Layout specifications
└── output/
    ├── reports/                     # Generated reports
    ├── figures/                     # Individual figure exports
    └── cache/                       # Cached computations
```

### Workflow Process

1. **Site Information Input**
   - Create site metadata file (YAML or CSV)
   - Contains: client name, address, lat/long, parcel boundary, project date

2. **Data Acquisition** (`1-dataAcquisition.R`)
   - Check cache for existing data
   - Download missing datasets
   - Validate data completeness

3. **Data Processing** (`2-dataProcessing.R`)
   - Clip all spatial data to site extent + buffer
   - Calculate derived metrics (slope, aspect, flow accumulation)
   - Aggregate climate data to site location
   - Process soil data into analysis-ready format

4. **Section Generation** (Scripts 3-11)
   - Each section script generates its visualizations
   - Saves individual figures to `output/figures/`
   - Returns plot objects for final composition

5. **Report Assembly** (`99-renderReport.R` or R Markdown)
   - Combines all sections
   - Applies consistent styling
   - Generates final PDF/document

---

## 4. Technical Considerations

### 4.1 Coordinate Reference Systems
- **Standard:** Use appropriate UTM zone for site location
- **Transformations:** All data must be in same CRS before analysis
- **Display:** May use geographic (lat/long) for regional context maps

### 4.2 Data Caching Strategy
- Cache downloaded data to avoid repeated API calls
- Use `here::here()` for path management
- Implement cache validation (check data freshness)

### 4.3 Performance Optimization
- Use `terra` for large raster operations (faster than `raster`)
- Simplify complex geometries for display (`rmapshaper`)
- Consider `data.table` for large tabular operations

### 4.4 Reproducibility
- Set random seeds where needed
- Version control data sources (record download dates)
- Document all package versions
- Use `renv` for package management (optional but recommended)

### 4.5 Custom Themes & Styling
- Create consistent theme based on existing examples
- Define color palettes for each map type
- Establish typography hierarchy (using installed fonts)
- Create reusable annotation functions (scale bars, north arrows)

---

## 5. Section-Specific Implementation Notes

### Cover Sheet
- **Layout:** `grid` or `patchwork` for precise positioning
- **Text:** `ggtext` for formatted text blocks
- **Map:** Small inset using `ggspatial` or `cowplot::draw_plot()`

### Regional Context (Section 1)
- **Maps:** Multi-scale with `patchwork` or `cowplot`
- **Ecoregions:** Color-coded polygons from `sf`
- **Watershed:** Overlay boundary on base map
- **Text:** Side panel with `gridExtra::tableGrob()` or `gt` tables

### Topography (Section 2)
- **DEM Visualization:** `terra::plot()` or convert to `sf` for ggplot2
- **Hillshade:** Calculate using `terra::shade()` or `raster::hillShade()`
- **Slope/Aspect:** Calculate with `terra::terrain()`
- **Cross-section:** Extract profile line, plot with `ggplot2`

### Hydrology (Section 3)
- **Flow Direction:** Calculate with `whitebox` or `terra`
- **Flow Accumulation:** Derived from DEM
- **Streams:** Overlay NHD data
- **Flood Zones:** Overlay FEMA polygons

### Climate (Section 4)
- **Wind Rose:** Use `rWind` or custom `ggplot2` polar coordinates
- **Time Series:** `ggplot2` with dual y-axes (`sec.axis`)
- **Data:** Extract from PRISM rasters at site coordinates

### Soils (Section 5)
- **Soil Map:** `sf` polygons with `ggplot2::geom_sf()`
- **Profile Diagram:** Custom `ggplot2` or `grid` drawing
- **Tables:** `gt` or `kableExtra` for professional formatting

### Vulnerabilities (Section 6)
- **Composite Map:** Overlay multiple `sf` layers with transparency
- **Zones:** Create risk/opportunity polygons from analysis
- **Callouts:** `ggrepel` for annotations

### Data Tables (Section 7)
- **Formatting:** `gt` package for publication-quality tables
- **Layout:** `gridExtra` or `patchwork` for multi-table pages

---

## 6. Next Steps

1. **Update `0-setUp.R`** with complete package list
2. **Create site metadata template** (YAML format)
3. **Develop data acquisition functions** with caching
4. **Create custom theme** based on existing examples
5. **Build reusable mapping functions** (scale bar, north arrow, inset maps)
6. **Implement first section** (Cover Sheet) as proof of concept
7. **Iterate on design** based on output quality
8. **Documentation** - Create user guide for generating reports

---

## 7. Package Installation Priority

### Phase 1: Core Spatial & Visualization (Essential)
- sf, terra, ggplot2, patchwork, ggspatial, scales, systemfonts

### Phase 2: Data Acquisition (Essential)
- FedData, prism, rnoaa, nhdplusTools

### Phase 3: Advanced Analysis (Important)
- whitebox, soilDB, aqp, rWind

### Phase 4: Document & Tables (Important)
- rmarkdown, gt, gridExtra, magick

### Phase 5: Utilities & Polish (Nice to have)
- renv, config, tmap (alternative mapping)

---

## 8. Questions to Resolve

1. **Data Access:**
   - Do you have API keys for NOAA/PRISM or will we use public access?
   - Preferred method for parcel boundary input (shapefile, coordinates, drawing)?

2. **Workflow:**
   - Interactive R script workflow or R Markdown document?
   - Batch processing for multiple sites or single-site focus?

3. **Styling:**
   - Finalize color palette preferences
   - Typography hierarchy decisions
   - Logo/branding integration method

4. **Output:**
   - PDF only or also HTML/interactive?
   - Standard 11x17 or also support other sizes?

5. **Automation:**
   - Level of automation desired (fully automated vs. manual review steps)?
   - Integration with other tools (GIS software, design software)?

---

*Document created: 2025-01-02*  
*Last updated: 2025-01-02*


```

```markdown
# Site Assessment Report - Technical Planning Document

## Overview

This document outlines the technical architecture, package requirements, and implementation strategy for generating professional site assessment reports for landscape design projects.

**Output Format:** 
- PDF: 11x17 document (exclusively)
- Interactive: Quarto (.qmd) document for web/tablet viewing

**Primary Tool:** R with tidyverse and ggplot2 for visualization  
**Workflow:** Fully automated script-based workflow - input site data and run  
**Design Philosophy:** Focus on data acquisition, analysis, visualization, and layout first; styling refinement later  
**Data Principles:** Adhere to tidy data principles throughout

---

## 1. Package Requirements by Report Section

### Core Data Management (Tidyverse)
- **tidyverse** - Core suite (dplyr, tidyr, readr, purrr, tibble, stringr, forcats, lubridate, ggplot2)
- **here** - Project path management
- **readxl** - Excel file reading
- **yaml** - YAML parsing for site metadata

### Core Visualization & Design
- **ggplot2** - Primary plotting engine (included in tidyverse, but explicitly noted)
- **patchwork** - Multi-panel layout composition
- **cowplot** - Advanced plot arrangement and annotations
- **ggtext** - Rich text formatting in plots
- **ggrepel** - Smart label placement
- **scales** - Axis formatting and transformations
- **colorspace** / **viridis** / **RColorBrewer** / **scico** - Color palettes
- **rayshader** - 3D visualization for canopy heights and terrain
- **systemfonts** - Custom font management (Boska, Cabinet Grotesk, Pally, Tabular)

### Spatial Data & Mapping
- **sf** - Spatial data handling (CRS, geometries, spatial operations)
- **terra** - Raster data (DEM, slope, aspect calculations)
- **stars** - Alternative raster package (if needed)
- **rnaturalearth** - Base maps (countries, states, coastlines)
- **rmapshaper** - Spatial data simplification
- **tmap** - Thematic mapping (alternative/complement to ggplot2)
- **ggspatial** - Spatial annotations (scale bars, north arrows, inset maps)
- **maps** / **mapdata** - Additional base map data

### Climate & Weather Data
- **rnoaa** - NOAA climate data access
- **prism** - PRISM climate data (temperature, precipitation)
- **rWind** - Wind data processing and wind rose creation
- **circular** - Circular statistics for wind direction

### Soil Data
- **FedData** - Access to SSURGO soil data
- **soilDB** - Soil Survey Database queries
- **aqp** - Soil profile analysis and visualization

### Hydrology
- **nhdplusTools** - NHD Plus data and watershed delineation
- **whitebox** - Advanced terrain analysis (flow accumulation, watersheds)
- **raster** - Raster operations (may complement terra)

### Data Management
- **readr** / **readxl** - Data import
- **dplyr** / **tidyr** - Data manipulation
- **tibble** - Modern data frames
- **here** - Project path management
- **lubridate** - Date handling
- **stringr** - String manipulation
- **forcats** - Factor management

### Document Generation
- **rmarkdown** - Report generation
- **knitr** - Code execution in documents
- **grid** / **gridExtra** - Advanced layout (tables, complex arrangements)
- **gt** / **kableExtra** - Professional table formatting
- **magick** - Image manipulation and composition

### Utilities
- **devtools** - Package development and installation
- **usethis** - Project setup utilities
- **config** - Configuration management
- **yaml** - YAML parsing for metadata

---

## 2. Data Sources & Acquisition Strategy

### Required Data Types

#### 2.1 Elevation & Topography
- **Source:** USGS 3D Elevation Program (3DEP)
- **Format:** Digital Elevation Model (DEM)
- **Resolution:** 1m, 3m, or 10m depending on site size
- **Access Methods:**
  - `elevatr` package - Direct download
  - `FedData` package - USGS data access
  - Manual download from USGS National Map

#### 2.2 Watershed & Hydrology
- **Source:** USGS National Hydrography Dataset (NHD)
- **Format:** Vector (streams, waterbodies)
- **Access:** `nhdplusTools` or `FedData`
- **Watershed Delineation:** Calculate from DEM using `whitebox` or `raster`

#### 2.3 Ecoregions
- **Source:** EPA Ecoregions (Level III/IV)
- **Format:** Shapefile
- **Access:** Download from EPA website or use `FedData`

#### 2.4 Soils
- **Source:** NRCS SSURGO (Soil Survey Geographic Database)
- **Format:** Spatial polygons with attribute tables
- **Access:** `FedData::get_ssurgo()` or `soilDB` package
- **Required Attributes:**
  - Map unit name
  - Texture class
  - Drainage class
  - Hydrologic group
  - Permeability

#### 2.5 Climate Data
- **Source:** PRISM Climate Group (Oregon State)
- **Format:** Raster grids (monthly/annual normals)
- **Access:** `prism` package
- **Variables:**
  - Mean temperature (monthly/annual)
  - Precipitation (monthly/annual)
  - Potential evapotranspiration (if available)

#### 2.6 Wind Data
- **Source:** NOAA NCEI (National Centers for Environmental Information)
- **Format:** Time series data
- **Access:** `rnoaa` package or manual download
- **Required:** Direction, speed, frequency by season

#### 2.7 Flood Zones
- **Source:** FEMA Flood Map Service Center
- **Format:** Shapefile
- **Access:** Manual download or `FedData` (if available)

#### 2.8 Base Maps
- **Source:** OpenStreetMap, USGS, Natural Earth
- **Format:** Vector/raster tiles
- **Access:** `osmdata`, `rnaturalearth`, `ggmap` (if needed)

---

## 3. Script Architecture & Workflow

### Proposed Directory Structure

```
ggplot-GraphicDesign/
├── scripts/
│   ├── 0-setUp.R                    # Package installation & loading
│   ├── 1-dataAcquisition.R          # Download & cache all data sources
│   ├── 2-dataProcessing.R           # Process raw data into analysis-ready formats
│   ├── 3-coverSheet.R               # Generate cover sheet
│   ├── 4-regionalContext.R           # Section 1: Regional orientation
│   ├── 5-topography.R               # Section 2: Topography & landform
│   ├── 6-hydrology.R                # Section 3: Hydrology & drainage
│   ├── 7-climate.R                  # Section 4: Climate & wind
│   ├── 8-soils.R                    # Section 5: Soils & infiltration
│   ├── 9-vulnerabilities.R          # Section 6: Vulnerabilities & opportunities
│   ├── 10-dataTables.R              # Section 7: Supporting data tables
│   ├── 11-summary.R                 # Section 8: Summary & next steps
│   └── 99-renderReport.R             # Master script to generate full report
├── data/
│   ├── raw/                         # Raw downloaded data
│   │   ├── dem/
│   │   ├── soils/
│   │   ├── climate/
│   │   ├── watersheds/
│   │   └── ecoregions/
│   ├── processed/                   # Processed/analysis-ready data
│   └── siteInfo/                    # Site-specific metadata (YAML/CSV)
├── functions/
│   ├── mapHelpers.R                 # Reusable mapping functions
│   ├── themeCustom.R                # Custom ggplot themes
│   ├── dataHelpers.R                # Data processing utilities
│   └── tableHelpers.R               # Table formatting functions
├── templates/
│   ├── reportTemplate.Rmd           # R Markdown template
│   └── layoutTemplates.R            # Layout specifications
└── output/
    ├── reports/                     # Generated reports
    ├── figures/                     # Individual figure exports
    └── cache/                       # Cached computations
```

### Workflow Process

1. **Site Information Input**
   - Create site metadata file (YAML or CSV)
   - Contains: client name, address, lat/long, parcel boundary, project date

2. **Data Acquisition** (`1-dataAcquisition.R`)
   - Check cache for existing data
   - Download missing datasets
   - Validate data completeness

3. **Data Processing** (`2-dataProcessing.R`)
   - Clip all spatial data to site extent + buffer
   - Calculate derived metrics (slope, aspect, flow accumulation)
   - Aggregate climate data to site location
   - Process soil data into analysis-ready format

4. **Section Generation** (Scripts 3-11)
   - Each section script generates its visualizations
   - Saves individual figures to `output/figures/`
   - Returns plot objects for final composition

5. **Report Assembly** (`99-renderReport.R` or R Markdown)
   - Combines all sections
   - Applies consistent styling
   - Generates final PDF/document

---

## 4. Technical Considerations

### 4.1 Coordinate Reference Systems
- **Standard:** Use appropriate UTM zone for site location
- **Transformations:** All data must be in same CRS before analysis
- **Display:** May use geographic (lat/long) for regional context maps

### 4.2 Data Caching Strategy
- Cache downloaded data to avoid repeated API calls
- Use `here::here()` for path management
- Implement cache validation (check data freshness)

### 4.3 Performance Optimization
- Use `terra` for large raster operations (faster than `raster`)
- Simplify complex geometries for display (`rmapshaper`)
- Consider `data.table` for large tabular operations

### 4.4 Reproducibility
- Set random seeds where needed
- Version control data sources (record download dates)
- Document all package versions
- Use `renv` for package management (optional but recommended)

### 4.5 Custom Themes & Styling
- Create consistent theme based on existing examples
- Define color palettes for each map type
- Establish typography hierarchy (using installed fonts)
- Create reusable annotation functions (scale bars, north arrows)

---

## 5. Section-Specific Implementation Notes

### Cover Sheet
- **Layout:** `grid` or `patchwork` for precise positioning
- **Text:** `ggtext` for formatted text blocks
- **Map:** Small inset using `ggspatial` or `cowplot::draw_plot()`

### Regional Context (Section 1)
- **Maps:** Multi-scale with `patchwork` or `cowplot`
- **Ecoregions:** Color-coded polygons from `sf`
- **Watershed:** Overlay boundary on base map
- **Text:** Side panel with `gridExtra::tableGrob()` or `gt` tables

### Topography (Section 2)
- **DEM Visualization:** `terra::plot()` or convert to `sf` for ggplot2
- **Hillshade:** Calculate using `terra::shade()` or `raster::hillShade()`
- **Slope/Aspect:** Calculate with `terra::terrain()`
- **Cross-section:** Extract profile line, plot with `ggplot2`

### Hydrology (Section 3)
- **Flow Direction:** Calculate with `whitebox` or `terra`
- **Flow Accumulation:** Derived from DEM
- **Streams:** Overlay NHD data
- **Flood Zones:** Overlay FEMA polygons

### Climate (Section 4)
- **Wind Rose:** Use `rWind` or custom `ggplot2` polar coordinates
- **Time Series:** `ggplot2` with dual y-axes (`sec.axis`)
- **Data:** Extract from PRISM rasters at site coordinates

### Soils (Section 5)
- **Soil Map:** `sf` polygons with `ggplot2::geom_sf()`
- **Profile Diagram:** Custom `ggplot2` or `grid` drawing
- **Tables:** `gt` or `kableExtra` for professional formatting

### Vulnerabilities (Section 6)
- **Composite Map:** Overlay multiple `sf` layers with transparency
- **Zones:** Create risk/opportunity polygons from analysis
- **Callouts:** `ggrepel` for annotations

### Data Tables (Section 7)
- **Formatting:** `gt` package for publication-quality tables
- **Layout:** `gridExtra` or `patchwork` for multi-table pages

---

## 6. Next Steps

1. **Update `0-setUp.R`** with complete package list
2. **Create site metadata template** (YAML format)
3. **Develop data acquisition functions** with caching
4. **Create custom theme** based on existing examples
5. **Build reusable mapping functions** (scale bar, north arrow, inset maps)
6. **Implement first section** (Cover Sheet) as proof of concept
7. **Iterate on design** based on output quality
8. **Documentation** - Create user guide for generating reports

---

## 7. Package Installation Priority

### Phase 1: Core Spatial & Visualization (Essential)
- sf, terra, ggplot2, patchwork, ggspatial, scales, systemfonts

### Phase 2: Data Acquisition (Essential)
- FedData, prism, rnoaa, nhdplusTools

### Phase 3: Advanced Analysis (Important)
- whitebox, soilDB, aqp, rWind

### Phase 4: Document & Tables (Important)
- rmarkdown, gt, gridExtra, magick

### Phase 5: Utilities & Polish (Nice to have)
- renv, config, tmap (alternative mapping)

---

## 8. Questions to Resolve

1. **Data Access:**
   - Do you have API keys for NOAA/PRISM or will we use public access?
   - Preferred method for parcel boundary input (shapefile, coordinates, drawing)?

2. **Workflow:**
   - Interactive R script workflow or R Markdown document?
   - Batch processing for multiple sites or single-site focus?

3. **Styling:**
   - Finalize color palette preferences
   - Typography hierarchy decisions
   - Logo/branding integration method

4. **Output:**
   - PDF only or also HTML/interactive?
   - Standard 11x17 or also support other sizes?

5. **Automation:**
   - Level of automation desired (fully automated vs. manual review steps)?
   - Integration with other tools (GIS software, design software)?

---

*Document created: 2025-01-02*  
*Last updated: 2025-01-02*


```

```markdown
# Site Assessment Report - Technical Planning Document

## Overview

This document outlines the technical architecture, package requirements, and implementation strategy for generating professional site assessment reports for landscape design projects.

**Output Format:** 
- PDF: 11x17 document (exclusively)
- Interactive: Quarto (.qmd) document for web/tablet viewing

**Primary Tool:** R with tidyverse and ggplot2 for visualization  
**Workflow:** Fully automated script-based workflow - input site data and run  
**Design Philosophy:** Focus on data acquisition, analysis, visualization, and layout first; styling refinement later  
**Data Principles:** Adhere to tidy data principles throughout

---

## 1. Package Requirements by Report Section

### Core Data Management (Tidyverse)
- **tidyverse** - Core suite (dplyr, tidyr, readr, purrr, tibble, stringr, forcats, lubridate, ggplot2)
- **here** - Project path management
- **readxl** - Excel file reading
- **yaml** - YAML parsing for site metadata

### Core Visualization & Design
- **ggplot2** - Primary plotting engine (included in tidyverse, but explicitly noted)
- **patchwork** - Multi-panel layout composition
- **cowplot** - Advanced plot arrangement and annotations
- **ggtext** - Rich text formatting in plots
- **ggrepel** - Smart label placement
- **scales** - Axis formatting and transformations
- **colorspace** / **viridis** / **RColorBrewer** / **scico** - Color palettes
- **rayshader** - 3D visualization for canopy heights and terrain
- **systemfonts** - Custom font management (Boska, Cabinet Grotesk, Pally, Tabular)

### Spatial Data & Mapping
- **sf** - Spatial data handling (CRS, geometries, spatial operations)
- **terra** - Raster data (DEM, slope, aspect calculations)
- **stars** - Alternative raster package (if needed)
- **rnaturalearth** - Base maps (countries, states, coastlines)
- **rmapshaper** - Spatial data simplification
- **tmap** - Thematic mapping (alternative/complement to ggplot2)
- **ggspatial** - Spatial annotations (scale bars, north arrows, inset maps)
- **maps** / **mapdata** - Additional base map data

### Climate & Weather Data
- **rnoaa** - NOAA climate data access (API)
- **prism** - PRISM climate data (temperature, precipitation) - API access
- **rWind** - Wind data processing and wind rose creation
- **circular** - Circular statistics for wind direction
- **Note:** Wind data will be combined with spatial data to create flow field visualizations based on built environment structures

### Soil Data
- **FedData** - Access to SSURGO soil data
- **soilDB** - Soil Survey Database queries
- **aqp** - Soil profile analysis and visualization

### Hydrology
- **nhdplusTools** - NHD Plus data and watershed delineation
- **whitebox** - Advanced terrain analysis (flow accumulation, watersheds)
- **raster** - Raster operations (may complement terra)

### Data Management
- **readr** / **readxl** - Data import
- **dplyr** / **tidyr** - Data manipulation
- **tibble** - Modern data frames
- **here** - Project path management
- **lubridate** - Date handling
- **stringr** - String manipulation
- **forcats** - Factor management

### Document Generation
- **rmarkdown** - Report generation
- **knitr** - Code execution in documents
- **grid** / **gridExtra** - Advanced layout (tables, complex arrangements)
- **gt** / **kableExtra** - Professional table formatting
- **magick** - Image manipulation and composition

### Utilities
- **devtools** - Package development and installation
- **usethis** - Project setup utilities
- **config** - Configuration management
- **yaml** - YAML parsing for metadata

---

## 2. Data Sources & Acquisition Strategy

### Required Data Types

#### 2.1 Elevation & Topography
- **Source:** USGS 3D Elevation Program (3DEP)
- **Format:** Digital Elevation Model (DEM)
- **Resolution:** 1m, 3m, or 10m depending on site size
- **Access Methods:**
  - `elevatr` package - Direct download
  - `FedData` package - USGS data access
  - Manual download from USGS National Map

#### 2.2 Watershed & Hydrology
- **Source:** USGS National Hydrography Dataset (NHD)
- **Format:** Vector (streams, waterbodies)
- **Access:** `nhdplusTools` or `FedData`
- **Watershed Delineation:** Calculate from DEM using `whitebox` or `raster`

#### 2.3 Ecoregions
- **Source:** EPA Ecoregions (Level III/IV)
- **Format:** Shapefile
- **Access:** Download from EPA website or use `FedData`

#### 2.4 Soils
- **Source:** NRCS SSURGO (Soil Survey Geographic Database)
- **Format:** Spatial polygons with attribute tables
- **Access:** `FedData::get_ssurgo()` or `soilDB` package
- **Required Attributes:**
  - Map unit name
  - Texture class
  - Drainage class
  - Hydrologic group
  - Permeability

#### 2.5 Climate Data
- **Source:** PRISM Climate Group (Oregon State)
- **Format:** Raster grids (monthly/annual normals)
- **Access:** `prism` package
- **Variables:**
  - Mean temperature (monthly/annual)
  - Precipitation (monthly/annual)
  - Potential evapotranspiration (if available)

#### 2.6 Wind Data
- **Source:** NOAA NCEI (National Centers for Environmental Information)
- **Format:** Time series data
- **Access:** `rnoaa` package or manual download
- **Required:** Direction, speed, frequency by season

#### 2.7 Flood Zones
- **Source:** FEMA Flood Map Service Center
- **Format:** Shapefile
- **Access:** Manual download or `FedData` (if available)

#### 2.8 Base Maps
- **Source:** OpenStreetMap, USGS, Natural Earth
- **Format:** Vector/raster tiles
- **Access:** `osmdata`, `rnaturalearth`, `ggmap` (if needed)

---

## 3. Script Architecture & Workflow

### Proposed Directory Structure

```
ggplot-GraphicDesign/
├── scripts/
│   ├── 0-setUp.R                    # Package installation & loading
│   ├── 1-dataAcquisition.R          # Download & cache all data sources
│   ├── 2-dataProcessing.R           # Process raw data into analysis-ready formats
│   ├── 3-coverSheet.R               # Generate cover sheet
│   ├── 4-regionalContext.R           # Section 1: Regional orientation
│   ├── 5-topography.R               # Section 2: Topography & landform
│   ├── 6-hydrology.R                # Section 3: Hydrology & drainage
│   ├── 7-climate.R                  # Section 4: Climate & wind
│   ├── 8-soils.R                    # Section 5: Soils & infiltration
│   ├── 9-vulnerabilities.R          # Section 6: Vulnerabilities & opportunities
│   ├── 10-dataTables.R              # Section 7: Supporting data tables
│   ├── 11-summary.R                 # Section 8: Summary & next steps
│   └── 99-renderReport.R             # Master script to generate full report
├── data/
│   ├── raw/                         # Raw downloaded data
│   │   ├── dem/
│   │   ├── soils/
│   │   ├── climate/
│   │   ├── watersheds/
│   │   └── ecoregions/
│   ├── processed/                   # Processed/analysis-ready data
│   └── siteInfo/                    # Site-specific metadata (YAML/CSV)
├── functions/
│   ├── mapHelpers.R                 # Reusable mapping functions
│   ├── themeCustom.R                # Custom ggplot themes
│   ├── dataHelpers.R                # Data processing utilities
│   └── tableHelpers.R               # Table formatting functions
├── templates/
│   ├── reportTemplate.Rmd           # R Markdown template
│   └── layoutTemplates.R            # Layout specifications
└── output/
    ├── reports/                     # Generated reports
    ├── figures/                     # Individual figure exports
    └── cache/                       # Cached computations
```

### Workflow Process

1. **Site Information Input**
   - Create site metadata file (YAML or CSV)
   - Contains: client name, address, lat/long, parcel boundary, project date

2. **Data Acquisition** (`1-dataAcquisition.R`)
   - Check cache for existing data
   - Download missing datasets
   - Validate data completeness

3. **Data Processing** (`2-dataProcessing.R`)
   - Clip all spatial data to site extent + buffer
   - Calculate derived metrics (slope, aspect, flow accumulation)
   - Aggregate climate data to site location
   - Process soil data into analysis-ready format

4. **Section Generation** (Scripts 3-11)
   - Each section script generates its visualizations
   - Saves individual figures to `output/figures/`
   - Returns plot objects for final composition

5. **Report Assembly** (`99-renderReport.R` or R Markdown)
   - Combines all sections
   - Applies consistent styling
   - Generates final PDF/document

---

## 4. Technical Considerations

### 4.1 Coordinate Reference Systems
- **Standard:** Use appropriate UTM zone for site location
- **Transformations:** All data must be in same CRS before analysis
- **Display:** May use geographic (lat/long) for regional context maps

### 4.2 Data Caching Strategy
- Cache downloaded data to avoid repeated API calls
- Use `here::here()` for path management
- Implement cache validation (check data freshness)

### 4.3 Performance Optimization
- Use `terra` for large raster operations (faster than `raster`)
- Simplify complex geometries for display (`rmapshaper`)
- Consider `data.table` for large tabular operations

### 4.4 Reproducibility
- Set random seeds where needed
- Version control data sources (record download dates)
- Document all package versions
- Use `renv` for package management (optional but recommended)

### 4.5 Custom Themes & Styling
- Create consistent theme based on existing examples
- Define color palettes for each map type
- Establish typography hierarchy (using installed fonts)
- Create reusable annotation functions (scale bars, north arrows)

---

## 5. Section-Specific Implementation Notes

### Cover Sheet
- **Layout:** `grid` or `patchwork` for precise positioning
- **Text:** `ggtext` for formatted text blocks
- **Map:** Small inset using `ggspatial` or `cowplot::draw_plot()`

### Regional Context (Section 1)
- **Maps:** Multi-scale with `patchwork` or `cowplot`
- **Ecoregions:** Color-coded polygons from `sf`
- **Watershed:** Overlay boundary on base map
- **Text:** Side panel with `gridExtra::tableGrob()` or `gt` tables

### Topography (Section 2)
- **DEM Visualization:** `terra::plot()` or convert to `sf` for ggplot2
- **Hillshade:** Calculate using `terra::shade()` or `raster::hillShade()`
- **Slope/Aspect:** Calculate with `terra::terrain()`
- **Cross-section:** Extract profile line, plot with `ggplot2`

### Hydrology (Section 3)
- **Flow Direction:** Calculate with `whitebox` or `terra`
- **Flow Accumulation:** Derived from DEM
- **Streams:** Overlay NHD data
- **Flood Zones:** Overlay FEMA polygons

### Climate (Section 4)
- **Wind Rose:** Use `rWind` or custom `ggplot2` polar coordinates
- **Time Series:** `ggplot2` with dual y-axes (`sec.axis`)
- **Data:** Extract from PRISM rasters at site coordinates

### Soils (Section 5)
- **Soil Map:** `sf` polygons with `ggplot2::geom_sf()`
- **Profile Diagram:** Custom `ggplot2` or `grid` drawing
- **Tables:** `gt` or `kableExtra` for professional formatting

### Vulnerabilities (Section 6)
- **Composite Map:** Overlay multiple `sf` layers with transparency
- **Zones:** Create risk/opportunity polygons from analysis
- **Callouts:** `ggrepel` for annotations

### Data Tables (Section 7)
- **Formatting:** `gt` package for publication-quality tables
- **Layout:** `gridExtra` or `patchwork` for multi-table pages

---

## 6. Next Steps

1. **Update `0-setUp.R`** with complete package list
2. **Create site metadata template** (YAML format)
3. **Develop data acquisition functions** with caching
4. **Create custom theme** based on existing examples
5. **Build reusable mapping functions** (scale bar, north arrow, inset maps)
6. **Implement first section** (Cover Sheet) as proof of concept
7. **Iterate on design** based on output quality
8. **Documentation** - Create user guide for generating reports

---

## 7. Package Installation Priority

### Phase 1: Core Spatial & Visualization (Essential)
- sf, terra, ggplot2, patchwork, ggspatial, scales, systemfonts

### Phase 2: Data Acquisition (Essential)
- FedData, prism, rnoaa, nhdplusTools

### Phase 3: Advanced Analysis (Important)
- whitebox, soilDB, aqp, rWind

### Phase 4: Document & Tables (Important)
- rmarkdown, gt, gridExtra, magick

### Phase 5: Utilities & Polish (Nice to have)
- renv, config, tmap (alternative mapping)

---

## 8. Questions to Resolve

1. **Data Access:**
   - Do you have API keys for NOAA/PRISM or will we use public access?
   - Preferred method for parcel boundary input (shapefile, coordinates, drawing)?

2. **Workflow:**
   - Interactive R script workflow or R Markdown document?
   - Batch processing for multiple sites or single-site focus?

3. **Styling:**
   - Finalize color palette preferences
   - Typography hierarchy decisions
   - Logo/branding integration method

4. **Output:**
   - PDF only or also HTML/interactive?
   - Standard 11x17 or also support other sizes?

5. **Automation:**
   - Level of automation desired (fully automated vs. manual review steps)?
   - Integration with other tools (GIS software, design software)?

---

*Document created: 2025-01-02*  
*Last updated: 2025-01-02*


```

```markdown
# Site Assessment Report - Technical Planning Document

## Overview

This document outlines the technical architecture, package requirements, and implementation strategy for generating professional site assessment reports for landscape design projects.

**Output Format:** 
- PDF: 11x17 document (exclusively)
- Interactive: Quarto (.qmd) document for web/tablet viewing

**Primary Tool:** R with tidyverse and ggplot2 for visualization  
**Workflow:** Fully automated script-based workflow - input site data and run  
**Design Philosophy:** Focus on data acquisition, analysis, visualization, and layout first; styling refinement later  
**Data Principles:** Adhere to tidy data principles throughout

---

## 1. Package Requirements by Report Section

### Core Data Management (Tidyverse)
- **tidyverse** - Core suite (dplyr, tidyr, readr, purrr, tibble, stringr, forcats, lubridate, ggplot2)
- **here** - Project path management
- **readxl** - Excel file reading
- **yaml** - YAML parsing for site metadata

### Core Visualization & Design
- **ggplot2** - Primary plotting engine (included in tidyverse, but explicitly noted)
- **patchwork** - Multi-panel layout composition
- **cowplot** - Advanced plot arrangement and annotations
- **ggtext** - Rich text formatting in plots
- **ggrepel** - Smart label placement
- **scales** - Axis formatting and transformations
- **colorspace** / **viridis** / **RColorBrewer** / **scico** - Color palettes
- **rayshader** - 3D visualization for canopy heights and terrain
- **systemfonts** - Custom font management (Boska, Cabinet Grotesk, Pally, Tabular)

### Spatial Data & Mapping
- **sf** - Spatial data handling (CRS, geometries, spatial operations)
- **terra** - Raster data (DEM, slope, aspect calculations)
- **stars** - Alternative raster package (if needed)
- **rnaturalearth** - Base maps (countries, states, coastlines)
- **rmapshaper** - Spatial data simplification
- **tmap** - Thematic mapping (alternative/complement to ggplot2)
- **ggspatial** - Spatial annotations (scale bars, north arrows, inset maps)
- **maps** / **mapdata** - Additional base map data

### Climate & Weather Data
- **rnoaa** - NOAA climate data access (API)
- **prism** - PRISM climate data (temperature, precipitation) - API access
- **rWind** - Wind data processing and wind rose creation
- **circular** - Circular statistics for wind direction
- **Note:** Wind data will be combined with spatial data to create flow field visualizations based on built environment structures

### Soil Data
- **FedData** - Access to SSURGO soil data
- **soilDB** - Soil Survey Database queries
- **aqp** - Soil profile analysis and visualization

### Hydrology
- **nhdplusTools** - NHD Plus data and watershed delineation
- **whitebox** - Advanced terrain analysis (flow accumulation, watersheds)
- **raster** - Raster operations (may complement terra)

### API & Web Data Access
- **httr** - HTTP requests for REST API access
- **jsonlite** - JSON parsing for API responses
- **xml2** - XML parsing (if needed for some APIs)
- **Note:** All data acquisition should use API/REST server access where possible

### Document Generation (Quarto Workflow)
- **quarto** - Modern document generation (replaces R Markdown)
- **grid** / **gridExtra** - Advanced layout (tables, complex arrangements)
- **gt** / **kableExtra** - Professional table formatting
- **magick** - Image manipulation and composition

### Utilities
- **devtools** - Package development and installation
- **usethis** - Project setup utilities
- **config** - Configuration management
- **yaml** - YAML parsing for metadata

---

## 2. Data Sources & Acquisition Strategy

### Required Data Types

#### 2.1 Elevation & Topography
- **Source:** USGS 3D Elevation Program (3DEP)
- **Format:** Digital Elevation Model (DEM)
- **Resolution:** 1m, 3m, or 10m depending on site size
- **Access Methods:**
  - `elevatr` package - Direct download
  - `FedData` package - USGS data access
  - Manual download from USGS National Map

#### 2.2 Watershed & Hydrology
- **Source:** USGS National Hydrography Dataset (NHD)
- **Format:** Vector (streams, waterbodies)
- **Access:** `nhdplusTools` or `FedData`
- **Watershed Delineation:** Calculate from DEM using `whitebox` or `raster`

#### 2.3 Ecoregions
- **Source:** EPA Ecoregions (Level III/IV)
- **Format:** Shapefile
- **Access:** Download from EPA website or use `FedData`

#### 2.4 Soils
- **Source:** NRCS SSURGO (Soil Survey Geographic Database)
- **Format:** Spatial polygons with attribute tables
- **Access:** `FedData::get_ssurgo()` or `soilDB` package
- **Required Attributes:**
  - Map unit name
  - Texture class
  - Drainage class
  - Hydrologic group
  - Permeability

#### 2.5 Climate Data
- **Source:** PRISM Climate Group (Oregon State)
- **Format:** Raster grids (monthly/annual normals)
- **Access:** `prism` package
- **Variables:**
  - Mean temperature (monthly/annual)
  - Precipitation (monthly/annual)
  - Potential evapotranspiration (if available)

#### 2.6 Wind Data
- **Source:** NOAA NCEI (National Centers for Environmental Information)
- **Format:** Time series data
- **Access:** `rnoaa` package or manual download
- **Required:** Direction, speed, frequency by season

#### 2.7 Flood Zones
- **Source:** FEMA Flood Map Service Center
- **Format:** Shapefile
- **Access:** Manual download or `FedData` (if available)

#### 2.8 Base Maps
- **Source:** OpenStreetMap, USGS, Natural Earth
- **Format:** Vector/raster tiles
- **Access:** `osmdata`, `rnaturalearth`, `ggmap` (if needed)

---

## 3. Script Architecture & Workflow

### Proposed Directory Structure

```
ggplot-GraphicDesign/
├── scripts/
│   ├── 0-setUp.R                    # Package installation & loading
│   ├── 1-dataAcquisition.R          # Download & cache all data sources
│   ├── 2-dataProcessing.R           # Process raw data into analysis-ready formats
│   ├── 3-coverSheet.R               # Generate cover sheet
│   ├── 4-regionalContext.R           # Section 1: Regional orientation
│   ├── 5-topography.R               # Section 2: Topography & landform
│   ├── 6-hydrology.R                # Section 3: Hydrology & drainage
│   ├── 7-climate.R                  # Section 4: Climate & wind
│   ├── 8-soils.R                    # Section 5: Soils & infiltration
│   ├── 9-vulnerabilities.R          # Section 6: Vulnerabilities & opportunities
│   ├── 10-dataTables.R              # Section 7: Supporting data tables
│   ├── 11-summary.R                 # Section 8: Summary & next steps
│   └── 99-renderReport.R             # Master script to generate full report
├── data/
│   ├── raw/                         # Raw downloaded data
│   │   ├── dem/
│   │   ├── soils/
│   │   ├── climate/
│   │   ├── watersheds/
│   │   └── ecoregions/
│   ├── processed/                   # Processed/analysis-ready data
│   └── siteInfo/                    # Site-specific metadata (YAML/CSV)
├── functions/
│   ├── mapHelpers.R                 # Reusable mapping functions
│   ├── themeCustom.R                # Custom ggplot themes
│   ├── dataHelpers.R                # Data processing utilities
│   └── tableHelpers.R               # Table formatting functions
├── templates/
│   ├── reportTemplate.Rmd           # R Markdown template
│   └── layoutTemplates.R            # Layout specifications
└── output/
    ├── reports/                     # Generated reports
    ├── figures/                     # Individual figure exports
    └── cache/                       # Cached computations
```

### Workflow Process

1. **Site Information Input**
   - Create site metadata file (YAML or CSV)
   - Contains: client name, address, lat/long, parcel boundary, project date

2. **Data Acquisition** (`1-dataAcquisition.R`)
   - Check cache for existing data
   - Download missing datasets
   - Validate data completeness

3. **Data Processing** (`2-dataProcessing.R`)
   - Clip all spatial data to site extent + buffer
   - Calculate derived metrics (slope, aspect, flow accumulation)
   - Aggregate climate data to site location
   - Process soil data into analysis-ready format

4. **Section Generation** (Scripts 3-11)
   - Each section script generates its visualizations
   - Saves individual figures to `output/figures/`
   - Returns plot objects for final composition

5. **Report Assembly** (`99-renderReport.R` or R Markdown)
   - Combines all sections
   - Applies consistent styling
   - Generates final PDF/document

---

## 4. Technical Considerations

### 4.1 Coordinate Reference Systems
- **Standard:** Use appropriate UTM zone for site location
- **Transformations:** All data must be in same CRS before analysis
- **Display:** May use geographic (lat/long) for regional context maps

### 4.2 Data Caching Strategy
- Cache downloaded data to avoid repeated API calls
- Use `here::here()` for path management
- Implement cache validation (check data freshness)

### 4.3 Performance Optimization
- Use `terra` for large raster operations (faster than `raster`)
- Simplify complex geometries for display (`rmapshaper`)
- Consider `data.table` for large tabular operations

### 4.4 Reproducibility
- Set random seeds where needed
- Version control data sources (record download dates)
- Document all package versions
- Use `renv` for package management (optional but recommended)

### 4.5 Custom Themes & Styling
- Create consistent theme based on existing examples
- Define color palettes for each map type
- Establish typography hierarchy (using installed fonts)
- Create reusable annotation functions (scale bars, north arrows)

---

## 5. Section-Specific Implementation Notes

### Cover Sheet
- **Layout:** `grid` or `patchwork` for precise positioning
- **Text:** `ggtext` for formatted text blocks
- **Map:** Small inset using `ggspatial` or `cowplot::draw_plot()`

### Regional Context (Section 1)
- **Maps:** Multi-scale with `patchwork` or `cowplot`
- **Ecoregions:** Color-coded polygons from `sf`
- **Watershed:** Overlay boundary on base map
- **Text:** Side panel with `gridExtra::tableGrob()` or `gt` tables

### Topography (Section 2)
- **DEM Visualization:** `terra::plot()` or convert to `sf` for ggplot2
- **Hillshade:** Calculate using `terra::shade()` or `raster::hillShade()`
- **Slope/Aspect:** Calculate with `terra::terrain()`
- **Cross-section:** Extract profile line, plot with `ggplot2`

### Hydrology (Section 3)
- **Flow Direction:** Calculate with `whitebox` or `terra`
- **Flow Accumulation:** Derived from DEM
- **Streams:** Overlay NHD data
- **Flood Zones:** Overlay FEMA polygons

### Climate (Section 4)
- **Wind Rose:** Use `rWind` or custom `ggplot2` polar coordinates
- **Time Series:** `ggplot2` with dual y-axes (`sec.axis`)
- **Data:** Extract from PRISM rasters at site coordinates

### Soils (Section 5)
- **Soil Map:** `sf` polygons with `ggplot2::geom_sf()`
- **Profile Diagram:** Custom `ggplot2` or `grid` drawing
- **Tables:** `gt` or `kableExtra` for professional formatting

### Vulnerabilities (Section 6)
- **Composite Map:** Overlay multiple `sf` layers with transparency
- **Zones:** Create risk/opportunity polygons from analysis
- **Callouts:** `ggrepel` for annotations

### Data Tables (Section 7)
- **Formatting:** `gt` package for publication-quality tables
- **Layout:** `gridExtra` or `patchwork` for multi-table pages

---

## 6. Next Steps

1. **Update `0-setUp.R`** with complete package list
2. **Create site metadata template** (YAML format)
3. **Develop data acquisition functions** with caching
4. **Create custom theme** based on existing examples
5. **Build reusable mapping functions** (scale bar, north arrow, inset maps)
6. **Implement first section** (Cover Sheet) as proof of concept
7. **Iterate on design** based on output quality
8. **Documentation** - Create user guide for generating reports

---

## 7. Package Installation Priority

### Phase 1: Core Spatial & Visualization (Essential)
- sf, terra, ggplot2, patchwork, ggspatial, scales, systemfonts

### Phase 2: Data Acquisition (Essential)
- FedData, prism, rnoaa, nhdplusTools

### Phase 3: Advanced Analysis (Important)
- whitebox, soilDB, aqp, rWind

### Phase 4: Document & Tables (Important)
- rmarkdown, gt, gridExtra, magick

### Phase 5: Utilities & Polish (Nice to have)
- renv, config, tmap (alternative mapping)

---

## 8. Questions to Resolve

1. **Data Access:**
   - Do you have API keys for NOAA/PRISM or will we use public access?
   - Preferred method for parcel boundary input (shapefile, coordinates, drawing)?

2. **Workflow:**
   - Interactive R script workflow or R Markdown document?
   - Batch processing for multiple sites or single-site focus?

3. **Styling:**
   - Finalize color palette preferences
   - Typography hierarchy decisions
   - Logo/branding integration method

4. **Output:**
   - PDF only or also HTML/interactive?
   - Standard 11x17 or also support other sizes?

5. **Automation:**
   - Level of automation desired (fully automated vs. manual review steps)?
   - Integration with other tools (GIS software, design software)?

---

*Document created: 2025-01-02*  
*Last updated: 2025-01-02*


```

```markdown
# Site Assessment Report - Technical Planning Document

## Overview

This document outlines the technical architecture, package requirements, and implementation strategy for generating professional site assessment reports for landscape design projects.

**Output Format:** 
- PDF: 11x17 document (exclusively)
- Interactive: Quarto (.qmd) document for web/tablet viewing

**Primary Tool:** R with tidyverse and ggplot2 for visualization  
**Workflow:** Fully automated script-based workflow - input site data and run  
**Design Philosophy:** Focus on data acquisition, analysis, visualization, and layout first; styling refinement later  
**Data Principles:** Adhere to tidy data principles throughout

---

## 1. Package Requirements by Report Section

### Core Data Management (Tidyverse)
- **tidyverse** - Core suite (dplyr, tidyr, readr, purrr, tibble, stringr, forcats, lubridate, ggplot2)
- **here** - Project path management
- **readxl** - Excel file reading
- **yaml** - YAML parsing for site metadata

### Core Visualization & Design
- **ggplot2** - Primary plotting engine (included in tidyverse, but explicitly noted)
- **patchwork** - Multi-panel layout composition
- **cowplot** - Advanced plot arrangement and annotations
- **ggtext** - Rich text formatting in plots
- **ggrepel** - Smart label placement
- **scales** - Axis formatting and transformations
- **colorspace** / **viridis** / **RColorBrewer** / **scico** - Color palettes
- **rayshader** - 3D visualization for canopy heights and terrain
- **systemfonts** - Custom font management (Boska, Cabinet Grotesk, Pally, Tabular)

### Spatial Data & Mapping
- **sf** - Spatial data handling (CRS, geometries, spatial operations)
- **terra** - Raster data (DEM, slope, aspect calculations)
- **stars** - Alternative raster package (if needed)
- **rnaturalearth** - Base maps (countries, states, coastlines)
- **rmapshaper** - Spatial data simplification
- **tmap** - Thematic mapping (alternative/complement to ggplot2)
- **ggspatial** - Spatial annotations (scale bars, north arrows, inset maps)
- **maps** / **mapdata** - Additional base map data

### Climate & Weather Data
- **rnoaa** - NOAA climate data access (API)
- **prism** - PRISM climate data (temperature, precipitation) - API access
- **rWind** - Wind data processing and wind rose creation
- **circular** - Circular statistics for wind direction
- **Note:** Wind data will be combined with spatial data to create flow field visualizations based on built environment structures

### Soil Data
- **FedData** - Access to SSURGO soil data
- **soilDB** - Soil Survey Database queries
- **aqp** - Soil profile analysis and visualization

### Hydrology
- **nhdplusTools** - NHD Plus data and watershed delineation
- **whitebox** - Advanced terrain analysis (flow accumulation, watersheds)
- **raster** - Raster operations (may complement terra)

### API & Web Data Access
- **httr** - HTTP requests for REST API access
- **jsonlite** - JSON parsing for API responses
- **xml2** - XML parsing (if needed for some APIs)
- **Note:** All data acquisition should use API/REST server access where possible

### Document Generation (Quarto Workflow)
- **quarto** - Modern document generation (replaces R Markdown)
- **grid** / **gridExtra** - Advanced layout (tables, complex arrangements)
- **gt** / **kableExtra** - Professional table formatting
- **magick** - Image manipulation and composition

### Utilities
- **devtools** - Package development and installation
- **usethis** - Project setup utilities
- **config** - Configuration management
- **yaml** - YAML parsing for metadata

---

## 2. Data Sources & Acquisition Strategy

**Primary Strategy:** API-based data retrieval from REST servers or similar web services. All data acquisition should be automated via API calls where possible.

### Required Data Types

#### 2.1 Elevation & Topography
- **Source:** USGS 3D Elevation Program (3DEP)
- **Format:** Digital Elevation Model (DEM)
- **Resolution:** 1m, 3m, or 10m depending on site size
- **Access Methods:**
  - USGS National Map API (REST service)
  - `elevatr` package - API wrapper
  - `FedData` package - API wrapper
  - Direct REST API calls via `httr` if needed

#### 2.2 Watershed & Hydrology
- **Source:** USGS National Hydrography Dataset (NHD)
- **Format:** Vector (streams, waterbodies)
- **Access:** `nhdplusTools` or `FedData`
- **Watershed Delineation:** Calculate from DEM using `whitebox` or `raster`

#### 2.3 Ecoregions
- **Source:** EPA Ecoregions (Level III/IV)
- **Format:** Shapefile
- **Access:** Download from EPA website or use `FedData`

#### 2.4 Soils
- **Source:** NRCS SSURGO (Soil Survey Geographic Database)
- **Format:** Spatial polygons with attribute tables
- **Access:** `FedData::get_ssurgo()` or `soilDB` package
- **Required Attributes:**
  - Map unit name
  - Texture class
  - Drainage class
  - Hydrologic group
  - Permeability

#### 2.5 Climate Data
- **Source:** PRISM Climate Group (Oregon State)
- **Format:** Raster grids (monthly/annual normals)
- **Access:** `prism` package
- **Variables:**
  - Mean temperature (monthly/annual)
  - Precipitation (monthly/annual)
  - Potential evapotranspiration (if available)

#### 2.6 Wind Data
- **Source:** NOAA NCEI (National Centers for Environmental Information)
- **Format:** Time series data
- **Access:** `rnoaa` package or manual download
- **Required:** Direction, speed, frequency by season

#### 2.7 Flood Zones
- **Source:** FEMA Flood Map Service Center
- **Format:** Shapefile
- **Access:** Manual download or `FedData` (if available)

#### 2.8 Base Maps
- **Source:** OpenStreetMap, USGS, Natural Earth
- **Format:** Vector/raster tiles
- **Access:** `osmdata`, `rnaturalearth`, `ggmap` (if needed)

---

## 3. Script Architecture & Workflow

### Proposed Directory Structure

```
ggplot-GraphicDesign/
├── scripts/
│   ├── 0-setUp.R                    # Package installation & loading
│   ├── 1-dataAcquisition.R          # Download & cache all data sources
│   ├── 2-dataProcessing.R           # Process raw data into analysis-ready formats
│   ├── 3-coverSheet.R               # Generate cover sheet
│   ├── 4-regionalContext.R           # Section 1: Regional orientation
│   ├── 5-topography.R               # Section 2: Topography & landform
│   ├── 6-hydrology.R                # Section 3: Hydrology & drainage
│   ├── 7-climate.R                  # Section 4: Climate & wind
│   ├── 8-soils.R                    # Section 5: Soils & infiltration
│   ├── 9-vulnerabilities.R          # Section 6: Vulnerabilities & opportunities
│   ├── 10-dataTables.R              # Section 7: Supporting data tables
│   ├── 11-summary.R                 # Section 8: Summary & next steps
│   └── 99-renderReport.R             # Master script to generate full report
├── data/
│   ├── raw/                         # Raw downloaded data
│   │   ├── dem/
│   │   ├── soils/
│   │   ├── climate/
│   │   ├── watersheds/
│   │   └── ecoregions/
│   ├── processed/                   # Processed/analysis-ready data
│   └── siteInfo/                    # Site-specific metadata (YAML/CSV)
├── functions/
│   ├── mapHelpers.R                 # Reusable mapping functions
│   ├── themeCustom.R                # Custom ggplot themes
│   ├── dataHelpers.R                # Data processing utilities
│   └── tableHelpers.R               # Table formatting functions
├── templates/
│   ├── reportTemplate.Rmd           # R Markdown template
│   └── layoutTemplates.R            # Layout specifications
└── output/
    ├── reports/                     # Generated reports
    ├── figures/                     # Individual figure exports
    └── cache/                       # Cached computations
```

### Workflow Process

1. **Site Information Input**
   - Create site metadata file (YAML or CSV)
   - Contains: client name, address, lat/long, parcel boundary, project date

2. **Data Acquisition** (`1-dataAcquisition.R`)
   - Check cache for existing data
   - Download missing datasets
   - Validate data completeness

3. **Data Processing** (`2-dataProcessing.R`)
   - Clip all spatial data to site extent + buffer
   - Calculate derived metrics (slope, aspect, flow accumulation)
   - Aggregate climate data to site location
   - Process soil data into analysis-ready format

4. **Section Generation** (Scripts 3-11)
   - Each section script generates its visualizations
   - Saves individual figures to `output/figures/`
   - Returns plot objects for final composition

5. **Report Assembly** (`99-renderReport.R` or R Markdown)
   - Combines all sections
   - Applies consistent styling
   - Generates final PDF/document

---

## 4. Technical Considerations

### 4.1 Coordinate Reference Systems
- **Standard:** Use appropriate UTM zone for site location
- **Transformations:** All data must be in same CRS before analysis
- **Display:** May use geographic (lat/long) for regional context maps

### 4.2 Data Caching Strategy
- Cache downloaded data to avoid repeated API calls
- Use `here::here()` for path management
- Implement cache validation (check data freshness)

### 4.3 Performance Optimization
- Use `terra` for large raster operations (faster than `raster`)
- Simplify complex geometries for display (`rmapshaper`)
- Consider `data.table` for large tabular operations

### 4.4 Reproducibility
- Set random seeds where needed
- Version control data sources (record download dates)
- Document all package versions
- Use `renv` for package management (optional but recommended)

### 4.5 Custom Themes & Styling
- Create consistent theme based on existing examples
- Define color palettes for each map type
- Establish typography hierarchy (using installed fonts)
- Create reusable annotation functions (scale bars, north arrows)

---

## 5. Section-Specific Implementation Notes

### Cover Sheet
- **Layout:** `grid` or `patchwork` for precise positioning
- **Text:** `ggtext` for formatted text blocks
- **Map:** Small inset using `ggspatial` or `cowplot::draw_plot()`

### Regional Context (Section 1)
- **Maps:** Multi-scale with `patchwork` or `cowplot`
- **Ecoregions:** Color-coded polygons from `sf`
- **Watershed:** Overlay boundary on base map
- **Text:** Side panel with `gridExtra::tableGrob()` or `gt` tables

### Topography (Section 2)
- **DEM Visualization:** `terra::plot()` or convert to `sf` for ggplot2
- **Hillshade:** Calculate using `terra::shade()` or `raster::hillShade()`
- **Slope/Aspect:** Calculate with `terra::terrain()`
- **Cross-section:** Extract profile line, plot with `ggplot2`

### Hydrology (Section 3)
- **Flow Direction:** Calculate with `whitebox` or `terra`
- **Flow Accumulation:** Derived from DEM
- **Streams:** Overlay NHD data
- **Flood Zones:** Overlay FEMA polygons

### Climate (Section 4)
- **Wind Rose:** Use `rWind` or custom `ggplot2` polar coordinates
- **Time Series:** `ggplot2` with dual y-axes (`sec.axis`)
- **Data:** Extract from PRISM rasters at site coordinates

### Soils (Section 5)
- **Soil Map:** `sf` polygons with `ggplot2::geom_sf()`
- **Profile Diagram:** Custom `ggplot2` or `grid` drawing
- **Tables:** `gt` or `kableExtra` for professional formatting

### Vulnerabilities (Section 6)
- **Composite Map:** Overlay multiple `sf` layers with transparency
- **Zones:** Create risk/opportunity polygons from analysis
- **Callouts:** `ggrepel` for annotations

### Data Tables (Section 7)
- **Formatting:** `gt` package for publication-quality tables
- **Layout:** `gridExtra` or `patchwork` for multi-table pages

---

## 6. Next Steps

1. **Update `0-setUp.R`** with complete package list
2. **Create site metadata template** (YAML format)
3. **Develop data acquisition functions** with caching
4. **Create custom theme** based on existing examples
5. **Build reusable mapping functions** (scale bar, north arrow, inset maps)
6. **Implement first section** (Cover Sheet) as proof of concept
7. **Iterate on design** based on output quality
8. **Documentation** - Create user guide for generating reports

---

## 7. Package Installation Priority

### Phase 1: Core Spatial & Visualization (Essential)
- sf, terra, ggplot2, patchwork, ggspatial, scales, systemfonts

### Phase 2: Data Acquisition (Essential)
- FedData, prism, rnoaa, nhdplusTools

### Phase 3: Advanced Analysis (Important)
- whitebox, soilDB, aqp, rWind

### Phase 4: Document & Tables (Important)
- rmarkdown, gt, gridExtra, magick

### Phase 5: Utilities & Polish (Nice to have)
- renv, config, tmap (alternative mapping)

---

## 8. Questions to Resolve

1. **Data Access:**
   - Do you have API keys for NOAA/PRISM or will we use public access?
   - Preferred method for parcel boundary input (shapefile, coordinates, drawing)?

2. **Workflow:**
   - Interactive R script workflow or R Markdown document?
   - Batch processing for multiple sites or single-site focus?

3. **Styling:**
   - Finalize color palette preferences
   - Typography hierarchy decisions
   - Logo/branding integration method

4. **Output:**
   - PDF only or also HTML/interactive?
   - Standard 11x17 or also support other sizes?

5. **Automation:**
   - Level of automation desired (fully automated vs. manual review steps)?
   - Integration with other tools (GIS software, design software)?

---

*Document created: 2025-01-02*  
*Last updated: 2025-01-02*


```

```markdown
# Site Assessment Report - Technical Planning Document

## Overview

This document outlines the technical architecture, package requirements, and implementation strategy for generating professional site assessment reports for landscape design projects.

**Output Format:** 
- PDF: 11x17 document (exclusively)
- Interactive: Quarto (.qmd) document for web/tablet viewing

**Primary Tool:** R with tidyverse and ggplot2 for visualization  
**Workflow:** Fully automated script-based workflow - input site data and run  
**Design Philosophy:** Focus on data acquisition, analysis, visualization, and layout first; styling refinement later  
**Data Principles:** Adhere to tidy data principles throughout

---

## 1. Package Requirements by Report Section

### Core Data Management (Tidyverse)
- **tidyverse** - Core suite (dplyr, tidyr, readr, purrr, tibble, stringr, forcats, lubridate, ggplot2)
- **here** - Project path management
- **readxl** - Excel file reading
- **yaml** - YAML parsing for site metadata

### Core Visualization & Design
- **ggplot2** - Primary plotting engine (included in tidyverse, but explicitly noted)
- **patchwork** - Multi-panel layout composition
- **cowplot** - Advanced plot arrangement and annotations
- **ggtext** - Rich text formatting in plots
- **ggrepel** - Smart label placement
- **scales** - Axis formatting and transformations
- **colorspace** / **viridis** / **RColorBrewer** / **scico** - Color palettes
- **rayshader** - 3D visualization for canopy heights and terrain
- **systemfonts** - Custom font management (Boska, Cabinet Grotesk, Pally, Tabular)

### Spatial Data & Mapping
- **sf** - Spatial data handling (CRS, geometries, spatial operations)
- **terra** - Raster data (DEM, slope, aspect calculations)
- **stars** - Alternative raster package (if needed)
- **rnaturalearth** - Base maps (countries, states, coastlines)
- **rmapshaper** - Spatial data simplification
- **tmap** - Thematic mapping (alternative/complement to ggplot2)
- **ggspatial** - Spatial annotations (scale bars, north arrows, inset maps)
- **maps** / **mapdata** - Additional base map data

### Climate & Weather Data
- **rnoaa** - NOAA climate data access (API)
- **prism** - PRISM climate data (temperature, precipitation) - API access
- **rWind** - Wind data processing and wind rose creation
- **circular** - Circular statistics for wind direction
- **Note:** Wind data will be combined with spatial data to create flow field visualizations based on built environment structures

### Soil Data
- **FedData** - Access to SSURGO soil data
- **soilDB** - Soil Survey Database queries
- **aqp** - Soil profile analysis and visualization

### Hydrology
- **nhdplusTools** - NHD Plus data and watershed delineation
- **whitebox** - Advanced terrain analysis (flow accumulation, watersheds)
- **raster** - Raster operations (may complement terra)

### API & Web Data Access
- **httr** - HTTP requests for REST API access
- **jsonlite** - JSON parsing for API responses
- **xml2** - XML parsing (if needed for some APIs)
- **Note:** All data acquisition should use API/REST server access where possible

### Document Generation (Quarto Workflow)
- **quarto** - Modern document generation (replaces R Markdown)
- **grid** / **gridExtra** - Advanced layout (tables, complex arrangements)
- **gt** / **kableExtra** - Professional table formatting
- **magick** - Image manipulation and composition

### Utilities
- **devtools** - Package development and installation
- **usethis** - Project setup utilities
- **config** - Configuration management
- **yaml** - YAML parsing for metadata

---

## 2. Data Sources & Acquisition Strategy

**Primary Strategy:** API-based data retrieval from REST servers or similar web services. All data acquisition should be automated via API calls where possible.

### Required Data Types

#### 2.1 Elevation & Topography
- **Source:** USGS 3D Elevation Program (3DEP)
- **Format:** Digital Elevation Model (DEM)
- **Resolution:** 1m, 3m, or 10m depending on site size
- **Access Methods:**
  - USGS National Map API (REST service)
  - `elevatr` package - API wrapper
  - `FedData` package - API wrapper
  - Direct REST API calls via `httr` if needed

#### 2.2 Watershed & Hydrology
- **Source:** USGS National Hydrography Dataset (NHD)
- **Format:** Vector (streams, waterbodies)
- **Access:** 
  - NHDPlus REST API (via `nhdplusTools`)
  - `FedData` package (API wrapper)
  - Direct REST API calls if needed
- **Watershed Delineation:** Calculate from DEM using `whitebox` or `terra`

#### 2.3 Ecoregions
- **Source:** EPA Ecoregions (Level III/IV)
- **Format:** Spatial polygons
- **Access:** 
  - EPA REST/API service (if available)
  - `FedData` package (API wrapper)
  - Direct download with API call via `httr` if REST endpoint exists

#### 2.4 Soils
- **Source:** NRCS SSURGO (Soil Survey Geographic Database)
- **Format:** Spatial polygons with attribute tables
- **Access:** 
  - NRCS Soil Data Access API (via `soilDB` or `FedData`)
  - `FedData::get_ssurgo()` - API wrapper
  - `soilDB` package - Direct API access
- **Required Attributes:**
  - Map unit name
  - Texture class
  - Drainage class
  - Hydrologic group
  - Permeability

#### 2.5 Climate Data
- **Source:** PRISM Climate Group (Oregon State)
- **Format:** Raster grids (monthly/annual normals)
- **Access:** `prism` package (API access)
- **Variables:**
  - Mean temperature (monthly/annual)
  - Precipitation (monthly/annual)
  - Potential evapotranspiration (if available)

#### 2.6 Wind Data
- **Source:** NOAA NCEI (National Centers for Environmental Information)
- **Format:** Time series data
- **Access:** `rnoaa` package (NOAA API)
- **Required:** Direction, speed, frequency by season
- **Special Use:** Combine with spatial data to create flow field visualizations showing wind patterns around built environment structures

#### 2.7 Canopy Height / LiDAR Data
- **Source:** USGS 3DEP (LiDAR point clouds), NASA GEDI, or local sources
- **Format:** Point clouds or rasterized canopy height models
- **Access:** 
  - USGS 3DEP API (if available)
  - NASA GEDI API
  - Direct REST API calls
- **Visualization:** Use `rayshader` for 3D canopy height visualization

#### 2.8 Flood Zones
- **Source:** FEMA Flood Map Service Center
- **Format:** Spatial polygons
- **Access:** 
  - FEMA REST API (if available)
  - `FedData` package (if API wrapper exists)
  - Direct API calls via `httr`

#### 2.9 Base Maps
- **Source:** OpenStreetMap, USGS, Natural Earth
- **Format:** Vector/raster tiles
- **Access:** 
  - OSM Overpass API (via `osmdata`)
  - `rnaturalearth` package
  - REST tile services

---

## 3. Script Architecture & Workflow

### Proposed Directory Structure

```
ggplot-GraphicDesign/
├── scripts/
│   ├── 0-setUp.R                    # Package installation & loading
│   ├── 1-dataAcquisition.R          # Download & cache all data sources
│   ├── 2-dataProcessing.R           # Process raw data into analysis-ready formats
│   ├── 3-coverSheet.R               # Generate cover sheet
│   ├── 4-regionalContext.R           # Section 1: Regional orientation
│   ├── 5-topography.R               # Section 2: Topography & landform
│   ├── 6-hydrology.R                # Section 3: Hydrology & drainage
│   ├── 7-climate.R                  # Section 4: Climate & wind
│   ├── 8-soils.R                    # Section 5: Soils & infiltration
│   ├── 9-vulnerabilities.R          # Section 6: Vulnerabilities & opportunities
│   ├── 10-dataTables.R              # Section 7: Supporting data tables
│   ├── 11-summary.R                 # Section 8: Summary & next steps
│   └── 99-renderReport.R             # Master script to generate full report
├── data/
│   ├── raw/                         # Raw downloaded data
│   │   ├── dem/
│   │   ├── soils/
│   │   ├── climate/
│   │   ├── watersheds/
│   │   └── ecoregions/
│   ├── processed/                   # Processed/analysis-ready data
│   └── siteInfo/                    # Site-specific metadata (YAML/CSV)
├── functions/
│   ├── mapHelpers.R                 # Reusable mapping functions
│   ├── themeCustom.R                # Custom ggplot themes
│   ├── dataHelpers.R                # Data processing utilities
│   └── tableHelpers.R               # Table formatting functions
├── templates/
│   ├── reportTemplate.Rmd           # R Markdown template
│   └── layoutTemplates.R            # Layout specifications
└── output/
    ├── reports/                     # Generated reports
    ├── figures/                     # Individual figure exports
    └── cache/                       # Cached computations
```

### Workflow Process

1. **Site Information Input**
   - Create site metadata file (YAML or CSV)
   - Contains: client name, address, lat/long, parcel boundary, project date

2. **Data Acquisition** (`1-dataAcquisition.R`)
   - Check cache for existing data
   - Download missing datasets
   - Validate data completeness

3. **Data Processing** (`2-dataProcessing.R`)
   - Clip all spatial data to site extent + buffer
   - Calculate derived metrics (slope, aspect, flow accumulation)
   - Aggregate climate data to site location
   - Process soil data into analysis-ready format

4. **Section Generation** (Scripts 3-11)
   - Each section script generates its visualizations
   - Saves individual figures to `output/figures/`
   - Returns plot objects for final composition

5. **Report Assembly** (`99-renderReport.R` or R Markdown)
   - Combines all sections
   - Applies consistent styling
   - Generates final PDF/document

---

## 4. Technical Considerations

### 4.1 Coordinate Reference Systems
- **Standard:** Use appropriate UTM zone for site location
- **Transformations:** All data must be in same CRS before analysis
- **Display:** May use geographic (lat/long) for regional context maps

### 4.2 Data Caching Strategy
- Cache downloaded data to avoid repeated API calls
- Use `here::here()` for path management
- Implement cache validation (check data freshness)

### 4.3 Performance Optimization
- Use `terra` for large raster operations (faster than `raster`)
- Simplify complex geometries for display (`rmapshaper`)
- Consider `data.table` for large tabular operations

### 4.4 Reproducibility
- Set random seeds where needed
- Version control data sources (record download dates)
- Document all package versions
- Use `renv` for package management (optional but recommended)

### 4.5 Custom Themes & Styling
- Create consistent theme based on existing examples
- Define color palettes for each map type
- Establish typography hierarchy (using installed fonts)
- Create reusable annotation functions (scale bars, north arrows)

---

## 5. Section-Specific Implementation Notes

### Cover Sheet
- **Layout:** `grid` or `patchwork` for precise positioning
- **Text:** `ggtext` for formatted text blocks
- **Map:** Small inset using `ggspatial` or `cowplot::draw_plot()`

### Regional Context (Section 1)
- **Maps:** Multi-scale with `patchwork` or `cowplot`
- **Ecoregions:** Color-coded polygons from `sf`
- **Watershed:** Overlay boundary on base map
- **Text:** Side panel with `gridExtra::tableGrob()` or `gt` tables

### Topography (Section 2)
- **DEM Visualization:** `terra::plot()` or convert to `sf` for ggplot2
- **Hillshade:** Calculate using `terra::shade()` or `raster::hillShade()`
- **Slope/Aspect:** Calculate with `terra::terrain()`
- **Cross-section:** Extract profile line, plot with `ggplot2`

### Hydrology (Section 3)
- **Flow Direction:** Calculate with `whitebox` or `terra`
- **Flow Accumulation:** Derived from DEM
- **Streams:** Overlay NHD data
- **Flood Zones:** Overlay FEMA polygons

### Climate (Section 4)
- **Wind Rose:** Use `rWind` or custom `ggplot2` polar coordinates
- **Time Series:** `ggplot2` with dual y-axes (`sec.axis`)
- **Data:** Extract from PRISM rasters at site coordinates

### Soils (Section 5)
- **Soil Map:** `sf` polygons with `ggplot2::geom_sf()`
- **Profile Diagram:** Custom `ggplot2` or `grid` drawing
- **Tables:** `gt` or `kableExtra` for professional formatting

### Vulnerabilities (Section 6)
- **Composite Map:** Overlay multiple `sf` layers with transparency
- **Zones:** Create risk/opportunity polygons from analysis
- **Callouts:** `ggrepel` for annotations

### Data Tables (Section 7)
- **Formatting:** `gt` package for publication-quality tables
- **Layout:** `gridExtra` or `patchwork` for multi-table pages

---

## 6. Next Steps

1. **Update `0-setUp.R`** with complete package list
2. **Create site metadata template** (YAML format)
3. **Develop data acquisition functions** with caching
4. **Create custom theme** based on existing examples
5. **Build reusable mapping functions** (scale bar, north arrow, inset maps)
6. **Implement first section** (Cover Sheet) as proof of concept
7. **Iterate on design** based on output quality
8. **Documentation** - Create user guide for generating reports

---

## 7. Package Installation Priority

### Phase 1: Core Spatial & Visualization (Essential)
- sf, terra, ggplot2, patchwork, ggspatial, scales, systemfonts

### Phase 2: Data Acquisition (Essential)
- FedData, prism, rnoaa, nhdplusTools

### Phase 3: Advanced Analysis (Important)
- whitebox, soilDB, aqp, rWind

### Phase 4: Document & Tables (Important)
- rmarkdown, gt, gridExtra, magick

### Phase 5: Utilities & Polish (Nice to have)
- renv, config, tmap (alternative mapping)

---

## 8. Questions to Resolve

1. **Data Access:**
   - Do you have API keys for NOAA/PRISM or will we use public access?
   - Preferred method for parcel boundary input (shapefile, coordinates, drawing)?

2. **Workflow:**
   - Interactive R script workflow or R Markdown document?
   - Batch processing for multiple sites or single-site focus?

3. **Styling:**
   - Finalize color palette preferences
   - Typography hierarchy decisions
   - Logo/branding integration method

4. **Output:**
   - PDF only or also HTML/interactive?
   - Standard 11x17 or also support other sizes?

5. **Automation:**
   - Level of automation desired (fully automated vs. manual review steps)?
   - Integration with other tools (GIS software, design software)?

---

*Document created: 2025-01-02*  
*Last updated: 2025-01-02*


```

```markdown
# Site Assessment Report - Technical Planning Document

## Overview

This document outlines the technical architecture, package requirements, and implementation strategy for generating professional site assessment reports for landscape design projects.

**Output Format:** 
- PDF: 11x17 document (exclusively)
- Interactive: Quarto (.qmd) document for web/tablet viewing

**Primary Tool:** R with tidyverse and ggplot2 for visualization  
**Workflow:** Fully automated script-based workflow - input site data and run  
**Design Philosophy:** Focus on data acquisition, analysis, visualization, and layout first; styling refinement later  
**Data Principles:** Adhere to tidy data principles throughout

---

## 1. Package Requirements by Report Section

### Core Data Management (Tidyverse)
- **tidyverse** - Core suite (dplyr, tidyr, readr, purrr, tibble, stringr, forcats, lubridate, ggplot2)
- **here** - Project path management
- **readxl** - Excel file reading
- **yaml** - YAML parsing for site metadata

### Core Visualization & Design
- **ggplot2** - Primary plotting engine (included in tidyverse, but explicitly noted)
- **patchwork** - Multi-panel layout composition
- **cowplot** - Advanced plot arrangement and annotations
- **ggtext** - Rich text formatting in plots
- **ggrepel** - Smart label placement
- **scales** - Axis formatting and transformations
- **colorspace** / **viridis** / **RColorBrewer** / **scico** - Color palettes
- **rayshader** - 3D visualization for canopy heights and terrain
- **systemfonts** - Custom font management (Boska, Cabinet Grotesk, Pally, Tabular)

### Spatial Data & Mapping
- **sf** - Spatial data handling (CRS, geometries, spatial operations)
- **terra** - Raster data (DEM, slope, aspect calculations)
- **stars** - Alternative raster package (if needed)
- **rnaturalearth** - Base maps (countries, states, coastlines)
- **rmapshaper** - Spatial data simplification
- **tmap** - Thematic mapping (alternative/complement to ggplot2)
- **ggspatial** - Spatial annotations (scale bars, north arrows, inset maps)
- **maps** / **mapdata** - Additional base map data

### Climate & Weather Data
- **rnoaa** - NOAA climate data access (API)
- **prism** - PRISM climate data (temperature, precipitation) - API access
- **rWind** - Wind data processing and wind rose creation
- **circular** - Circular statistics for wind direction
- **Note:** Wind data will be combined with spatial data to create flow field visualizations based on built environment structures

### Soil Data
- **FedData** - Access to SSURGO soil data
- **soilDB** - Soil Survey Database queries
- **aqp** - Soil profile analysis and visualization

### Hydrology
- **nhdplusTools** - NHD Plus data and watershed delineation
- **whitebox** - Advanced terrain analysis (flow accumulation, watersheds)
- **raster** - Raster operations (may complement terra)

### API & Web Data Access
- **httr** - HTTP requests for REST API access
- **jsonlite** - JSON parsing for API responses
- **xml2** - XML parsing (if needed for some APIs)
- **Note:** All data acquisition should use API/REST server access where possible

### Document Generation (Quarto Workflow)
- **quarto** - Modern document generation (replaces R Markdown)
- **grid** / **gridExtra** - Advanced layout (tables, complex arrangements)
- **gt** / **kableExtra** - Professional table formatting
- **magick** - Image manipulation and composition

### Utilities
- **devtools** - Package development and installation
- **usethis** - Project setup utilities
- **config** - Configuration management
- **yaml** - YAML parsing for metadata

---

## 2. Data Sources & Acquisition Strategy

**Primary Strategy:** API-based data retrieval from REST servers or similar web services. All data acquisition should be automated via API calls where possible.

### Required Data Types

#### 2.1 Elevation & Topography
- **Source:** USGS 3D Elevation Program (3DEP)
- **Format:** Digital Elevation Model (DEM)
- **Resolution:** 1m, 3m, or 10m depending on site size
- **Access Methods:**
  - USGS National Map API (REST service)
  - `elevatr` package - API wrapper
  - `FedData` package - API wrapper
  - Direct REST API calls via `httr` if needed

#### 2.2 Watershed & Hydrology
- **Source:** USGS National Hydrography Dataset (NHD)
- **Format:** Vector (streams, waterbodies)
- **Access:** 
  - NHDPlus REST API (via `nhdplusTools`)
  - `FedData` package (API wrapper)
  - Direct REST API calls if needed
- **Watershed Delineation:** Calculate from DEM using `whitebox` or `terra`

#### 2.3 Ecoregions
- **Source:** EPA Ecoregions (Level III/IV)
- **Format:** Spatial polygons
- **Access:** 
  - EPA REST/API service (if available)
  - `FedData` package (API wrapper)
  - Direct download with API call via `httr` if REST endpoint exists

#### 2.4 Soils
- **Source:** NRCS SSURGO (Soil Survey Geographic Database)
- **Format:** Spatial polygons with attribute tables
- **Access:** 
  - NRCS Soil Data Access API (via `soilDB` or `FedData`)
  - `FedData::get_ssurgo()` - API wrapper
  - `soilDB` package - Direct API access
- **Required Attributes:**
  - Map unit name
  - Texture class
  - Drainage class
  - Hydrologic group
  - Permeability

#### 2.5 Climate Data
- **Source:** PRISM Climate Group (Oregon State)
- **Format:** Raster grids (monthly/annual normals)
- **Access:** `prism` package (API access)
- **Variables:**
  - Mean temperature (monthly/annual)
  - Precipitation (monthly/annual)
  - Potential evapotranspiration (if available)

#### 2.6 Wind Data
- **Source:** NOAA NCEI (National Centers for Environmental Information)
- **Format:** Time series data
- **Access:** `rnoaa` package (NOAA API)
- **Required:** Direction, speed, frequency by season
- **Special Use:** Combine with spatial data to create flow field visualizations showing wind patterns around built environment structures

#### 2.7 Canopy Height / LiDAR Data
- **Source:** USGS 3DEP (LiDAR point clouds), NASA GEDI, or local sources
- **Format:** Point clouds or rasterized canopy height models
- **Access:** 
  - USGS 3DEP API (if available)
  - NASA GEDI API
  - Direct REST API calls
- **Visualization:** Use `rayshader` for 3D canopy height visualization

#### 2.8 Flood Zones
- **Source:** FEMA Flood Map Service Center
- **Format:** Spatial polygons
- **Access:** 
  - FEMA REST API (if available)
  - `FedData` package (if API wrapper exists)
  - Direct API calls via `httr`

#### 2.9 Base Maps
- **Source:** OpenStreetMap, USGS, Natural Earth
- **Format:** Vector/raster tiles
- **Access:** 
  - OSM Overpass API (via `osmdata`)
  - `rnaturalearth` package
  - REST tile services

---

## 3. Script Architecture & Workflow

**Workflow Type:** Fully automated script-based workflow  
**Execution:** Run in RStudio - input site data and execute master script  
**Output:** PDF (11x17) + Interactive Quarto document (.qmd)

### Proposed Directory Structure

```
ggplot-GraphicDesign/
├── scripts/
│   ├── 0-setUp.R                    # Package installation & loading
│   ├── 1-dataAcquisition.R          # Download & cache all data via APIs
│   ├── 2-dataProcessing.R           # Process raw data into tidy formats
│   ├── 3-coverSheet.R               # Generate cover sheet
│   ├── 4-regionalContext.R           # Section 1: Regional orientation
│   ├── 5-topography.R               # Section 2: Topography & landform
│   ├── 6-hydrology.R                # Section 3: Hydrology & drainage
│   ├── 7-climate.R                  # Section 4: Climate & wind (with flow fields)
│   ├── 8-soils.R                    # Section 5: Soils & infiltration
│   ├── 9-vulnerabilities.R          # Section 6: Vulnerabilities & opportunities
│   ├── 10-dataTables.R              # Section 7: Supporting data tables
│   ├── 11-summary.R                 # Section 8: Summary & next steps
│   └── 99-renderReport.R             # Master script: runs all & generates outputs
├── data/
│   ├── raw/                         # Raw downloaded data (cached)
│   │   ├── dem/
│   │   ├── soils/
│   │   ├── climate/
│   │   ├── wind/
│   │   ├── canopy/
│   │   ├── watersheds/
│   │   └── ecoregions/
│   ├── processed/                   # Processed/analysis-ready tidy data
│   └── siteInfo/                    # Site-specific metadata (YAML)
├── functions/
│   ├── apiHelpers.R                 # API access functions (REST calls)
│   ├── mapHelpers.R                 # Reusable mapping functions
│   ├── dataHelpers.R                # Data processing utilities (tidy principles)
│   ├── flowFieldHelpers.R           # Wind flow field calculations
│   └── tableHelpers.R               # Table formatting functions
├── templates/
│   ├── reportTemplate.qmd           # Quarto template for interactive output
│   └── layoutTemplates.R            # Layout specifications
└── output/
    ├── reports/                     # Generated reports (PDF + .qmd)
    ├── figures/                     # Individual figure exports
    └── cache/                       # Cached computations
```

### Automated Workflow Process

1. **Site Information Input**
   - User creates/edits site metadata file (`data/siteInfo/siteMetadata_[project].yaml`)
   - Contains: client name, address, lat/long, parcel boundary, project date
   - Single source of truth for all site parameters

2. **Data Acquisition** (`1-dataAcquisition.R`)
   - **Fully automated via APIs**
   - Check cache for existing data (with validation)
   - Make API calls to retrieve missing datasets:
     - DEM from USGS 3DEP API
     - Soils from NRCS SSURGO API
     - Climate from PRISM API
     - Wind from NOAA API
     - Watersheds from NHDPlus API
     - Ecoregions from EPA (if API available)
     - Canopy height from USGS/NASA APIs
   - Cache all downloaded data
   - Validate data completeness

3. **Data Processing** (`2-dataProcessing.R`)
   - **Adhere to tidy data principles**
   - Convert all data to tidy format (tibbles, sf objects)
   - Clip all spatial data to site extent + buffer
   - Calculate derived metrics (slope, aspect, flow accumulation)
   - Aggregate climate data to site location
   - Process soil data into tidy format
   - Calculate wind flow fields (combining wind data with spatial structures)
   - Process canopy height data for rayshader visualization
   - Save processed data in tidy format

4. **Section Generation** (Scripts 3-11)
   - Each section script:
     - Reads processed tidy data
     - Generates visualizations using ggplot2
     - Saves individual figures to `output/figures/`
     - Returns plot objects and data for final composition
   - All data manipulation follows tidyverse principles

5. **Report Assembly** (`99-renderReport.R`)
   - **Master script that runs everything**
   - Sources all section scripts
   - Combines all sections
   - Generates PDF output (11x17) using `quarto render`
   - Generates interactive Quarto document (.qmd)
   - Fully automated - user just runs this script

### Execution Flow

```r
# User workflow (in RStudio):
# 1. Edit site metadata: data/siteInfo/siteMetadata_[project].yaml
# 2. Run master script:
source("scripts/99-renderReport.R")
# 3. Outputs generated in output/reports/
```

---

## 4. Technical Considerations

### 4.1 Coordinate Reference Systems
- **Standard:** Use appropriate UTM zone for site location
- **Transformations:** All data must be in same CRS before analysis
- **Display:** May use geographic (lat/long) for regional context maps

### 4.2 Data Caching Strategy
- Cache downloaded data to avoid repeated API calls
- Use `here::here()` for path management
- Implement cache validation (check data freshness)

### 4.3 Performance Optimization
- Use `terra` for large raster operations (faster than `raster`)
- Simplify complex geometries for display (`rmapshaper`)
- Consider `data.table` for large tabular operations

### 4.4 Reproducibility
- Set random seeds where needed
- Version control data sources (record download dates)
- Document all package versions
- Use `renv` for package management (optional but recommended)

### 4.5 Custom Themes & Styling
- Create consistent theme based on existing examples
- Define color palettes for each map type
- Establish typography hierarchy (using installed fonts)
- Create reusable annotation functions (scale bars, north arrows)

---

## 5. Section-Specific Implementation Notes

### Cover Sheet
- **Layout:** `grid` or `patchwork` for precise positioning
- **Text:** `ggtext` for formatted text blocks
- **Map:** Small inset using `ggspatial` or `cowplot::draw_plot()`

### Regional Context (Section 1)
- **Maps:** Multi-scale with `patchwork` or `cowplot`
- **Ecoregions:** Color-coded polygons from `sf`
- **Watershed:** Overlay boundary on base map
- **Text:** Side panel with `gridExtra::tableGrob()` or `gt` tables

### Topography (Section 2)
- **DEM Visualization:** `terra::plot()` or convert to `sf` for ggplot2
- **Hillshade:** Calculate using `terra::shade()` or `raster::hillShade()`
- **Slope/Aspect:** Calculate with `terra::terrain()`
- **Cross-section:** Extract profile line, plot with `ggplot2`

### Hydrology (Section 3)
- **Flow Direction:** Calculate with `whitebox` or `terra`
- **Flow Accumulation:** Derived from DEM
- **Streams:** Overlay NHD data
- **Flood Zones:** Overlay FEMA polygons

### Climate (Section 4)
- **Wind Rose:** Use `rWind` or custom `ggplot2` polar coordinates
- **Time Series:** `ggplot2` with dual y-axes (`sec.axis`)
- **Data:** Extract from PRISM rasters at site coordinates

### Soils (Section 5)
- **Soil Map:** `sf` polygons with `ggplot2::geom_sf()`
- **Profile Diagram:** Custom `ggplot2` or `grid` drawing
- **Tables:** `gt` or `kableExtra` for professional formatting

### Vulnerabilities (Section 6)
- **Composite Map:** Overlay multiple `sf` layers with transparency
- **Zones:** Create risk/opportunity polygons from analysis
- **Callouts:** `ggrepel` for annotations

### Data Tables (Section 7)
- **Formatting:** `gt` package for publication-quality tables
- **Layout:** `gridExtra` or `patchwork` for multi-table pages

---

## 6. Next Steps

1. **Update `0-setUp.R`** with complete package list
2. **Create site metadata template** (YAML format)
3. **Develop data acquisition functions** with caching
4. **Create custom theme** based on existing examples
5. **Build reusable mapping functions** (scale bar, north arrow, inset maps)
6. **Implement first section** (Cover Sheet) as proof of concept
7. **Iterate on design** based on output quality
8. **Documentation** - Create user guide for generating reports

---

## 7. Package Installation Priority

### Phase 1: Core Spatial & Visualization (Essential)
- sf, terra, ggplot2, patchwork, ggspatial, scales, systemfonts

### Phase 2: Data Acquisition (Essential)
- FedData, prism, rnoaa, nhdplusTools

### Phase 3: Advanced Analysis (Important)
- whitebox, soilDB, aqp, rWind

### Phase 4: Document & Tables (Important)
- rmarkdown, gt, gridExtra, magick

### Phase 5: Utilities & Polish (Nice to have)
- renv, config, tmap (alternative mapping)

---

## 8. Questions to Resolve

1. **Data Access:**
   - Do you have API keys for NOAA/PRISM or will we use public access?
   - Preferred method for parcel boundary input (shapefile, coordinates, drawing)?

2. **Workflow:**
   - Interactive R script workflow or R Markdown document?
   - Batch processing for multiple sites or single-site focus?

3. **Styling:**
   - Finalize color palette preferences
   - Typography hierarchy decisions
   - Logo/branding integration method

4. **Output:**
   - PDF only or also HTML/interactive?
   - Standard 11x17 or also support other sizes?

5. **Automation:**
   - Level of automation desired (fully automated vs. manual review steps)?
   - Integration with other tools (GIS software, design software)?

---

*Document created: 2025-01-02*  
*Last updated: 2025-01-02*


```

```markdown
# Site Assessment Report - Technical Planning Document

## Overview

This document outlines the technical architecture, package requirements, and implementation strategy for generating professional site assessment reports for landscape design projects.

**Output Format:** 
- PDF: 11x17 document (exclusively)
- Interactive: Quarto (.qmd) document for web/tablet viewing

**Primary Tool:** R with tidyverse and ggplot2 for visualization  
**Workflow:** Fully automated script-based workflow - input site data and run  
**Design Philosophy:** Focus on data acquisition, analysis, visualization, and layout first; styling refinement later  
**Data Principles:** Adhere to tidy data principles throughout

---

## 1. Package Requirements by Report Section

### Core Data Management (Tidyverse)
- **tidyverse** - Core suite (dplyr, tidyr, readr, purrr, tibble, stringr, forcats, lubridate, ggplot2)
- **here** - Project path management
- **readxl** - Excel file reading
- **yaml** - YAML parsing for site metadata

### Core Visualization & Design
- **ggplot2** - Primary plotting engine (included in tidyverse, but explicitly noted)
- **patchwork** - Multi-panel layout composition
- **cowplot** - Advanced plot arrangement and annotations
- **ggtext** - Rich text formatting in plots
- **ggrepel** - Smart label placement
- **scales** - Axis formatting and transformations
- **colorspace** / **viridis** / **RColorBrewer** / **scico** - Color palettes
- **rayshader** - 3D visualization for canopy heights and terrain
- **systemfonts** - Custom font management (Boska, Cabinet Grotesk, Pally, Tabular)

### Spatial Data & Mapping
- **sf** - Spatial data handling (CRS, geometries, spatial operations)
- **terra** - Raster data (DEM, slope, aspect calculations)
- **stars** - Alternative raster package (if needed)
- **rnaturalearth** - Base maps (countries, states, coastlines)
- **rmapshaper** - Spatial data simplification
- **tmap** - Thematic mapping (alternative/complement to ggplot2)
- **ggspatial** - Spatial annotations (scale bars, north arrows, inset maps)
- **maps** / **mapdata** - Additional base map data

### Climate & Weather Data
- **rnoaa** - NOAA climate data access (API)
- **prism** - PRISM climate data (temperature, precipitation) - API access
- **rWind** - Wind data processing and wind rose creation
- **circular** - Circular statistics for wind direction
- **Note:** Wind data will be combined with spatial data to create flow field visualizations based on built environment structures

### Soil Data
- **FedData** - Access to SSURGO soil data
- **soilDB** - Soil Survey Database queries
- **aqp** - Soil profile analysis and visualization

### Hydrology
- **nhdplusTools** - NHD Plus data and watershed delineation
- **whitebox** - Advanced terrain analysis (flow accumulation, watersheds)
- **raster** - Raster operations (may complement terra)

### API & Web Data Access
- **httr** - HTTP requests for REST API access
- **jsonlite** - JSON parsing for API responses
- **xml2** - XML parsing (if needed for some APIs)
- **Note:** All data acquisition should use API/REST server access where possible

### Document Generation (Quarto Workflow)
- **quarto** - Modern document generation (replaces R Markdown)
- **grid** / **gridExtra** - Advanced layout (tables, complex arrangements)
- **gt** / **kableExtra** - Professional table formatting
- **magick** - Image manipulation and composition

### Utilities
- **devtools** - Package development and installation
- **usethis** - Project setup utilities
- **config** - Configuration management
- **yaml** - YAML parsing for metadata

---

## 2. Data Sources & Acquisition Strategy

**Primary Strategy:** API-based data retrieval from REST servers or similar web services. All data acquisition should be automated via API calls where possible.

### Required Data Types

#### 2.1 Elevation & Topography
- **Source:** USGS 3D Elevation Program (3DEP)
- **Format:** Digital Elevation Model (DEM)
- **Resolution:** 1m, 3m, or 10m depending on site size
- **Access Methods:**
  - USGS National Map API (REST service)
  - `elevatr` package - API wrapper
  - `FedData` package - API wrapper
  - Direct REST API calls via `httr` if needed

#### 2.2 Watershed & Hydrology
- **Source:** USGS National Hydrography Dataset (NHD)
- **Format:** Vector (streams, waterbodies)
- **Access:** 
  - NHDPlus REST API (via `nhdplusTools`)
  - `FedData` package (API wrapper)
  - Direct REST API calls if needed
- **Watershed Delineation:** Calculate from DEM using `whitebox` or `terra`

#### 2.3 Ecoregions
- **Source:** EPA Ecoregions (Level III/IV)
- **Format:** Spatial polygons
- **Access:** 
  - EPA REST/API service (if available)
  - `FedData` package (API wrapper)
  - Direct download with API call via `httr` if REST endpoint exists

#### 2.4 Soils
- **Source:** NRCS SSURGO (Soil Survey Geographic Database)
- **Format:** Spatial polygons with attribute tables
- **Access:** 
  - NRCS Soil Data Access API (via `soilDB` or `FedData`)
  - `FedData::get_ssurgo()` - API wrapper
  - `soilDB` package - Direct API access
- **Required Attributes:**
  - Map unit name
  - Texture class
  - Drainage class
  - Hydrologic group
  - Permeability

#### 2.5 Climate Data
- **Source:** PRISM Climate Group (Oregon State)
- **Format:** Raster grids (monthly/annual normals)
- **Access:** `prism` package (API access)
- **Variables:**
  - Mean temperature (monthly/annual)
  - Precipitation (monthly/annual)
  - Potential evapotranspiration (if available)

#### 2.6 Wind Data
- **Source:** NOAA NCEI (National Centers for Environmental Information)
- **Format:** Time series data
- **Access:** `rnoaa` package (NOAA API)
- **Required:** Direction, speed, frequency by season
- **Special Use:** Combine with spatial data to create flow field visualizations showing wind patterns around built environment structures

#### 2.7 Canopy Height / LiDAR Data
- **Source:** USGS 3DEP (LiDAR point clouds), NASA GEDI, or local sources
- **Format:** Point clouds or rasterized canopy height models
- **Access:** 
  - USGS 3DEP API (if available)
  - NASA GEDI API
  - Direct REST API calls
- **Visualization:** Use `rayshader` for 3D canopy height visualization

#### 2.8 Flood Zones
- **Source:** FEMA Flood Map Service Center
- **Format:** Spatial polygons
- **Access:** 
  - FEMA REST API (if available)
  - `FedData` package (if API wrapper exists)
  - Direct API calls via `httr`

#### 2.9 Base Maps
- **Source:** OpenStreetMap, USGS, Natural Earth
- **Format:** Vector/raster tiles
- **Access:** 
  - OSM Overpass API (via `osmdata`)
  - `rnaturalearth` package
  - REST tile services

---

## 3. Script Architecture & Workflow

**Workflow Type:** Fully automated script-based workflow  
**Execution:** Run in RStudio - input site data and execute master script  
**Output:** PDF (11x17) + Interactive Quarto document (.qmd)

### Proposed Directory Structure

```
ggplot-GraphicDesign/
├── scripts/
│   ├── 0-setUp.R                    # Package installation & loading
│   ├── 1-dataAcquisition.R          # Download & cache all data via APIs
│   ├── 2-dataProcessing.R           # Process raw data into tidy formats
│   ├── 3-coverSheet.R               # Generate cover sheet
│   ├── 4-regionalContext.R           # Section 1: Regional orientation
│   ├── 5-topography.R               # Section 2: Topography & landform
│   ├── 6-hydrology.R                # Section 3: Hydrology & drainage
│   ├── 7-climate.R                  # Section 4: Climate & wind (with flow fields)
│   ├── 8-soils.R                    # Section 5: Soils & infiltration
│   ├── 9-vulnerabilities.R          # Section 6: Vulnerabilities & opportunities
│   ├── 10-dataTables.R              # Section 7: Supporting data tables
│   ├── 11-summary.R                 # Section 8: Summary & next steps
│   └── 99-renderReport.R             # Master script: runs all & generates outputs
├── data/
│   ├── raw/                         # Raw downloaded data (cached)
│   │   ├── dem/
│   │   ├── soils/
│   │   ├── climate/
│   │   ├── wind/
│   │   ├── canopy/
│   │   ├── watersheds/
│   │   └── ecoregions/
│   ├── processed/                   # Processed/analysis-ready tidy data
│   └── siteInfo/                    # Site-specific metadata (YAML)
├── functions/
│   ├── apiHelpers.R                 # API access functions (REST calls)
│   ├── mapHelpers.R                 # Reusable mapping functions
│   ├── dataHelpers.R                # Data processing utilities (tidy principles)
│   ├── flowFieldHelpers.R           # Wind flow field calculations
│   └── tableHelpers.R               # Table formatting functions
├── templates/
│   ├── reportTemplate.qmd           # Quarto template for interactive output
│   └── layoutTemplates.R            # Layout specifications
└── output/
    ├── reports/                     # Generated reports (PDF + .qmd)
    ├── figures/                     # Individual figure exports
    └── cache/                       # Cached computations
```

### Automated Workflow Process

1. **Site Information Input**
   - User creates/edits site metadata file (`data/siteInfo/siteMetadata_[project].yaml`)
   - Contains: client name, address, lat/long, parcel boundary, project date
   - Single source of truth for all site parameters

2. **Data Acquisition** (`1-dataAcquisition.R`)
   - **Fully automated via APIs**
   - Check cache for existing data (with validation)
   - Make API calls to retrieve missing datasets:
     - DEM from USGS 3DEP API
     - Soils from NRCS SSURGO API
     - Climate from PRISM API
     - Wind from NOAA API
     - Watersheds from NHDPlus API
     - Ecoregions from EPA (if API available)
     - Canopy height from USGS/NASA APIs
   - Cache all downloaded data
   - Validate data completeness

3. **Data Processing** (`2-dataProcessing.R`)
   - **Adhere to tidy data principles**
   - Convert all data to tidy format (tibbles, sf objects)
   - Clip all spatial data to site extent + buffer
   - Calculate derived metrics (slope, aspect, flow accumulation)
   - Aggregate climate data to site location
   - Process soil data into tidy format
   - Calculate wind flow fields (combining wind data with spatial structures)
   - Process canopy height data for rayshader visualization
   - Save processed data in tidy format

4. **Section Generation** (Scripts 3-11)
   - Each section script:
     - Reads processed tidy data
     - Generates visualizations using ggplot2
     - Saves individual figures to `output/figures/`
     - Returns plot objects and data for final composition
   - All data manipulation follows tidyverse principles

5. **Report Assembly** (`99-renderReport.R`)
   - **Master script that runs everything**
   - Sources all section scripts
   - Combines all sections
   - Generates PDF output (11x17) using `quarto render`
   - Generates interactive Quarto document (.qmd)
   - Fully automated - user just runs this script

### Execution Flow

```r
# User workflow (in RStudio):
# 1. Edit site metadata: data/siteInfo/siteMetadata_[project].yaml
# 2. Run master script:
source("scripts/99-renderReport.R")
# 3. Outputs generated in output/reports/
```

---

## 4. Technical Considerations

### 4.1 Coordinate Reference Systems
- **Standard:** Use appropriate UTM zone for site location
- **Transformations:** All data must be in same CRS before analysis
- **Display:** May use geographic (lat/long) for regional context maps

### 4.2 Data Caching Strategy
- Cache downloaded data to avoid repeated API calls
- Use `here::here()` for path management
- Implement cache validation (check data freshness)

### 4.3 Performance Optimization
- Use `terra` for large raster operations (faster than `raster`)
- Simplify complex geometries for display (`rmapshaper`)
- Consider `data.table` for large tabular operations

### 4.4 Reproducibility
- Set random seeds where needed
- Version control data sources (record download dates)
- Document all package versions
- Use `renv` for package management (optional but recommended)

### 4.5 Custom Themes & Styling
- Create consistent theme based on existing examples
- Define color palettes for each map type
- Establish typography hierarchy (using installed fonts)
- Create reusable annotation functions (scale bars, north arrows)

---

## 5. Section-Specific Implementation Notes

### Cover Sheet
- **Layout:** `grid` or `patchwork` for precise positioning
- **Text:** `ggtext` for formatted text blocks
- **Map:** Small inset using `ggspatial` or `cowplot::draw_plot()`

### Regional Context (Section 1)
- **Maps:** Multi-scale with `patchwork` or `cowplot`
- **Ecoregions:** Color-coded polygons from `sf`
- **Watershed:** Overlay boundary on base map
- **Text:** Side panel with `gridExtra::tableGrob()` or `gt` tables

### Topography (Section 2)
- **DEM Visualization:** `terra::plot()` or convert to `sf` for ggplot2
- **Hillshade:** Calculate using `terra::shade()` or `raster::hillShade()`
- **Slope/Aspect:** Calculate with `terra::terrain()`
- **Cross-section:** Extract profile line, plot with `ggplot2`

### Hydrology (Section 3)
- **Flow Direction:** Calculate with `whitebox` or `terra`
- **Flow Accumulation:** Derived from DEM
- **Streams:** Overlay NHD data
- **Flood Zones:** Overlay FEMA polygons

### Climate (Section 4)
- **Wind Rose:** Use `rWind` or custom `ggplot2` polar coordinates
- **Time Series:** `ggplot2` with dual y-axes (`sec.axis`)
- **Data:** Extract from PRISM rasters at site coordinates
- **Wind Flow Fields:** 
  - Combine wind data (direction, speed) with spatial data of built environment structures
  - Create flow field visualization showing how wind patterns are affected by structures
  - Use `ggplot2` with vector fields or streamlines
  - May use `rayshader` for 3D wind visualization if appropriate

### Soils (Section 5)
- **Soil Map:** `sf` polygons with `ggplot2::geom_sf()`
- **Profile Diagram:** Custom `ggplot2` or `grid` drawing
- **Tables:** `gt` or `kableExtra` for professional formatting

### Vulnerabilities (Section 6)
- **Composite Map:** Overlay multiple `sf` layers with transparency
- **Zones:** Create risk/opportunity polygons from analysis
- **Callouts:** `ggrepel` for annotations

### Data Tables (Section 7)
- **Formatting:** `gt` package for publication-quality tables
- **Layout:** `gridExtra` or `patchwork` for multi-table pages

---

## 6. Next Steps

1. **Update `0-setUp.R`** with complete package list
2. **Create site metadata template** (YAML format)
3. **Develop data acquisition functions** with caching
4. **Create custom theme** based on existing examples
5. **Build reusable mapping functions** (scale bar, north arrow, inset maps)
6. **Implement first section** (Cover Sheet) as proof of concept
7. **Iterate on design** based on output quality
8. **Documentation** - Create user guide for generating reports

---

## 7. Package Installation Priority

### Phase 1: Core Spatial & Visualization (Essential)
- sf, terra, ggplot2, patchwork, ggspatial, scales, systemfonts

### Phase 2: Data Acquisition (Essential)
- FedData, prism, rnoaa, nhdplusTools

### Phase 3: Advanced Analysis (Important)
- whitebox, soilDB, aqp, rWind

### Phase 4: Document & Tables (Important)
- rmarkdown, gt, gridExtra, magick

### Phase 5: Utilities & Polish (Nice to have)
- renv, config, tmap (alternative mapping)

---

## 8. Questions to Resolve

1. **Data Access:**
   - Do you have API keys for NOAA/PRISM or will we use public access?
   - Preferred method for parcel boundary input (shapefile, coordinates, drawing)?

2. **Workflow:**
   - Interactive R script workflow or R Markdown document?
   - Batch processing for multiple sites or single-site focus?

3. **Styling:**
   - Finalize color palette preferences
   - Typography hierarchy decisions
   - Logo/branding integration method

4. **Output:**
   - PDF only or also HTML/interactive?
   - Standard 11x17 or also support other sizes?

5. **Automation:**
   - Level of automation desired (fully automated vs. manual review steps)?
   - Integration with other tools (GIS software, design software)?

---

*Document created: 2025-01-02*  
*Last updated: 2025-01-02*


```

```markdown
# Site Assessment Report - Technical Planning Document

## Overview

This document outlines the technical architecture, package requirements, and implementation strategy for generating professional site assessment reports for landscape design projects.

**Output Format:** 
- PDF: 11x17 document (exclusively)
- Interactive: Quarto (.qmd) document for web/tablet viewing

**Primary Tool:** R with tidyverse and ggplot2 for visualization  
**Workflow:** Fully automated script-based workflow - input site data and run  
**Design Philosophy:** Focus on data acquisition, analysis, visualization, and layout first; styling refinement later  
**Data Principles:** Adhere to tidy data principles throughout

---

## 1. Package Requirements by Report Section

### Core Data Management (Tidyverse)
- **tidyverse** - Core suite (dplyr, tidyr, readr, purrr, tibble, stringr, forcats, lubridate, ggplot2)
- **here** - Project path management
- **readxl** - Excel file reading
- **yaml** - YAML parsing for site metadata

### Core Visualization & Design
- **ggplot2** - Primary plotting engine (included in tidyverse, but explicitly noted)
- **patchwork** - Multi-panel layout composition
- **cowplot** - Advanced plot arrangement and annotations
- **ggtext** - Rich text formatting in plots
- **ggrepel** - Smart label placement
- **scales** - Axis formatting and transformations
- **colorspace** / **viridis** / **RColorBrewer** / **scico** - Color palettes
- **rayshader** - 3D visualization for canopy heights and terrain
- **systemfonts** - Custom font management (Boska, Cabinet Grotesk, Pally, Tabular)

### Spatial Data & Mapping
- **sf** - Spatial data handling (CRS, geometries, spatial operations)
- **terra** - Raster data (DEM, slope, aspect calculations)
- **stars** - Alternative raster package (if needed)
- **rnaturalearth** - Base maps (countries, states, coastlines)
- **rmapshaper** - Spatial data simplification
- **tmap** - Thematic mapping (alternative/complement to ggplot2)
- **ggspatial** - Spatial annotations (scale bars, north arrows, inset maps)
- **maps** / **mapdata** - Additional base map data

### Climate & Weather Data
- **rnoaa** - NOAA climate data access (API)
- **prism** - PRISM climate data (temperature, precipitation) - API access
- **rWind** - Wind data processing and wind rose creation
- **circular** - Circular statistics for wind direction
- **Note:** Wind data will be combined with spatial data to create flow field visualizations based on built environment structures

### Soil Data
- **FedData** - Access to SSURGO soil data
- **soilDB** - Soil Survey Database queries
- **aqp** - Soil profile analysis and visualization

### Hydrology
- **nhdplusTools** - NHD Plus data and watershed delineation
- **whitebox** - Advanced terrain analysis (flow accumulation, watersheds)
- **raster** - Raster operations (may complement terra)

### API & Web Data Access
- **httr** - HTTP requests for REST API access
- **jsonlite** - JSON parsing for API responses
- **xml2** - XML parsing (if needed for some APIs)
- **Note:** All data acquisition should use API/REST server access where possible

### Document Generation (Quarto Workflow)
- **quarto** - Modern document generation (replaces R Markdown)
- **grid** / **gridExtra** - Advanced layout (tables, complex arrangements)
- **gt** / **kableExtra** - Professional table formatting
- **magick** - Image manipulation and composition

### Utilities
- **devtools** - Package development and installation
- **usethis** - Project setup utilities
- **config** - Configuration management
- **yaml** - YAML parsing for metadata

---

## 2. Data Sources & Acquisition Strategy

**Primary Strategy:** API-based data retrieval from REST servers or similar web services. All data acquisition should be automated via API calls where possible.

### Required Data Types

#### 2.1 Elevation & Topography
- **Source:** USGS 3D Elevation Program (3DEP)
- **Format:** Digital Elevation Model (DEM)
- **Resolution:** 1m, 3m, or 10m depending on site size
- **Access Methods:**
  - USGS National Map API (REST service)
  - `elevatr` package - API wrapper
  - `FedData` package - API wrapper
  - Direct REST API calls via `httr` if needed

#### 2.2 Watershed & Hydrology
- **Source:** USGS National Hydrography Dataset (NHD)
- **Format:** Vector (streams, waterbodies)
- **Access:** 
  - NHDPlus REST API (via `nhdplusTools`)
  - `FedData` package (API wrapper)
  - Direct REST API calls if needed
- **Watershed Delineation:** Calculate from DEM using `whitebox` or `terra`

#### 2.3 Ecoregions
- **Source:** EPA Ecoregions (Level III/IV)
- **Format:** Spatial polygons
- **Access:** 
  - EPA REST/API service (if available)
  - `FedData` package (API wrapper)
  - Direct download with API call via `httr` if REST endpoint exists

#### 2.4 Soils
- **Source:** NRCS SSURGO (Soil Survey Geographic Database)
- **Format:** Spatial polygons with attribute tables
- **Access:** 
  - NRCS Soil Data Access API (via `soilDB` or `FedData`)
  - `FedData::get_ssurgo()` - API wrapper
  - `soilDB` package - Direct API access
- **Required Attributes:**
  - Map unit name
  - Texture class
  - Drainage class
  - Hydrologic group
  - Permeability

#### 2.5 Climate Data
- **Source:** PRISM Climate Group (Oregon State)
- **Format:** Raster grids (monthly/annual normals)
- **Access:** `prism` package (API access)
- **Variables:**
  - Mean temperature (monthly/annual)
  - Precipitation (monthly/annual)
  - Potential evapotranspiration (if available)

#### 2.6 Wind Data
- **Source:** NOAA NCEI (National Centers for Environmental Information)
- **Format:** Time series data
- **Access:** `rnoaa` package (NOAA API)
- **Required:** Direction, speed, frequency by season
- **Special Use:** Combine with spatial data to create flow field visualizations showing wind patterns around built environment structures

#### 2.7 Canopy Height / LiDAR Data
- **Source:** USGS 3DEP (LiDAR point clouds), NASA GEDI, or local sources
- **Format:** Point clouds or rasterized canopy height models
- **Access:** 
  - USGS 3DEP API (if available)
  - NASA GEDI API
  - Direct REST API calls
- **Visualization:** Use `rayshader` for 3D canopy height visualization

#### 2.8 Flood Zones
- **Source:** FEMA Flood Map Service Center
- **Format:** Spatial polygons
- **Access:** 
  - FEMA REST API (if available)
  - `FedData` package (if API wrapper exists)
  - Direct API calls via `httr`

#### 2.9 Base Maps
- **Source:** OpenStreetMap, USGS, Natural Earth
- **Format:** Vector/raster tiles
- **Access:** 
  - OSM Overpass API (via `osmdata`)
  - `rnaturalearth` package
  - REST tile services

---

## 3. Script Architecture & Workflow

**Workflow Type:** Fully automated script-based workflow  
**Execution:** Run in RStudio - input site data and execute master script  
**Output:** PDF (11x17) + Interactive Quarto document (.qmd)

### Proposed Directory Structure

```
ggplot-GraphicDesign/
├── scripts/
│   ├── 0-setUp.R                    # Package installation & loading
│   ├── 1-dataAcquisition.R          # Download & cache all data via APIs
│   ├── 2-dataProcessing.R           # Process raw data into tidy formats
│   ├── 3-coverSheet.R               # Generate cover sheet
│   ├── 4-regionalContext.R           # Section 1: Regional orientation
│   ├── 5-topography.R               # Section 2: Topography & landform
│   ├── 6-hydrology.R                # Section 3: Hydrology & drainage
│   ├── 7-climate.R                  # Section 4: Climate & wind (with flow fields)
│   ├── 8-soils.R                    # Section 5: Soils & infiltration
│   ├── 9-vulnerabilities.R          # Section 6: Vulnerabilities & opportunities
│   ├── 10-dataTables.R              # Section 7: Supporting data tables
│   ├── 11-summary.R                 # Section 8: Summary & next steps
│   └── 99-renderReport.R             # Master script: runs all & generates outputs
├── data/
│   ├── raw/                         # Raw downloaded data (cached)
│   │   ├── dem/
│   │   ├── soils/
│   │   ├── climate/
│   │   ├── wind/
│   │   ├── canopy/
│   │   ├── watersheds/
│   │   └── ecoregions/
│   ├── processed/                   # Processed/analysis-ready tidy data
│   └── siteInfo/                    # Site-specific metadata (YAML)
├── functions/
│   ├── apiHelpers.R                 # API access functions (REST calls)
│   ├── mapHelpers.R                 # Reusable mapping functions
│   ├── dataHelpers.R                # Data processing utilities (tidy principles)
│   ├── flowFieldHelpers.R           # Wind flow field calculations
│   └── tableHelpers.R               # Table formatting functions
├── templates/
│   ├── reportTemplate.qmd           # Quarto template for interactive output
│   └── layoutTemplates.R            # Layout specifications
└── output/
    ├── reports/                     # Generated reports (PDF + .qmd)
    ├── figures/                     # Individual figure exports
    └── cache/                       # Cached computations
```

### Automated Workflow Process

1. **Site Information Input**
   - User creates/edits site metadata file (`data/siteInfo/siteMetadata_[project].yaml`)
   - Contains: client name, address, lat/long, parcel boundary, project date
   - Single source of truth for all site parameters

2. **Data Acquisition** (`1-dataAcquisition.R`)
   - **Fully automated via APIs**
   - Check cache for existing data (with validation)
   - Make API calls to retrieve missing datasets:
     - DEM from USGS 3DEP API
     - Soils from NRCS SSURGO API
     - Climate from PRISM API
     - Wind from NOAA API
     - Watersheds from NHDPlus API
     - Ecoregions from EPA (if API available)
     - Canopy height from USGS/NASA APIs
   - Cache all downloaded data
   - Validate data completeness

3. **Data Processing** (`2-dataProcessing.R`)
   - **Adhere to tidy data principles**
   - Convert all data to tidy format (tibbles, sf objects)
   - Clip all spatial data to site extent + buffer
   - Calculate derived metrics (slope, aspect, flow accumulation)
   - Aggregate climate data to site location
   - Process soil data into tidy format
   - Calculate wind flow fields (combining wind data with spatial structures)
   - Process canopy height data for rayshader visualization
   - Save processed data in tidy format

4. **Section Generation** (Scripts 3-11)
   - Each section script:
     - Reads processed tidy data
     - Generates visualizations using ggplot2
     - Saves individual figures to `output/figures/`
     - Returns plot objects and data for final composition
   - All data manipulation follows tidyverse principles

5. **Report Assembly** (`99-renderReport.R`)
   - **Master script that runs everything**
   - Sources all section scripts
   - Combines all sections
   - Generates PDF output (11x17) using `quarto render`
   - Generates interactive Quarto document (.qmd)
   - Fully automated - user just runs this script

### Execution Flow

```r
# User workflow (in RStudio):
# 1. Edit site metadata: data/siteInfo/siteMetadata_[project].yaml
# 2. Run master script:
source("scripts/99-renderReport.R")
# 3. Outputs generated in output/reports/
```

---

## 4. Technical Considerations

### 4.1 Coordinate Reference Systems
- **Standard:** Use appropriate UTM zone for site location
- **Transformations:** All data must be in same CRS before analysis
- **Display:** May use geographic (lat/long) for regional context maps

### 4.2 Data Caching Strategy
- Cache downloaded data to avoid repeated API calls
- Use `here::here()` for path management
- Implement cache validation (check data freshness)

### 4.3 Performance Optimization
- Use `terra` for large raster operations (faster than `raster`)
- Simplify complex geometries for display (`rmapshaper`)
- Consider `data.table` for large tabular operations

### 4.4 Reproducibility
- Set random seeds where needed
- Version control data sources (record download dates)
- Document all package versions
- Use `renv` for package management (optional but recommended)

### 4.5 Custom Themes & Styling
- Create consistent theme based on existing examples
- Define color palettes for each map type
- Establish typography hierarchy (using installed fonts)
- Create reusable annotation functions (scale bars, north arrows)

---

## 5. Section-Specific Implementation Notes

### Cover Sheet
- **Layout:** `grid` or `patchwork` for precise positioning
- **Text:** `ggtext` for formatted text blocks
- **Map:** Small inset using `ggspatial` or `cowplot::draw_plot()`

### Regional Context (Section 1)
- **Maps:** Multi-scale with `patchwork` or `cowplot`
- **Ecoregions:** Color-coded polygons from `sf`
- **Watershed:** Overlay boundary on base map
- **Text:** Side panel with `gridExtra::tableGrob()` or `gt` tables

### Topography (Section 2)
- **DEM Visualization:** `terra::plot()` or convert to `sf` for ggplot2
- **Hillshade:** Calculate using `terra::shade()` or `raster::hillShade()`
- **Slope/Aspect:** Calculate with `terra::terrain()`
- **Cross-section:** Extract profile line, plot with `ggplot2`
- **Canopy Heights (if available):**
  - Process LiDAR or canopy height data
  - Use `rayshader` for 3D visualization of canopy structure
  - Export as static image or interactive 3D plot

### Hydrology (Section 3)
- **Flow Direction:** Calculate with `whitebox` or `terra`
- **Flow Accumulation:** Derived from DEM
- **Streams:** Overlay NHD data
- **Flood Zones:** Overlay FEMA polygons

### Climate (Section 4)
- **Wind Rose:** Use `rWind` or custom `ggplot2` polar coordinates
- **Time Series:** `ggplot2` with dual y-axes (`sec.axis`)
- **Data:** Extract from PRISM rasters at site coordinates
- **Wind Flow Fields:** 
  - Combine wind data (direction, speed) with spatial data of built environment structures
  - Create flow field visualization showing how wind patterns are affected by structures
  - Use `ggplot2` with vector fields or streamlines
  - May use `rayshader` for 3D wind visualization if appropriate

### Soils (Section 5)
- **Soil Map:** `sf` polygons with `ggplot2::geom_sf()`
- **Profile Diagram:** Custom `ggplot2` or `grid` drawing
- **Tables:** `gt` or `kableExtra` for professional formatting

### Vulnerabilities (Section 6)
- **Composite Map:** Overlay multiple `sf` layers with transparency
- **Zones:** Create risk/opportunity polygons from analysis
- **Callouts:** `ggrepel` for annotations

### Data Tables (Section 7)
- **Formatting:** `gt` package for publication-quality tables
- **Layout:** `gridExtra` or `patchwork` for multi-table pages

---

## 6. Next Steps

1. **Update `0-setUp.R`** with complete package list
2. **Create site metadata template** (YAML format)
3. **Develop data acquisition functions** with caching
4. **Create custom theme** based on existing examples
5. **Build reusable mapping functions** (scale bar, north arrow, inset maps)
6. **Implement first section** (Cover Sheet) as proof of concept
7. **Iterate on design** based on output quality
8. **Documentation** - Create user guide for generating reports

---

## 7. Package Installation Priority

### Phase 1: Core Spatial & Visualization (Essential)
- sf, terra, ggplot2, patchwork, ggspatial, scales, systemfonts

### Phase 2: Data Acquisition (Essential)
- FedData, prism, rnoaa, nhdplusTools

### Phase 3: Advanced Analysis (Important)
- whitebox, soilDB, aqp, rWind

### Phase 4: Document & Tables (Important)
- rmarkdown, gt, gridExtra, magick

### Phase 5: Utilities & Polish (Nice to have)
- renv, config, tmap (alternative mapping)

---

## 8. Questions to Resolve

1. **Data Access:**
   - Do you have API keys for NOAA/PRISM or will we use public access?
   - Preferred method for parcel boundary input (shapefile, coordinates, drawing)?

2. **Workflow:**
   - Interactive R script workflow or R Markdown document?
   - Batch processing for multiple sites or single-site focus?

3. **Styling:**
   - Finalize color palette preferences
   - Typography hierarchy decisions
   - Logo/branding integration method

4. **Output:**
   - PDF only or also HTML/interactive?
   - Standard 11x17 or also support other sizes?

5. **Automation:**
   - Level of automation desired (fully automated vs. manual review steps)?
   - Integration with other tools (GIS software, design software)?

---

*Document created: 2025-01-02*  
*Last updated: 2025-01-02*


```

```markdown
# Site Assessment Report - Technical Planning Document

## Overview

This document outlines the technical architecture, package requirements, and implementation strategy for generating professional site assessment reports for landscape design projects.

**Output Format:** 
- PDF: 11x17 document (exclusively)
- Interactive: Quarto (.qmd) document for web/tablet viewing

**Primary Tool:** R with tidyverse and ggplot2 for visualization  
**Workflow:** Fully automated script-based workflow - input site data and run  
**Design Philosophy:** Focus on data acquisition, analysis, visualization, and layout first; styling refinement later  
**Data Principles:** Adhere to tidy data principles throughout

---

## 1. Package Requirements by Report Section

### Core Data Management (Tidyverse)
- **tidyverse** - Core suite (dplyr, tidyr, readr, purrr, tibble, stringr, forcats, lubridate, ggplot2)
- **here** - Project path management
- **readxl** - Excel file reading
- **yaml** - YAML parsing for site metadata

### Core Visualization & Design
- **ggplot2** - Primary plotting engine (included in tidyverse, but explicitly noted)
- **patchwork** - Multi-panel layout composition
- **cowplot** - Advanced plot arrangement and annotations
- **ggtext** - Rich text formatting in plots
- **ggrepel** - Smart label placement
- **scales** - Axis formatting and transformations
- **colorspace** / **viridis** / **RColorBrewer** / **scico** - Color palettes
- **rayshader** - 3D visualization for canopy heights and terrain
- **systemfonts** - Custom font management (Boska, Cabinet Grotesk, Pally, Tabular)

### Spatial Data & Mapping
- **sf** - Spatial data handling (CRS, geometries, spatial operations)
- **terra** - Raster data (DEM, slope, aspect calculations)
- **stars** - Alternative raster package (if needed)
- **rnaturalearth** - Base maps (countries, states, coastlines)
- **rmapshaper** - Spatial data simplification
- **tmap** - Thematic mapping (alternative/complement to ggplot2)
- **ggspatial** - Spatial annotations (scale bars, north arrows, inset maps)
- **maps** / **mapdata** - Additional base map data

### Climate & Weather Data
- **rnoaa** - NOAA climate data access (API)
- **prism** - PRISM climate data (temperature, precipitation) - API access
- **rWind** - Wind data processing and wind rose creation
- **circular** - Circular statistics for wind direction
- **Note:** Wind data will be combined with spatial data to create flow field visualizations based on built environment structures

### Soil Data
- **FedData** - Access to SSURGO soil data
- **soilDB** - Soil Survey Database queries
- **aqp** - Soil profile analysis and visualization

### Hydrology
- **nhdplusTools** - NHD Plus data and watershed delineation
- **whitebox** - Advanced terrain analysis (flow accumulation, watersheds)
- **raster** - Raster operations (may complement terra)

### API & Web Data Access
- **httr** - HTTP requests for REST API access
- **jsonlite** - JSON parsing for API responses
- **xml2** - XML parsing (if needed for some APIs)
- **Note:** All data acquisition should use API/REST server access where possible

### Document Generation (Quarto Workflow)
- **quarto** - Modern document generation (replaces R Markdown)
- **grid** / **gridExtra** - Advanced layout (tables, complex arrangements)
- **gt** / **kableExtra** - Professional table formatting
- **magick** - Image manipulation and composition

### Utilities
- **devtools** - Package development and installation
- **usethis** - Project setup utilities
- **config** - Configuration management
- **yaml** - YAML parsing for metadata

---

## 2. Data Sources & Acquisition Strategy

**Primary Strategy:** API-based data retrieval from REST servers or similar web services. All data acquisition should be automated via API calls where possible.

### Required Data Types

#### 2.1 Elevation & Topography
- **Source:** USGS 3D Elevation Program (3DEP)
- **Format:** Digital Elevation Model (DEM)
- **Resolution:** 1m, 3m, or 10m depending on site size
- **Access Methods:**
  - USGS National Map API (REST service)
  - `elevatr` package - API wrapper
  - `FedData` package - API wrapper
  - Direct REST API calls via `httr` if needed

#### 2.2 Watershed & Hydrology
- **Source:** USGS National Hydrography Dataset (NHD)
- **Format:** Vector (streams, waterbodies)
- **Access:** 
  - NHDPlus REST API (via `nhdplusTools`)
  - `FedData` package (API wrapper)
  - Direct REST API calls if needed
- **Watershed Delineation:** Calculate from DEM using `whitebox` or `terra`

#### 2.3 Ecoregions
- **Source:** EPA Ecoregions (Level III/IV)
- **Format:** Spatial polygons
- **Access:** 
  - EPA REST/API service (if available)
  - `FedData` package (API wrapper)
  - Direct download with API call via `httr` if REST endpoint exists

#### 2.4 Soils
- **Source:** NRCS SSURGO (Soil Survey Geographic Database)
- **Format:** Spatial polygons with attribute tables
- **Access:** 
  - NRCS Soil Data Access API (via `soilDB` or `FedData`)
  - `FedData::get_ssurgo()` - API wrapper
  - `soilDB` package - Direct API access
- **Required Attributes:**
  - Map unit name
  - Texture class
  - Drainage class
  - Hydrologic group
  - Permeability

#### 2.5 Climate Data
- **Source:** PRISM Climate Group (Oregon State)
- **Format:** Raster grids (monthly/annual normals)
- **Access:** `prism` package (API access)
- **Variables:**
  - Mean temperature (monthly/annual)
  - Precipitation (monthly/annual)
  - Potential evapotranspiration (if available)

#### 2.6 Wind Data
- **Source:** NOAA NCEI (National Centers for Environmental Information)
- **Format:** Time series data
- **Access:** `rnoaa` package (NOAA API)
- **Required:** Direction, speed, frequency by season
- **Special Use:** Combine with spatial data to create flow field visualizations showing wind patterns around built environment structures

#### 2.7 Canopy Height / LiDAR Data
- **Source:** USGS 3DEP (LiDAR point clouds), NASA GEDI, or local sources
- **Format:** Point clouds or rasterized canopy height models
- **Access:** 
  - USGS 3DEP API (if available)
  - NASA GEDI API
  - Direct REST API calls
- **Visualization:** Use `rayshader` for 3D canopy height visualization

#### 2.8 Flood Zones
- **Source:** FEMA Flood Map Service Center
- **Format:** Spatial polygons
- **Access:** 
  - FEMA REST API (if available)
  - `FedData` package (if API wrapper exists)
  - Direct API calls via `httr`

#### 2.9 Base Maps
- **Source:** OpenStreetMap, USGS, Natural Earth
- **Format:** Vector/raster tiles
- **Access:** 
  - OSM Overpass API (via `osmdata`)
  - `rnaturalearth` package
  - REST tile services

---

## 3. Script Architecture & Workflow

**Workflow Type:** Fully automated script-based workflow  
**Execution:** Run in RStudio - input site data and execute master script  
**Output:** PDF (11x17) + Interactive Quarto document (.qmd)

### Proposed Directory Structure

```
ggplot-GraphicDesign/
├── scripts/
│   ├── 0-setUp.R                    # Package installation & loading
│   ├── 1-dataAcquisition.R          # Download & cache all data via APIs
│   ├── 2-dataProcessing.R           # Process raw data into tidy formats
│   ├── 3-coverSheet.R               # Generate cover sheet
│   ├── 4-regionalContext.R           # Section 1: Regional orientation
│   ├── 5-topography.R               # Section 2: Topography & landform
│   ├── 6-hydrology.R                # Section 3: Hydrology & drainage
│   ├── 7-climate.R                  # Section 4: Climate & wind (with flow fields)
│   ├── 8-soils.R                    # Section 5: Soils & infiltration
│   ├── 9-vulnerabilities.R          # Section 6: Vulnerabilities & opportunities
│   ├── 10-dataTables.R              # Section 7: Supporting data tables
│   ├── 11-summary.R                 # Section 8: Summary & next steps
│   └── 99-renderReport.R             # Master script: runs all & generates outputs
├── data/
│   ├── raw/                         # Raw downloaded data (cached)
│   │   ├── dem/
│   │   ├── soils/
│   │   ├── climate/
│   │   ├── wind/
│   │   ├── canopy/
│   │   ├── watersheds/
│   │   └── ecoregions/
│   ├── processed/                   # Processed/analysis-ready tidy data
│   └── siteInfo/                    # Site-specific metadata (YAML)
├── functions/
│   ├── apiHelpers.R                 # API access functions (REST calls)
│   ├── mapHelpers.R                 # Reusable mapping functions
│   ├── dataHelpers.R                # Data processing utilities (tidy principles)
│   ├── flowFieldHelpers.R           # Wind flow field calculations
│   └── tableHelpers.R               # Table formatting functions
├── templates/
│   ├── reportTemplate.qmd           # Quarto template for interactive output
│   └── layoutTemplates.R            # Layout specifications
└── output/
    ├── reports/                     # Generated reports (PDF + .qmd)
    ├── figures/                     # Individual figure exports
    └── cache/                       # Cached computations
```

### Automated Workflow Process

1. **Site Information Input**
   - User creates/edits site metadata file (`data/siteInfo/siteMetadata_[project].yaml`)
   - Contains: client name, address, lat/long, parcel boundary, project date
   - Single source of truth for all site parameters

2. **Data Acquisition** (`1-dataAcquisition.R`)
   - **Fully automated via APIs**
   - Check cache for existing data (with validation)
   - Make API calls to retrieve missing datasets:
     - DEM from USGS 3DEP API
     - Soils from NRCS SSURGO API
     - Climate from PRISM API
     - Wind from NOAA API
     - Watersheds from NHDPlus API
     - Ecoregions from EPA (if API available)
     - Canopy height from USGS/NASA APIs
   - Cache all downloaded data
   - Validate data completeness

3. **Data Processing** (`2-dataProcessing.R`)
   - **Adhere to tidy data principles**
   - Convert all data to tidy format (tibbles, sf objects)
   - Clip all spatial data to site extent + buffer
   - Calculate derived metrics (slope, aspect, flow accumulation)
   - Aggregate climate data to site location
   - Process soil data into tidy format
   - Calculate wind flow fields (combining wind data with spatial structures)
   - Process canopy height data for rayshader visualization
   - Save processed data in tidy format

4. **Section Generation** (Scripts 3-11)
   - Each section script:
     - Reads processed tidy data
     - Generates visualizations using ggplot2
     - Saves individual figures to `output/figures/`
     - Returns plot objects and data for final composition
   - All data manipulation follows tidyverse principles

5. **Report Assembly** (`99-renderReport.R`)
   - **Master script that runs everything**
   - Sources all section scripts
   - Combines all sections
   - Generates PDF output (11x17) using `quarto render`
   - Generates interactive Quarto document (.qmd)
   - Fully automated - user just runs this script

### Execution Flow

```r
# User workflow (in RStudio):
# 1. Edit site metadata: data/siteInfo/siteMetadata_[project].yaml
# 2. Run master script:
source("scripts/99-renderReport.R")
# 3. Outputs generated in output/reports/
```

---

## 4. Technical Considerations

### 4.1 Coordinate Reference Systems
- **Standard:** Use appropriate UTM zone for site location
- **Transformations:** All data must be in same CRS before analysis
- **Display:** May use geographic (lat/long) for regional context maps

### 4.2 Data Caching Strategy
- Cache downloaded data to avoid repeated API calls
- Use `here::here()` for path management
- Implement cache validation (check data freshness)

### 4.3 Performance Optimization
- Use `terra` for large raster operations (faster than `raster`)
- Simplify complex geometries for display (`rmapshaper`)
- Consider `data.table` for large tabular operations

### 4.4 Reproducibility
- Set random seeds where needed
- Version control data sources (record download dates)
- Document all package versions
- Use `renv` for package management (optional but recommended)

### 4.5 Data Format & Tidy Principles
- **All data in tidy format:** Use tibbles, follow tidy data principles
- **Spatial data:** Use `sf` objects (tidy spatial data)
- **Raster data:** Use `terra` SpatRaster objects, convert to tidy format when needed
- **Consistent data structures:** All section scripts expect same data format
- **Reproducible data processing:** All transformations documented and reversible

### 4.6 Custom Themes & Styling
- **Note:** Styling refinement comes after core functionality
- Create consistent theme based on existing examples (later phase)
- Define color palettes for each map type (later phase)
- Establish typography hierarchy (using installed fonts) (later phase)
- Create reusable annotation functions (scale bars, north arrows)

---

## 5. Section-Specific Implementation Notes

### Cover Sheet
- **Layout:** `grid` or `patchwork` for precise positioning
- **Text:** `ggtext` for formatted text blocks
- **Map:** Small inset using `ggspatial` or `cowplot::draw_plot()`

### Regional Context (Section 1)
- **Maps:** Multi-scale with `patchwork` or `cowplot`
- **Ecoregions:** Color-coded polygons from `sf`
- **Watershed:** Overlay boundary on base map
- **Text:** Side panel with `gridExtra::tableGrob()` or `gt` tables

### Topography (Section 2)
- **DEM Visualization:** `terra::plot()` or convert to `sf` for ggplot2
- **Hillshade:** Calculate using `terra::shade()` or `raster::hillShade()`
- **Slope/Aspect:** Calculate with `terra::terrain()`
- **Cross-section:** Extract profile line, plot with `ggplot2`
- **Canopy Heights (if available):**
  - Process LiDAR or canopy height data
  - Use `rayshader` for 3D visualization of canopy structure
  - Export as static image or interactive 3D plot

### Hydrology (Section 3)
- **Flow Direction:** Calculate with `whitebox` or `terra`
- **Flow Accumulation:** Derived from DEM
- **Streams:** Overlay NHD data
- **Flood Zones:** Overlay FEMA polygons

### Climate (Section 4)
- **Wind Rose:** Use `rWind` or custom `ggplot2` polar coordinates
- **Time Series:** `ggplot2` with dual y-axes (`sec.axis`)
- **Data:** Extract from PRISM rasters at site coordinates
- **Wind Flow Fields:** 
  - Combine wind data (direction, speed) with spatial data of built environment structures
  - Create flow field visualization showing how wind patterns are affected by structures
  - Use `ggplot2` with vector fields or streamlines
  - May use `rayshader` for 3D wind visualization if appropriate

### Soils (Section 5)
- **Soil Map:** `sf` polygons with `ggplot2::geom_sf()`
- **Profile Diagram:** Custom `ggplot2` or `grid` drawing
- **Tables:** `gt` or `kableExtra` for professional formatting

### Vulnerabilities (Section 6)
- **Composite Map:** Overlay multiple `sf` layers with transparency
- **Zones:** Create risk/opportunity polygons from analysis
- **Callouts:** `ggrepel` for annotations

### Data Tables (Section 7)
- **Formatting:** `gt` package for publication-quality tables
- **Layout:** `gridExtra` or `patchwork` for multi-table pages

---

## 6. Next Steps

1. **Update `0-setUp.R`** with complete package list
2. **Create site metadata template** (YAML format)
3. **Develop data acquisition functions** with caching
4. **Create custom theme** based on existing examples
5. **Build reusable mapping functions** (scale bar, north arrow, inset maps)
6. **Implement first section** (Cover Sheet) as proof of concept
7. **Iterate on design** based on output quality
8. **Documentation** - Create user guide for generating reports

---

## 7. Package Installation Priority

### Phase 1: Core Spatial & Visualization (Essential)
- sf, terra, ggplot2, patchwork, ggspatial, scales, systemfonts

### Phase 2: Data Acquisition (Essential)
- FedData, prism, rnoaa, nhdplusTools

### Phase 3: Advanced Analysis (Important)
- whitebox, soilDB, aqp, rWind

### Phase 4: Document & Tables (Important)
- rmarkdown, gt, gridExtra, magick

### Phase 5: Utilities & Polish (Nice to have)
- renv, config, tmap (alternative mapping)

---

## 8. Questions to Resolve

1. **Data Access:**
   - Do you have API keys for NOAA/PRISM or will we use public access?
   - Preferred method for parcel boundary input (shapefile, coordinates, drawing)?

2. **Workflow:**
   - Interactive R script workflow or R Markdown document?
   - Batch processing for multiple sites or single-site focus?

3. **Styling:**
   - Finalize color palette preferences
   - Typography hierarchy decisions
   - Logo/branding integration method

4. **Output:**
   - PDF only or also HTML/interactive?
   - Standard 11x17 or also support other sizes?

5. **Automation:**
   - Level of automation desired (fully automated vs. manual review steps)?
   - Integration with other tools (GIS software, design software)?

---

*Document created: 2025-01-02*  
*Last updated: 2025-01-02*


```

```markdown
# Site Assessment Report - Technical Planning Document

## Overview

This document outlines the technical architecture, package requirements, and implementation strategy for generating professional site assessment reports for landscape design projects.

**Output Format:** 
- PDF: 11x17 document (exclusively)
- Interactive: Quarto (.qmd) document for web/tablet viewing

**Primary Tool:** R with tidyverse and ggplot2 for visualization  
**Workflow:** Fully automated script-based workflow - input site data and run  
**Design Philosophy:** Focus on data acquisition, analysis, visualization, and layout first; styling refinement later  
**Data Principles:** Adhere to tidy data principles throughout

---

## 1. Package Requirements by Report Section

### Core Data Management (Tidyverse)
- **tidyverse** - Core suite (dplyr, tidyr, readr, purrr, tibble, stringr, forcats, lubridate, ggplot2)
- **here** - Project path management
- **readxl** - Excel file reading
- **yaml** - YAML parsing for site metadata

### Core Visualization & Design
- **ggplot2** - Primary plotting engine (included in tidyverse, but explicitly noted)
- **patchwork** - Multi-panel layout composition
- **cowplot** - Advanced plot arrangement and annotations
- **ggtext** - Rich text formatting in plots
- **ggrepel** - Smart label placement
- **scales** - Axis formatting and transformations
- **colorspace** / **viridis** / **RColorBrewer** / **scico** - Color palettes
- **rayshader** - 3D visualization for canopy heights and terrain
- **systemfonts** - Custom font management (Boska, Cabinet Grotesk, Pally, Tabular)

### Spatial Data & Mapping
- **sf** - Spatial data handling (CRS, geometries, spatial operations)
- **terra** - Raster data (DEM, slope, aspect calculations)
- **stars** - Alternative raster package (if needed)
- **rnaturalearth** - Base maps (countries, states, coastlines)
- **rmapshaper** - Spatial data simplification
- **tmap** - Thematic mapping (alternative/complement to ggplot2)
- **ggspatial** - Spatial annotations (scale bars, north arrows, inset maps)
- **maps** / **mapdata** - Additional base map data

### Climate & Weather Data
- **rnoaa** - NOAA climate data access (API)
- **prism** - PRISM climate data (temperature, precipitation) - API access
- **rWind** - Wind data processing and wind rose creation
- **circular** - Circular statistics for wind direction
- **Note:** Wind data will be combined with spatial data to create flow field visualizations based on built environment structures

### Soil Data
- **FedData** - Access to SSURGO soil data
- **soilDB** - Soil Survey Database queries
- **aqp** - Soil profile analysis and visualization

### Hydrology
- **nhdplusTools** - NHD Plus data and watershed delineation
- **whitebox** - Advanced terrain analysis (flow accumulation, watersheds)
- **raster** - Raster operations (may complement terra)

### API & Web Data Access
- **httr** - HTTP requests for REST API access
- **jsonlite** - JSON parsing for API responses
- **xml2** - XML parsing (if needed for some APIs)
- **Note:** All data acquisition should use API/REST server access where possible

### Document Generation (Quarto Workflow)
- **quarto** - Modern document generation (replaces R Markdown)
- **grid** / **gridExtra** - Advanced layout (tables, complex arrangements)
- **gt** / **kableExtra** - Professional table formatting
- **magick** - Image manipulation and composition

### Utilities
- **devtools** - Package development and installation
- **usethis** - Project setup utilities
- **config** - Configuration management
- **yaml** - YAML parsing for metadata

---

## 2. Data Sources & Acquisition Strategy

**Primary Strategy:** API-based data retrieval from REST servers or similar web services. All data acquisition should be automated via API calls where possible.

### Required Data Types

#### 2.1 Elevation & Topography
- **Source:** USGS 3D Elevation Program (3DEP)
- **Format:** Digital Elevation Model (DEM)
- **Resolution:** 1m, 3m, or 10m depending on site size
- **Access Methods:**
  - USGS National Map API (REST service)
  - `elevatr` package - API wrapper
  - `FedData` package - API wrapper
  - Direct REST API calls via `httr` if needed

#### 2.2 Watershed & Hydrology
- **Source:** USGS National Hydrography Dataset (NHD)
- **Format:** Vector (streams, waterbodies)
- **Access:** 
  - NHDPlus REST API (via `nhdplusTools`)
  - `FedData` package (API wrapper)
  - Direct REST API calls if needed
- **Watershed Delineation:** Calculate from DEM using `whitebox` or `terra`

#### 2.3 Ecoregions
- **Source:** EPA Ecoregions (Level III/IV)
- **Format:** Spatial polygons
- **Access:** 
  - EPA REST/API service (if available)
  - `FedData` package (API wrapper)
  - Direct download with API call via `httr` if REST endpoint exists

#### 2.4 Soils
- **Source:** NRCS SSURGO (Soil Survey Geographic Database)
- **Format:** Spatial polygons with attribute tables
- **Access:** 
  - NRCS Soil Data Access API (via `soilDB` or `FedData`)
  - `FedData::get_ssurgo()` - API wrapper
  - `soilDB` package - Direct API access
- **Required Attributes:**
  - Map unit name
  - Texture class
  - Drainage class
  - Hydrologic group
  - Permeability

#### 2.5 Climate Data
- **Source:** PRISM Climate Group (Oregon State)
- **Format:** Raster grids (monthly/annual normals)
- **Access:** `prism` package (API access)
- **Variables:**
  - Mean temperature (monthly/annual)
  - Precipitation (monthly/annual)
  - Potential evapotranspiration (if available)

#### 2.6 Wind Data
- **Source:** NOAA NCEI (National Centers for Environmental Information)
- **Format:** Time series data
- **Access:** `rnoaa` package (NOAA API)
- **Required:** Direction, speed, frequency by season
- **Special Use:** Combine with spatial data to create flow field visualizations showing wind patterns around built environment structures

#### 2.7 Canopy Height / LiDAR Data
- **Source:** USGS 3DEP (LiDAR point clouds), NASA GEDI, or local sources
- **Format:** Point clouds or rasterized canopy height models
- **Access:** 
  - USGS 3DEP API (if available)
  - NASA GEDI API
  - Direct REST API calls
- **Visualization:** Use `rayshader` for 3D canopy height visualization

#### 2.8 Flood Zones
- **Source:** FEMA Flood Map Service Center
- **Format:** Spatial polygons
- **Access:** 
  - FEMA REST API (if available)
  - `FedData` package (if API wrapper exists)
  - Direct API calls via `httr`

#### 2.9 Base Maps
- **Source:** OpenStreetMap, USGS, Natural Earth
- **Format:** Vector/raster tiles
- **Access:** 
  - OSM Overpass API (via `osmdata`)
  - `rnaturalearth` package
  - REST tile services

---

## 3. Script Architecture & Workflow

**Workflow Type:** Fully automated script-based workflow  
**Execution:** Run in RStudio - input site data and execute master script  
**Output:** PDF (11x17) + Interactive Quarto document (.qmd)

### Proposed Directory Structure

```
ggplot-GraphicDesign/
├── scripts/
│   ├── 0-setUp.R                    # Package installation & loading
│   ├── 1-dataAcquisition.R          # Download & cache all data via APIs
│   ├── 2-dataProcessing.R           # Process raw data into tidy formats
│   ├── 3-coverSheet.R               # Generate cover sheet
│   ├── 4-regionalContext.R           # Section 1: Regional orientation
│   ├── 5-topography.R               # Section 2: Topography & landform
│   ├── 6-hydrology.R                # Section 3: Hydrology & drainage
│   ├── 7-climate.R                  # Section 4: Climate & wind (with flow fields)
│   ├── 8-soils.R                    # Section 5: Soils & infiltration
│   ├── 9-vulnerabilities.R          # Section 6: Vulnerabilities & opportunities
│   ├── 10-dataTables.R              # Section 7: Supporting data tables
│   ├── 11-summary.R                 # Section 8: Summary & next steps
│   └── 99-renderReport.R             # Master script: runs all & generates outputs
├── data/
│   ├── raw/                         # Raw downloaded data (cached)
│   │   ├── dem/
│   │   ├── soils/
│   │   ├── climate/
│   │   ├── wind/
│   │   ├── canopy/
│   │   ├── watersheds/
│   │   └── ecoregions/
│   ├── processed/                   # Processed/analysis-ready tidy data
│   └── siteInfo/                    # Site-specific metadata (YAML)
├── functions/
│   ├── apiHelpers.R                 # API access functions (REST calls)
│   ├── mapHelpers.R                 # Reusable mapping functions
│   ├── dataHelpers.R                # Data processing utilities (tidy principles)
│   ├── flowFieldHelpers.R           # Wind flow field calculations
│   └── tableHelpers.R               # Table formatting functions
├── templates/
│   ├── reportTemplate.qmd           # Quarto template for interactive output
│   └── layoutTemplates.R            # Layout specifications
└── output/
    ├── reports/                     # Generated reports (PDF + .qmd)
    ├── figures/                     # Individual figure exports
    └── cache/                       # Cached computations
```

### Automated Workflow Process

1. **Site Information Input**
   - User creates/edits site metadata file (`data/siteInfo/siteMetadata_[project].yaml`)
   - Contains: client name, address, lat/long, parcel boundary, project date
   - Single source of truth for all site parameters

2. **Data Acquisition** (`1-dataAcquisition.R`)
   - **Fully automated via APIs**
   - Check cache for existing data (with validation)
   - Make API calls to retrieve missing datasets:
     - DEM from USGS 3DEP API
     - Soils from NRCS SSURGO API
     - Climate from PRISM API
     - Wind from NOAA API
     - Watersheds from NHDPlus API
     - Ecoregions from EPA (if API available)
     - Canopy height from USGS/NASA APIs
   - Cache all downloaded data
   - Validate data completeness

3. **Data Processing** (`2-dataProcessing.R`)
   - **Adhere to tidy data principles**
   - Convert all data to tidy format (tibbles, sf objects)
   - Clip all spatial data to site extent + buffer
   - Calculate derived metrics (slope, aspect, flow accumulation)
   - Aggregate climate data to site location
   - Process soil data into tidy format
   - Calculate wind flow fields (combining wind data with spatial structures)
   - Process canopy height data for rayshader visualization
   - Save processed data in tidy format

4. **Section Generation** (Scripts 3-11)
   - Each section script:
     - Reads processed tidy data
     - Generates visualizations using ggplot2
     - Saves individual figures to `output/figures/`
     - Returns plot objects and data for final composition
   - All data manipulation follows tidyverse principles

5. **Report Assembly** (`99-renderReport.R`)
   - **Master script that runs everything**
   - Sources all section scripts
   - Combines all sections
   - Generates PDF output (11x17) using `quarto render`
   - Generates interactive Quarto document (.qmd)
   - Fully automated - user just runs this script

### Execution Flow

```r
# User workflow (in RStudio):
# 1. Edit site metadata: data/siteInfo/siteMetadata_[project].yaml
# 2. Run master script:
source("scripts/99-renderReport.R")
# 3. Outputs generated in output/reports/
```

---

## 4. Technical Considerations

### 4.1 Coordinate Reference Systems
- **Standard:** Use appropriate UTM zone for site location
- **Transformations:** All data must be in same CRS before analysis
- **Display:** May use geographic (lat/long) for regional context maps

### 4.2 Data Caching Strategy
- Cache downloaded data to avoid repeated API calls
- Use `here::here()` for path management
- Implement cache validation (check data freshness)

### 4.3 Performance Optimization
- Use `terra` for large raster operations (faster than `raster`)
- Simplify complex geometries for display (`rmapshaper`)
- Consider `data.table` for large tabular operations

### 4.4 Reproducibility
- Set random seeds where needed
- Version control data sources (record download dates)
- Document all package versions
- Use `renv` for package management (optional but recommended)

### 4.5 Data Format & Tidy Principles
- **All data in tidy format:** Use tibbles, follow tidy data principles
- **Spatial data:** Use `sf` objects (tidy spatial data)
- **Raster data:** Use `terra` SpatRaster objects, convert to tidy format when needed
- **Consistent data structures:** All section scripts expect same data format
- **Reproducible data processing:** All transformations documented and reversible

### 4.6 Custom Themes & Styling
- **Note:** Styling refinement comes after core functionality
- Create consistent theme based on existing examples (later phase)
- Define color palettes for each map type (later phase)
- Establish typography hierarchy (using installed fonts) (later phase)
- Create reusable annotation functions (scale bars, north arrows)

---

## 5. Section-Specific Implementation Notes

### Cover Sheet
- **Layout:** `grid` or `patchwork` for precise positioning
- **Text:** `ggtext` for formatted text blocks
- **Map:** Small inset using `ggspatial` or `cowplot::draw_plot()`

### Regional Context (Section 1)
- **Maps:** Multi-scale with `patchwork` or `cowplot`
- **Ecoregions:** Color-coded polygons from `sf`
- **Watershed:** Overlay boundary on base map
- **Text:** Side panel with `gridExtra::tableGrob()` or `gt` tables

### Topography (Section 2)
- **DEM Visualization:** `terra::plot()` or convert to `sf` for ggplot2
- **Hillshade:** Calculate using `terra::shade()` or `raster::hillShade()`
- **Slope/Aspect:** Calculate with `terra::terrain()`
- **Cross-section:** Extract profile line, plot with `ggplot2`
- **Canopy Heights (if available):**
  - Process LiDAR or canopy height data
  - Use `rayshader` for 3D visualization of canopy structure
  - Export as static image or interactive 3D plot

### Hydrology (Section 3)
- **Flow Direction:** Calculate with `whitebox` or `terra`
- **Flow Accumulation:** Derived from DEM
- **Streams:** Overlay NHD data
- **Flood Zones:** Overlay FEMA polygons

### Climate (Section 4)
- **Wind Rose:** Use `rWind` or custom `ggplot2` polar coordinates
- **Time Series:** `ggplot2` with dual y-axes (`sec.axis`)
- **Data:** Extract from PRISM rasters at site coordinates
- **Wind Flow Fields:** 
  - Combine wind data (direction, speed) with spatial data of built environment structures
  - Create flow field visualization showing how wind patterns are affected by structures
  - Use `ggplot2` with vector fields or streamlines
  - May use `rayshader` for 3D wind visualization if appropriate

### Soils (Section 5)
- **Soil Map:** `sf` polygons with `ggplot2::geom_sf()`
- **Profile Diagram:** Custom `ggplot2` or `grid` drawing
- **Tables:** `gt` or `kableExtra` for professional formatting

### Vulnerabilities (Section 6)
- **Composite Map:** Overlay multiple `sf` layers with transparency
- **Zones:** Create risk/opportunity polygons from analysis
- **Callouts:** `ggrepel` for annotations

### Data Tables (Section 7)
- **Formatting:** `gt` package for publication-quality tables
- **Layout:** `gridExtra` or `patchwork` for multi-table pages

---

## 6. Implementation Priority & Next Steps

### Phase 1: Core Infrastructure (Current Focus)
1. ✅ **Update `0-setUp.R`** with complete package list (including tidyverse, rayshader, quarto)
2. ✅ **Create site metadata template** (YAML format)
3. **Develop API-based data acquisition functions** with caching
   - Create `functions/apiHelpers.R` with REST API wrapper functions
   - Implement caching strategy with validation
4. **Build data processing pipeline** following tidy principles
   - Create `functions/dataHelpers.R` with tidy data processing functions
   - Ensure all outputs are in tidy format (tibbles, sf objects)

### Phase 2: Core Functionality
5. **Implement data acquisition script** (`1-dataAcquisition.R`)
   - API calls for all data sources
   - Caching and validation
6. **Implement data processing script** (`2-dataProcessing.R`)
   - Tidy data transformations
   - Spatial operations
   - Derived metrics calculations
   - Wind flow field calculations
7. **Build reusable mapping functions** (`functions/mapHelpers.R`)
   - Scale bar, north arrow, inset maps
   - Consistent map styling (basic)

### Phase 3: Section Implementation
8. **Implement first section** (Cover Sheet) as proof of concept
9. **Implement remaining sections** (3-11)
   - Focus on data visualization and layout
   - Styling refinement comes later
10. **Implement wind flow field visualization** (Section 4)
11. **Implement canopy height visualization with rayshader** (Section 2, if data available)

### Phase 4: Report Generation
12. **Create Quarto template** (`templates/reportTemplate.qmd`)
13. **Implement master script** (`99-renderReport.R`)
   - Automated workflow
   - PDF generation (11x17)
   - Interactive Quarto document generation

### Phase 5: Refinement (Later)
14. **Styling refinement** - Custom themes, color palettes, typography
15. **Documentation** - Create user guide for generating reports
16. **Testing** - Validate with multiple sites

---

## 7. Package Installation Priority

### Phase 1: Core Spatial & Visualization (Essential)
- sf, terra, ggplot2, patchwork, ggspatial, scales, systemfonts

### Phase 2: Data Acquisition (Essential)
- FedData, prism, rnoaa, nhdplusTools

### Phase 3: Advanced Analysis (Important)
- whitebox, soilDB, aqp, rWind

### Phase 4: Document & Tables (Important)
- rmarkdown, gt, gridExtra, magick

### Phase 5: Utilities & Polish (Nice to have)
- renv, config, tmap (alternative mapping)

---

## 8. Questions to Resolve

1. **Data Access:**
   - Do you have API keys for NOAA/PRISM or will we use public access?
   - Preferred method for parcel boundary input (shapefile, coordinates, drawing)?

2. **Workflow:**
   - Interactive R script workflow or R Markdown document?
   - Batch processing for multiple sites or single-site focus?

3. **Styling:**
   - Finalize color palette preferences
   - Typography hierarchy decisions
   - Logo/branding integration method

4. **Output:**
   - PDF only or also HTML/interactive?
   - Standard 11x17 or also support other sizes?

5. **Automation:**
   - Level of automation desired (fully automated vs. manual review steps)?
   - Integration with other tools (GIS software, design software)?

---

*Document created: 2025-01-02*  
*Last updated: 2025-01-02*


```

```markdown
# Site Assessment Report - Technical Planning Document

## Overview

This document outlines the technical architecture, package requirements, and implementation strategy for generating professional site assessment reports for landscape design projects.

**Output Format:** 
- PDF: 11x17 document (exclusively)
- Interactive: Quarto (.qmd) document for web/tablet viewing

**Primary Tool:** R with tidyverse and ggplot2 for visualization  
**Workflow:** Fully automated script-based workflow - input site data and run  
**Design Philosophy:** Focus on data acquisition, analysis, visualization, and layout first; styling refinement later  
**Data Principles:** Adhere to tidy data principles throughout

---

## 1. Package Requirements by Report Section

### Core Data Management (Tidyverse)
- **tidyverse** - Core suite (dplyr, tidyr, readr, purrr, tibble, stringr, forcats, lubridate, ggplot2)
- **here** - Project path management
- **readxl** - Excel file reading
- **yaml** - YAML parsing for site metadata

### Core Visualization & Design
- **ggplot2** - Primary plotting engine (included in tidyverse, but explicitly noted)
- **patchwork** - Multi-panel layout composition
- **cowplot** - Advanced plot arrangement and annotations
- **ggtext** - Rich text formatting in plots
- **ggrepel** - Smart label placement
- **scales** - Axis formatting and transformations
- **colorspace** / **viridis** / **RColorBrewer** / **scico** - Color palettes
- **rayshader** - 3D visualization for canopy heights and terrain
- **systemfonts** - Custom font management (Boska, Cabinet Grotesk, Pally, Tabular)

### Spatial Data & Mapping
- **sf** - Spatial data handling (CRS, geometries, spatial operations)
- **terra** - Raster data (DEM, slope, aspect calculations)
- **stars** - Alternative raster package (if needed)
- **rnaturalearth** - Base maps (countries, states, coastlines)
- **rmapshaper** - Spatial data simplification
- **tmap** - Thematic mapping (alternative/complement to ggplot2)
- **ggspatial** - Spatial annotations (scale bars, north arrows, inset maps)
- **maps** / **mapdata** - Additional base map data

### Climate & Weather Data
- **rnoaa** - NOAA climate data access (API)
- **prism** - PRISM climate data (temperature, precipitation) - API access
- **rWind** - Wind data processing and wind rose creation
- **circular** - Circular statistics for wind direction
- **Note:** Wind data will be combined with spatial data to create flow field visualizations based on built environment structures

### Soil Data
- **FedData** - Access to SSURGO soil data
- **soilDB** - Soil Survey Database queries
- **aqp** - Soil profile analysis and visualization

### Hydrology
- **nhdplusTools** - NHD Plus data and watershed delineation
- **whitebox** - Advanced terrain analysis (flow accumulation, watersheds)
- **raster** - Raster operations (may complement terra)

### API & Web Data Access
- **httr** - HTTP requests for REST API access
- **jsonlite** - JSON parsing for API responses
- **xml2** - XML parsing (if needed for some APIs)
- **Note:** All data acquisition should use API/REST server access where possible

### Document Generation (Quarto Workflow)
- **quarto** - Modern document generation (replaces R Markdown)
- **grid** / **gridExtra** - Advanced layout (tables, complex arrangements)
- **gt** / **kableExtra** - Professional table formatting
- **magick** - Image manipulation and composition

### Utilities
- **devtools** - Package development and installation
- **usethis** - Project setup utilities
- **config** - Configuration management
- **yaml** - YAML parsing for metadata

---

## 2. Data Sources & Acquisition Strategy

**Primary Strategy:** API-based data retrieval from REST servers or similar web services. All data acquisition should be automated via API calls where possible.

### Required Data Types

#### 2.1 Elevation & Topography
- **Source:** USGS 3D Elevation Program (3DEP)
- **Format:** Digital Elevation Model (DEM)
- **Resolution:** 1m, 3m, or 10m depending on site size
- **Access Methods:**
  - USGS National Map API (REST service)
  - `elevatr` package - API wrapper
  - `FedData` package - API wrapper
  - Direct REST API calls via `httr` if needed

#### 2.2 Watershed & Hydrology
- **Source:** USGS National Hydrography Dataset (NHD)
- **Format:** Vector (streams, waterbodies)
- **Access:** 
  - NHDPlus REST API (via `nhdplusTools`)
  - `FedData` package (API wrapper)
  - Direct REST API calls if needed
- **Watershed Delineation:** Calculate from DEM using `whitebox` or `terra`

#### 2.3 Ecoregions
- **Source:** EPA Ecoregions (Level III/IV)
- **Format:** Spatial polygons
- **Access:** 
  - EPA REST/API service (if available)
  - `FedData` package (API wrapper)
  - Direct download with API call via `httr` if REST endpoint exists

#### 2.4 Soils
- **Source:** NRCS SSURGO (Soil Survey Geographic Database)
- **Format:** Spatial polygons with attribute tables
- **Access:** 
  - NRCS Soil Data Access API (via `soilDB` or `FedData`)
  - `FedData::get_ssurgo()` - API wrapper
  - `soilDB` package - Direct API access
- **Required Attributes:**
  - Map unit name
  - Texture class
  - Drainage class
  - Hydrologic group
  - Permeability

#### 2.5 Climate Data
- **Source:** PRISM Climate Group (Oregon State)
- **Format:** Raster grids (monthly/annual normals)
- **Access:** `prism` package (API access)
- **Variables:**
  - Mean temperature (monthly/annual)
  - Precipitation (monthly/annual)
  - Potential evapotranspiration (if available)

#### 2.6 Wind Data
- **Source:** NOAA NCEI (National Centers for Environmental Information)
- **Format:** Time series data
- **Access:** `rnoaa` package (NOAA API)
- **Required:** Direction, speed, frequency by season
- **Special Use:** Combine with spatial data to create flow field visualizations showing wind patterns around built environment structures

#### 2.7 Canopy Height / LiDAR Data
- **Source:** USGS 3DEP (LiDAR point clouds), NASA GEDI, or local sources
- **Format:** Point clouds or rasterized canopy height models
- **Access:** 
  - USGS 3DEP API (if available)
  - NASA GEDI API
  - Direct REST API calls
- **Visualization:** Use `rayshader` for 3D canopy height visualization

#### 2.8 Flood Zones
- **Source:** FEMA Flood Map Service Center
- **Format:** Spatial polygons
- **Access:** 
  - FEMA REST API (if available)
  - `FedData` package (if API wrapper exists)
  - Direct API calls via `httr`

#### 2.9 Base Maps
- **Source:** OpenStreetMap, USGS, Natural Earth
- **Format:** Vector/raster tiles
- **Access:** 
  - OSM Overpass API (via `osmdata`)
  - `rnaturalearth` package
  - REST tile services

---

## 3. Script Architecture & Workflow

**Workflow Type:** Fully automated script-based workflow  
**Execution:** Run in RStudio - input site data and execute master script  
**Output:** PDF (11x17) + Interactive Quarto document (.qmd)

### Proposed Directory Structure

```
ggplot-GraphicDesign/
├── scripts/
│   ├── 0-setUp.R                    # Package installation & loading
│   ├── 1-dataAcquisition.R          # Download & cache all data via APIs
│   ├── 2-dataProcessing.R           # Process raw data into tidy formats
│   ├── 3-coverSheet.R               # Generate cover sheet
│   ├── 4-regionalContext.R           # Section 1: Regional orientation
│   ├── 5-topography.R               # Section 2: Topography & landform
│   ├── 6-hydrology.R                # Section 3: Hydrology & drainage
│   ├── 7-climate.R                  # Section 4: Climate & wind (with flow fields)
│   ├── 8-soils.R                    # Section 5: Soils & infiltration
│   ├── 9-vulnerabilities.R          # Section 6: Vulnerabilities & opportunities
│   ├── 10-dataTables.R              # Section 7: Supporting data tables
│   ├── 11-summary.R                 # Section 8: Summary & next steps
│   └── 99-renderReport.R             # Master script: runs all & generates outputs
├── data/
│   ├── raw/                         # Raw downloaded data (cached)
│   │   ├── dem/
│   │   ├── soils/
│   │   ├── climate/
│   │   ├── wind/
│   │   ├── canopy/
│   │   ├── watersheds/
│   │   └── ecoregions/
│   ├── processed/                   # Processed/analysis-ready tidy data
│   └── siteInfo/                    # Site-specific metadata (YAML)
├── functions/
│   ├── apiHelpers.R                 # API access functions (REST calls)
│   ├── mapHelpers.R                 # Reusable mapping functions
│   ├── dataHelpers.R                # Data processing utilities (tidy principles)
│   ├── flowFieldHelpers.R           # Wind flow field calculations
│   └── tableHelpers.R               # Table formatting functions
├── templates/
│   ├── reportTemplate.qmd           # Quarto template for interactive output
│   └── layoutTemplates.R            # Layout specifications
└── output/
    ├── reports/                     # Generated reports (PDF + .qmd)
    ├── figures/                     # Individual figure exports
    └── cache/                       # Cached computations
```

### Automated Workflow Process

1. **Site Information Input**
   - User creates/edits site metadata file (`data/siteInfo/siteMetadata_[project].yaml`)
   - Contains: client name, address, lat/long, parcel boundary, project date
   - Single source of truth for all site parameters

2. **Data Acquisition** (`1-dataAcquisition.R`)
   - **Fully automated via APIs**
   - Check cache for existing data (with validation)
   - Make API calls to retrieve missing datasets:
     - DEM from USGS 3DEP API
     - Soils from NRCS SSURGO API
     - Climate from PRISM API
     - Wind from NOAA API
     - Watersheds from NHDPlus API
     - Ecoregions from EPA (if API available)
     - Canopy height from USGS/NASA APIs
   - Cache all downloaded data
   - Validate data completeness

3. **Data Processing** (`2-dataProcessing.R`)
   - **Adhere to tidy data principles**
   - Convert all data to tidy format (tibbles, sf objects)
   - Clip all spatial data to site extent + buffer
   - Calculate derived metrics (slope, aspect, flow accumulation)
   - Aggregate climate data to site location
   - Process soil data into tidy format
   - Calculate wind flow fields (combining wind data with spatial structures)
   - Process canopy height data for rayshader visualization
   - Save processed data in tidy format

4. **Section Generation** (Scripts 3-11)
   - Each section script:
     - Reads processed tidy data
     - Generates visualizations using ggplot2
     - Saves individual figures to `output/figures/`
     - Returns plot objects and data for final composition
   - All data manipulation follows tidyverse principles

5. **Report Assembly** (`99-renderReport.R`)
   - **Master script that runs everything**
   - Sources all section scripts
   - Combines all sections
   - Generates PDF output (11x17) using `quarto render`
   - Generates interactive Quarto document (.qmd)
   - Fully automated - user just runs this script

### Execution Flow

```r
# User workflow (in RStudio):
# 1. Edit site metadata: data/siteInfo/siteMetadata_[project].yaml
# 2. Run master script:
source("scripts/99-renderReport.R")
# 3. Outputs generated in output/reports/
```

---

## 4. Technical Considerations

### 4.1 Coordinate Reference Systems
- **Standard:** Use appropriate UTM zone for site location
- **Transformations:** All data must be in same CRS before analysis
- **Display:** May use geographic (lat/long) for regional context maps

### 4.2 Data Caching Strategy
- Cache downloaded data to avoid repeated API calls
- Use `here::here()` for path management
- Implement cache validation (check data freshness)

### 4.3 Performance Optimization
- Use `terra` for large raster operations (faster than `raster`)
- Simplify complex geometries for display (`rmapshaper`)
- Consider `data.table` for large tabular operations

### 4.4 Reproducibility
- Set random seeds where needed
- Version control data sources (record download dates)
- Document all package versions
- Use `renv` for package management (optional but recommended)

### 4.5 Data Format & Tidy Principles
- **All data in tidy format:** Use tibbles, follow tidy data principles
- **Spatial data:** Use `sf` objects (tidy spatial data)
- **Raster data:** Use `terra` SpatRaster objects, convert to tidy format when needed
- **Consistent data structures:** All section scripts expect same data format
- **Reproducible data processing:** All transformations documented and reversible

### 4.6 Custom Themes & Styling
- **Note:** Styling refinement comes after core functionality
- Create consistent theme based on existing examples (later phase)
- Define color palettes for each map type (later phase)
- Establish typography hierarchy (using installed fonts) (later phase)
- Create reusable annotation functions (scale bars, north arrows)

---

## 5. Section-Specific Implementation Notes

### Cover Sheet
- **Layout:** `grid` or `patchwork` for precise positioning
- **Text:** `ggtext` for formatted text blocks
- **Map:** Small inset using `ggspatial` or `cowplot::draw_plot()`

### Regional Context (Section 1)
- **Maps:** Multi-scale with `patchwork` or `cowplot`
- **Ecoregions:** Color-coded polygons from `sf`
- **Watershed:** Overlay boundary on base map
- **Text:** Side panel with `gridExtra::tableGrob()` or `gt` tables

### Topography (Section 2)
- **DEM Visualization:** `terra::plot()` or convert to `sf` for ggplot2
- **Hillshade:** Calculate using `terra::shade()` or `raster::hillShade()`
- **Slope/Aspect:** Calculate with `terra::terrain()`
- **Cross-section:** Extract profile line, plot with `ggplot2`
- **Canopy Heights (if available):**
  - Process LiDAR or canopy height data
  - Use `rayshader` for 3D visualization of canopy structure
  - Export as static image or interactive 3D plot

### Hydrology (Section 3)
- **Flow Direction:** Calculate with `whitebox` or `terra`
- **Flow Accumulation:** Derived from DEM
- **Streams:** Overlay NHD data
- **Flood Zones:** Overlay FEMA polygons

### Climate (Section 4)
- **Wind Rose:** Use `rWind` or custom `ggplot2` polar coordinates
- **Time Series:** `ggplot2` with dual y-axes (`sec.axis`)
- **Data:** Extract from PRISM rasters at site coordinates
- **Wind Flow Fields:** 
  - Combine wind data (direction, speed) with spatial data of built environment structures
  - Create flow field visualization showing how wind patterns are affected by structures
  - Use `ggplot2` with vector fields or streamlines
  - May use `rayshader` for 3D wind visualization if appropriate

### Soils (Section 5)
- **Soil Map:** `sf` polygons with `ggplot2::geom_sf()`
- **Profile Diagram:** Custom `ggplot2` or `grid` drawing
- **Tables:** `gt` or `kableExtra` for professional formatting

### Vulnerabilities (Section 6)
- **Composite Map:** Overlay multiple `sf` layers with transparency
- **Zones:** Create risk/opportunity polygons from analysis
- **Callouts:** `ggrepel` for annotations

### Data Tables (Section 7)
- **Formatting:** `gt` package for publication-quality tables
- **Layout:** `gridExtra` or `patchwork` for multi-table pages

---

## 6. Implementation Priority & Next Steps

### Phase 1: Core Infrastructure (Current Focus)
1. ✅ **Update `0-setUp.R`** with complete package list (including tidyverse, rayshader, quarto)
2. ✅ **Create site metadata template** (YAML format)
3. **Develop API-based data acquisition functions** with caching
   - Create `functions/apiHelpers.R` with REST API wrapper functions
   - Implement caching strategy with validation
4. **Build data processing pipeline** following tidy principles
   - Create `functions/dataHelpers.R` with tidy data processing functions
   - Ensure all outputs are in tidy format (tibbles, sf objects)

### Phase 2: Core Functionality
5. **Implement data acquisition script** (`1-dataAcquisition.R`)
   - API calls for all data sources
   - Caching and validation
6. **Implement data processing script** (`2-dataProcessing.R`)
   - Tidy data transformations
   - Spatial operations
   - Derived metrics calculations
   - Wind flow field calculations
7. **Build reusable mapping functions** (`functions/mapHelpers.R`)
   - Scale bar, north arrow, inset maps
   - Consistent map styling (basic)

### Phase 3: Section Implementation
8. **Implement first section** (Cover Sheet) as proof of concept
9. **Implement remaining sections** (3-11)
   - Focus on data visualization and layout
   - Styling refinement comes later
10. **Implement wind flow field visualization** (Section 4)
11. **Implement canopy height visualization with rayshader** (Section 2, if data available)

### Phase 4: Report Generation
12. **Create Quarto template** (`templates/reportTemplate.qmd`)
13. **Implement master script** (`99-renderReport.R`)
   - Automated workflow
   - PDF generation (11x17)
   - Interactive Quarto document generation

### Phase 5: Refinement (Later)
14. **Styling refinement** - Custom themes, color palettes, typography
15. **Documentation** - Create user guide for generating reports
16. **Testing** - Validate with multiple sites

---

## 7. Package Installation Priority

### Phase 1: Core Infrastructure (Essential - Install First)
- **tidyverse** - Core data manipulation and visualization
- **sf, terra** - Spatial data handling
- **ggplot2, patchwork, cowplot** - Visualization and layout
- **ggspatial** - Map annotations
- **here, yaml** - Project management

### Phase 2: Data Acquisition via APIs (Essential)
- **httr, jsonlite, xml2** - REST API access
- **FedData, prism, rnoaa** - Data source API wrappers
- **nhdplusTools, soilDB** - Additional API wrappers

### Phase 3: Advanced Analysis (Important)
- **whitebox** - Terrain analysis
- **aqp, rWind, circular** - Specialized analysis
- **rayshader** - 3D visualization for canopy heights

### Phase 4: Document Generation (Important)
- **quarto** - Document generation (replaces rmarkdown)
- **gt, gridExtra** - Tables and layout
- **magick** - Image manipulation

### Phase 5: Visualization Enhancements (Nice to have)
- **scales, colorspace, viridis, scico** - Color palettes
- **ggtext, ggrepel** - Text and labels
- **systemfonts** - Custom fonts (for later styling phase)

---

## 8. Questions to Resolve

1. **Data Access:**
   - Do you have API keys for NOAA/PRISM or will we use public access?
   - Preferred method for parcel boundary input (shapefile, coordinates, drawing)?

2. **Workflow:**
   - Interactive R script workflow or R Markdown document?
   - Batch processing for multiple sites or single-site focus?

3. **Styling:**
   - Finalize color palette preferences
   - Typography hierarchy decisions
   - Logo/branding integration method

4. **Output:**
   - PDF only or also HTML/interactive?
   - Standard 11x17 or also support other sizes?

5. **Automation:**
   - Level of automation desired (fully automated vs. manual review steps)?
   - Integration with other tools (GIS software, design software)?

---

*Document created: 2025-01-02*  
*Last updated: 2025-01-02*


```

```markdown
# Site Assessment Report - Technical Planning Document

## Overview

This document outlines the technical architecture, package requirements, and implementation strategy for generating professional site assessment reports for landscape design projects.

**Output Format:** 
- PDF: 11x17 document (exclusively)
- Interactive: Quarto (.qmd) document for web/tablet viewing

**Primary Tool:** R with tidyverse and ggplot2 for visualization  
**Workflow:** Fully automated script-based workflow - input site data and run  
**Design Philosophy:** Focus on data acquisition, analysis, visualization, and layout first; styling refinement later  
**Data Principles:** Adhere to tidy data principles throughout

---

## 1. Package Requirements by Report Section

### Core Data Management (Tidyverse)
- **tidyverse** - Core suite (dplyr, tidyr, readr, purrr, tibble, stringr, forcats, lubridate, ggplot2)
- **here** - Project path management
- **readxl** - Excel file reading
- **yaml** - YAML parsing for site metadata

### Core Visualization & Design
- **ggplot2** - Primary plotting engine (included in tidyverse, but explicitly noted)
- **patchwork** - Multi-panel layout composition
- **cowplot** - Advanced plot arrangement and annotations
- **ggtext** - Rich text formatting in plots
- **ggrepel** - Smart label placement
- **scales** - Axis formatting and transformations
- **colorspace** / **viridis** / **RColorBrewer** / **scico** - Color palettes
- **rayshader** - 3D visualization for canopy heights and terrain
- **systemfonts** - Custom font management (Boska, Cabinet Grotesk, Pally, Tabular)

### Spatial Data & Mapping
- **sf** - Spatial data handling (CRS, geometries, spatial operations)
- **terra** - Raster data (DEM, slope, aspect calculations)
- **stars** - Alternative raster package (if needed)
- **rnaturalearth** - Base maps (countries, states, coastlines)
- **rmapshaper** - Spatial data simplification
- **tmap** - Thematic mapping (alternative/complement to ggplot2)
- **ggspatial** - Spatial annotations (scale bars, north arrows, inset maps)
- **maps** / **mapdata** - Additional base map data

### Climate & Weather Data
- **rnoaa** - NOAA climate data access (API)
- **prism** - PRISM climate data (temperature, precipitation) - API access
- **rWind** - Wind data processing and wind rose creation
- **circular** - Circular statistics for wind direction
- **Note:** Wind data will be combined with spatial data to create flow field visualizations based on built environment structures

### Soil Data
- **FedData** - Access to SSURGO soil data
- **soilDB** - Soil Survey Database queries
- **aqp** - Soil profile analysis and visualization

### Hydrology
- **nhdplusTools** - NHD Plus data and watershed delineation
- **whitebox** - Advanced terrain analysis (flow accumulation, watersheds)
- **raster** - Raster operations (may complement terra)

### API & Web Data Access
- **httr** - HTTP requests for REST API access
- **jsonlite** - JSON parsing for API responses
- **xml2** - XML parsing (if needed for some APIs)
- **Note:** All data acquisition should use API/REST server access where possible

### Document Generation (Quarto Workflow)
- **quarto** - Modern document generation (replaces R Markdown)
- **grid** / **gridExtra** - Advanced layout (tables, complex arrangements)
- **gt** / **kableExtra** - Professional table formatting
- **magick** - Image manipulation and composition

### Utilities
- **devtools** - Package development and installation
- **usethis** - Project setup utilities
- **config** - Configuration management
- **yaml** - YAML parsing for metadata

---

## 2. Data Sources & Acquisition Strategy

**Primary Strategy:** API-based data retrieval from REST servers or similar web services. All data acquisition should be automated via API calls where possible.

### Required Data Types

#### 2.1 Elevation & Topography
- **Source:** USGS 3D Elevation Program (3DEP)
- **Format:** Digital Elevation Model (DEM)
- **Resolution:** 1m, 3m, or 10m depending on site size
- **Access Methods:**
  - USGS National Map API (REST service)
  - `elevatr` package - API wrapper
  - `FedData` package - API wrapper
  - Direct REST API calls via `httr` if needed

#### 2.2 Watershed & Hydrology
- **Source:** USGS National Hydrography Dataset (NHD)
- **Format:** Vector (streams, waterbodies)
- **Access:** 
  - NHDPlus REST API (via `nhdplusTools`)
  - `FedData` package (API wrapper)
  - Direct REST API calls if needed
- **Watershed Delineation:** Calculate from DEM using `whitebox` or `terra`

#### 2.3 Ecoregions
- **Source:** EPA Ecoregions (Level III/IV)
- **Format:** Spatial polygons
- **Access:** 
  - EPA REST/API service (if available)
  - `FedData` package (API wrapper)
  - Direct download with API call via `httr` if REST endpoint exists

#### 2.4 Soils
- **Source:** NRCS SSURGO (Soil Survey Geographic Database)
- **Format:** Spatial polygons with attribute tables
- **Access:** 
  - NRCS Soil Data Access API (via `soilDB` or `FedData`)
  - `FedData::get_ssurgo()` - API wrapper
  - `soilDB` package - Direct API access
- **Required Attributes:**
  - Map unit name
  - Texture class
  - Drainage class
  - Hydrologic group
  - Permeability

#### 2.5 Climate Data
- **Source:** PRISM Climate Group (Oregon State)
- **Format:** Raster grids (monthly/annual normals)
- **Access:** `prism` package (API access)
- **Variables:**
  - Mean temperature (monthly/annual)
  - Precipitation (monthly/annual)
  - Potential evapotranspiration (if available)

#### 2.6 Wind Data
- **Source:** NOAA NCEI (National Centers for Environmental Information)
- **Format:** Time series data
- **Access:** `rnoaa` package (NOAA API)
- **Required:** Direction, speed, frequency by season
- **Special Use:** Combine with spatial data to create flow field visualizations showing wind patterns around built environment structures

#### 2.7 Canopy Height / LiDAR Data
- **Source:** USGS 3DEP (LiDAR point clouds), NASA GEDI, or local sources
- **Format:** Point clouds or rasterized canopy height models
- **Access:** 
  - USGS 3DEP API (if available)
  - NASA GEDI API
  - Direct REST API calls
- **Visualization:** Use `rayshader` for 3D canopy height visualization

#### 2.8 Flood Zones
- **Source:** FEMA Flood Map Service Center
- **Format:** Spatial polygons
- **Access:** 
  - FEMA REST API (if available)
  - `FedData` package (if API wrapper exists)
  - Direct API calls via `httr`

#### 2.9 Base Maps
- **Source:** OpenStreetMap, USGS, Natural Earth
- **Format:** Vector/raster tiles
- **Access:** 
  - OSM Overpass API (via `osmdata`)
  - `rnaturalearth` package
  - REST tile services

---

## 3. Script Architecture & Workflow

**Workflow Type:** Fully automated script-based workflow  
**Execution:** Run in RStudio - input site data and execute master script  
**Output:** PDF (11x17) + Interactive Quarto document (.qmd)

### Proposed Directory Structure

```
ggplot-GraphicDesign/
├── scripts/
│   ├── 0-setUp.R                    # Package installation & loading
│   ├── 1-dataAcquisition.R          # Download & cache all data via APIs
│   ├── 2-dataProcessing.R           # Process raw data into tidy formats
│   ├── 3-coverSheet.R               # Generate cover sheet
│   ├── 4-regionalContext.R           # Section 1: Regional orientation
│   ├── 5-topography.R               # Section 2: Topography & landform
│   ├── 6-hydrology.R                # Section 3: Hydrology & drainage
│   ├── 7-climate.R                  # Section 4: Climate & wind (with flow fields)
│   ├── 8-soils.R                    # Section 5: Soils & infiltration
│   ├── 9-vulnerabilities.R          # Section 6: Vulnerabilities & opportunities
│   ├── 10-dataTables.R              # Section 7: Supporting data tables
│   ├── 11-summary.R                 # Section 8: Summary & next steps
│   └── 99-renderReport.R             # Master script: runs all & generates outputs
├── data/
│   ├── raw/                         # Raw downloaded data (cached)
│   │   ├── dem/
│   │   ├── soils/
│   │   ├── climate/
│   │   ├── wind/
│   │   ├── canopy/
│   │   ├── watersheds/
│   │   └── ecoregions/
│   ├── processed/                   # Processed/analysis-ready tidy data
│   └── siteInfo/                    # Site-specific metadata (YAML)
├── functions/
│   ├── apiHelpers.R                 # API access functions (REST calls)
│   ├── mapHelpers.R                 # Reusable mapping functions
│   ├── dataHelpers.R                # Data processing utilities (tidy principles)
│   ├── flowFieldHelpers.R           # Wind flow field calculations
│   └── tableHelpers.R               # Table formatting functions
├── templates/
│   ├── reportTemplate.qmd           # Quarto template for interactive output
│   └── layoutTemplates.R            # Layout specifications
└── output/
    ├── reports/                     # Generated reports (PDF + .qmd)
    ├── figures/                     # Individual figure exports
    └── cache/                       # Cached computations
```

### Automated Workflow Process

1. **Site Information Input**
   - User creates/edits site metadata file (`data/siteInfo/siteMetadata_[project].yaml`)
   - Contains: client name, address, lat/long, parcel boundary, project date
   - Single source of truth for all site parameters

2. **Data Acquisition** (`1-dataAcquisition.R`)
   - **Fully automated via APIs**
   - Check cache for existing data (with validation)
   - Make API calls to retrieve missing datasets:
     - DEM from USGS 3DEP API
     - Soils from NRCS SSURGO API
     - Climate from PRISM API
     - Wind from NOAA API
     - Watersheds from NHDPlus API
     - Ecoregions from EPA (if API available)
     - Canopy height from USGS/NASA APIs
   - Cache all downloaded data
   - Validate data completeness

3. **Data Processing** (`2-dataProcessing.R`)
   - **Adhere to tidy data principles**
   - Convert all data to tidy format (tibbles, sf objects)
   - Clip all spatial data to site extent + buffer
   - Calculate derived metrics (slope, aspect, flow accumulation)
   - Aggregate climate data to site location
   - Process soil data into tidy format
   - Calculate wind flow fields (combining wind data with spatial structures)
   - Process canopy height data for rayshader visualization
   - Save processed data in tidy format

4. **Section Generation** (Scripts 3-11)
   - Each section script:
     - Reads processed tidy data
     - Generates visualizations using ggplot2
     - Saves individual figures to `output/figures/`
     - Returns plot objects and data for final composition
   - All data manipulation follows tidyverse principles

5. **Report Assembly** (`99-renderReport.R`)
   - **Master script that runs everything**
   - Sources all section scripts
   - Combines all sections
   - Generates PDF output (11x17) using `quarto render`
   - Generates interactive Quarto document (.qmd)
   - Fully automated - user just runs this script

### Execution Flow

```r
# User workflow (in RStudio):
# 1. Edit site metadata: data/siteInfo/siteMetadata_[project].yaml
# 2. Run master script:
source("scripts/99-renderReport.R")
# 3. Outputs generated in output/reports/
```

---

## 4. Technical Considerations

### 4.1 Coordinate Reference Systems
- **Standard:** Use appropriate UTM zone for site location
- **Transformations:** All data must be in same CRS before analysis
- **Display:** May use geographic (lat/long) for regional context maps

### 4.2 Data Caching Strategy
- Cache downloaded data to avoid repeated API calls
- Use `here::here()` for path management
- Implement cache validation (check data freshness)

### 4.3 Performance Optimization
- Use `terra` for large raster operations (faster than `raster`)
- Simplify complex geometries for display (`rmapshaper`)
- Consider `data.table` for large tabular operations

### 4.4 Reproducibility
- Set random seeds where needed
- Version control data sources (record download dates)
- Document all package versions
- Use `renv` for package management (optional but recommended)

### 4.5 Data Format & Tidy Principles
- **All data in tidy format:** Use tibbles, follow tidy data principles
- **Spatial data:** Use `sf` objects (tidy spatial data)
- **Raster data:** Use `terra` SpatRaster objects, convert to tidy format when needed
- **Consistent data structures:** All section scripts expect same data format
- **Reproducible data processing:** All transformations documented and reversible

### 4.6 Custom Themes & Styling
- **Note:** Styling refinement comes after core functionality
- Create consistent theme based on existing examples (later phase)
- Define color palettes for each map type (later phase)
- Establish typography hierarchy (using installed fonts) (later phase)
- Create reusable annotation functions (scale bars, north arrows)

---

## 5. Section-Specific Implementation Notes

### Cover Sheet
- **Layout:** `grid` or `patchwork` for precise positioning
- **Text:** `ggtext` for formatted text blocks
- **Map:** Small inset using `ggspatial` or `cowplot::draw_plot()`

### Regional Context (Section 1)
- **Maps:** Multi-scale with `patchwork` or `cowplot`
- **Ecoregions:** Color-coded polygons from `sf`
- **Watershed:** Overlay boundary on base map
- **Text:** Side panel with `gridExtra::tableGrob()` or `gt` tables

### Topography (Section 2)
- **DEM Visualization:** `terra::plot()` or convert to `sf` for ggplot2
- **Hillshade:** Calculate using `terra::shade()` or `raster::hillShade()`
- **Slope/Aspect:** Calculate with `terra::terrain()`
- **Cross-section:** Extract profile line, plot with `ggplot2`
- **Canopy Heights (if available):**
  - Process LiDAR or canopy height data
  - Use `rayshader` for 3D visualization of canopy structure
  - Export as static image or interactive 3D plot

### Hydrology (Section 3)
- **Flow Direction:** Calculate with `whitebox` or `terra`
- **Flow Accumulation:** Derived from DEM
- **Streams:** Overlay NHD data
- **Flood Zones:** Overlay FEMA polygons

### Climate (Section 4)
- **Wind Rose:** Use `rWind` or custom `ggplot2` polar coordinates
- **Time Series:** `ggplot2` with dual y-axes (`sec.axis`)
- **Data:** Extract from PRISM rasters at site coordinates
- **Wind Flow Fields:** 
  - Combine wind data (direction, speed) with spatial data of built environment structures
  - Create flow field visualization showing how wind patterns are affected by structures
  - Use `ggplot2` with vector fields or streamlines
  - May use `rayshader` for 3D wind visualization if appropriate

### Soils (Section 5)
- **Soil Map:** `sf` polygons with `ggplot2::geom_sf()`
- **Profile Diagram:** Custom `ggplot2` or `grid` drawing
- **Tables:** `gt` or `kableExtra` for professional formatting

### Vulnerabilities (Section 6)
- **Composite Map:** Overlay multiple `sf` layers with transparency
- **Zones:** Create risk/opportunity polygons from analysis
- **Callouts:** `ggrepel` for annotations

### Data Tables (Section 7)
- **Formatting:** `gt` package for publication-quality tables
- **Layout:** `gridExtra` or `patchwork` for multi-table pages

---

## 6. Implementation Priority & Next Steps

### Phase 1: Core Infrastructure (Current Focus)
1. ✅ **Update `0-setUp.R`** with complete package list (including tidyverse, rayshader, quarto)
2. ✅ **Create site metadata template** (YAML format)
3. **Develop API-based data acquisition functions** with caching
   - Create `functions/apiHelpers.R` with REST API wrapper functions
   - Implement caching strategy with validation
4. **Build data processing pipeline** following tidy principles
   - Create `functions/dataHelpers.R` with tidy data processing functions
   - Ensure all outputs are in tidy format (tibbles, sf objects)

### Phase 2: Core Functionality
5. **Implement data acquisition script** (`1-dataAcquisition.R`)
   - API calls for all data sources
   - Caching and validation
6. **Implement data processing script** (`2-dataProcessing.R`)
   - Tidy data transformations
   - Spatial operations
   - Derived metrics calculations
   - Wind flow field calculations
7. **Build reusable mapping functions** (`functions/mapHelpers.R`)
   - Scale bar, north arrow, inset maps
   - Consistent map styling (basic)

### Phase 3: Section Implementation
8. **Implement first section** (Cover Sheet) as proof of concept
9. **Implement remaining sections** (3-11)
   - Focus on data visualization and layout
   - Styling refinement comes later
10. **Implement wind flow field visualization** (Section 4)
11. **Implement canopy height visualization with rayshader** (Section 2, if data available)

### Phase 4: Report Generation
12. **Create Quarto template** (`templates/reportTemplate.qmd`)
13. **Implement master script** (`99-renderReport.R`)
   - Automated workflow
   - PDF generation (11x17)
   - Interactive Quarto document generation

### Phase 5: Refinement (Later)
14. **Styling refinement** - Custom themes, color palettes, typography
15. **Documentation** - Create user guide for generating reports
16. **Testing** - Validate with multiple sites

---

## 7. Package Installation Priority

### Phase 1: Core Infrastructure (Essential - Install First)
- **tidyverse** - Core data manipulation and visualization
- **sf, terra** - Spatial data handling
- **ggplot2, patchwork, cowplot** - Visualization and layout
- **ggspatial** - Map annotations
- **here, yaml** - Project management

### Phase 2: Data Acquisition via APIs (Essential)
- **httr, jsonlite, xml2** - REST API access
- **FedData, prism, rnoaa** - Data source API wrappers
- **nhdplusTools, soilDB** - Additional API wrappers

### Phase 3: Advanced Analysis (Important)
- **whitebox** - Terrain analysis
- **aqp, rWind, circular** - Specialized analysis
- **rayshader** - 3D visualization for canopy heights

### Phase 4: Document Generation (Important)
- **quarto** - Document generation (replaces rmarkdown)
- **gt, gridExtra** - Tables and layout
- **magick** - Image manipulation

### Phase 5: Visualization Enhancements (Nice to have)
- **scales, colorspace, viridis, scico** - Color palettes
- **ggtext, ggrepel** - Text and labels
- **systemfonts** - Custom fonts (for later styling phase)

---

## 8. Resolved Decisions

### 8.1 Data Access ✅
- **Strategy:** All data retrieved via API from designated sources
- **Method:** REST servers or similar web services
- **Implementation:** Use API wrapper packages (`rnoaa`, `prism`, etc.) and direct REST calls via `httr` where needed
- **Parcel Boundary:** Provided in site metadata YAML (coordinates, bbox, or shapefile path)

### 8.2 Workflow ✅
- **Type:** Script-based workflow (not R Markdown)
- **Interactive Output:** Use Quarto (.qmd) for interactive document generation
- **Execution:** Fully automated - input site data and run master script
- **Focus:** Single-site focus (can be adapted for batch later)

### 8.3 Styling ✅
- **Priority:** Focus on data acquisition, analysis, visualization, and layout first
- **Timing:** Styling refinement comes after core functionality is working
- **Approach:** Basic styling initially, refine later

### 8.4 Output ✅
- **PDF:** Exclusively 11x17 format
- **Interactive:** Quarto document (.qmd) for web/tablet viewing
- **Generation:** Both outputs generated from same script workflow

### 8.5 Automation ✅
- **Level:** Fully automated - input site data and press "go"
- **Execution:** Run fully in RStudio
- **Process:** Master script (`99-renderReport.R`) orchestrates entire workflow

### 8.6 Additional Features ✅
- **Wind Flow Fields:** Combine wind data with spatial data to visualize flow patterns around built environment structures
- **Canopy Heights:** Use `rayshader` for 3D visualization if LiDAR/canopy data is available
- **Tidy Data:** Adhere to tidy data principles throughout all data processing

---

*Document created: 2025-01-02*  
*Last updated: 2025-01-02*  
*Refined: 2025-01-02 - Based on user feedback*


```


Creating a summary document and updating the directory structure to reflect the refined plan:



Creating a quick reference summary of the refined plan:


```markdown
# Site Assessment Product - Refined Plan Summary

## Key Decisions Made

### 1. Data Management
- ✅ **Use `tidyverse`** package instead of individual packages
- ✅ **Adhere to tidy data principles** throughout all data processing
- ✅ **All data in tidy format**: tibbles, sf objects, consistent structures

### 2. Workflow
- ✅ **Script-based workflow** (not R Markdown)
- ✅ **Quarto (.qmd)** for interactive output
- ✅ **Fully automated**: Input site data → Run master script → Get outputs
- ✅ **RStudio execution**: Designed to run entirely in RStudio

### 3. Data Acquisition
- ✅ **API-based retrieval**: All data from REST servers/APIs where possible
- ✅ **Automated caching**: Check cache, download missing data, validate
- ✅ **API packages**: `rnoaa`, `prism`, `FedData`, `soilDB`, `nhdplusTools`
- ✅ **Direct REST calls**: Use `httr`, `jsonlite`, `xml2` when needed

### 4. Special Features
- ✅ **Wind flow fields**: Combine wind data with spatial data to visualize flow patterns around built environment structures
- ✅ **Canopy height visualization**: Use `rayshader` for 3D visualization if LiDAR data available

### 5. Output
- ✅ **PDF**: Exclusively 11x17 format
- ✅ **Interactive**: Quarto document (.qmd) for web/tablet viewing
- ✅ **Both generated**: From same automated workflow

### 6. Development Priority
- ✅ **Phase 1**: Data acquisition, analysis, visualization, layout
- ✅ **Phase 2**: Styling refinement (comes later)

## Updated Package List

### Core
- `tidyverse` (includes dplyr, tidyr, readr, ggplot2, etc.)
- `quarto` (replaces rmarkdown)
- `rayshader` (3D visualization)

### API Access
- `httr`, `jsonlite`, `xml2` (REST API access)

### All other packages remain as planned

## Workflow Summary

```
1. User edits: data/siteInfo/siteMetadata_[project].yaml
2. User runs: source("scripts/99-renderReport.R")
3. System executes:
   - 1-dataAcquisition.R (API calls, caching)
   - 2-dataProcessing.R (tidy data processing)
   - 3-11 (section generation)
   - Quarto render (PDF + interactive)
4. Outputs in: output/reports/
```

## Next Implementation Steps

1. Create `functions/apiHelpers.R` - REST API wrapper functions
2. Create `functions/dataHelpers.R` - Tidy data processing utilities
3. Create `functions/flowFieldHelpers.R` - Wind flow field calculations
4. Implement `1-dataAcquisition.R` - Automated API-based data retrieval
5. Implement `2-dataProcessing.R` - Tidy data processing pipeline
6. Build section scripts (3-11) with focus on functionality
7. Create Quarto template
8. Implement master script (`99-renderReport.R`)

## Key Files Updated

- ✅ `scripts/0-setUp.R` - Now uses tidyverse, includes rayshader, quarto, API packages
- ✅ `PLANNING_SiteAssessment.md` - Fully refined with all decisions
- ✅ `data/siteInfo/siteMetadata_template.yaml` - Site metadata template

---

*Summary created: 2025-01-02*

```


Checking for linting issues in the updated files:



## Refinements complete

### 1. Updated setup script (`scripts/0-setUp.R`)
- Uses `tidyverse` instead of individual packages
- Added `rayshader` for canopy height visualization
- Added `quarto` for document generation
- Added API packages: `httr`, `jsonlite`, `xml2` for REST API access
- Organized packages by category with comments

### 2. Refined planning document (`PLANNING_SiteAssessment.md`)
- Workflow: Script-based with Quarto output
- Data acquisition: API-based via REST servers
- Automation: Fully automated — input site data and run
- Special features:
  - Wind flow fields (wind data + spatial structures)
  - Canopy height visualization with `rayshader`
- Development priority: Functionality first, styling later
- Tidy data principles throughout

### 3. Created summary document (`REFINED_PLAN_SUMMARY.md`)
- Quick reference for key decisions
- Workflow summary
- Next implementation steps

## Changes

1. Tidyverse integration: Core data manipulation uses `tidyverse`
2. Quarto workflow: Replaces R Markdown; generates PDF + interactive .qmd
3. API-first approach: All data acquisition via REST APIs
4. Wind flow fields: Visualization combining wind data with built environment structures
5. Rayshader integration: 3D canopy height visualization when data is available
6. Automation focus: Single script execution for full workflow

## Ready for implementation

The plan is refined and ready. Next steps:
1. Create helper functions (`apiHelpers.R`, `dataHelpers.R`, `flowFieldHelpers.R`)
2. Implement data acquisition script with API calls
3. Build the processing pipeline following tidy principles

Should I start implementing any of these components, or do you want to review the refined plan first?

---

**User**

Let's set up a task list that I can copy and paste into Things 3.

---

**Cursor**


Creating a task list formatted for Things 3, organized by implementation phases:


```markdown
# Site Assessment Product - Implementation Task List

## Phase 1: Core Infrastructure

### Setup & Configuration
- [ ] Install all required packages from `scripts/0-setUp.R`
- [ ] Verify tidyverse, quarto, rayshader, and API packages are working
- [ ] Test package loading and dependencies

### Helper Functions - API Access
- [ ] Create `functions/apiHelpers.R`
- [ ] Implement REST API wrapper function template
- [ ] Add caching logic for API responses
- [ ] Create error handling for API failures
- [ ] Add retry logic for failed API calls
- [ ] Test API helper functions with sample calls

### Helper Functions - Data Processing
- [ ] Create `functions/dataHelpers.R`
- [ ] Implement tidy data conversion functions
- [ ] Add spatial data processing utilities (sf objects)
- [ ] Create raster processing helpers (terra objects)
- [ ] Add data validation functions
- [ ] Test data processing functions

### Helper Functions - Wind Flow Fields
- [ ] Create `functions/flowFieldHelpers.R`
- [ ] Research wind flow field calculation methods
- [ ] Implement function to combine wind data with spatial structures
- [ ] Create flow field visualization helpers
- [ ] Test with sample wind and structure data

### Helper Functions - Mapping
- [ ] Create `functions/mapHelpers.R`
- [ ] Implement scale bar function
- [ ] Implement north arrow function
- [ ] Create inset map helper function
- [ ] Add map styling utilities (basic)
- [ ] Test mapping helper functions

## Phase 2: Data Acquisition & Processing

### Data Acquisition Script
- [ ] Create `scripts/1-dataAcquisition.R`
- [ ] Implement DEM acquisition from USGS 3DEP API
- [ ] Implement soil data acquisition from NRCS SSURGO API
- [ ] Implement climate data acquisition from PRISM API
- [ ] Implement wind data acquisition from NOAA API
- [ ] Implement watershed data acquisition from NHDPlus API
- [ ] Implement ecoregion data acquisition (EPA or alternative)
- [ ] Implement canopy height data acquisition (if available)
- [ ] Implement flood zone data acquisition (FEMA)
- [ ] Add data caching and validation
- [ ] Test data acquisition with sample site

### Data Processing Script
- [ ] Create `scripts/2-dataProcessing.R`
- [ ] Implement site boundary processing (from YAML metadata)
- [ ] Implement spatial data clipping to site extent + buffer
- [ ] Implement DEM processing (slope, aspect, hillshade calculations)
- [ ] Implement flow accumulation calculations
- [ ] Implement climate data aggregation to site location
- [ ] Implement soil data processing to tidy format
- [ ] Implement wind flow field calculations
- [ ] Implement canopy height processing (if data available)
- [ ] Add data validation checks
- [ ] Test data processing pipeline end-to-end

## Phase 3: Section Implementation

### Cover Sheet
- [ ] Create `scripts/3-coverSheet.R`
- [ ] Implement project header layout
- [ ] Implement client/site information block
- [ ] Implement data sources list
- [ ] Implement small locator map
- [ ] Test cover sheet generation

### Section 1: Regional Context
- [ ] Create `scripts/4-regionalContext.R`
- [ ] Implement regional context map (ecoregions, watershed)
- [ ] Implement summary panel (watershed stats, ecoregion description)
- [ ] Implement climate summary box
- [ ] Add interpretive text block
- [ ] Test regional context section

### Section 2: Topography
- [ ] Create `scripts/5-topography.R`
- [ ] Implement shaded relief map with contours
- [ ] Implement slope map (color-coded gradient)
- [ ] Implement aspect map (directional shading)
- [ ] Implement cross-section profile
- [ ] Implement metrics table (elevation range, slope, aspect)
- [ ] Add canopy height visualization with rayshader (if data available)
- [ ] Test topography section

### Section 3: Hydrology
- [ ] Create `scripts/6-hydrology.R`
- [ ] Implement drainage flow map with arrows
- [ ] Implement flow accumulation zones
- [ ] Implement flood zone overlay
- [ ] Implement nearby hydrologic features
- [ ] Implement metrics table
- [ ] Test hydrology section

### Section 4: Climate & Wind
- [ ] Create `scripts/7-climate.R`
- [ ] Implement wind rose diagram
- [ ] Implement precipitation/temperature chart (dual-axis)
- [ ] Implement moisture index visualization
- [ ] Implement wind flow field visualization (wind + structures)
- [ ] Implement metrics table
- [ ] Test climate section

### Section 5: Soils
- [ ] Create `scripts/8-soils.R`
- [ ] Implement soil map (SSURGO polygons)
- [ ] Implement infiltration class map
- [ ] Implement soil profile diagram
- [ ] Implement metrics table
- [ ] Test soils section

### Section 6: Vulnerabilities & Opportunities
- [ ] Create `scripts/9-vulnerabilities.R`
- [ ] Implement composite overlay map (slope + drainage + soil)
- [ ] Implement risk/opportunity zone identification
- [ ] Implement callout boxes for key insights
- [ ] Implement interpretive narrative
- [ ] Test vulnerabilities section

### Section 7: Data Tables
- [ ] Create `scripts/10-dataTables.R`
- [ ] Implement climate normals table
- [ ] Implement wind data table
- [ ] Implement soil data table
- [ ] Implement data sources reference table
- [ ] Test data tables section

### Section 8: Summary
- [ ] Create `scripts/11-summary.R`
- [ ] Implement key findings summary narrative
- [ ] Implement next steps checklist
- [ ] Implement "At-a-Glance" metrics snapshot
- [ ] Test summary section

## Phase 4: Report Generation

### Quarto Template
- [ ] Create `templates/reportTemplate.qmd`
- [ ] Set up Quarto document structure
- [ ] Configure for 11x17 PDF output
- [ ] Configure for interactive HTML output
- [ ] Add YAML header with site metadata integration
- [ ] Test template rendering

### Master Script
- [ ] Create `scripts/99-renderReport.R`
- [ ] Implement site metadata loading from YAML
- [ ] Add script orchestration (run all section scripts in order)
- [ ] Implement PDF generation via Quarto
- [ ] Implement interactive document generation
- [ ] Add error handling and logging
- [ ] Test full workflow end-to-end

## Phase 5: Testing & Refinement

### Testing
- [ ] Test with multiple different site locations
- [ ] Test with various site sizes (small, medium, large parcels)
- [ ] Test error handling (missing data, API failures)
- [ ] Validate all data sources are correctly acquired
- [ ] Verify all visualizations render correctly
- [ ] Check PDF output quality (11x17 format)
- [ ] Test interactive Quarto document functionality

### Documentation
- [ ] Create user guide for generating reports
- [ ] Document site metadata YAML format
- [ ] Document API requirements and setup
- [ ] Create troubleshooting guide
- [ ] Add code comments and documentation

### Styling Refinement (Later Phase)
- [ ] Refine color palettes for each map type
- [ ] Establish typography hierarchy
- [ ] Create custom ggplot themes
- [ ] Refine layout and spacing
- [ ] Add logo/branding integration
- [ ] Polish visual consistency across all sections

---

## Quick Reference: Directory Structure to Create

```
functions/
  ├── apiHelpers.R
  ├── dataHelpers.R
  ├── flowFieldHelpers.R
  └── mapHelpers.R

scripts/
  ├── 0-setUp.R (✅ Done)
  ├── 1-dataAcquisition.R
  ├── 2-dataProcessing.R
  ├── 3-coverSheet.R
  ├── 4-regionalContext.R
  ├── 5-topography.R
  ├── 6-hydrology.R
  ├── 7-climate.R
  ├── 8-soils.R
  ├── 9-vulnerabilities.R
  ├── 10-dataTables.R
  ├── 11-summary.R
  └── 99-renderReport.R

templates/
  └── reportTemplate.qmd

data/
  ├── raw/ (subdirectories created as needed)
  ├── processed/
  └── siteInfo/ (✅ Template exists)

output/
  ├── reports/
  ├── figures/
  └── cache/
```

---

*Task list created: 2025-01-02*  
*Format: Plain text for Things 3 import*

```


Created a task list formatted for Things 3. It's organized by implementation phases and includes checkboxes. Here's a summary:



Created a task list in `THINGS3_TASK_LIST.md` formatted for Things 3. It includes:

## Task list structure

- **Phase 1: Core Infrastructure** (6 groups, ~30 tasks)
  - Setup & Configuration
  - Helper Functions (API, Data Processing, Wind Flow Fields, Mapping)

- **Phase 2: Data Acquisition & Processing** (2 groups, ~20 tasks)
  - Data Acquisition Script
  - Data Processing Script

- **Phase 3: Section Implementation** (8 sections, ~50 tasks)
  - Cover Sheet through Summary sections

- **Phase 4: Report Generation** (2 groups, ~10 tasks)
  - Quarto Template
  - Master Script

- **Phase 5: Testing & Refinement** (3 groups, ~15 tasks)
  - Testing, Documentation, Styling Refinement

Total: ~125 tasks organized by phase.

## How to import into Things 3

1. Copy the content from `THINGS3_TASK_LIST.md`
2. In Things 3, use File → Import → Text File, or paste into a new project
3. Things 3 should recognize the markdown checkboxes `- [ ]` and create tasks

The file is ready to copy and paste. Tasks are organized hierarchically with clear phase groupings. Should I create an alternative format or adjust the organization?

