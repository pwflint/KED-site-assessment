library(sf)
library(ggplot2)
library(ggrepel)
library(ggspatial)

# Section 01 (Regional context) illustrations, styled to the design system.
# Started 2026-09-18. Two graphics, the report's opening zoom-out then the
# first step in:
#
#   1. regional inset  - the state outline, the parcel's Level III and IV
#                        ecoregions clipped to the state, its HUC06 river,
#                        the parcel as a marker. Composition settled in July
#                        (R/illustrate/regional_inset.R); restyled here.
#   2. orientation map - the block the client recognizes: named streets,
#                        buildings, the parcel outlined and labeled with its
#                        address. Its only job is "yes, this is your parcel"
#                        (docs/WORKFLOW_SPEC.md step 4). No data display.
#
# Labeling rules carried in from Peter's section 03 review (2026-09-18):
# every label on a busy map sits in a surface-colored box, labels are offset
# from their anchors with a leader, the subject is labeled with its address,
# and the marker for the parcel is a solid shape, not a thin ring.
#
# Caller must source R/illustrate/parcel_topography.R (tokens, themes,
# layer_scale_north) first.

# ---- 1. regional inset -----------------------------------------------------

#' @param parcel_sf parcel polygon (any CRS)
#' @param eco get_ecoregion() result (level3, level4)
#' @param state_sf state outline (get_state_outline), EPSG:4326
#' @param river_sf principal river linework (get_principal_river), clipped to the state
#' @param huc06_name basin name for the river label ("Neuse")
prep_regional <- function(parcel_sf, eco, state_sf, river_sf, huc06_name) {
  state <- st_transform(state_sf, 4326)
  # Clipping a multi-state ecoregion to the state can return a collection or
  # several pieces; reduce each level to one polygon geometry for fill + label
  clip_eco <- function(x) {
    g <- suppressWarnings(st_intersection(st_geometry(st_transform(x, 4326)), st_geometry(state)))
    st_union(st_collection_extract(g, "POLYGON"))
  }
  l3 <- clip_eco(eco$level3)
  l4 <- clip_eco(eco$level4)
  pt <- st_transform(st_centroid(st_geometry(parcel_sf)), 4326)
  river <- if (nrow(river_sf) > 0) st_transform(river_sf, 4326) else river_sf
  river_label <- NULL
  if (nrow(river) > 0) {
    # st_line_sample needs a projected CRS: place the label in state plane, return to lon/lat
    lines <- st_transform(st_collection_extract(st_geometry(river), "LINESTRING"), 2264)
    merged <- st_line_merge(st_cast(st_union(lines), "MULTILINESTRING"))
    pieces <- st_cast(merged, "LINESTRING")
    longest <- pieces[which.max(st_length(pieces))]
    xy <- st_coordinates(st_transform(st_line_sample(longest, sample = 0.62), 4326))
    river_label <- data.frame(x = xy[1], y = xy[2], label = paste(huc06_name, "River"))
  }
  list(state = state, l3 = l3, l4 = l4, river = river, river_label = river_label, pt = pt,
       l3_name = eco$level3$US_L3NAME, l4_name = eco$level4$US_L4NAME)
}

render_regional_inset_ked <- function(reg) {
  bb <- st_bbox(reg$state)
  pad <- c(0.15, 0.12)
  l3_xy <- st_coordinates(suppressWarnings(st_point_on_surface(reg$l3)))
  l4_xy <- st_coordinates(suppressWarnings(st_point_on_surface(reg$l4)))
  pt_xy <- st_coordinates(reg$pt)
  # One repelled layer for every label so they avoid each other and the
  # parcel marker; nudges push each label away from the crowded center
  labels <- data.frame(
    x = c(l3_xy[1, 1], l4_xy[1, 1], pt_xy[1]),
    y = c(l3_xy[1, 2], l4_xy[1, 2], pt_xy[2]),
    label = c(toupper(reg$l3_name), reg$l4_name, "Your parcel"),
    color = c(KED$canopy[6], KED$canopy[7], KED$ink),
    size = c(3.2, 2.9, 3),
    nx = c(-0.9, 1.1, -0.7), ny = c(-0.55, 0.45, 0.5),
    seg = c(KED$canopy[5], KED$canopy[5], KED$ink))
  if (!is.null(reg$river_label)) {
    labels <- rbind(labels, data.frame(x = reg$river_label$x, y = reg$river_label$y, label = reg$river_label$label,
                                       color = KED$water[6], size = 2.8, nx = 0.2, ny = -0.3, seg = KED$water[4]))
  }
  p <- ggplot() +
    geom_sf(data = reg$state, fill = KED$surface, color = KED$material[3], linewidth = 0.5) +
    geom_sf(data = reg$l3, fill = KED$canopy[1], color = KED$canopy[3], linewidth = 0.3) +
    geom_sf(data = reg$l4, fill = KED$canopy[2], color = KED$canopy[4], linewidth = 0.4)
  if (nrow(reg$river) > 0) p <- p + geom_sf(data = reg$river, color = KED$water[4], linewidth = 0.8, lineend = "round")
  p +
    annotate("point", x = pt_xy[1], y = pt_xy[2], shape = 21, size = 3.6, stroke = 0.7,
             fill = KED$bloom_marker, color = KED$ink) +
    geom_label_repel(data = labels, aes(x = x, y = y, label = label, color = color, size = size, segment.color = seg),
                     family = KED_FONT, fill = scales::alpha(KED$surface, 0.9), label.size = NA,
                     label.padding = unit(0.2, "lines"), segment.size = 0.3, min.segment.length = 0,
                     nudge_x = labels$nx, nudge_y = labels$ny, point.padding = 0.5, box.padding = 0.35,
                     seed = 42, max.overlaps = Inf) +
    scale_color_identity() + scale_size_identity() +
    coord_sf(datum = NA, xlim = c(bb["xmin"] - pad[1], bb["xmax"] + pad[1]),
             ylim = c(bb["ymin"] - pad[2], bb["ymax"] + pad[2]), expand = FALSE) +
    theme_ked_map()
}

# ---- 2. neighborhood orientation ------------------------------------------

#' @param parcel_sf parcel polygon (any CRS)
#' @param roads road centerlines (highway, name), any CRS; a wider fetch is fine, it is clipped
#' @param bldgs building footprints (PID), any CRS
#' @param address the parcel's street address for the label
#' @param buffer_ft frame radius; ~900 ft shows a block or two, enough to recognize
prep_neighborhood_orientation <- function(parcel_sf, roads, bldgs, address, buffer_ft = 900) {
  parcel <- st_transform(parcel_sf, 2264)
  frame <- st_as_sfc(st_bbox(st_buffer(parcel, buffer_ft)), crs = 2264)
  clip <- function(x) suppressWarnings(st_intersection(st_transform(x, 2264), frame))
  roads <- clip(roads)
  roads$rank <- ifelse(roads$highway %in% c("motorway", "trunk", "primary", "secondary"), 1L,
                       ifelse(roads$highway == "tertiary", 2L, 3L))
  bldgs <- clip(st_cast(bldgs, "MULTIPOLYGON"))
  bldgs$is_own <- bldgs$PID == parcel$parno
  # One label per named street, at the midpoint of its longest merged run
  named <- roads[!is.na(roads$name), ]
  street_labels <- NULL
  if (nrow(named) > 0) {
    street_labels <- do.call(rbind, lapply(unique(named$name), function(nm) {
      g <- st_collection_extract(st_geometry(named[named$name == nm, ]), "LINESTRING")
      g <- st_cast(st_line_merge(st_cast(st_union(g), "MULTILINESTRING")), "LINESTRING")
      g <- g[which.max(st_length(g))]
      if (as.numeric(st_length(g)) < 250) return(NULL)
      xy <- st_coordinates(st_line_sample(g, sample = 0.5))
      data.frame(name = nm, x = xy[1], y = xy[2])
    }))
  }
  cen <- st_coordinates(st_centroid(st_geometry(parcel)))
  list(parcel = parcel, frame = frame, roads = roads, bldgs = bldgs, street_labels = street_labels,
       address = address, cen = cen)
}

render_neighborhood_orientation_ked <- function(nb) {
  bb <- st_bbox(nb$frame)
  p <- ggplot() +
    geom_sf(data = nb$bldgs[!nb$bldgs$is_own, ], fill = KED$material[2], color = NA) +
    geom_sf(data = nb$roads[nb$roads$rank == 3, ], color = KED$material[3], linewidth = 0.9) +
    geom_sf(data = nb$roads[nb$roads$rank == 2, ], color = KED$material[4], linewidth = 1.3) +
    geom_sf(data = nb$roads[nb$roads$rank == 1, ], color = KED$material[4], linewidth = 1.8) +
    geom_sf(data = nb$parcel, fill = scales::alpha(KED$bloom_marker, 0.35), color = KED$bloom_marker, linewidth = 1) +
    geom_sf(data = nb$bldgs[nb$bldgs$is_own, ], fill = KED$material[5], color = KED$material[7], linewidth = 0.3)
  if (!is.null(nb$street_labels)) {
    p <- p + geom_label_repel(data = nb$street_labels, aes(x = x, y = y, label = name), family = KED_FONT,
                              size = 2.5, color = KED$material[6], fill = scales::alpha(KED$surface, 0.85),
                              label.size = NA, label.padding = unit(0.15, "lines"), segment.color = KED$material[4],
                              segment.size = 0.25, min.segment.length = 0.3, box.padding = 0.3, seed = 11,
                              max.overlaps = Inf)
  }
  p +
    geom_label_repel(data = data.frame(x = nb$cen[1], y = nb$cen[2], label = paste0("Your parcel\n", nb$address)),
                     aes(x = x, y = y, label = label), family = KED_FONT, size = 3, color = KED$ink,
                     fill = scales::alpha(KED$surface, 0.92), label.size = NA, lineheight = 0.95,
                     nudge_y = 190, segment.color = KED$ink, segment.size = 0.35, min.segment.length = 0, seed = 4) +
    layer_scale_north() +
    coord_sf(datum = NA, expand = FALSE, xlim = bb[c("xmin", "xmax")], ylim = bb[c("ymin", "ymax")]) +
    theme_ked_map()
}

# ---- statistics for the report ---------------------------------------------

regional_stats <- function(eco, ws) {
  list(
    ecoregion_l3 = eco$level3$US_L3NAME,
    ecoregion_l4 = eco$level4$US_L4NAME,
    ecoregion_l2 = eco$level3$NA_L2NAME,
    ecoregion_l1 = eco$level3$NA_L1NAME,
    huc06_name = ws$huc06$name,
    huc12_name = ws$huc12$name
  )
}
