library(sf)
library(terra)
library(ggplot2)
library(ggrepel)
library(ggspatial)

# Section 02 (Topography and landform) illustrations, styled to the site
# assessment design system (docs/DESIGN_SYSTEM.md, R/report/assets/styles.css).
# Started 2026-09-17 from the settled prototypes in parcel_base_map.R and
# parcel_slope_drainage.R; those stay as the plain-R record of what was
# validated, this file is the client-facing version.
#
# Four graphics from one prepared dataset (prep_parcel_topography):
#   1. base map      - contours over a hypsometric tint, buildings, parcel line,
#                      transect marker (the report's most-used base image)
#   2. slope/drainage - slope class fill, downhill arrows, erosion-risk zone
#   3. profile       - street-to-back-fence ground section along the transect
#   4. aspect rose   - share of sloping ground facing each compass direction
# plus topography_stats() for the report's stat row and bar chart.
#
# Same rules as the prototypes: the DEM is masked to exclude the building
# footprint BEFORE any terrain math (the void-fill under a roof fabricates a
# slope ring that traces the building - see docs/ILLUSTRATION_NOTES.md), and
# canopy is deliberately absent at this scale (30m NLCD pixels are bigger than
# the frame).
#
# Interpolation, stated plainly: the 3.1 ft DEM is upsampled 4x (bilinear) and
# lightly smoothed before contouring and sampling. That is what makes the
# contours read as ground rather than pixel edges; it does not add information.
# The profile's segment under the house is a straight-line interpolation
# between the ground at the walls and is drawn dashed to say so.
#
# Caller must source R/acquisition/dem.R, R/acquisition/building_footprint.R,
# and R/illustrate/parcel_building_mask.R first.

# ---- design tokens ----------------------------------------------------------
# Hex values copied from R/report/assets/styles.css (the vendored design
# system). Data-family colors are the same in light and dark themes; chrome
# colors (ink, muted, line, surface) are swapped for CSS variables by
# svg_apply_tokens() so the SVG follows the page theme.
KED <- list(
  ink = "#2C2620", heading = "#3A3228", muted = "#887D6C", caption = "#9E9484",
  line = "#D4CAB4", line_light = "#E2DACB", surface = "#FBF9F5", accent = "#9A6A2F",
  ochre = c("#E9E6E2", "#D3C7BB", "#C1A68B", "#AE855B", "#856647", "#5F4C3A", "#42382E", "#2C2621"),
  ember = c("#E9E3E2", "#D3BEBB", "#C1928B", "#AE665B", "#855047", "#5F3F3A", "#42312E", "#2C2221"),
  gold  = c("#E9E7E2", "#D3CCBB", "#C1B18B", "#AE975B", "#857347", "#5F543A", "#423C2E", "#2C2921"),
  water = c("#E2E6E9", "#BBC8D3", "#8BA8C1", "#5B87AE", "#476885", "#3A4E5F", "#2E3942", "#21272C"),
  material = c("#ECEBE9", "#D0CCC8", "#B4ADA7", "#988F86", "#797067", "#5E5750", "#423D38", "#2C2926"),
  bloom_marker = "#E0913A"
)
KED_FONT <- "Poppins"

KED_SVG_TOKENS <- c(
  "#2C2620" = "var(--ink)", "#3A3228" = "var(--heading)", "#887D6C" = "var(--muted)",
  "#9E9484" = "var(--caption)", "#D4CAB4" = "var(--line)", "#E2DACB" = "var(--line-light)",
  "#FBF9F5" = "var(--surface-elevated)", "#9A6A2F" = "var(--accent)"
)

theme_ked_map <- function(base_size = 9) {
  theme_void(base_size = base_size, base_family = KED_FONT) +
    theme(plot.margin = margin(4, 4, 4, 4), legend.position = "none")
}

theme_ked_chart <- function(base_size = 10) {
  theme_minimal(base_size = base_size, base_family = KED_FONT) +
    theme(
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = KED$line_light, linewidth = 0.3),
      axis.text = element_text(color = KED$muted, size = base_size * 0.9),
      axis.title = element_text(color = KED$muted, size = base_size * 0.9),
      plot.margin = margin(6, 8, 4, 4), legend.position = "none"
    )
}

# ---- data preparation ------------------------------------------------------

# Opening-then-closing buffer: rounds raster-derived polygon corners without
# moving the shape, so a class boundary reads as a contour, not a staircase.
round_corners <- function(x, r_ft) {
  g <- st_buffer(st_buffer(st_geometry(x), -r_ft), 2 * r_ft)
  g <- st_buffer(g, -r_ft)
  st_set_geometry(x, g)
}

slope_classes <- data.frame(
  key = c("flat_0_2", "gentle_2_8", "moderate_8_15", "steep_15_plus"),
  label = c("Flat (0–2%)", "Gentle (2–8%)", "Moderate (8–15%)", "Steep (15%+)"),
  lower = c(0, 2, 8, 15), upper = c(2, 8, 15, Inf),
  fill = KED$ochre[1:4], stringsAsFactors = FALSE)

#' @param parcel_sf parcel polygon (any CRS)
#' @param dem SpatRaster from get_dem_clip(), buffered well beyond the parcel
#' @param bldgs_sf building footprints in and around the parcel (get_building_footprints);
#'   the parcel's own building is identified by PID == parno, the rest are context
#' @param street_side which parcel edge faces the street ("E","W","N","S"): sets
#'   the transect direction and the "Street" label. Comes from the practitioner
#'   or a road lookup, not guessed from the DEM.
prep_parcel_topography <- function(parcel_sf, dem, bldgs_sf, street_side = "E",
                                    buffer_ft = 30, upsample = 4,
                                    contour_interval_ft = 0.25, index_interval_ft = 1,
                                    risk_threshold_pct = 20) {
  parcel <- st_transform(parcel_sf, 2264)
  bldgs <- st_transform(bldgs_sf, 2264)
  own <- bldgs[bldgs$PID == parcel$parno, ]
  neighbors <- bldgs[bldgs$PID != parcel$parno, ]
  frame <- st_as_sfc(st_bbox(st_buffer(parcel, buffer_ft)), crs = 2264)

  # Mask, then interpolate. Masking first is the whole point (see header).
  dem_m <- mask_dem_to_exclude_building(dem, own)
  dem_s <- disagg(dem_m, fact = upsample, method = "bilinear")
  dem_s <- focal(dem_s, w = 5, fun = "mean", na.rm = TRUE, na.policy = "omit")
  dem_s <- mask_dem_to_exclude_building(dem_s, own)
  dem_s <- crop(dem_s, vect(frame))

  slope_pct <- tan(terrain(dem_s, v = "slope", unit = "radians")) * 100
  aspect_deg <- terrain(dem_s, v = "aspect", unit = "degrees")

  rng <- range(values(dem_s), na.rm = TRUE)
  levels <- seq(floor(rng[1] / contour_interval_ft) * contour_interval_ft,
                ceiling(rng[2] / contour_interval_ft) * contour_interval_ft,
                by = contour_interval_ft)
  contours <- st_as_sf(as.contour(dem_s, levels = levels))
  contours$is_index <- abs(contours$level %% index_interval_ft) < 1e-6

  # Slope-class polygons for the drainage graphic (open ground only)
  # Class fills are for reading, not measuring: smooth a little more than the
  # stats use, and round the polygon corners so class edges read as ground,
  # not pixels. Stats in topography_stats() use the unsmoothed slope_pct.
  slope_for_fill <- focal(slope_pct, w = 7, fun = "mean", na.rm = TRUE)
  cls <- classify(slope_for_fill, rbind(c(0, 2, 1), c(2, 8, 2), c(8, 15, 3), c(15, Inf, 4)))
  class_polys <- st_as_sf(as.polygons(cls, dissolve = TRUE))
  names(class_polys)[1] <- "class_id"
  class_polys <- round_corners(class_polys, 1.5)
  class_polys <- suppressWarnings(st_intersection(class_polys, parcel))
  class_polys$key <- slope_classes$key[class_polys$class_id]

  risk <- slope_for_fill > risk_threshold_pct
  risk[risk == 0] <- NA
  risk_polys <- st_as_sf(as.polygons(risk, dissolve = TRUE))
  if (nrow(risk_polys) > 0) {
    risk_polys <- round_corners(risk_polys, 1)
    risk_polys <- suppressWarnings(st_intersection(risk_polys, parcel))
  }

  # Transect: straight through the parcel centroid, street edge -> back edge
  bb <- st_bbox(parcel); cen <- st_coordinates(st_centroid(st_geometry(parcel)))
  transect <- switch(street_side,
    E = rbind(c(bb["xmax"], cen[2]), c(bb["xmin"], cen[2])),
    W = rbind(c(bb["xmin"], cen[2]), c(bb["xmax"], cen[2])),
    N = rbind(c(cen[1], bb["ymax"]), c(cen[1], bb["ymin"])),
    S = rbind(c(cen[1], bb["ymin"]), c(cen[1], bb["ymax"])))
  transect_sf <- st_sfc(st_linestring(transect), crs = 2264)
  transect_sf <- st_intersection(transect_sf, st_geometry(parcel))

  list(parcel = parcel, own = own, neighbors = neighbors, frame = frame,
       dem = dem_s, slope_pct = slope_pct, aspect_deg = aspect_deg,
       contours = contours, class_polys = class_polys, risk_polys = risk_polys,
       transect = transect_sf, street_side = street_side,
       risk_threshold_pct = risk_threshold_pct)
}

# ---- statistics for the report ---------------------------------------------

topography_stats <- function(topo) {
  pv <- vect(topo$parcel)
  on_parcel <- function(r) values(mask(crop(r, pv), pv))
  elev <- on_parcel(topo$dem); slope <- on_parcel(topo$slope_pct)
  slope <- slope[!is.na(slope)]
  dist <- vapply(seq_len(nrow(slope_classes)), function(i) {
    mean(slope >= slope_classes$lower[i] & slope < slope_classes$upper[i]) * 100
  }, numeric(1))
  names(dist) <- slope_classes$key
  list(
    elevation_change_ft = round(diff(range(elev, na.rm = TRUE)), 1),
    elevation_range_ft = round(range(elev, na.rm = TRUE), 1),
    max_slope_pct = round(quantile(slope, 0.99)),   # 99th pct: ignores a single spiky cell
    parcel_area_acres = round(as.numeric(st_area(topo$parcel)) / 43560, 2),
    slope_distribution = as.list(round(dist)),
    erosion_risk_pct = round(mean(slope > topo$risk_threshold_pct) * 100, 1),
    mean_slope_pct = round(mean(slope), 1)
  )
}

# ---- shared layers ---------------------------------------------------------

layer_buildings <- function(topo) {
  list(
    if (nrow(topo$neighbors) > 0)
      geom_sf(data = topo$neighbors, fill = KED$material[2], color = NA),
    if (nrow(topo$own) > 0)
      geom_sf(data = topo$own, fill = KED$material[4], color = KED$material[6], linewidth = 0.3)
  )
}

layer_parcel <- function(topo) {
  geom_sf(data = topo$parcel, fill = NA, color = KED$ink, linewidth = 0.6, linetype = "22")
}

# "Street" label just outside the street-side edge, rotated to run along it
layer_street_label <- function(topo, offset_ft = 16) {
  bb <- st_bbox(topo$parcel); cen <- st_coordinates(st_centroid(st_geometry(topo$parcel)))
  pos <- switch(topo$street_side,
    E = c(bb["xmax"] + offset_ft, cen[2], 90), W = c(bb["xmin"] - offset_ft, cen[2], 90),
    N = c(cen[1], bb["ymax"] + offset_ft, 0), S = c(cen[1], bb["ymin"] - offset_ft, 0))
  annotate("text", x = pos[1], y = pos[2], label = "STREET", angle = pos[3],
           family = KED_FONT, size = 2.4, color = KED$muted, fontface = "plain")
}

layer_scale_north <- function() {
  list(
    annotation_scale(location = "bl", unit_category = "imperial", width_hint = 0.2,
                     height = unit(0.12, "cm"), bar_cols = c(KED$ink, KED$surface),
                     line_col = KED$ink, text_col = KED$muted, text_family = KED_FONT,
                     text_cex = 0.6, pad_x = unit(0.3, "cm"), pad_y = unit(0.25, "cm")),
    annotation_north_arrow(location = "tr", which_north = "true", height = unit(0.7, "cm"),
                           width = unit(0.5, "cm"), pad_x = unit(0.3, "cm"), pad_y = unit(0.25, "cm"),
                           style = north_arrow_minimal(line_col = KED$muted, text_col = KED$muted,
                                                       fill = KED$muted, text_family = KED_FONT,
                                                       text_size = 7))
  )
}

# The transect's "A" end is the street end, whichever order the coordinates
# come back in after intersection.
transect_ends <- function(topo) {
  tc <- st_coordinates(topo$transect)
  e <- data.frame(x = tc[c(1, nrow(tc)), 1], y = tc[c(1, nrow(tc)), 2])
  street_first <- switch(topo$street_side, E = e$x[1] > e$x[2], W = e$x[1] < e$x[2],
                         N = e$y[1] > e$y[2], S = e$y[1] < e$y[2])
  e$label <- if (street_first) c("A", "A\u2032") else c("A\u2032", "A")
  e
}

# ---- 1. base map -----------------------------------------------------------

render_parcel_base_map_ked <- function(topo, show_transect = TRUE, label_contours = TRUE) {
  dem_df <- as.data.frame(topo$dem, xy = TRUE, na.rm = TRUE); names(dem_df)[3] <- "z"
  idx <- topo$contours[topo$contours$is_index, ]
  # One label per index contour, placed at the point of the line nearest the
  # frame's center-left so labels don't bunch on the busy edge
  label_pts <- do.call(rbind, lapply(seq_len(nrow(idx)), function(i) {
    pts <- st_coordinates(idx[i, ])[, 1:2, drop = FALSE]
    if (nrow(pts) < 6) return(NULL)
    p <- pts[round(nrow(pts) * 0.5), ]
    data.frame(x = p[1], y = p[2], label = sprintf("%g ft", idx$level[i]))
  }))
  # Drop labels whose anchor sits on a building or hugs the frame edge
  if (!is.null(label_pts)) {
    lp <- st_as_sf(label_pts, coords = c("x", "y"), crs = 2264, remove = FALSE)
    all_bldg <- c(st_geometry(topo$own), st_geometry(topo$neighbors))
    on_bldg <- if (length(all_bldg) > 0) lengths(st_intersects(lp, st_buffer(all_bldg, 3))) > 0 else FALSE
    inner <- st_buffer(topo$frame, -8)
    label_pts <- label_pts[!on_bldg & lengths(st_intersects(lp, inner)) > 0, ]
  }

  p <- ggplot() +
    geom_raster(data = dem_df, aes(x, y, fill = z), interpolate = TRUE) +
    scale_fill_gradient(low = KED$ochre[1], high = KED$ochre[3]) +
    geom_sf(data = topo$contours[!topo$contours$is_index, ], color = KED$ochre[4], linewidth = 0.25, alpha = 0.8) +
    geom_sf(data = idx, color = KED$ochre[6], linewidth = 0.5) +
    layer_buildings(topo) +
    layer_parcel(topo)
  if (label_contours && !is.null(label_pts) && nrow(label_pts) > 0) {
    p <- p + geom_label_repel(data = label_pts, aes(x, y, label = label), family = KED_FONT,
                              size = 2.3, color = KED$ink, fill = scales::alpha(KED$surface, 0.85),
                              label.size = NA, label.padding = 0.12, segment.color = KED$ochre[5],
                              segment.size = 0.25, min.segment.length = 0.2, max.overlaps = Inf, seed = 7)
  }
  if (show_transect) {
    ends <- transect_ends(topo)
    p <- p +
      geom_sf(data = topo$transect, color = KED$accent, linewidth = 0.5, linetype = "solid", alpha = 0.9) +
      geom_point(data = ends, aes(x, y), color = KED$accent, size = 1.4) +
      geom_text(data = ends, aes(x, y, label = label), family = KED_FONT, size = 2.6,
                color = KED$accent, nudge_y = 5, fontface = "bold")
  }
  p + layer_street_label(topo) + layer_scale_north() +
    coord_sf(datum = NA, expand = FALSE) + theme_ked_map()
}

# ---- 2. slope and drainage -------------------------------------------------

# Arrow field: sample the smoothed slope/aspect on a grid inside the parcel,
# clear of the building. Circular mean via sin/cos handles the 0/360 wrap.
# Arrow length grows with slope (min_len_ft + slope * slope_scale, capped).
# Shared by the section 02 slope graphic and the section 03 flow graphic.
downhill_arrows <- function(topo, grid_spacing_ft = 10, bldg_clearance_ft = 8,
                            max_arrow_len_ft = 9, min_len_ft = 3.5, slope_scale = 0.3) {
  parcel <- topo$parcel; own <- topo$own
  aspect_rad <- topo$aspect_deg * pi / 180
  sin_a <- focal(sin(aspect_rad), w = 5, fun = "mean", na.rm = TRUE)
  cos_a <- focal(cos(aspect_rad), w = 5, fun = "mean", na.rm = TRUE)
  slope_s <- focal(topo$slope_pct, w = 5, fun = "mean", na.rm = TRUE)

  bb <- st_bbox(parcel)
  grid <- expand.grid(x = seq(bb["xmin"] + 6, bb["xmax"] - 6, by = grid_spacing_ft),
                      y = seq(bb["ymin"] + 6, bb["ymax"] - 6, by = grid_spacing_ft))
  grid_sf <- st_as_sf(grid, coords = c("x", "y"), crs = 2264, remove = FALSE)
  keep <- lengths(st_intersects(grid_sf, parcel)) > 0
  if (nrow(own) > 0) keep <- keep & lengths(st_intersects(grid_sf, st_buffer(own, bldg_clearance_ft))) == 0
  grid <- grid[keep, ]
  m <- as.matrix(grid[, c("x", "y")])
  sl <- extract(slope_s, m)[, 1]; sa <- extract(sin_a, m)[, 1]; ca <- extract(cos_a, m)[, 1]
  ok <- !is.na(sl) & !is.na(sa)
  grid <- grid[ok, ]; sl <- sl[ok]; sa <- sa[ok]; ca <- ca[ok]
  half <- pmin(max_arrow_len_ft, min_len_ft + sl * slope_scale) / 2
  data.frame(x0 = grid$x - sa * half, y0 = grid$y - ca * half,
             x1 = grid$x + sa * half, y1 = grid$y + ca * half,
             label = paste0(round(sl), "%"), slope = sl)
}

render_parcel_slope_drainage_ked <- function(topo, grid_spacing_ft = 10, bldg_clearance_ft = 8,
                                             max_arrow_len_ft = 9, frame_buffer_ft = 14) {
  parcel <- topo$parcel
  frame <- st_bbox(st_buffer(parcel, frame_buffer_ft))
  arrows <- downhill_arrows(topo, grid_spacing_ft, bldg_clearance_ft, max_arrow_len_ft)

  cp <- topo$class_polys
  cp$fill <- slope_classes$fill[match(cp$key, slope_classes$key)]

  p <- ggplot() +
    geom_sf(data = parcel, fill = KED$ochre[1], color = NA) +
    geom_sf(data = cp, aes(fill = fill), color = NA) +
    scale_fill_identity()
  if (nrow(topo$risk_polys) > 0) {
    p <- p + geom_sf(data = topo$risk_polys, fill = scales::alpha(KED$ember[3], 0.55),
                     color = KED$ember[5], linewidth = 0.4)
  }
  p <- p + layer_buildings(topo) +
    geom_segment(data = arrows, aes(x = x0, y = y0, xend = x1, yend = y1),
                 arrow = arrow(length = unit(0.13, "cm"), angle = 24, type = "closed"),
                 color = KED$water[5], linewidth = 0.55, lineend = "round", linejoin = "mitre") +
    geom_label_repel(data = arrows, aes(x = x1, y = y1, label = label), family = KED_FONT,
                     color = KED$ink, size = 2.3, label.size = NA, label.padding = 0.1,
                     fill = scales::alpha(KED$surface, 0.85), segment.color = KED$water[4],
                     segment.size = 0.25, min.segment.length = 0, box.padding = 0.15,
                     max.overlaps = Inf, seed = 1) +
    layer_parcel(topo) + layer_street_label(topo) + layer_scale_north() +
    coord_sf(datum = NA, expand = FALSE, xlim = frame[c("xmin", "xmax")], ylim = frame[c("ymin", "ymax")]) +
    theme_ked_map()
  p
}

# ---- 3. ground profile along the transect ---------------------------------

profile_data <- function(topo, step_ft = 1) {
  line <- topo$transect
  e <- transect_ends(topo)
  if (e$label[1] != "A") line <- st_reverse(line)   # distance 0 = street end
  len <- as.numeric(st_length(line))
  d <- seq(0, len, by = step_ft)
  pts <- st_line_sample(line, sample = d / len)
  xy <- st_coordinates(st_cast(pts, "POINT"))[, 1:2]
  z <- extract(topo$dem, xy)[, 1]
  df <- data.frame(d = d, z = z)
  # Under the house the DEM is masked; interpolate straight across and flag it
  df$under_building <- is.na(df$z)
  if (any(df$under_building) && sum(!df$under_building) >= 2) {
    df$z <- approx(df$d[!df$under_building], df$z[!df$under_building], xout = df$d, rule = 2)$y
  }
  df
}

render_parcel_profile_ked <- function(topo) {
  df <- profile_data(topo)
  base <- min(df$z, na.rm = TRUE)
  df$rel <- df$z - base
  total_len <- max(df$d)
  # House block, only where the masked run actually is
  top <- max(df$rel)
  # House: a low, translucent block over its footprint span so the dashed
  # (interpolated) ground line stays visible beneath it
  house <- NULL
  if (any(df$under_building)) {
    r <- range(df$d[df$under_building])
    floor_z <- max(df$rel[df$d >= r[1] & df$d <= r[2]])
    house <- data.frame(xmin = r[1], xmax = r[2], ymin = floor_z, ymax = floor_z + top * 0.35)
  }
  hi <- df[which.max(df$rel), ]; lo <- df[which.min(df$rel), ]
  under <- df$under_building
  under_run <- under | c(FALSE, head(under, -1)) | c(tail(under, -1), FALSE)

  p <- ggplot(df, aes(d, rel)) +
    geom_area(fill = KED$ochre[2], color = NA, alpha = 0.9)
  if (!is.null(house)) {
    p <- p + geom_rect(data = house, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
                       inherit.aes = FALSE, fill = scales::alpha(KED$material[3], 0.7),
                       color = KED$material[5], linewidth = 0.3) +
      annotate("text", x = mean(c(house$xmin, house$xmax)), y = house$ymax + top * 0.08,
               label = "house", family = KED_FONT, size = 3, color = KED$material[6])
  }
  p <- p +
    geom_line(data = df[!under, ], color = KED$ochre[6], linewidth = 0.7) +
    geom_line(data = df[under_run, ], color = KED$ochre[5], linewidth = 0.5, linetype = "22") +
    scale_x_continuous(expand = expansion(mult = c(0.01, 0.01))) +
    scale_y_continuous(breaks = pretty(c(0, top), 4), labels = function(v) paste0(v, " ft"),
                       expand = expansion(mult = c(0, 0.3))) +
    labs(x = NULL, y = NULL) +
    coord_cartesian(clip = "off") +
    theme_ked_chart() +
    theme(panel.grid.major.x = element_blank(), axis.text.x = element_blank())
  ann <- data.frame(
    d = c(hi$d, lo$d), rel = c(hi$rel, lo$rel),
    label = c(sprintf("high point, +%g ft", round(hi$rel, 1)), "low point"))
  p + geom_point(data = ann, aes(d, rel), color = KED$accent, size = 1.6) +
    geom_text_repel(data = ann, aes(d, rel, label = label), family = KED_FONT, size = 3,
                    color = KED$accent, nudge_y = top * 0.18, segment.color = KED$accent,
                    segment.size = 0.3, min.segment.length = 0, seed = 3) +
    annotate("text", x = 0, y = -top * 0.1, label = "A  street side", hjust = 0, vjust = 1,
             family = KED_FONT, size = 3.1, color = KED$ink) +
    annotate("text", x = total_len, y = -top * 0.1, label = "back of lot  A\u2032", hjust = 1, vjust = 1,
             family = KED_FONT, size = 3.1, color = KED$ink) +
    annotate("text", x = total_len * 0.5, y = top * 1.26,
             label = sprintf("%g ft of rise and fall over %g ft; vertical scale exaggerated", round(top, 1), round(total_len)),
             family = KED_FONT, size = 2.9, color = KED$muted)
}

# ---- 4. aspect rose ---------------------------------------------------------

aspect_rose_data <- function(topo, min_slope_pct = 1.5) {
  pv <- vect(topo$parcel)
  a <- values(mask(crop(topo$aspect_deg, pv), pv))
  s <- values(mask(crop(topo$slope_pct, pv), pv))
  ok <- !is.na(a) & !is.na(s) & s >= min_slope_pct
  a <- a[ok]
  dirs <- c("N", "NE", "E", "SE", "S", "SW", "W", "NW")
  idx <- floor(((a + 22.5) %% 360) / 45) + 1
  counts <- tabulate(idx, nbins = 8)
  data.frame(dir = factor(dirs, levels = dirs), pct = counts / sum(counts) * 100,
             sloping_share = mean(ok))
}

render_aspect_rose_ked <- function(topo) {
  df <- aspect_rose_data(topo)
  df$fill <- ifelse(df$dir %in% c("SE", "S", "SW"), KED$gold[4], KED$gold[2])
  top <- df$dir[which.max(df$pct)]
  rings <- data.frame(y = c(20, 40)); rings <- rings[rings$y < max(df$pct) * 1.1, , drop = FALSE]
  ggplot(df, aes(dir, pct)) +
    geom_hline(data = rings, aes(yintercept = y), color = KED$line_light, linewidth = 0.3) +
    geom_col(aes(fill = fill), width = 0.85, color = NA) +
    scale_fill_identity() +
    geom_text(data = rings, aes(x = 0.5, y = y, label = paste0(y, "%")), family = KED_FONT,
              size = 2.1, color = KED$caption, vjust = -0.3, inherit.aes = FALSE) +
    geom_text(aes(y = max(pct) * 1.28, label = dir), family = KED_FONT, size = 3, color = KED$ink) +
    geom_text(data = df[df$pct >= 8, ], aes(y = pct * 0.55, label = paste0(round(pct), "%")),
              family = KED_FONT, size = 2.4, color = KED$gold[7]) +
    coord_polar(start = -pi / 8) +
    scale_y_continuous(limits = c(0, max(df$pct) * 1.4)) +
    theme_ked_map() +
    theme(plot.margin = margin(0, 0, 0, 0))
}

# ---- SVG export ------------------------------------------------------------

#' Render a ggplot to an SVG string ready for inline embedding: transparent
#' background, fixed pt size removed so CSS width:100% scales it, chrome colors
#' swapped for design-system CSS variables, R's font-metric text stretching
#' removed so the browser lays Poppins out itself.
ggplot_to_svg <- function(p, width = 7.6, height = 5, tokens = KED_SVG_TOKENS) {
  tmp <- tempfile(fileext = ".svg")
  svglite::svglite(tmp, width = width, height = height, bg = "transparent")
  print(p)
  dev.off()
  svg <- paste(readLines(tmp, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  svg <- sub("^<\\?xml[^>]*>\\s*", "", svg)
  svg <- sub("width='[0-9.]+pt' height='[0-9.]+pt' ", "", svg)
  svg <- gsub(" textLength='[0-9.]+px' lengthAdjust='spacingAndGlyphs'", "", svg)
  svg <- gsub("<rect width='100%' height='100%' style='stroke: none; fill: (transparent|none);'/>\n?", "", svg)
  for (hex in names(tokens)) svg <- gsub(hex, tokens[[hex]], svg, fixed = TRUE)
  svg
}
