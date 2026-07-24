library(sf)
library(terra)

# PRISM 30-year monthly normals are CONUS-wide grids, not parcel-clippable via the
# distribution service - so cache each element/month grid once and reuse across
# every parcel, rather than re-downloading per site. ~2.8MB per grid, ~134MB total
# for 4 elements x 12 months - a one-time cost, not a per-assessment cost.
PRISM_CACHE_DIR <- Sys.getenv("PRISM_CACHE_DIR", file.path(tempdir(), "prism_normals_cache"))

prism_normal_raster <- function(element, month, cache_dir = PRISM_CACHE_DIR) {
  fname <- sprintf("prism_%s_us_25m_2020%02d_avg_30y", element, month)
  extract_dir <- file.path(cache_dir, fname)
  tif_path <- file.path(extract_dir, paste0(fname, ".tif"))

  if (!file.exists(tif_path)) {
    dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)
    zip_path <- file.path(cache_dir, paste0(fname, ".zip"))
    url <- sprintf(
      "https://data.prism.oregonstate.edu/normals/us/4km/%s/monthly/%s.zip",
      element, fname
    )
    download.file(url, zip_path, quiet = TRUE, mode = "wb")
    unzip(zip_path, exdir = extract_dir)
  }
  rast(tif_path)
}

# PRD seasonal grouping: Winter Nov-Jan, Spring Feb-Apr, Summer May-Jul, Fall Aug-Oct
SEASONS <- list(
  winter = c(11, 12, 1),
  spring = c(2, 3, 4),
  summer = c(5, 6, 7),
  fall   = c(8, 9, 10)
)

# --- monthly normal value for one element, at one point ---
get_monthly_normal <- function(element, month, point_wgs84_xy) {
  r <- prism_normal_raster(element, month)
  pt <- vect(matrix(point_wgs84_xy, ncol = 2), crs = "EPSG:4326")
  pt <- project(pt, crs(r))
  as.numeric(extract(r, pt)[, 2])
}

# --- full seasonal normals profile for a parcel ---
get_seasonal_normals <- function(parcel_sf, elements = c("ppt", "tmax", "tmin", "tmean")) {
  centroid <- st_transform(st_centroid(parcel_sf), 4326) |> st_coordinates()
  point_xy <- c(centroid[1, "X"], centroid[1, "Y"])

  result <- list()
  for (el in elements) {
    monthly <- vapply(1:12, function(m) get_monthly_normal(el, m, point_xy), numeric(1))
    names(monthly) <- month.abb
    seasonal <- vapply(SEASONS, function(months) mean(monthly[months]), numeric(1))
    result[[el]] <- list(monthly = monthly, seasonal = seasonal)
  }
  result
}
