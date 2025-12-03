# Shiny Application Architecture

## Overview

The site assessment product will be built as a **Shiny application** that wraps the existing script-based workflow. This provides a user-friendly interface while maintaining the modular, script-based architecture for maintainability and testing.

## Architecture: Hybrid Approach

### Core Principle
**Keep scripts as the engine, Shiny as the interface**

- **Scripts (1-11, 99)**: Remain as the core processing engine
- **Shiny App**: Provides UI/UX layer that:
  - Accepts user input (address/coordinates)
  - Calls the scripts with proper parameters
  - Displays progress and results
  - Handles file downloads

### Benefits
1. **Better UX**: No manual YAML editing, interactive input, progress tracking
2. **Geocoding**: Automatic address → coordinates conversion
3. **Preview**: Show maps/data before generating full report
4. **Modularity**: Scripts remain testable and reusable independently
5. **Flexibility**: Can still run scripts directly for batch processing

---

## Updated Directory Structure

```
ggplot-GraphicDesign/
├── app.R                              # Main Shiny application entry point
├── app/
│   ├── ui.R                           # User interface definition
│   ├── server.R                       # Server logic
│   ├── global.R                       # Global setup (load packages, source functions)
│   └── modules/                       # Shiny modules for reusable components
│       ├── inputModule.R              # Site input module (address/coordinates)
│       ├── progressModule.R           # Progress tracking module
│       ├── previewModule.R            # Preview maps/data module
│       └── downloadModule.R           # File download module
├── scripts/
│   ├── 0-setUp.R                      # Package installation & loading
│   ├── 1-dataAcquisition.R            # Download & cache all data via APIs
│   ├── 2-dataProcessing.R             # Process raw data into tidy formats
│   ├── 3-coverSheet.R                 # Generate cover sheet
│   ├── 4-regionalContext.R            # Section 1: Regional orientation
│   ├── 5-topography.R                 # Section 2: Topography & landform
│   ├── 6-hydrology.R                  # Section 3: Hydrology & drainage
│   ├── 7-climate.R                    # Section 4: Climate & wind (with flow fields)
│   ├── 8-soils.R                      # Section 5: Soils & infiltration
│   ├── 9-vulnerabilities.R            # Section 6: Vulnerabilities & opportunities
│   ├── 10-dataTables.R                # Section 7: Supporting data tables
│   ├── 11-summary.R                   # Section 8: Summary & next steps
│   └── 99-renderReport.R               # Master script: runs all & generates outputs
├── functions/
│   ├── apiHelpers.R                   # API access functions (REST calls)
│   ├── mapHelpers.R                   # Reusable mapping functions
│   ├── dataHelpers.R                  # Data processing utilities (tidy principles)
│   ├── flowFieldHelpers.R             # Wind flow field calculations
│   ├── tableHelpers.R                 # Table formatting functions
│   └── geocodingHelpers.R             # Address geocoding functions
├── data/
│   ├── raw/                           # Raw downloaded data (cached)
│   ├── processed/                     # Processed/analysis-ready tidy data
│   └── siteInfo/                      # Site-specific metadata (YAML) - auto-generated
├── templates/
│   ├── reportTemplate.qmd             # Quarto template for interactive output
│   └── layoutTemplates.R               # Layout specifications
└── output/
    ├── reports/                       # Generated reports (PDF + .qmd)
    ├── figures/                       # Individual figure exports
    └── cache/                         # Cached computations
```

---

## Shiny Application Workflow

### User Flow
1. **Launch App**: User runs `shiny::runApp()` or deploys to server
2. **Input Site Information**:
   - Enter address (text input) OR
   - Enter coordinates (lat/long) OR
   - Click on map to select location
   - Optional: Client name, project name, assessment date
3. **Geocoding** (if address provided):
   - App calls geocoding service (tidygeocoder, Nominatim, etc.)
   - Converts address → coordinates
   - Validates location
4. **Preview** (optional):
   - Show location on map
   - Display basic site info
   - Allow user to adjust before processing
5. **Generate Report**:
   - User clicks "Generate Report" button
   - App creates YAML metadata file automatically
   - Calls `99-renderReport.R` with site parameters
   - Shows progress bar/status updates
6. **Results**:
   - Display preview of generated report
   - Provide download buttons for PDF and interactive document
   - Show summary statistics

### Technical Flow
```
User Input (UI)
    ↓
Geocoding (if needed) → Coordinates
    ↓
Create YAML metadata (auto-generated)
    ↓
Call 99-renderReport.R with parameters
    ↓
    ├─→ 1-dataAcquisition.R (with progress updates)
    ├─→ 2-dataProcessing.R (with progress updates)
    ├─→ 3-11 (section generation, with progress updates)
    └─→ Quarto render (PDF + interactive) ← STILL HAPPENS HERE!
    ↓
Display results + download options
```

**Key Point**: Quarto rendering happens exactly as planned - the Shiny app just triggers it and provides the interface for downloads.

---

## Key Shiny Components

### 1. Input Module (`inputModule.R`)
- Address text input with geocoding
- Coordinate inputs (lat/long)
- Interactive map for point selection (leaflet)
- Project metadata inputs (client name, date, etc.)
- Parcel boundary upload (optional - shapefile or coordinates)

### 2. Progress Module (`progressModule.R`)
- Progress bar for long-running operations
- Status messages for each step
- Estimated time remaining
- Cancel button (if needed)

### 3. Preview Module (`previewModule.R`)
- Map showing site location
- Basic site information display
- Data availability check (what data sources are available for this location)

### 4. Download Module (`downloadModule.R`)
- Download buttons for PDF report
- Download button for interactive Quarto document
- Download individual figures (optional)

### 5. Main UI (`ui.R`)
- Modern, clean interface using `bslib` or `shinydashboard`
- Tabbed interface:
  - Tab 1: Site Input
  - Tab 2: Preview
  - Tab 3: Generate Report
  - Tab 4: Results & Downloads

### 6. Server Logic (`server.R`)
- Reactive values for site data
- Geocoding reactive function
- Report generation reactive function (with progress)
- File download handlers

---

## Required Additional Packages

### Shiny Ecosystem
- **shiny** - Core Shiny framework
- **bslib** or **shinydashboard** - Modern UI framework
- **shinycssloaders** - Loading spinners
- **shinyjs** - Enhanced JavaScript functionality
- **shinyWidgets** - Enhanced input widgets
- **DT** - Interactive data tables
- **leaflet** - Interactive maps for site selection
- **tidygeocoder** - Address geocoding (or **ggmap**, **opencage**)

### Progress & Status
- **shinybusy** - Busy indicators
- **waiter** - Loading screens

### File Handling
- Built into Shiny (downloadHandler)

---

## Changes to Existing Scripts

### Minimal Changes Required
The existing scripts can remain largely unchanged. Key modifications:

1. **99-renderReport.R**:
   - Accept parameters (coordinates, project name, etc.) instead of reading YAML
   - Optionally create YAML file for record-keeping
   - **Still uses Quarto to render PDF and interactive documents**:
     ```r
     # Inside 99-renderReport.R (unchanged Quarto rendering)
     quarto::quarto_render(
       input = "templates/reportTemplate.qmd",
       output_format = c("pdf", "html"),
       execute_params = list(
         site_lat = coordinates$lat,
         site_lon = coordinates$lon,
         project_name = project_name
       )
     )
     ```
   - Return status/progress information

2. **Functions**:
   - Add `geocodingHelpers.R` for address → coordinates
   - Modify data acquisition to accept coordinates directly

3. **Scripts 1-11**:
   - No changes needed if they read from processed data or YAML
   - Or: modify to accept parameters directly

4. **Quarto Template** (`templates/reportTemplate.qmd`):
   - **No changes needed** - works exactly as planned
   - Still generates 11x17 PDF and interactive HTML
   - Receives parameters from Shiny via `99-renderReport.R`

---

## Implementation Strategy

### Phase 1: Core Shiny Structure
1. Create basic Shiny app structure (`app.R`, `ui.R`, `server.R`)
2. Implement input module (address/coordinates)
3. Add geocoding functionality
4. Create basic UI layout

### Phase 2: Integration with Scripts
1. Modify `99-renderReport.R` to accept parameters
2. Add progress tracking to scripts
3. Integrate script execution into Shiny server
4. Add progress module

### Phase 3: Preview & Results
1. Add preview module (map, basic info)
2. Implement download handlers
3. Add results display
4. Polish UI/UX

### Phase 4: Advanced Features
1. Parcel boundary upload
2. Batch processing (multiple sites)
3. Report history/saved reports
4. Advanced preview options

---

## Workflow Comparison

### Old Workflow (Script-Based)
```
1. User edits YAML file manually
2. User runs: source("scripts/99-renderReport.R")
3. Scripts execute
4. User navigates to output folder to find results
```

### New Workflow (Shiny App)
```
1. User launches Shiny app
2. User enters address/coordinates in UI
3. User clicks "Generate Report"
4. App shows progress, executes scripts
5. User downloads results directly from app
```

### Both Workflows Supported
- **Shiny App**: Primary interface for end users
- **Scripts Directly**: Still available for batch processing, automation, debugging

---

## Deployment Options

### Local
- Run with `shiny::runApp()` in RStudio
- Good for development and single-user use

### Shiny Server / ShinyApps.io
- Deploy to web server
- Multi-user access
- Requires server setup

### RStudio Connect
- Enterprise deployment
- Advanced features (authentication, scheduling)

---

## Next Steps

1. **Update setup script** - Add Shiny packages
2. **Create basic Shiny app structure** - `app.R`, `ui.R`, `server.R`
3. **Implement geocoding** - Address → coordinates
4. **Create input module** - Site information collection
5. **Integrate with existing scripts** - Modify `99-renderReport.R` to accept parameters
6. **Add progress tracking** - Show status during long operations
7. **Implement downloads** - PDF and interactive document downloads

---

*Document created: 2025-01-02*  
*Architecture: Hybrid Shiny + Scripts*

