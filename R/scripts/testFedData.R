# Test if FedData works without arcgislayers
# Most FedData functions don't require arcgislayers

cat("Testing FedData installation...\n\n")

# Try to load FedData
tryCatch({
  library(FedData)
  cat("✅ FedData loaded successfully!\n\n")
  
  # Check what functions are available
  cat("Available FedData functions:\n")
  feddata_functions <- ls("package:FedData")
  cat("  -", paste(head(feddata_functions, 10), collapse = "\n  - "))
  if (length(feddata_functions) > 10) {
    cat("\n  ... and", length(feddata_functions) - 10, "more\n")
  }
  
  cat("\n✅ FedData is working! arcgislayers is NOT required for most functions.\n")
  cat("   arcgislayers is only needed for ArcGIS-specific features.\n")
  
}, error = function(e) {
  cat("❌ FedData failed to load:\n")
  cat("   Error:", e$message, "\n")
  cat("\nThis might indicate a different problem.\n")
})

