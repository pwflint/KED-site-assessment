# Quick script to install arcgislayers package
# This is a dependency of FedData (but OPTIONAL)

cat("Installing arcgislayers...\n\n")

# Track installation success
install_success <- FALSE

# Try source installation first
result <- tryCatch({
  install.packages("arcgislayers", type = "source", repos = "https://cran.rstudio.com/")
  TRUE  # Return TRUE if no error
}, error = function(e) {
  cat("⚠️  Source installation failed\n")
  cat("   Error:", e$message, "\n\n")
  FALSE  # Return FALSE on error
}, warning = function(w) {
  # Warnings don't necessarily mean failure, but check anyway
  FALSE
})

# Check if package is actually available (regardless of what install.packages reported)
if (requireNamespace("arcgislayers", quietly = TRUE)) {
  install_success <- TRUE
  cat("✅ arcgislayers is now available\n")
  cat("   You can load it with: library(arcgislayers)\n")
} else {
  # Installation failed - provide helpful information
  cat("\n" , "=", rep("=", 50), "\n", sep = "")
  cat("INSTALLATION FAILED - But this is OK!\n")
  cat("=", rep("=", 50), "\n", sep = "")
  cat("\n⚠️  arcgislayers is NOT available\n\n")
  cat("IMPORTANT: arcgislayers is OPTIONAL!\n\n")
  cat("Most FedData functions work WITHOUT arcgislayers.\n")
  cat("It's only needed for ArcGIS-specific features.\n\n")
  cat("Common reasons for failure:\n")
  cat("  - Requires Rust compiler (rustc)\n")
  cat("  - Dependencies (arcpbf, arcgisutils) also need Rust\n")
  cat("  - C++ compilation issues (RcppSimdJson)\n\n")
  cat("To test if FedData works without it, run:\n")
  cat("  source('R/scripts/testFedData.R')\n\n")
  cat("If you really need arcgislayers, install Rust first:\n")
  cat("  brew install rust\n")
  cat("Then retry: source('R/scripts/installArcGISLayers.R')\n")
}

