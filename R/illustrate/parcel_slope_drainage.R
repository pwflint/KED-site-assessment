library(sf)
library(terra)
library(ggplot2)
library(ggrepel)

# Parcel-scale interpretive graphic: slope and drainage direction. Settled
# 2026-09-16. Caller must source R/illustrate/parcel_building_mask.R first.
#
# Companion to parcel_base_map.R (the "actual data" graphic) - this one is
# derived/interpretive: arrows show downslope direction (from DEM aspect),
# scaled in length to slope %, labeled with slope % rounded to the nearest
# whole number. An "area of particular risk" zone highlights ground over
# the same 20%-grade NRCS-style erosion threshold already used in
# dem.R's summarize_topography().
#
# Uses ggplot2 + ggrepel for the labels, not base R text() - a base-R
# attempt (manual grid spacing + fixed-offset labels) went through two
# rounds of real bugs: labels landing on the building fill, then a
# denser grid fixing coverage but reintroducing label collisions that
# simple point-distance thinning couldn't catch (collisions came from
# variable label-arrow length, not point spacing). ggrepel solves general
# label collision properly, the same reason regional_inset.R already uses
# it. See docs/ILLUSTRATION_NOTES.md for the full iteration history.
#
# GRID/THRESHOLD PARAMETERS ARE NOT VALIDATED DEFAULTS - all four
# (grid_spacing_ft, bldg_clearance_ft, risk_threshold_pct, focal window)
# were tuned against one small (0.14 acre) rectangular parcel with one
# building. A larger or irregularly-shaped parcel may need different values
# to get sensible coverage.
render_parcel_slope_drainage <- function(parcel_sf, dem, own_building_sf, buffer_ft = 15,
                                          grid_spacing_ft = 10, bldg_clearance_ft = 8,
                                          risk_threshold_pct = 20, max_arrow_len_ft = 9) {
  parcel_2264 <- st_transform(parcel_sf, 2264)
  bldg_2264 <- st_transform(own_building_sf, 2264)
  display_poly <- st_as_sfc(st_bbox(st_buffer(parcel_2264, buffer_ft)), crs = 2264)

  dem_masked <- mask_dem_to_exclude_building(dem, own_building_sf)
  slope_pct <- tan(terrain(dem_masked, v = "slope", unit = "degrees") * pi / 180) * 100
  aspect_rad <- terrain(dem_masked, v = "aspect", unit = "radians")
  sin_a <- sin(aspect_rad); cos_a <- cos(aspect_rad)
  # local smoothing before sampling - single native pixels are noisy; a
  # circular mean (via sin/cos components) avoids the classic bug of
  # averaging angles directly, which breaks near the 0/360 wrap
  slope_pct_s <- focal(slope_pct, w = 3, fun = "mean", na.rm = TRUE)
  sin_a_s <- focal(sin_a, w = 3, fun = "mean", na.rm = TRUE)
  cos_a_s <- focal(cos_a, w = 3, fun = "mean", na.rm = TRUE)

  bb <- st_bbox(parcel_2264)
  grid_pts <- expand.grid(
    x = seq(bb["xmin"] + 6, bb["xmax"] - 6, by = grid_spacing_ft),
    y = seq(bb["ymin"] + 6, bb["ymax"] - 6, by = grid_spacing_ft)
  )
  grid_sf <- st_as_sf(grid_pts, coords = c("x", "y"), crs = 2264, remove = FALSE)
  inside_parcel <- lengths(st_intersects(grid_sf, parcel_2264)) > 0
  away_from_bldg <- if (nrow(bldg_2264) > 0) {
    lengths(st_intersects(grid_sf, st_buffer(bldg_2264, bldg_clearance_ft))) == 0
  } else {
    rep(TRUE, nrow(grid_pts))
  }
  grid_pts <- grid_pts[inside_parcel & away_from_bldg, ]

  grid_m <- as.matrix(grid_pts[, c("x", "y")])
  slope_at <- extract(slope_pct_s, grid_m)[, 1]
  sin_at <- extract(sin_a_s, grid_m)[, 1]
  cos_at <- extract(cos_a_s, grid_m)[, 1]
  valid <- !is.na(slope_at) & !is.na(sin_at)
  grid_pts <- grid_pts[valid, ]; slope_at <- slope_at[valid]; sin_at <- sin_at[valid]; cos_at <- cos_at[valid]

  half_len <- pmin(max_arrow_len_ft, 4 + slope_at * 0.25) / 2
  arrow_df <- data.frame(
    x0 = grid_pts$x - sin_at * half_len, y0 = grid_pts$y - cos_at * half_len,
    x1 = grid_pts$x + sin_at * half_len, y1 = grid_pts$y + cos_at * half_len,
    label = paste0(round(slope_at), "%")
  )

  risk_mask <- slope_pct > risk_threshold_pct
  risk_mask[risk_mask == 0] <- NA
  risk_sf <- st_as_sf(as.polygons(risk_mask, dissolve = TRUE))
  risk_clip <- if (nrow(risk_sf) > 0) suppressWarnings(st_intersection(risk_sf, parcel_2264)) else risk_sf

  p <- ggplot() +
    geom_sf(data = display_poly, fill = "white", color = NA)
  if (nrow(risk_clip) > 0) {
    p <- p + geom_sf(data = risk_clip, fill = scales::alpha("#b5502a", 0.28), color = "#b5502a", linewidth = 0.4)
  }
  if (nrow(bldg_2264) > 0) {
    p <- p + geom_sf(data = bldg_2264, fill = grey(0.4), color = grey(0.25), linewidth = 0.4)
  }
  p <- p +
    geom_segment(data = arrow_df, aes(x = x0, y = y0, xend = x1, yend = y1),
                 arrow = arrow(length = unit(0.12, "cm"), angle = 25), color = "#2a5a8c", linewidth = 0.5) +
    geom_label_repel(data = arrow_df, aes(x = x1, y = y1, label = label), color = "#2a5a8c",
                      size = 2.6, label.size = NA, fill = scales::alpha("white", 0.85),
                      segment.color = "#2a5a8c", segment.size = 0.25, min.segment.length = 0,
                      box.padding = 0.15, max.overlaps = Inf, seed = 1) +
    geom_sf(data = parcel_2264, fill = NA, color = "black", linewidth = 0.7, linetype = "dashed") +
    coord_sf(datum = NA) +
    theme_void()

  p
}
