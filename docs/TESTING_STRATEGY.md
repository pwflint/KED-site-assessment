# Package Testing Strategy

## Approach: Comprehensive First, Then Incremental

### Phase 1: Initial Comprehensive Test

**Before starting development**, run a comprehensive test to verify all packages load:

```r
source("R/utils/testPackageLoading.R")
```

This will:
- ✅ Test loading all required packages
- ✅ Test key package combinations (sf + terra, tidyverse, etc.)
- ✅ Check for dependency conflicts
- ✅ Verify Quarto is available
- ✅ Check project structure
- ✅ Provide clear summary of any issues

**Why do this first?**
- Catch dependency issues early
- Ensure development environment is ready
- Avoid discovering problems mid-development
- Get a baseline of what works

### Phase 2: Component-Specific Testing

**As we build each component**, test the packages that component uses:

#### When building data acquisition (`1-dataAcquisition.R`):
```r
# Test packages needed for data acquisition
library(FedData)      # Soils
library(prism)        # Climate
library(rnoaa)        # Wind/NOAA
library(nhdplusTools) # Watersheds
# Test API helpers
source("R/functions/apiHelpers.R")
```

#### When building data processing (`2-dataProcessing.R`):
```r
# Test spatial packages
library(sf)
library(terra)
# Test data helpers
source("R/functions/dataHelpers.R")
# Test basic operations
test_boundary <- st_point(c(0, 0)) %>% st_sfc(crs = "EPSG:4326")
test_raster <- rast(nrows = 10, ncols = 10)
```

#### When building visualizations (scripts 3-11):
```r
# Test visualization packages
library(ggplot2)
library(patchwork)
library(ggspatial)
# Test mapping helpers
source("R/functions/mapHelpers.R")
# Test basic plot
ggplot() + theme_minimal()
```

## Testing Workflow

### 1. Initial Setup (Do Once)
```r
# Comprehensive test
source("R/utils/testPackageLoading.R")

# If issues found, fix them:
source("R/utils/installSpecialPackages.R")
source("R/utils/checkPackages.R")
```

### 2. Before Building Each Component
- Test packages that component will use
- Test helper functions that component will call
- Verify basic functionality works

### 3. After Building Each Component
- Run the component script
- Verify it produces expected output
- Check for warnings or errors

## Benefits of This Approach

1. **Early Detection**: Catch issues before they block development
2. **Focused Testing**: Test what you need when you need it
3. **Context-Aware**: Test packages in the context they'll be used
4. **Incremental Validation**: Verify each component works as you build

## Quick Reference

### Comprehensive Test
```r
source("R/utils/testPackageLoading.R")
```

### Component-Specific Tests
- **Data Acquisition**: Test `FedData`, `prism`, `rnoaa`, `nhdplusTools`
- **Data Processing**: Test `sf`, `terra`, data helpers
- **Visualization**: Test `ggplot2`, `patchwork`, mapping helpers
- **Report Generation**: Test `quarto`, `gt`, `kableExtra`

### If Issues Found
1. Check `docs/TROUBLESHOOTING.md` for solutions
2. Run `source("R/utils/checkPackages.R")` for detailed status
3. Use `source("R/utils/installSpecialPackages.R")` for special cases

