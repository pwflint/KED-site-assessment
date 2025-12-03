# Special Package Installation Script
# Handles packages that may need special installation methods

# Install arcgislayers first (dependency of FedData)
if (!requireNamespace("arcgislayers", quietly = TRUE)) {
  cat("Installing arcgislayers (dependency of FedData)...\n")
  
  # Try installing from source
  tryCatch({
    install.packages("arcgislayers", type = "source", repos = "https://cran.rstudio.com/")
    cat("✅ arcgislayers installed from source\n")
  }, error = function(e) {
    cat("⚠️  Source installation failed, trying binary...\n")
    tryCatch({
      install.packages("arcgislayers", repos = "https://cran.rstudio.com/")
      cat("✅ arcgislayers installed from binary\n")
    }, error = function(e2) {
      cat("❌ arcgislayers installation failed:\n")
      cat("   Error:", e2$message, "\n")
      cat("   Note: arcgislayers may not be critical if FedData works\n")
    })
  })
} else {
  cat("✅ arcgislayers is already installed\n")
}

# Install FedData from source (if binary fails)
if (!requireNamespace("FedData", quietly = TRUE)) {
  cat("\nInstalling FedData...\n")
  
  # Try installing from source first
  tryCatch({
    install.packages("FedData", type = "source", repos = "https://cran.rstudio.com/")
    cat("✅ FedData installed from source\n")
  }, error = function(e) {
    cat("⚠️  Source installation failed, trying GitHub...\n")
    # Try from GitHub if source fails
    if (!requireNamespace("devtools", quietly = TRUE)) {
      install.packages("devtools")
    }
    tryCatch({
      devtools::install_github("ropensci/FedData")
      cat("✅ FedData installed from GitHub\n")
    }, error = function(e2) {
      cat("❌ FedData installation failed:\n")
      cat("   Error:", e2$message, "\n")
      cat("   You may need to install dependencies manually:\n")
      cat("   - arcgislayers\n")
      cat("   - rgdal (if available)\n")
    })
  })
} else {
  cat("✅ FedData is already installed\n")
}

# Verify installations
cat("\n" , "=", rep("=", 50), "\n", sep = "")
cat("Verification:\n")
cat("=", rep("=", 50), "\n", sep = "")

if (requireNamespace("arcgislayers", quietly = TRUE)) {
  cat("✅ arcgislayers is available\n")
} else {
  cat("⚠️  arcgislayers is not available (may not be critical)\n")
}

if (requireNamespace("FedData", quietly = TRUE)) {
  cat("✅ FedData is available\n")
} else {
  cat("❌ FedData installation failed. Check error messages above.\n")
  cat("   Note: FedData may have system dependencies (GDAL, PROJ)\n")
  cat("   Install via Homebrew: brew install gdal proj\n")
}

