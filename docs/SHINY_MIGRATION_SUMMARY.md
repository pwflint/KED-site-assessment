# Shiny Application Migration Summary

## Decision: Convert to Shiny Application

**Yes, this is absolutely possible and actually improves the workflow significantly!**

## What Changes vs. What Stays the Same

### ✅ Stays the Same (Core Engine)
- **All scripts (1-11, 99)**: Remain as the core processing engine
- **Functions**: All helper functions remain unchanged
- **Data processing**: Tidy data principles, API-based acquisition
- **Output format**: PDF (11x17) + Interactive Quarto document
- **Modularity**: Scripts remain testable and reusable

### 🔄 Changes (Interface Layer)
- **User Input**: Shiny UI instead of manual YAML editing
- **Geocoding**: Automatic address → coordinates conversion
- **Execution**: Shiny app calls scripts with parameters
- **Results**: Download directly from app interface
- **Progress**: Real-time progress tracking during processing

## Architecture: Hybrid Approach

```
┌─────────────────────────────────────┐
│      Shiny Application (UI)        │
│  - Address/Coordinate Input         │
│  - Geocoding                        │
│  - Progress Tracking                │
│  - Results Display & Downloads      │
└──────────────┬──────────────────────┘
               │
               │ Calls with parameters
               ▼
┌─────────────────────────────────────┐
│   Script-Based Processing Engine    │
│  - 99-renderReport.R (master)       │
│  - 1-dataAcquisition.R              │
│  - 2-dataProcessing.R               │
│  - 3-11 (section generation)        │
│  - Functions (helpers)              │
└─────────────────────────────────────┘
```

## Benefits

1. **Better User Experience**
   - No manual YAML editing
   - Interactive input forms
   - Real-time progress updates
   - Direct downloads from app

2. **Geocoding Integration**
   - Enter address → automatic coordinate conversion
   - Map-based site selection (optional)
   - Validation of location

3. **Flexibility**
   - Scripts still runnable directly (for batch processing)
   - Shiny app for interactive use
   - Best of both worlds

4. **Professional Interface**
   - Modern, clean UI
   - Preview capabilities
   - Status updates
   - Error handling

## Updated Workflow

### New Shiny App Workflow
1. Launch Shiny app (`app.R`)
2. Enter address or coordinates in UI
3. App geocodes address (if needed)
4. Click "Generate Report"
5. App shows progress, executes scripts
6. Download PDF and interactive document

### Old Script Workflow (Still Supported)
1. Edit YAML file manually
2. Run `source("scripts/99-renderReport.R")`
3. Check output folder for results

## Required Changes to Implementation

### 1. Setup Script ✅
- **Updated**: Added Shiny packages to `0-setUp.R`
- Packages added: `shiny`, `bslib`, `leaflet`, `tidygeocoder`, etc.

### 2. New Files to Create
- `app.R` - Main Shiny application entry point
- `app/ui.R` - User interface
- `app/server.R` - Server logic
- `app/global.R` - Global setup
- `app/modules/` - Shiny modules (input, progress, preview, download)
- `functions/geocodingHelpers.R` - Address geocoding functions

### 3. Script Modifications (Minimal)
- **99-renderReport.R**: Accept parameters instead of only reading YAML
  - Can still create YAML for record-keeping
  - Accept coordinates, project name, etc. as function parameters
- **Scripts 1-11**: No changes needed (they read from data/YAML)

### 4. New Function
- **geocodingHelpers.R**: Functions to convert address → coordinates
  - Use `tidygeocoder` package
  - Support multiple geocoding services
  - Handle errors gracefully

## Implementation Phases

### Phase 1: Shiny Foundation (Start Here)
1. ✅ Update setup script with Shiny packages
2. Create basic Shiny app structure
3. Implement geocoding functionality
4. Create input module for site information

### Phase 2: Core Processing (Continue as Planned)
1. Create helper functions (apiHelpers, dataHelpers, etc.)
2. Implement data acquisition and processing scripts
3. Build section generation scripts
4. Create Quarto template

### Phase 3: Integration
1. Modify `99-renderReport.R` to accept parameters
2. Integrate script execution into Shiny
3. Add progress tracking
4. Implement download handlers

### Phase 4: Polish
1. Add preview module
2. Improve UI/UX
3. Add error handling
4. Test end-to-end

## Key Takeaway

**The Shiny app is a wrapper around the existing script architecture.** This means:
- We can develop scripts first (as planned)
- Then wrap them in Shiny later
- Or develop both in parallel
- Scripts remain independently testable and usable

## Next Steps

1. **Review the architecture document** (`SHINY_APP_ARCHITECTURE.md`)
2. **Decide on development approach**:
   - Option A: Build scripts first, then Shiny wrapper
   - Option B: Build Shiny app and scripts in parallel
   - Option C: Build minimal Shiny app first, then enhance
3. **Start with setup**: Install packages from updated `0-setUp.R`

---

*Summary created: 2025-01-02*  
*Decision: Hybrid Shiny + Scripts Architecture*

