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

