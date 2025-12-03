# Development Rules & Guidelines

**Purpose**: Ensure consistency across multiple coding sessions and developers.

## General Principles

1. **Tidy Data First**: All data processing follows tidyverse principles
2. **Modular Design**: Functions are reusable and testable independently
3. **Clear Documentation**: Code is self-documenting with clear function names
4. **Error Handling**: Graceful failure with informative error messages
5. **Path Management**: Always use `here::here()` for file paths

## Code Organization

### Directory Structure Rules

- **R/**: All R code
  - **R/functions/**: Helper functions only (reusable utilities)
  - **R/scripts/**: Workflow scripts only (numbered execution order)
  - **R/utils/**: Utility scripts only (setup, testing, maintenance)
  - **R/ root**: Only `.Rhistory`, `.Rproj`, `.app` files (NO `.R` files)

### File Naming

- **Helper Functions**: Descriptive names ending in `Helpers.R` (e.g., `apiHelpers.R`)
- **Workflow Scripts**: Numbered with descriptive names (e.g., `1-dataAcquisition.R`)
- **Utility Scripts**: Descriptive names (e.g., `testPackageLoading.R`)

### Function Naming

- Use **snake_case** for function names
- Use **descriptive verbs**: `get_`, `create_`, `process_`, `validate_`, `save_`
- Examples: `fetch_with_cache()`, `create_site_boundary()`, `clip_to_site()`

## Coding Standards

### R Code Style

- Follow **tidyverse style guide**
- Use **tidyverse packages** (dplyr, tidyr, etc.) for data manipulation
- Use **`sf`** for vector data (not `sp`)
- Use **`terra`** for raster data (not `raster`)
- Use **`here::here()`** for all file paths

### Documentation

- **Function documentation**: Use roxygen2-style comments (`#'`)
- **Inline comments**: Explain "why", not "what"
- **Section headers**: Use `# Section Name` for major code blocks

### Error Handling

- Use `tryCatch()` for API calls and file operations
- Provide informative error messages
- Log errors but don't stop workflow unnecessarily
- Return `NULL` or empty objects on failure (not errors)

### Data Formats

- **Spatial vectors**: Always use `sf` objects
- **Rasters**: Always use `terra::SpatRaster` objects
- **Tabular data**: Always use `tibble` objects
- **Save processed data**: Use `saveRDS()` for R objects, `readr::write_csv()` for CSVs

## Workflow Rules

### Script Execution Order

1. **Setup**: Always run `source("R/scripts/0-setUp.R")` first
2. **Helper Functions**: Source as needed before using
3. **Workflow Scripts**: Execute in numbered order (1, 2, 3... 99)

### Path Conventions

```r
# Helper functions
source(here::here("R", "functions", "apiHelpers.R"))

# Workflow scripts
source(here::here("R", "scripts", "1-dataAcquisition.R"))

# Data paths
data_path <- here::here("data", "raw", "dem", "site_dem.tif")

# Output paths
output_path <- here::here("output", "figures", "cover_sheet.pdf")
```

### Testing

- **Before development**: Run `source("R/utils/testPackageLoading.R")`
- **During development**: Test packages in context as you build
- **After completion**: Test end-to-end workflow

## Package Management

### Required Packages

- All packages listed in `R/scripts/0-setUp.R`
- Never add packages without updating setup script
- Document why a package is needed

### Package Installation

- Use `install.packages()` for CRAN packages
- Use `devtools::install_github()` for GitHub packages
- Use `install.packages(..., type = "source")` if binary fails
- Document special installation requirements in `docs/TROUBLESHOOTING.md`

## Data Management

### Caching Strategy

- Cache all downloaded data in `data/raw/`
- Check cache before downloading
- Use `R/functions/apiHelpers.R` functions for caching
- Cache validation: Check file age (default: 30 days)

### Data Processing

- Process data into tidy formats
- Save processed data in `data/processed/`
- Use consistent file naming: `{data_type}_{site}_{date}.rds`
- Document data structure in code comments

## Git & Version Control

### Commit Messages

- Use clear, descriptive commit messages
- Reference issue numbers if applicable
- Group related changes in single commits

### File Organization

- Don't commit large data files (use `.gitignore`)
- Don't commit output files (use `.gitignore`)
- Do commit: code, documentation, templates, small test data

## Documentation Rules

### README Files

- **Root README.md**: Primary development guide (this file)
- **docs/README.md**: Placeholder for production documentation
- **No other READMEs**: Consolidate information into main README

### Code Comments

- **Function headers**: Document parameters, return values, examples
- **Complex logic**: Explain the "why", not just the "what"
- **TODOs**: Mark with `# TODO: description` for future work

## Session Consistency

### Starting a New Session

1. Open project: `dev_siteAssessment.Rproj`
2. Review: `README.md` for current status
3. Check: `docs/NEXT_STEPS.md` for current tasks
4. Test: Run `source("R/utils/testPackageLoading.R")` if needed

### Ending a Session

1. Update: `README.md` with progress
2. Update: `docs/NEXT_STEPS.md` with completed tasks
3. Update: `docs/planning/THINGS3_TASK_LIST.md` if using
4. Document: Any issues or decisions in appropriate docs

### Communication

- **Document decisions**: Update planning docs when making architectural decisions
- **Note issues**: Add to `docs/TROUBLESHOOTING.md` if recurring
- **Update status**: Keep README.md current with project state

## Special Considerations

### FedData v4

- Uses `terra` and `sf` (not `raster` and `sp`)
- No need for `arcgislayers` (optional)
- See `docs/FEDDATA_V4_NOTES.md` for details

### Shiny Integration (Future)

- Scripts remain independent (can run without Shiny)
- Shiny app will call scripts with parameters
- See `docs/SHINY_APP_ARCHITECTURE.md` for design

### Quarto Rendering

- All document generation uses Quarto
- Templates in `templates/reportTemplate.qmd`
- Output: PDF (11x17) + Interactive HTML

---

**Remember**: Code should be readable, maintainable, and follow these conventions for consistency across sessions.

