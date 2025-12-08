# Test Helper Functions
# Tests all helper functions to ensure they work correctly

cat("=", rep("=", 60), "\n", sep = "")
cat("HELPER FUNCTIONS TEST\n")
cat("=", rep("=", 60), "\n\n")

# Load required packages
if (!requireNamespace("here", quietly = TRUE)) {
  stop("'here' package is required")
}
library(here)

# Source setup script
source(here::here("R", "scripts", "0-setUp.R"))

# Source helper functions
cat("Loading helper functions...\n")
source(here::here("R", "functions", "apiHelpers.R"))
source(here::here("R", "functions", "dataHelpers.R"))
source(here::here("R", "functions", "geocodingHelpers.R"))
source(here::here("R", "functions", "mapHelpers.R"))

cat("\n", "=", rep("=", 60), "\n", sep = "")
cat("TESTING API HELPERS\n")
cat("=", rep("=", 60), "\n\n")

# Test check_cache
cat("Testing check_cache()... ")
test_cache_file <- here::here("data", "raw", "test_cache.rds")
if (file.exists(test_cache_file)) {
  unlink(test_cache_file)
}
result <- check_cache(test_cache_file)
if (!result) {
  cat("✅ OK (correctly returns FALSE for non-existent file)\n")
} else {
  cat("❌ FAILED\n")
}

# Test create cache file
dir.create(dirname(test_cache_file), showWarnings = FALSE, recursive = TRUE)
saveRDS(list(test = "data"), test_cache_file)
result <- check_cache(test_cache_file)
if (result) {
  cat("Testing check_cache() with existing file... ✅ OK\n")
} else {
  cat("Testing check_cache() with existing file... ❌ FAILED\n")
}

# Clean up
unlink(test_cache_file)

cat("\n", "=", rep("=", 60), "\n", sep = "")
cat("TESTING DATA HELPERS\n")
cat("=", rep("=", 60), "\n\n")

# Test load_site_metadata
cat("Testing load_site_metadata()... ")
test_yaml <- here::here("data", "siteInfo", "siteMetadata_template.yaml")
if (file.exists(test_yaml)) {
  tryCatch({
    metadata <- load_site_metadata(test_yaml)
    if (is.list(metadata) && "project" %in% names(metadata)) {
      cat("✅ OK\n")
    } else {
      cat("❌ FAILED (invalid structure)\n")
    }
  }, error = function(e) {
    cat("❌ FAILED:", e$message, "\n")
  })
} else {
  cat("⚠️  SKIPPED (template file not found)\n")
}

# Test create_site_boundary
cat("Testing create_site_boundary()... ")
test_metadata <- list(
  site = list(
    latitude = 35.7796,  # North Carolina coordinates
    longitude = -78.6382,
    bbox = list(
      xmin = -78.65,
      xmax = -78.63,
      ymin = 35.77,
      ymax = 35.79
    )
  ),
  analysis = list(
    buffer_distance = 500
  )
)

tryCatch({
  boundary <- create_site_boundary(test_metadata)
  if (inherits(boundary, "sf")) {
    cat("✅ OK\n")
  } else {
    cat("❌ FAILED (not an sf object)\n")
  }
}, error = function(e) {
  cat("❌ FAILED:", e$message, "\n")
})

# Test raster_to_tibble
cat("Testing raster_to_tibble()... ")
tryCatch({
  test_raster <- terra::rast(nrows = 10, ncols = 10, 
                              xmin = -78.65, xmax = -78.63,
                              ymin = 35.77, ymax = 35.79,
                              vals = runif(100))
  terra::crs(test_raster) <- "EPSG:4326"
  test_tibble <- raster_to_tibble(test_raster)
  if (tibble::is_tibble(test_tibble) && ncol(test_tibble) == 3) {
    cat("✅ OK\n")
  } else {
    cat("❌ FAILED (invalid structure)\n")
  }
}, error = function(e) {
  cat("❌ FAILED:", e$message, "\n")
})

cat("\n", "=", rep("=", 60), "\n", sep = "")
cat("TESTING GEOCODING HELPERS\n")
cat("=", rep("=", 60), "\n\n")

# Test geocode_address (will make actual API call - may take time)
cat("Testing geocode_address()... ")
cat("(Skipping - requires API call, test manually)\n")

cat("\n", "=", rep("=", 60), "\n", sep = "")
cat("TESTING MAP HELPERS\n")
cat("=", rep("=", 60), "\n\n")

# Test create_base_map
cat("Testing create_base_map()... ")
tryCatch({
  test_boundary <- create_site_boundary(test_metadata)
  base_map <- create_base_map(test_boundary)
  if (inherits(base_map, "gg")) {
    cat("✅ OK\n")
  } else {
    cat("❌ FAILED (not a ggplot object)\n")
  }
}, error = function(e) {
  cat("❌ FAILED:", e$message, "\n")
})

cat("\n", "=", rep("=", 60), "\n", sep = "")
cat("TEST SUMMARY\n")
cat("=", rep("=", 60), "\n\n")
cat("✅ Helper functions test complete!\n")
cat("   Review any failures above and fix before proceeding.\n\n")

