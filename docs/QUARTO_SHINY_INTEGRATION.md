# Quarto + Shiny Integration Guide

## Overview

**Yes, Quarto rendering works perfectly with Shiny!** The Shiny app is just the interface - Quarto still generates all the documents exactly as planned.

## How It Works

### The Flow

```
┌─────────────────────────────────────┐
│      Shiny Application (UI)        │
│  User enters address/coordinates    │
│  Clicks "Generate Report"           │
└──────────────┬──────────────────────┘
               │
               │ Calls function with parameters
               ▼
┌─────────────────────────────────────┐
│   99-renderReport.R (unchanged)     │
│  - Runs all section scripts          │
│  - Generates figures                 │
│  - Calls Quarto render               │
│    quarto::quarto_render(...)        │
└──────────────┬──────────────────────┘
               │
               │ Quarto processes template
               ▼
┌─────────────────────────────────────┐
│   templates/reportTemplate.qmd      │
│  - 11x17 PDF output                 │
│  - Interactive HTML output           │
│  - All sections included             │
└──────────────┬──────────────────────┘
               │
               │ Files saved to output/
               ▼
┌─────────────────────────────────────┐
│   Shiny Download Handlers           │
│  - Download PDF button              │
│  - Download HTML button              │
└─────────────────────────────────────┘
```

## Code Example: Shiny Server Integration

Here's how the Shiny server would call the Quarto rendering:

```r
# In app/server.R

# Reactive function to generate report
generate_report <- reactive({
  # Get user input
  site_address <- input$address
  project_name <- input$project_name
  
  # Geocode address (if needed)
  coords <- geocode_address(site_address)
  
  # Call the master script with parameters
  # This function wraps 99-renderReport.R
  result <- render_site_assessment(
    latitude = coords$lat,
    longitude = coords$lon,
    project_name = project_name,
    client_name = input$client_name,
    assessment_date = input$date
  )
  
  return(result)
})

# Download handler for PDF
output$downloadPDF <- downloadHandler(
  filename = function() {
    paste0("SiteAssessment_", input$project_name, ".pdf")
  },
  content = function(file) {
    # Generate report (if not already generated)
    report_path <- generate_report()$pdf_path
    
    # Copy to download location
    file.copy(report_path, file)
  }
)

# Download handler for Interactive HTML
output$downloadHTML <- downloadHandler(
  filename = function() {
    paste0("SiteAssessment_", input$project_name, ".html")
  },
  content = function(file) {
    report_path <- generate_report()$html_path
    file.copy(report_path, file)
  }
)
```

## Wrapper Function for 99-renderReport.R

The `99-renderReport.R` script would be wrapped in a function that Shiny can call:

```r
# In functions/reportHelpers.R or directly in 99-renderReport.R

render_site_assessment <- function(
  latitude,
  longitude,
  project_name,
  client_name = NULL,
  assessment_date = Sys.Date(),
  output_dir = "output/reports"
) {
  
  # Create YAML metadata (auto-generated from parameters)
  site_metadata <- list(
    project = list(
      name = project_name,
      client = client_name,
      date_assessment = as.character(assessment_date)
    ),
    site = list(
      latitude = latitude,
      longitude = longitude
    )
  )
  
  # Save YAML (for record-keeping)
  yaml_file <- here("data", "siteInfo", paste0("siteMetadata_", project_name, ".yaml"))
  yaml::write_yaml(site_metadata, yaml_file)
  
  # Run data acquisition
  source(here("scripts", "1-dataAcquisition.R"))
  
  # Run data processing
  source(here("scripts", "2-dataProcessing.R"))
  
  # Run all section scripts
  for (i in 3:11) {
    source(here("scripts", paste0(i, "-", section_names[i], ".R")))
  }
  
  # Render Quarto document (THIS IS THE KEY PART)
  quarto::quarto_render(
    input = here("templates", "reportTemplate.qmd"),
    output_format = c("pdf", "html"),
    execute_params = list(
      site_lat = latitude,
      site_lon = longitude,
      project_name = project_name,
      client_name = client_name,
      assessment_date = as.character(assessment_date)
    ),
    output_dir = output_dir
  )
  
  # Return paths to generated files
  return(list(
    pdf_path = file.path(output_dir, paste0("reportTemplate.pdf")),
    html_path = file.path(output_dir, paste0("reportTemplate.html")),
    status = "success"
  ))
}
```

## Quarto Template Structure (Unchanged)

The Quarto template (`templates/reportTemplate.qmd`) works exactly as planned:

```yaml
---
title: "Site Assessment Report"
format:
  pdf:
    documentclass: article
    geometry:
      - paperwidth=11in
      - paperheight=17in
      - margin=0.5in
  html:
    theme: cosmo
    toc: true
params:
  site_lat: 40.7128
  site_lon: -74.0060
  project_name: "Example Project"
  client_name: "Example Client"
  assessment_date: "2025-01-02"
---

# Site Assessment Report

## Project Information
- **Project:** `r params$project_name`
- **Client:** `r params$client_name`
- **Date:** `r params$assessment_date`
- **Location:** `r params$site_lat`, `r params$site_lon`

```{r}
#| echo: false
#| fig-width: 10
#| fig-height: 8

# Load processed data
source(here("scripts", "loadProcessedData.R"))

# Generate sections (these call scripts 3-11)
source(here("scripts", "3-coverSheet.R"))
source(here("scripts", "4-regionalContext.R"))
# ... etc
```

## Key Points

1. **Quarto rendering is unchanged** - Still uses `quarto::quarto_render()`
2. **Template works as planned** - Still generates 11x17 PDF and interactive HTML
3. **Shiny just triggers it** - The app calls the rendering function
4. **Parameters passed through** - Site info flows: Shiny → Script → Quarto
5. **Downloads work seamlessly** - Shiny provides download buttons for generated files

## Benefits of This Approach

1. **Separation of Concerns**:
   - Shiny = User interface
   - Scripts = Processing logic
   - Quarto = Document generation

2. **Flexibility**:
   - Can still run scripts directly (for batch processing)
   - Can still use Quarto directly (for testing)
   - Shiny adds convenience layer

3. **Maintainability**:
   - Scripts remain testable independently
   - Quarto template remains unchanged
   - Shiny UI can evolve separately

## Output Files

Both formats are generated and available for download:

1. **PDF Report** (`reportTemplate.pdf`):
   - 11x17 format (as specified)
   - Professional layout
   - All sections included

2. **Interactive HTML** (`reportTemplate.html`):
   - Web/tablet viewable
   - Interactive elements
   - Can be hosted or viewed locally

## Progress Tracking

Shiny can show progress during Quarto rendering:

```r
# In Shiny server
withProgress(message = 'Generating report...', value = 0, {
  incProgress(0.1, detail = "Acquiring data...")
  source(here("scripts", "1-dataAcquisition.R"))
  
  incProgress(0.2, detail = "Processing data...")
  source(here("scripts", "2-dataProcessing.R"))
  
  incProgress(0.5, detail = "Generating sections...")
  # ... section scripts ...
  
  incProgress(0.8, detail = "Rendering PDF and HTML...")
  quarto::quarto_render(...)
  
  incProgress(1.0, detail = "Complete!")
})
```

## Summary

✅ **Quarto rendering works perfectly with Shiny**  
✅ **No changes needed to Quarto template**  
✅ **Both PDF and HTML outputs generated**  
✅ **Shiny provides convenient download interface**  
✅ **Scripts remain modular and testable**

The Shiny app is just a friendly wrapper around the same powerful Quarto document generation you planned!

---

*Document created: 2025-01-02*  
*Integration: Shiny UI + Quarto Rendering*

