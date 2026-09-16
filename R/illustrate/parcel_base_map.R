library(sf)
library(terra)

# Parcel-scale "actual data" base map. Settled 2026-09-16. Caller must source
# R/acquisition/dem.R and R/illustrate/parcel_building_mask.R first.
#
# Deliberately NOT a DEM raster/hillshade render - see
# docs/ILLUSTRATION_NOTES.md for why (a full raster-shading approach was
# tried and rejected at neighborhood scale; at parcel scale the same DEM's
# building-void artifact covers a much larger share of the tiny frame,
# making it worse, not better). This draws our own vector base map instead:
# contours (derived from the DEM, masked around the building), the building
# footprint as a flat fill (not pretending to know what's under the roof),
# and the parcel boundary - all vector, all attributable to a real source.
#
# CANOPY DELIBERATELY OMITTED: NLCD Tree Canopy Cover is 30m native
# resolution (see canopy.R) - a typical parcel-scale display extent (order
# of 150ft) is smaller than a single native pixel. A canopy polygon clipped
# to this frame would just be one coarse pixel's yes/no answer rendered as
# if it were a precise tree-crown boundary - the same false-precision
# mistake the building-void masking exists to avoid elsewhere. Not resolved,
# just correctly left out rather than shown misleadingly.
#
# CONTOUR INTERVAL: 0.25ft / 1ft index chosen after comparing 1ft, 0.5ft,
# 0.25ft, and 0.1ft on the same DEM - 1ft was too sparse to show real shape
# (Peter's call), 0.1ft started looking like amplified noise/edge artifact
# rather than real ground (our call, no documented vertical-accuracy figure
# for this DEM to confirm precisely where that line is). Not a validated
# general default - re-check on a parcel with different relief.
render_parcel_base_map <- function(parcel_sf, dem, own_building_sf, buffer_ft = 15,
                                    contour_interval_ft = 0.25, index_interval_ft = 1) {
  parcel_2264 <- st_transform(parcel_sf, 2264)
  bldg_2264 <- st_transform(own_building_sf, 2264)
  display_poly <- st_as_sfc(st_bbox(st_buffer(parcel_2264, buffer_ft)), crs = 2264)

  dem_masked <- mask_dem_to_exclude_building(dem, own_building_sf)
  rng <- range(values(dem_masked), na.rm = TRUE)
  levels <- seq(floor(rng[1] / contour_interval_ft) * contour_interval_ft,
                ceiling(rng[2] / contour_interval_ft) * contour_interval_ft,
                by = contour_interval_ft)
  contours_sf <- st_as_sf(as.contour(dem_masked, levels = levels))
  contours_sf$is_index <- abs(contours_sf$level %% index_interval_ft) < 1e-6

  list(
    plot = function() {
      plot(display_poly, col = "white", border = NA)
      plot(st_geometry(contours_sf[!contours_sf$is_index, ]), add = TRUE, col = grey(0.8), lwd = 0.6)
      plot(st_geometry(contours_sf[contours_sf$is_index, ]), add = TRUE, col = grey(0.6), lwd = 1.1)
      if (nrow(bldg_2264) > 0) plot(st_geometry(bldg_2264), add = TRUE, col = grey(0.4), border = grey(0.25), lwd = 1)
      plot(st_geometry(parcel_2264), add = TRUE, border = "black", lwd = 2, lty = 2)
    },
    contour_count = nrow(contours_sf),
    relief_ft = rng[2] - rng[1]
  )
}
