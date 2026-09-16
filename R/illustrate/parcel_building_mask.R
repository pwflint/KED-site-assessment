library(sf)
library(terra)

# Caller must source R/acquisition/building_footprint.R first (for
# get_building_footprints()).
#
# Shared helper for both parcel-scale illustrations. Settled 2026-09-16 after
# finding the DEM's bare-earth void-fill under a building shows up as a
# fabricated flat surface with sharp edges - slope/aspect/relief computed
# across it produces a fake elevated-slope "ring" tracing the building
# footprint exactly, not real terrain. See docs/ILLUSTRATION_NOTES.md.
#
# get_building_footprints() can return a neighboring parcel's building too
# (anything within the search buffer, not just the subject parcel) - filter
# to PID == the subject parcel's own parno, confirmed exact-match convention
# already documented in building_footprint.R.

#' @return sf polygon(s) for the buildings that actually belong to this
#'   parcel (PID match), or a zero-row sf if none - a parcel can have no
#'   structure at all, don't assume there's always one to mask.
get_own_building_footprint <- function(parcel_sf, county) {
  bldg <- get_building_footprints(parcel_sf, county = county)
  bldg[bldg$PID == parcel_sf$parno, ]
}

#' Mask a DEM to exclude the building footprint before any terrain-derived
#' computation (contours, slope, aspect) - that area is fabricated fill, not
#' real ground. Returns the DEM unchanged if there's no building to mask.
mask_dem_to_exclude_building <- function(dem, own_building_sf) {
  if (nrow(own_building_sf) == 0) return(dem)
  bldg_native <- st_transform(own_building_sf, crs(dem))
  mask(dem, vect(bldg_native), inverse = TRUE)
}
