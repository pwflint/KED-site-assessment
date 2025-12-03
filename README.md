# Site Assessment Report Generator

Automated site assessment report generation for landscape design projects. Generates professional 11x17 PDF reports and interactive Quarto documents from site location data.

## Project Status

**Current Phase**: Core Infrastructure Complete → Starting Data Acquisition  
**Last Updated**: 2025-01-02

### ✅ Completed

- **Project Structure**: Organized directory structure with R/, data/, output/, templates/
- **Package Setup**: All required packages installed and verified
  - Tidyverse, spatial packages (sf, terra), visualization packages
  - Data acquisition packages (FedData, prism, rnoaa, nhdplusTools)
  - Shiny packages (for future UI)
  - Document generation (quarto, gt, kableExtra)
- **Helper Functions**: Core utility functions created
  - `R/functions/apiHelpers.R` - API access with caching
  - `R/functions/dataHelpers.R` - Tidy data processing
  - `R/functions/geocodingHelpers.R` - Address geocoding
  - `R/functions/mapHelpers.R` - Mapping utilities
- **Utility Scripts**: Setup and testing scripts
  - Package verification and testing
  - Special package installation helpers
- **Documentation**: Planning and architecture documents

### 🚧 In Progress

- Data acquisition implementation (`R/scripts/1-dataAcquisition.R`)

### 📋 Next Steps

See `docs/NEXT_STEPS.md` for detailed task breakdown.

## Directory Structure

```
_dev-siteAssessment/
├── R/                          # All R code
│   ├── functions/              # Helper functions (reusable utilities)
│   │   ├── apiHelpers.R       # REST API wrapper functions
│   │   ├── dataHelpers.R      # Tidy data processing utilities
│   │   ├── geocodingHelpers.R # Address geocoding functions
│   │   └── mapHelpers.R       # Reusable mapping functions
│   ├── scripts/               # Workflow scripts (numbered execution order)
│   │   ├── 0-setUp.R          # Package installation and loading
│   │   ├── 1-dataAcquisition.R # Download and cache all data sources
│   │   ├── 2-dataProcessing.R  # Process raw data into tidy formats
│   │   ├── 3-coverSheet.R     # Generate cover sheet
│   │   ├── 4-regionalContext.R # Section 1: Regional orientation
│   │   ├── 5-topography.R     # Section 2: Topography & landform
│   │   ├── 6-hydrology.R      # Section 3: Hydrology & drainage
│   │   ├── 7-climate.R        # Section 4: Climate & wind
│   │   ├── 8-soils.R          # Section 5: Soils & infiltration
│   │   ├── 9-vulnerabilities.R # Section 6: Vulnerabilities & opportunities
│   │   ├── 10-dataTables.R    # Section 7: Supporting data tables
│   │   ├── 11-summary.R       # Section 8: Summary & next steps
│   │   └── 99-renderReport.R  # Master script (orchestrates everything)
│   └── utils/                  # Utility scripts (setup, testing, maintenance)
│       ├── checkPackages.R    # Verify package installation
│       ├── testPackageLoading.R # Comprehensive package test
│       └── ... (see R/utils/README.md)
├── data/
│   ├── raw/                    # Raw downloaded data (cached)
│   ├── processed/               # Processed/analysis-ready tidy data
│   └── siteInfo/               # Site-specific metadata (YAML templates)
├── output/
│   ├── cache/                  # Cached computations
│   ├── figures/                # Individual figure exports
│   └── reports/                # Generated reports (PDF + HTML)
├── templates/
│   ├── reportTemplate.qmd      # Quarto template (to be created)
│   └── Site Assessment Report Template.afpub # Affinity Publisher template
├── docs/                       # Documentation
│   ├── planning/               # Planning documents
│   ├── NEXT_STEPS.md           # Next development tasks
│   ├── TROUBLESHOOTING.md      # Common issues and solutions
│   └── ... (see docs/README.md for full list)
└── styles/fonts/               # Font files for styling
```

**Note**: Only `.Rhistory`, `.Rproj`, and `.app` files should be in `R/` root. All `.R` code files are organized in subdirectories.

**For detailed R code structure**, see inline comments in scripts or refer to planning documents.

## Quick Start

### 1. Setup (First Time)

```r
# Load packages
source("R/scripts/0-setUp.R")

# Verify all packages are working
source("R/utils/testPackageLoading.R")
```

### 2. Load Helper Functions

```r
# Source helper functions as needed
source("R/functions/apiHelpers.R")
source("R/functions/dataHelpers.R")
source("R/functions/geocodingHelpers.R")
source("R/functions/mapHelpers.R")
```

### 3. Run Workflow

```r
# Run master script (will source other scripts in order)
source("R/scripts/99-renderReport.R")
```

## Workflow Overview

1. **Input**: Site metadata (YAML file) with address/coordinates
2. **Data Acquisition** (`1-dataAcquisition.R`): Download and cache all data via APIs
3. **Data Processing** (`2-dataProcessing.R`): Process raw data into tidy formats
4. **Section Generation** (`3-11`): Generate visualizations for each report section
5. **Report Assembly** (`99-renderReport.R`): Combine sections and render via Quarto
6. **Output**: PDF (11x17) + Interactive HTML document

## Key Technologies

- **R + Tidyverse**: Data manipulation and analysis
- **ggplot2**: Visualization
- **sf + terra**: Spatial data handling
- **Quarto**: Document generation (PDF + HTML)
- **Shiny**: Future interactive UI (planned)
- **APIs**: Automated data acquisition (USGS, NOAA, PRISM, NRCS, etc.)

## Data Sources

- **Elevation**: USGS 3DEP (DEM)
- **Soils**: NRCS SSURGO
- **Climate**: PRISM Climate Group
- **Wind**: NOAA NCEI
- **Watersheds**: USGS NHDPlus
- **Ecoregions**: EPA
- **Flood Zones**: FEMA
- **Canopy Height**: USGS/NASA (if available)

## Development Guidelines

See `docs/DEVELOPMENT_RULES.md` for coding standards and workflow consistency.

## Documentation

### Development Guides
- **Next Steps**: `docs/NEXT_STEPS.md` - Current development tasks (start here!)
- **Development Rules**: `docs/DEVELOPMENT_RULES.md` - Coding standards and consistency
- **Testing Strategy**: `docs/TESTING_STRATEGY.md` - Package testing approach
- **Troubleshooting**: `docs/TROUBLESHOOTING.md` - Common issues and solutions

### Planning & Architecture
- **Planning**: `docs/planning/PLANNING_SiteAssessment.md` - Complete technical architecture
- **Task List**: `docs/planning/THINGS3_TASK_LIST.md` - Full task breakdown
- **Shiny Architecture**: `docs/SHINY_APP_ARCHITECTURE.md` - Future Shiny UI design
- **Quarto Integration**: `docs/QUARTO_SHINY_INTEGRATION.md` - How Quarto rendering works

## Notes

- **FedData v4**: Uses `terra` and `sf` (not `raster` and `sp`)
- **arcgislayers**: Optional - not required for most FedData functions
- **Package Warnings**: Version mismatch warnings are harmless

---

*For detailed architecture and planning, see `docs/planning/PLANNING_SiteAssessment.md`*
