# Quick verification script for arcgislayers
# Checks if it's actually installed and working

cat("Checking arcgislayers status...\n\n")

if (requireNamespace("arcgislayers", quietly = TRUE)) {
  cat("✅ arcgislayers IS installed and available\n")
  cat("   Version:", as.character(packageVersion("arcgislayers")), "\n\n")
  
  # Try to load it
  tryCatch({
    library(arcgislayers)
    cat("✅ arcgislayers loaded successfully\n")
  }, error = function(e) {
    cat("⚠️  arcgislayers installed but failed to load:\n")
    cat("   Error:", e$message, "\n")
  })
} else {
  cat("❌ arcgislayers is NOT installed\n\n")
  cat("This is OK! Most FedData functions work without it.\n")
  cat("arcgislayers is only needed for ArcGIS-specific features.\n\n")
  cat("To verify FedData works, run:\n")
  cat("  source('R/scripts/testFedData.R')\n")
}

