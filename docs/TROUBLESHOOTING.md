# Troubleshooting Guide

## Package Installation Issues

### FedData Package

**Problem**: `FedData` fails to install from CRAN binary (404 errors)

**Solutions**:

1. **Install from source**:
   ```r
   install.packages("FedData", type = "source")
   ```

2. **Install from GitHub** (if source fails):
   ```r
   if (!requireNamespace("devtools", quietly = TRUE)) {
     install.packages("devtools")
   }
   devtools::install_github("ropensci/FedData")
   ```

3. **System dependencies** (macOS):
   - FedData requires GDAL and PROJ libraries
   - Install via Homebrew:
     ```bash
     brew install gdal proj
     ```
   - Then retry R package installation

4. **Use the special installation script**:
   ```r
   source("R/scripts/installSpecialPackages.R")
   ```

### R Version Compatibility

**Problem**: Packages built for different R versions (e.g., "package 'bslib' was built under R version 4.2.3")

**Solution**: 
- This is usually just a warning, not an error
- Packages should still work, but you may want to update R or rebuild packages:
  ```r
   update.packages(ask = FALSE, checkBuilt = TRUE)
   ```

### arcgislayers Dependency

**Problem**: `arcgislayers` fails to install (dependency of FedData)

**Important**: `arcgislayers` is **OPTIONAL** - most FedData functions work without it!

**Why it fails**:
- Requires Rust compiler (`rustc`)
- Dependencies `arcgisutils` and `arcpbf` also require Rust
- `RcppSimdJson` may have C++ compilation issues

**Solutions**:

1. **Skip it** (Recommended):
   - Most FedData functions (SSURGO, NED, etc.) work fine without `arcgislayers`
   - Only needed for ArcGIS-specific features
   - Test FedData: `source("R/scripts/testFedData.R")`

2. **Install Rust** (if you really need arcgislayers):
   ```bash
   brew install rust
   ```
   Then retry:
   ```r
   install.packages("arcgislayers", type = "source")
   ```

3. **Fix RcppSimdJson** (if Rust is installed but still fails):
   - May need to update Xcode command line tools:
     ```bash
     xcode-select --install
     ```
   - Or install from binary if available

## Common Issues

### Package Masking Warnings

**Example**: `The following object is masked from 'package:utils': page`

**Solution**: 
- These are warnings, not errors
- Packages can mask functions from base R
- Usually safe to ignore, but be aware when using masked function names

### Binary vs Source Version Mismatch

**Problem**: "There is a binary version available but the source version is later"

**Solution**:
- Binary versions are pre-compiled and faster to install
- Source versions may have newer features
- You can force source installation:
  ```r
   install.packages("PackageName", type = "source")
   ```

## Checking Package Status

Run the package check script:
```r
source("R/scripts/checkPackages.R")
```

This will:
- List all required packages
- Check installation status
- Test loading each package
- Report any issues with specific error messages

## Getting Help

If packages continue to fail:

1. **Check R version**: `R.version.string`
2. **Check system dependencies**: Some packages (like `sf`, `terra`) need system libraries
3. **Update R**: Consider updating to latest R version
4. **Check package documentation**: Visit package CRAN or GitHub pages
5. **Install system dependencies** (macOS):
   ```bash
   brew install gdal proj geos udunits
   ```

## Package-Specific Notes

### Spatial Packages (sf, terra)
- Require GDAL, PROJ, GEOS system libraries
- Install via Homebrew on macOS

### Quarto
- Requires separate Quarto installation
- Download from: https://quarto.org/docs/get-started/
- R package `quarto` is just an interface

### Whitebox
- May require Java
- Check: `system("java -version")`

