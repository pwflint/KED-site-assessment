library(sf)
library(ggplot2)
library(ggrepel)

# Section 07 (Vulnerabilities and opportunities) illustrations. Started
# 2026-09-19. REVIEW 2026-09-19 (Peter): the sun path belongs in section 06 and
# is rendered there; the drafted site plan (draft_zones, render_site_plan_ked)
# was rejected (an assessment is not a design; too busy to read; site-specific
# drafting will not scale to production). The plan code is kept as a record
# and is not called by the build. This is the one section where interpretation belongs: the
# practitioner's reading of the site, drawn in the site-analysis idiom of
# the mood board (docs/reference/Graphic Mood Board.png: sun arcs, wind
# arrows, zones with a label each).
#
#   1. sun path  - plan view over the lot: the sun's daily arc on the summer
#                  solstice, the equinox and the winter solstice, drawn as a
#                  polar diagram around the house (angle = azimuth, distance =
#                  how low the sun is), with sunrise and sunset points and the
#                  day length. Pure geometry from the latitude; the same for
#                  every parcel at this latitude and still the thing most
#                  people have never seen drawn.
#   2. site plan - the section 02 base with the practitioner's zones drawn
#                  over it as SCHEMATIC polygons drafted from their notes
#                  (front, back, corners, strips relative to the house and the
#                  street), not surveyed lines, plus the prevailing winds. The
#                  notes come from a gitignored file, never from this repo.
#
# Caller must source R/illustrate/parcel_topography.R and
# R/illustrate/parcel_microclimate.R (sun_position) first.

# ---- 1. sun path ------------------------------------------------------------

#' Sunrise/sunset hour angle -> solar hours of daylight
day_length_h <- function(lat_deg, day_of_year) {
  lat <- lat_deg * pi / 180; dec <- solar_declination_deg(day_of_year) * pi / 180
  2 * acos(pmin(1, pmax(-1, -tan(lat) * tan(dec)))) * 180 / pi / 15
}

fmt_solar_time <- function(h) {
  hh <- floor(h); mm <- round((h - hh) * 60); hh <- hh + (mm == 60); mm[mm == 60] <- 0
  sprintf("%d:%02d %s", ifelse(hh > 12, hh - 12, hh), mm, ifelse(hh >= 12, "pm", "am"))
}

sun_path_data <- function(lat_deg, r_max) {
  days <- data.frame(key = c("summer", "equinox", "winter"), doy = c(172, 80, 355),
                     label = c("Summer solstice, Jun 21", "Equinox, Mar 20 and Sep 22", "Winter solstice, Dec 21"),
                     color = c(KED$gold[5], KED$gold[4], KED$ember[4]), stringsAsFactors = FALSE)
  paths <- do.call(rbind, lapply(seq_len(nrow(days)), function(i) {
    dl <- day_length_h(lat_deg, days$doy[i])
    h <- seq(12 - dl / 2, 12 + dl / 2, length.out = 121)
    p <- sun_position(lat_deg, days$doy[i], h)
    p$key <- days$key[i]; p$r <- r_max * (1 - p$altitude / 90)   # low sun = far out
    p$x <- p$r * sin(p$azimuth * pi / 180); p$y <- p$r * cos(p$azimuth * pi / 180)
    p
  }))
  days$day_length_h <- vapply(days$doy, function(d) day_length_h(lat_deg, d), numeric(1))
  days$noon_alt <- vapply(days$doy, function(d) sun_position(lat_deg, d, 12)$altitude, numeric(1))
  days$rise_az <- vapply(days$doy, function(d) sun_position(lat_deg, d, 12 - day_length_h(lat_deg, d) / 2)$azimuth, numeric(1))
  days$rise <- fmt_solar_time(12 - days$day_length_h / 2); days$set <- fmt_solar_time(12 + days$day_length_h / 2)
  list(days = days, paths = paths)
}

render_sun_path_ked <- function(topo, lat_deg, frame_buffer_ft = 60) {
  parcel <- topo$parcel; own <- topo$own
  cen <- st_coordinates(st_centroid(st_geometry(if (nrow(own) > 0) own else parcel)))
  frame <- st_bbox(st_buffer(parcel, frame_buffer_ft))
  r_max <- min(frame["xmax"] - frame["xmin"], frame["ymax"] - frame["ymin"]) * 0.47
  sp <- sun_path_data(lat_deg, r_max)
  paths <- sp$paths; paths$x <- paths$x + cen[1]; paths$y <- paths$y + cen[2]
  days <- sp$days
  paths$color <- days$color[match(paths$key, days$key)]
  ends <- do.call(rbind, lapply(days$key, function(k) {
    p <- paths[paths$key == k, ]; rbind(p[1, ], p[nrow(p), ])
  }))
  ends$which <- rep(c("rises", "sets"), nrow(days))
  ends$label <- sprintf("%s %s", ends$which, ifelse(ends$which == "rises", days$rise[match(ends$key, days$key)], days$set[match(ends$key, days$key)]))
  noon <- paths[abs(paths$hour - 12) < 1e-6 | paths$hour == 12, ]
  noon <- do.call(rbind, lapply(days$key, function(k) { p <- paths[paths$key == k, ]; p[which.min(abs(p$hour - 12)), ] }))
  noon$label <- sprintf("%s\n%d\u00b0 high at noon, %.1f h of daylight", days$label, round(days$noon_alt), days$day_length_h)
  hours <- paths[abs(paths$hour - round(paths$hour)) < 0.03 & paths$hour %in% c(6, 9, 15, 18), ]
  # Compass ring and rays
  ring <- data.frame(t = seq(0, 2 * pi, length.out = 181)); ring$x <- cen[1] + r_max * 1.02 * sin(ring$t); ring$y <- cen[2] + r_max * 1.02 * cos(ring$t)
  comp <- data.frame(dir = c("N", "E", "S", "W"), az = c(0, 90, 180, 270))
  comp$x <- cen[1] + r_max * 1.15 * sin(comp$az * pi / 180); comp$y <- cen[2] + r_max * 1.14 * cos(comp$az * pi / 180)
  ends$color <- days$color[match(ends$key, days$key)]; noon$color <- days$color[match(noon$key, days$key)]
  ggplot() +
    geom_sf(data = parcel, fill = KED$ochre[1], color = KED$ink, linewidth = 0.5, linetype = "22") +
    layer_buildings(topo) +
    geom_path(data = ring, aes(x, y), color = KED$line, linewidth = 0.3) +
    geom_segment(data = comp, aes(x = cen[1], y = cen[2], xend = cen[1] + r_max * 1.02 * sin(az * pi / 180), yend = cen[2] + r_max * 1.02 * cos(az * pi / 180)),
                 color = KED$line_light, linewidth = 0.3) +
    geom_text(data = comp, aes(x, y, label = dir), family = KED_FONT, size = 3, color = KED$muted) +
    geom_path(data = paths, aes(x, y, group = key, color = color), linewidth = 1.1, lineend = "round") +
    geom_point(data = hours, aes(x, y, color = color), size = 1.3) +
    geom_point(data = ends, aes(x, y, color = color), size = 2.2) +
    geom_text_repel(data = ends, aes(x, y, label = label, color = color), family = KED_FONT, size = 2.4,
                    segment.color = KED$line, segment.size = 0.25, min.segment.length = 0.3, seed = 3, max.overlaps = Inf) +
    geom_label_repel(data = noon, aes(x, y, label = label, color = color), family = KED_FONT, size = 2.5, lineheight = 0.95,
                     fill = scales::alpha(KED$surface, 0.9), label.size = NA, nudge_y = c(-14, -14, -14), direction = "y",
                     segment.color = KED$line, segment.size = 0.25, seed = 5, max.overlaps = Inf) +
    scale_color_identity() +
    coord_sf(datum = NA, expand = FALSE, xlim = c(cen[1] - r_max * 1.22, cen[1] + r_max * 1.22),
             ylim = c(cen[2] - r_max * 1.2, cen[2] + r_max * 1.2)) +
    theme_ked_map()
}

# ---- 2. site plan -----------------------------------------------------------

# Axis-aligned slabs relative to the house, by which parcel edge faces the
# street. "front" is between the house and the street, "back" behind it,
# "side_l"/"side_r" the two flanks (left/right as seen from the street).
slab <- function(parcel, own, street_side, part, inset_ft = 0) {
  bb <- st_bbox(parcel); hb <- st_bbox(own); big <- 1e8   # State Plane feet run into the millions
  box <- function(xmin, xmax, ymin, ymax) st_sfc(st_polygon(list(rbind(c(xmin, ymin), c(xmax, ymin), c(xmax, ymax), c(xmin, ymax), c(xmin, ymin)))), crs = 2264)
  g <- switch(paste(street_side, part),
    "E front" = box(hb["xmax"], big, -big, big), "E back" = box(-big, hb["xmin"], -big, big),
    "E side_l" = box(-big, big, hb["ymax"], big), "E side_r" = box(-big, big, -big, hb["ymin"]),
    "W front" = box(-big, hb["xmin"], -big, big), "W back" = box(hb["xmax"], big, -big, big),
    "W side_l" = box(-big, big, -big, hb["ymin"]), "W side_r" = box(-big, big, hb["ymax"], big),
    "N front" = box(-big, big, hb["ymax"], big), "N back" = box(-big, big, -big, hb["ymin"]),
    "N side_l" = box(hb["xmax"], big, -big, big), "N side_r" = box(-big, hb["xmin"], -big, big),
    "S front" = box(-big, big, -big, hb["ymin"]), "S back" = box(-big, big, hb["ymax"], big),
    "S side_l" = box(-big, hb["xmin"], -big, big), "S side_r" = box(hb["xmax"], big, -big, big))
  suppressWarnings(st_intersection(st_geometry(parcel), g))
}

# A strip of depth_ft along one parcel edge ("street", "rear", or a compass side)
edge_strip <- function(parcel, edge, depth_ft) {
  bb <- st_bbox(parcel); big <- 1e8
  box <- function(xmin, xmax, ymin, ymax) st_sfc(st_polygon(list(rbind(c(xmin, ymin), c(xmax, ymin), c(xmax, ymax), c(xmin, ymax), c(xmin, ymin)))), crs = 2264)
  g <- switch(edge, E = box(bb["xmax"] - depth_ft, big, -big, big), W = box(-big, bb["xmin"] + depth_ft, -big, big),
              N = box(-big, big, bb["ymax"] - depth_ft, big), S = box(-big, big, -big, bb["ymin"] + depth_ft))
  suppressWarnings(st_intersection(st_geometry(parcel), g))
}

opposite <- function(side) c(E = "W", W = "E", N = "S", S = "N")[[side]]

#' Draft the practitioner's zones as schematic geometry.
#' @param notes list from the practitioner notes file, see build_site_report.R:
#'   $rain_garden_corner (e.g. "SW", a corner of the house the garden sits off),
#'   $canopy_overhang (list(edge = "W", share = 0.25)), $understory_depth_ft,
#'   $street_heat_depth_ft, $swales (character: "N", "S" sides), $connectivity_side ("N")
draft_zones <- function(topo, notes) {
  parcel <- topo$parcel; own <- topo$own; ss <- topo$street_side
  house_pad <- st_buffer(st_geometry(own), 6)
  z <- list()
  z$front <- st_difference(slab(parcel, own, ss, "front"), house_pad)
  z$back <- st_difference(slab(parcel, own, ss, "back"), house_pad)
  z$street_heat <- edge_strip(parcel, ss, notes$street_heat_depth_ft %||% 12)
  z$understory <- edge_strip(parcel, opposite(ss), notes$understory_depth_ft %||% 18)
  co <- notes$canopy_overhang
  if (!is.null(co)) {
    bb <- st_bbox(parcel); depth <- (if (co$edge %in% c("E", "W")) bb["xmax"] - bb["xmin"] else bb["ymax"] - bb["ymin"]) * co$share
    z$canopy <- edge_strip(parcel, co$edge, as.numeric(depth))
  }
  # Rain garden: a disk off the named corner of the house, clipped to the lot
  hb <- st_bbox(own); corner <- notes$rain_garden_corner %||% "SW"
  cx <- if (grepl("E", corner)) hb["xmax"] else hb["xmin"]; cy <- if (grepl("N", corner)) hb["ymax"] else hb["ymin"]
  dx <- if (grepl("E", corner)) 1 else -1; dy <- if (grepl("N", corner)) 1 else -1
  r <- notes$rain_garden_radius_ft %||% 11
  rg <- st_buffer(st_sfc(st_point(c(cx + dx * (r + 2), cy + dy * (r + 2))), crs = 2264), r)
  z$rain_garden <- suppressWarnings(st_intersection(st_difference(rg, house_pad), st_geometry(parcel)))
  # Swales: from the rear line along each named side, wrapping to the rain garden
  rgc <- st_coordinates(st_centroid(z$rain_garden))
  z$swales <- do.call(c, lapply(notes$swales %||% c("N", "S"), function(side) {
    bb <- st_bbox(parcel); inset <- 7
    y <- if (side == "N") bb["ymax"] - inset else bb["ymin"] + inset
    x_rear <- if (ss == "E") bb["xmin"] + inset else bb["xmax"] - inset
    x_house <- if (ss == "E") hb["xmin"] - 8 else hb["xmax"] + 8
    st_sfc(st_linestring(rbind(c(x_rear, y), c(x_house, y), c(rgc[1], rgc[2]))), crs = 2264)
  }))
  z
}

zone_style <- data.frame(
  key = c("front", "back", "canopy", "understory", "street_heat", "rain_garden"),
  fill = c(KED$gold[2], KED$gold[1], KED$canopy[3], KED$understory[3], KED$ember[2], KED$water[3]),
  alpha = c(0.55, 0.35, 0.45, 0.6, 0.7, 0.85), stringsAsFactors = FALSE)

render_site_plan_ked <- function(topo, zones, labels, winds = NULL, frame_buffer_ft = 22) {
  parcel <- topo$parcel; frame <- st_bbox(st_buffer(parcel, frame_buffer_ft))
  p <- ggplot() + geom_sf(data = parcel, fill = KED$ochre[1], color = NA) +
    geom_sf(data = topo$contours[topo$contours$is_index, ], color = KED$ochre[3], linewidth = 0.3, alpha = 0.7)
  for (k in c("front", "back", "canopy", "understory", "street_heat", "rain_garden")) {
    g <- zones[[k]]; if (is.null(g) || length(g) == 0) next
    st <- zone_style[zone_style$key == k, ]
    p <- p + geom_sf(data = st_sf(geometry = g), fill = scales::alpha(st$fill, st$alpha), color = NA)
  }
  if (!is.null(zones$swales)) {
    p <- p + geom_sf(data = st_sf(geometry = zones$swales), color = KED$water[5], linewidth = 1, linetype = "42", lineend = "round",
                     arrow = arrow(length = unit(0.18, "cm"), angle = 22, type = "closed"))
  }
  p <- p + layer_buildings(topo) + layer_parcel(topo) + layer_street_label(topo)
  if (!is.null(winds) && nrow(winds) > 0) {
    cen <- st_coordinates(st_centroid(st_geometry(parcel)))
    ang <- c(N = 0, NE = 45, E = 90, SE = 135, S = 180, SW = 225, W = 270, NW = 315)[winds$dir] * pi / 180
    r_out <- min(frame["xmax"] - frame["xmin"], frame["ymax"] - frame["ymin"]) * 0.49
    winds$x0 <- cen[1] + r_out * sin(ang); winds$y0 <- cen[2] + r_out * cos(ang)
    winds$x1 <- cen[1] + (r_out - 26) * sin(ang); winds$y1 <- cen[2] + (r_out - 26) * cos(ang)
    p <- p + geom_segment(data = winds, aes(x = x0, y = y0, xend = x1, yend = y1, color = color),
                          arrow = arrow(length = unit(0.22, "cm"), angle = 22, type = "closed"), linewidth = 1.1, lineend = "round") +
      geom_label(data = winds, aes(x = x0, y = y0, label = label, color = color), family = KED_FONT, size = 2.4, lineheight = 0.95,
                 fill = scales::alpha(KED$surface, 0.9), label.size = NA, hjust = ifelse(sin(ang) > 0.3, 1, ifelse(sin(ang) < -0.3, 0, 0.5)),
                 vjust = ifelse(cos(ang) > 0.3, 1, ifelse(cos(ang) < -0.3, 0, 0.5))) +
      scale_color_identity()
  }
  # Zone labels in boxes with leaders, from the zone centroids
  lab <- do.call(rbind, lapply(names(labels), function(k) {
    g <- zones[[k]]; if (is.null(g) || length(g) == 0) return(NULL)
    xy <- st_coordinates(suppressWarnings(st_point_on_surface(st_union(g))))
    data.frame(key = k, x = xy[1], y = xy[2], label = labels[[k]], stringsAsFactors = FALSE)
  }))
  p + geom_label_repel(data = lab, aes(x, y, label = label), family = KED_FONT, size = 2.5, color = KED$ink, lineheight = 0.95,
                       fill = scales::alpha(KED$surface, 0.92), label.size = NA, label.padding = unit(0.2, "lines"),
                       segment.color = KED$ink, segment.size = 0.3, min.segment.length = 0, box.padding = 0.6, point.padding = 0.4,
                       seed = 8, max.overlaps = Inf) +
    layer_scale_north() +
    coord_sf(datum = NA, expand = FALSE, xlim = frame[c("xmin", "xmax")], ylim = frame[c("ymin", "ymax")]) +
    theme_ked_map()
}
