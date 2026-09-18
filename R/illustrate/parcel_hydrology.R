library(sf)
library(terra)
library(ggplot2)
library(ggrepel)
library(ggspatial)

# Section 03 (Hydrology and drainage) illustrations, styled to the design
# system. Started 2026-09-18. Two graphics, zoom in then zoom out, per Peter:
#
#   1. parcel flow    - the section 02 base map (contours over tint, buildings,
#                       parcel line) with downhill flow arrows over it: which
#                       way water moves across the lot, longer arrow = steeper
#   2. neighborhood   - self-rendered vector base (roads, buildings, contours),
#                       the parcel's HUC12 tinted and its boundary drawn and
#                       labeled, major reaches with flow direction, the parcel
#                       as a bloom marker, and where it all drains to
#
# No raster tile. Decision 2026-09-18, docs/ILLUSTRATION_NOTES.md (basemap
# provider section). Roads come from R/acquisition/roads.R, reaches from the
# City of Raleigh hydrology service (Raleigh-specific, see neighborhood_context.R),
# both through the county cache in R/acquisition/local_cache.R.
#
# Caller must source R/illustrate/parcel_topography.R (tokens, themes,
# prep_parcel_topography, downhill_arrows, layers) first.

# ---- 1. parcel-scale flow --------------------------------------------------

render_parcel_flow_ked <- function(topo, grid_spacing_ft = 10, bldg_clearance_ft = 8,
                                   max_arrow_len_ft = 10) {
  arrows <- downhill_arrows(topo, grid_spacing_ft, bldg_clearance_ft, max_arrow_len_ft,
                            min_len_ft = 4.5, slope_scale = 0.35)
  render_parcel_base_map_ked(topo, show_transect = FALSE, label_contours = FALSE) +
    geom_segment(data = arrows, aes(x = x0, y = y0, xend = x1, yend = y1),
                 arrow = arrow(length = unit(0.14, "cm"), angle = 24, type = "closed"),
                 color = KED$water[5], linewidth = 0.6, lineend = "round", linejoin = "mitre")
}

# ---- 2. neighborhood hydrology --------------------------------------------

#' @param parcel_sf parcel polygon (any CRS)
#' @param dem_n SpatRaster from get_dem_clip(parcel_sf, buffer_ft) at the same buffer
#' @param ws get_watershed() result (huc06, huc12 with tohuc)
#' @param hucs get_huc12_in_extent() result: every HUC12 touching the frame
#' @param hydro reach linework in EPSG:2264 (FTYPE, NAME, RCH_CODE)
#' @param roads road centerlines (highway, name), any CRS
#' @param bldgs building footprints, any CRS
#' @param flood check_flood_zone() result; its polygon is drawn when present
#' @param buffer_ft display extent radius. Not a validated standard extent
#'   (docs/ILLUSTRATION_NOTES.md): chosen because this parcel sits ~1,000 ft
#'   from its HUC12 boundary.
#' @param major_reach_min_ft reaches (grouped by RCH_CODE) shorter than this
#'   in total are dropped; 1,000 ft from a real gap in one parcel's data
prep_neighborhood_hydrology <- function(parcel_sf, dem_n, ws, hucs, hydro, roads, bldgs, flood = NULL,
                                         buffer_ft = 2500, major_reach_min_ft = 1000,
                                         contour_interval_ft = 2, index_interval_ft = 10) {
  parcel <- st_transform(parcel_sf, 2264)
  frame <- st_as_sfc(st_bbox(st_buffer(parcel, buffer_ft)), crs = 2264)
  clip <- function(x) suppressWarnings(st_intersection(st_transform(x, 2264), frame))

  # Contours: aggregate to ~25 ft cells first, which smooths past the
  # building-void artifact (same approach as the July prototype)
  dem_agg <- aggregate(dem_n, fact = 8, fun = "mean", na.rm = TRUE)
  rng <- range(values(dem_agg), na.rm = TRUE)
  levels <- seq(floor(rng[1] / contour_interval_ft) * contour_interval_ft,
                ceiling(rng[2] / contour_interval_ft) * contour_interval_ft, by = contour_interval_ft)
  contours <- clip(st_as_sf(as.contour(dem_agg, levels = levels)))
  contours$is_index <- abs(contours$level %% index_interval_ft) < 1e-6

  # HUC12s: the parcel's own, tinted; neighbors, labeled. The true boundary
  # line is extracted BEFORE clipping (clipping the polygon first silently
  # adds the frame's own edges as fake watershed edge; a real July bug).
  hucs_2264 <- st_transform(hucs, 2264)
  own_code <- ws$huc12$huc12
  hucs_2264$is_own <- hucs_2264$huc12 == own_code
  huc_polys <- clip(hucs_2264)
  boundary <- st_cast(st_boundary(hucs_2264[hucs_2264$is_own, ]), "MULTILINESTRING")
  boundary <- clip(boundary)
  pos <- st_coordinates(st_point_on_surface(st_geometry(huc_polys)))
  huc_labels <- data.frame(name = paste(huc_polys$name, "watershed"),
                           is_own = huc_polys$is_own, x = pos[, 1], y = pos[, 2])

  # Reaches: group by RCH_CODE, keep the long ones, point an arrow downstream
  # at the end of each group's longest segment (downstream = lower DEM value)
  hydro <- st_transform(hydro, 2264)
  hydro <- hydro[hydro$FTYPE %in% c("STREAM/RIVER", "CANAL/DITCH"), ]
  hydro$len_ft <- as.numeric(st_length(hydro))
  code_ok <- !is.na(hydro$RCH_CODE) & nzchar(trimws(hydro$RCH_CODE))
  by_code <- aggregate(len_ft ~ RCH_CODE, data = st_drop_geometry(hydro[code_ok, ]), sum)
  by_code <- by_code[order(-by_code$len_ft), ]
  major_codes <- by_code$RCH_CODE[by_code$len_ft > major_reach_min_ft]   # longest first
  major <- clip(hydro[code_ok & hydro$RCH_CODE %in% major_codes, ])
  minor <- clip(hydro[!(code_ok & hydro$RCH_CODE %in% major_codes), ])
  # Arrow per major reach, on the clipped linework so the arrow stays in
  # frame: longest clipped piece, downstream end = lower DEM value
  flow_arrows <- do.call(rbind, lapply(major_codes, function(code) {
    grp <- major[major$RCH_CODE == code, ]
    if (nrow(grp) == 0) return(NULL)
    pieces <- st_cast(st_cast(st_geometry(grp), "MULTILINESTRING"), "LINESTRING")
    seg <- pieces[which.max(st_length(pieces))]
    # Clipped ends sit on the frame edge where the DEM is NA: compare
    # elevation a little way in from each end, and draw the arrow along the
    # line at 80% of the way toward the downstream end so it stays in frame
    n <- 12
    pts <- st_cast(st_line_sample(seg, n = n), "POINT")
    xy <- st_coordinates(pts)[, c("X", "Y")]
    z <- extract(dem_n, xy)[, 1]
    if (sum(!is.na(z)) < 4) return(NULL)
    first_ok <- which(!is.na(z))[1]; last_ok <- tail(which(!is.na(z)), 1)
    downstream_last <- z[last_ok] < z[first_ok]
    if (!downstream_last) xy <- xy[nrow(xy):1, ]
    i <- round(n * 0.8); j <- min(n, i + 1)
    t <- xy[j, ] - xy[i - 1, ]; t <- t / sqrt(sum(t^2))
    data.frame(x0 = xy[i, 1] - t * 80, y0 = xy[i, 2] - t * 80, x1 = xy[i, 1] + t * 60, y1 = xy[i, 2] + t * 60)
  }))
  if (is.null(flow_arrows)) flow_arrows <- data.frame(x0 = numeric(), y0 = numeric(), x1 = numeric(), y1 = numeric())
  flow_arrows$labeled <- seq_len(nrow(flow_arrows)) == 1   # one "to <watershed>" label, on the longest reach

  roads <- clip(roads)
  roads$rank <- ifelse(roads$highway %in% c("motorway", "trunk", "primary", "secondary"), 1L,
                       ifelse(roads$highway == "tertiary", 2L, 3L))
  # Label a few named through-roads (rank 1-2), longest first, for orientation
  named <- roads[roads$rank <= 2 & !is.na(roads$name), ]
  road_labels <- NULL
  if (nrow(named) > 0) {
    named$len <- as.numeric(st_length(named))
    agg <- aggregate(len ~ name, st_drop_geometry(named), sum)
    agg <- agg[order(-agg$len), ][seq_len(min(3, nrow(agg))), ]
    road_labels <- do.call(rbind, lapply(agg$name, function(nm) {
      g <- st_union(st_geometry(named[named$name == nm, ]))
      g <- st_cast(st_line_merge(g), "LINESTRING")
      g <- g[which.max(st_length(g))]
      p <- st_coordinates(st_line_sample(g, sample = 0.5))
      xy <- st_coordinates(g); i <- which.min((xy[, 1] - p[1])^2 + (xy[, 2] - p[2])^2)
      j <- min(nrow(xy), i + 1); k <- max(1, i - 1)
      ang <- atan2(xy[j, 2] - xy[k, 2], xy[j, 1] - xy[k, 1]) * 180 / pi
      if (ang > 90) ang <- ang - 180; if (ang < -90) ang <- ang + 180
      data.frame(name = nm, x = p[1], y = p[2], angle = ang)
    }))
  }

  # The state footprint GDB stores a few buildings as MULTISURFACE (curved
  # edges); GEOS cannot intersect those, so cast everything to plain polygons
  bldgs <- clip(st_cast(bldgs, "MULTIPOLYGON"))
  flood_poly <- if (!is.null(flood) && !is.null(flood$geometry)) clip(flood$geometry) else NULL

  list(parcel = parcel, frame = frame, contours = contours, huc_polys = huc_polys,
       boundary = boundary, huc_labels = huc_labels, major = major, minor = minor,
       flow_arrows = flow_arrows, roads = roads, road_labels = road_labels, bldgs = bldgs,
       flood_poly = flood_poly, huc12_name = ws$huc12$name, huc06_name = ws$huc06$name)
}

render_neighborhood_hydrology_ked <- function(nb) {
  bb <- st_bbox(nb$frame)
  p <- ggplot() +
    geom_sf(data = nb$huc_polys[nb$huc_polys$is_own, ], fill = KED$water[1], color = NA)
  if (!is.null(nb$flood_poly) && length(nb$flood_poly) > 0) {
    p <- p + geom_sf(data = nb$flood_poly, fill = scales::alpha(KED$ember[2], 0.6), color = NA)
  }
  p <- p +
    geom_sf(data = nb$contours[!nb$contours$is_index, ], color = KED$ochre[2], linewidth = 0.15) +
    geom_sf(data = nb$contours[nb$contours$is_index, ], color = KED$ochre[3], linewidth = 0.3) +
    geom_sf(data = nb$bldgs, fill = KED$material[2], color = NA) +
    geom_sf(data = nb$roads[nb$roads$rank == 3, ], color = KED$material[3], linewidth = 0.35) +
    geom_sf(data = nb$roads[nb$roads$rank == 2, ], color = KED$material[4], linewidth = 0.6) +
    geom_sf(data = nb$roads[nb$roads$rank == 1, ], color = KED$material[4], linewidth = 0.9)
  if (nrow(nb$minor) > 0) p <- p + geom_sf(data = nb$minor, color = KED$water[2], linewidth = 0.4)
  if (nrow(nb$major) > 0) p <- p + geom_sf(data = nb$major, color = KED$water[4], linewidth = 1.3, lineend = "round")
  if (nrow(nb$flow_arrows) > 0) {
    p <- p + geom_segment(data = nb$flow_arrows, aes(x = x0, y = y0, xend = x1, yend = y1),
                          arrow = arrow(length = unit(0.18, "cm"), angle = 24, type = "closed"),
                          color = KED$water[5], linewidth = 0.8, lineend = "round", linejoin = "mitre") +
      geom_label_repel(data = nb$flow_arrows[nb$flow_arrows$labeled, ], aes(x = x1, y = y1, label = paste("to", nb$huc12_name)),
                       family = KED_FONT, size = 2.5, color = KED$water[6], fill = scales::alpha(KED$surface, 0.8),
                       label.size = NA, segment.color = KED$water[4], segment.size = 0.25,
                       min.segment.length = 0, box.padding = 0.4, seed = 5, max.overlaps = Inf)
  }
  p <- p +
    geom_sf(data = nb$boundary, color = KED$accent, linewidth = 0.8, linetype = "42") +
    geom_sf(data = nb$parcel, fill = KED$bloom_marker, color = KED$bloom_marker, linewidth = 0.8) +
    annotate("point", x = st_coordinates(st_centroid(st_geometry(nb$parcel)))[1],
             y = st_coordinates(st_centroid(st_geometry(nb$parcel)))[2],
             shape = 21, size = 5.5, stroke = 0.9, color = KED$bloom_marker, fill = NA)
  if (!is.null(nb$road_labels)) {
    p <- p + geom_text(data = nb$road_labels, aes(x, y, label = name, angle = angle), family = KED_FONT,
                       size = 2.4, color = KED$material[6], vjust = -0.5)
  }
  p <- p +
    geom_label(data = nb$huc_labels, aes(x, y, label = name), family = KED_FONT, size = 2.9,
               color = KED$accent, fill = scales::alpha(KED$surface, 0.8), label.size = NA,
               label.padding = unit(0.18, "lines"), fontface = "plain") +
    annotate("label", x = st_coordinates(st_centroid(st_geometry(nb$parcel)))[1],
             y = st_coordinates(st_centroid(st_geometry(nb$parcel)))[2] + 140,
             label = "your parcel", family = KED_FONT, size = 2.8, color = KED$ink,
             fill = scales::alpha(KED$surface, 0.85), label.size = NA) +
    layer_scale_north() +
    coord_sf(datum = NA, expand = FALSE, xlim = bb[c("xmin", "xmax")], ylim = bb[c("ymin", "ymax")]) +
    theme_ked_map()
  p
}

# ---- statistics for the report ---------------------------------------------

compass_word <- c(N = "north", NE = "northeast", E = "east", SE = "southeast",
                  S = "south", SW = "southwest", W = "west", NW = "northwest")

hydrology_stats <- function(topo, ws, flood, hucs) {
  rose <- aspect_rose_data(topo)
  top <- as.character(rose$dir[which.max(rose$pct)])
  to_name <- hucs$name[match(ws$huc12$tohuc, hucs$huc12)]
  list(
    watershed_name = ws$huc12$name,
    basin_name = ws$huc06$name,
    downstream_huc12_name = if (length(to_name) && !is.na(to_name)) to_name else NULL,
    drainage_direction = unname(compass_word[top]),
    flood_zone = if (identical(flood$status, "studied")) paste("Zone", flood$flood_zone) else NULL,
    flood_zone_subtype = if (identical(flood$status, "studied")) flood$zone_subtype else NULL,
    in_special_flood_hazard_area = flood$in_special_flood_hazard_area
  )
}
