# Site Assessment Product - Refined Plan Summary

## Key Decisions Made

### 1. Data Management
- ✅ **Use `tidyverse`** package instead of individual packages
- ✅ **Adhere to tidy data principles** throughout all data processing
- ✅ **All data in tidy format**: tibbles, sf objects, consistent structures

### 2. Workflow
- ✅ **Shiny Application**: User-friendly interface for site input and report generation
- ✅ **Script-based engine**: Core processing remains in modular scripts
- ✅ **Quarto (.qmd)** for interactive output
- ✅ **Fully automated**: Input address/coordinates → Generate report → Download outputs
- ✅ **Hybrid architecture**: Shiny UI wraps script-based processing engine

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

### Shiny Application
- `shiny`, `bslib` (UI framework)
- `leaflet` (interactive maps)
- `tidygeocoder` (address geocoding)
- `shinyWidgets`, `DT` (enhanced UI components)
- `shinybusy`, `waiter` (progress indicators)

### API Access
- `httr`, `jsonlite`, `xml2` (REST API access)

### All other packages remain as planned

## Workflow Summary

### Shiny Application Workflow
```
1. User launches Shiny app (app.R)
2. User enters address or coordinates in UI
3. App geocodes address → coordinates (if needed)
4. User clicks "Generate Report"
5. App creates YAML metadata automatically
6. App calls 99-renderReport.R with parameters
7. System executes (with progress updates):
   - 1-dataAcquisition.R (API calls, caching)
   - 2-dataProcessing.R (tidy data processing)
   - 3-11 (section generation)
   - Quarto render (PDF + interactive)
8. App displays results and download options
```

### Alternative: Direct Script Execution (Still Supported)
```
1. User edits: data/siteInfo/siteMetadata_[project].yaml
2. User runs: source("scripts/99-renderReport.R")
3. System executes scripts (same as above)
4. Outputs in: output/reports/
```

## Next Implementation Steps

### Phase 1: Shiny App Foundation
1. Create basic Shiny app structure (`app.R`, `app/ui.R`, `app/server.R`)
2. Create `functions/geocodingHelpers.R` - Address geocoding functions
3. Implement input module for site information (address/coordinates)
4. Add geocoding integration

### Phase 2: Core Processing (Unchanged)
1. Create `functions/apiHelpers.R` - REST API wrapper functions
2. Create `functions/dataHelpers.R` - Tidy data processing utilities
3. Create `functions/flowFieldHelpers.R` - Wind flow field calculations
4. Implement `1-dataAcquisition.R` - Automated API-based data retrieval
5. Implement `2-dataProcessing.R` - Tidy data processing pipeline
6. Build section scripts (3-11) with focus on functionality
7. Create Quarto template
8. Modify `99-renderReport.R` to accept parameters (for Shiny integration)

### Phase 3: Shiny Integration
1. Integrate script execution into Shiny server
2. Add progress tracking module
3. Implement download handlers (PDF, interactive document)
4. Add preview module (map, basic site info)
5. Polish UI/UX

## Key Files Updated

- ✅ `scripts/0-setUp.R` - Now uses tidyverse, includes rayshader, quarto, API packages
- ✅ `PLANNING_SiteAssessment.md` - Fully refined with all decisions
- ✅ `data/siteInfo/siteMetadata_template.yaml` - Site metadata template

---

*Summary created: 2025-01-02*

