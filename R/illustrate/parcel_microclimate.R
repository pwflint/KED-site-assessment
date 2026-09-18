library(sf)
library(terra)
library(ggplot2)
library(ggrepel)

# Section 06 (Microclimate) illustrations, styled to the design system.
# Started 2026-09-19. Two graphics from the section 02 topography data plus
# the building footprints and their placeholder heights:
#
#   1. heat accumulation - relative direct solar load across open ground from
#                          DEM slope and aspect (McCune & Keon 2002 heat load
#                          index), gold (cool, north-facing) to ember (hot,
#                          southwest-facing), with the ground the buildings
#                          shade for two or more midday hours in summer laid
#                          over it in understory
#   2. seasonal shade     - hours of building shade through the middle of the
#                          day (9 to 3, solar time) on the winter and summer
#                          solstices, from plain sun geometry at the parcel's
#                          latitude and the footprint inventory's placeholder
#                          height, for the parcel's own building and the
#                          neighbors' (a neighbor's house shades this lot too)
#
# What is inferred, stated plainly: building height is the 30 ft placeholder
# from R/acquisition/building_footprint.R (the inventory does not carry
# height; a field measurement replaces it). Canopy is absent at this scale for
# the reason recorded in docs/ILLUSTRATION_NOTES.md (30 m NLCD pixels are
# bigger than the frame); tree shade is therefore NOT drawn, and the caption
# says so. The heat load index is a relative ranking of ground by the sun it
# faces, not a temperature.
#
# Caller must source R/illustrate/parcel_topography.R (tokens, themes,
# prep_parcel_topography, layers) first.

# ---- sun geometry ----------------------------------------------------------
# Solar declination and position from the standard approximations (Spencer
# 1971 declination; altitude/azimuth from the hour angle). Hour is local solar
# time, so 12 is solar noon; the equation of time and longitude offset are
# ignored, which shifts the sweep by up to ~20 minutes and changes nothing
# the graphic shows.

solar_declination_deg <- function(day_of_year) {
  g <- 2 * pi / 365 * (day_of_year - 1)
  (0.006918 - 0.399912 * cos(g) + 0.070257 * sin(g) - 0.006758 * cos(2 * g) +
     0.000907 * sin(2 * g) - 0.002697 * cos(3 * g) + 0.00148 * sin(3 * g)) * 180 / pi
}

#' Sun altitude and azimuth (degrees, azimuth clockwise from north) for a
#' latitude, day of year and local solar hour.
sun_position <- function(lat_deg, day_of_year, solar_hour) {
  lat <- lat_deg * pi / 180
  dec <- solar_declination_deg(day_of_year) * pi / 180
  h <- (solar_hour - 12) * 15 * pi / 180
  alt <- asin(sin(lat) * sin(dec) + cos(lat) * cos(dec) * cos(h))
  az <- atan2(sin(h), cos(h) * sin(lat) - tan(dec) * cos(lat))   # from south, west positive
  az <- (az * 180 / pi + 180) %% 360                              # clockwise from north
  data.frame(hour = solar_hour, altitude = alt * 180 / pi, azimuth = az)
}

#' Ground shadow of a set of footprints of height h at one sun position:
#' each footprint translated along the shadow direction by h / tan(altitude)
#' and hulled with itself (a flat-roofed prism's shadow is the convex hull of
#' the footprint and its translated copy, taken per ring so L-shapes hold).
shadow_polygons <- function(bldgs_2264, height_ft, altitude_deg, azimuth_deg) {
  if (altitude_deg <= 0 || nrow(bldgs_2264) == 0) return(NULL)
  len <- height_ft / tan(altitude_deg * pi / 180)
  # Shadow falls away from the sun: azimuth + 180
  dir <- (azimuth_deg + 180) * pi / 180
  dx <- len * sin(dir); dy <- len * cos(dir)
  g <- st_geometry(bldgs_2264)
  shadows <- lapply(seq_along(g), function(i) {
    polys <- st_cast(st_sfc(g[i], crs = 2264), "POLYGON")
    pieces <- lapply(seq_along(polys), function(j) {
      base <- polys[j]
      moved <- base + c(dx, dy)
      # Sweep: hull of each edge's parallelogram, unioned, so concave
      # footprints do not get filled in
      xy <- st_coordinates(base)[, 1:2]
      quads <- lapply(seq_len(nrow(xy) - 1), function(k) {
        st_polygon(list(rbind(xy[k, ], xy[k + 1, ], xy[k + 1, ] + c(dx, dy), xy[k, ] + c(dx, dy), xy[k, ])))
      })
      st_union(c(st_sfc(quads, crs = 2264), base, st_set_crs(moved, 2264)))
    })
    st_union(do.call(c, pieces))
  })
  st_union(do.call(c, shadows))
}

# ---- data preparation ------------------------------------------------------

#' @param topo prep_parcel_topography() result (dem, slope_pct, aspect_deg, own, neighbors, parcel, frame)
#' @param lat_deg parcel latitude
#' @param building_height_ft placeholder height applied to every footprint
#' @param hours local solar hours swept on each solstice, every half hour;
#'   9 to 15 is the middle of the day, when shade matters most for heat
prep_microclimate <- function(topo, lat_deg, building_height_ft = 30, hours = seq(9, 15, by = 0.5)) {
  parcel <- topo$parcel
  # Heat load index (McCune & Keon 2002, eq. 3): folded aspect so that
  # southwest (225 deg) is the hottest, northeast the coolest; slope in radians
  aspect_folded <- abs(180 - abs(topo$aspect_deg - 225)) * pi / 180
  slope_rad <- atan(topo$slope_pct / 100)
  lat <- lat_deg * pi / 180
  hli <- 0.339 + 0.808 * cos(lat) * cos(slope_rad) - 0.196 * sin(lat) * sin(slope_rad) -
    0.482 * cos(aspect_folded) * sin(slope_rad)
  # Flat ground has no aspect; its index is the flat-ground value
  flat <- topo$slope_pct < 1.5
  hli_flat <- 0.339 + 0.808 * cos(lat)
  hli[flat] <- hli_flat
  hli <- focal(hli, w = 5, fun = "mean", na.rm = TRUE)
  hli <- mask(crop(hli, vect(parcel)), vect(parcel))
  rel <- hli / hli_flat                                    # 1 = flat ground

  # Buildings: own + neighbors, one placeholder height
  bldgs <- rbind(topo$own[, c("PID")], topo$neighbors[, c("PID")])
  bldgs$height_ft <- building_height_ft
  bldg_union <- st_union(st_geometry(bldgs))
  open <- st_difference(st_geometry(parcel), bldg_union)
  open_area <- as.numeric(st_area(open))
  # Shade hours: count the half-hour steps each DEM cell sits in a shadow
  grid <- crop(topo$dem, vect(topo$frame))
  step_h <- if (length(hours) > 1) diff(hours)[1] else 1
  solstices <- c(winter = 355, summer = 172)
  shade <- lapply(names(solstices), function(s) {
    pos <- sun_position(lat_deg, solstices[[s]], hours)
    hrs <- grid * 0
    for (i in seq_len(nrow(pos))) {
      sh <- shadow_polygons(bldgs, building_height_ft, pos$altitude[i], pos$azimuth[i])
      if (is.null(sh)) next
      r <- rasterize(vect(st_sf(geometry = sh)), grid, field = 1, background = 0)
      hrs <- hrs + r * step_h
    }
    hrs <- mask(hrs, vect(open))
    v <- values(hrs); v <- v[!is.na(v)]
    list(season = s, sun = pos, hours = hrs,
         noon = pos[which.min(abs(pos$hour - 12)), ],
         full_sun_pct = round(mean(v == 0) * 100),
         shade_2h_pct = round(mean(v >= 2) * 100),
         shade_4h_pct = round(mean(v >= 4) * 100))
  })
  names(shade) <- names(solstices)

  list(parcel = parcel, frame = topo$frame, own = topo$own, neighbors = topo$neighbors,
       bldgs = bldgs, hli = hli, hli_rel = rel, hli_flat = hli_flat, shade = shade,
       lat_deg = lat_deg, building_height_ft = building_height_ft, hours = range(hours),
       street_side = topo$street_side,
       open_ground_sqft = round(open_area), building_sqft = round(as.numeric(st_area(st_geometry(topo$own)))))
}

# ---- 1. heat accumulation --------------------------------------------------

# Gold (cool, north-facing) -> ember (hot, southwest-facing), the design
# system's microclimate rule. Flat ground sits at gold-02; the scale is
# relative to flat ground and squished at +/- 25%.
heat_fill_scale <- function() {
  scale_fill_gradientn(colours = c(KED$gold[1], KED$gold[2], KED$ember[3], KED$ember[4]),
                       values = scales::rescale(c(0.8, 1.0, 1.12, 1.25)), limits = c(0.8, 1.25),
                       oob = scales::squish, na.value = NA)
}

shade_class_polys <- function(hours_raster, breaks = c(0, 1, 2, 4, Inf)) {
  cls <- classify(hours_raster, cbind(breaks[-length(breaks)], breaks[-1], seq_along(breaks[-1]) - 1))
  cls[cls == 0] <- NA
  p <- st_as_sf(as.polygons(cls, dissolve = TRUE))
  names(p)[1] <- "class"
  p
}

render_heat_map_ked <- function(mc, frame_buffer_ft = 20, shade_min_hours = 2) {
  parcel <- mc$parcel
  frame <- st_bbox(st_buffer(parcel, frame_buffer_ft))
  df <- as.data.frame(mc$hli_rel, xy = TRUE, na.rm = TRUE); names(df)[3] <- "rel"
  summer <- mc$shade$summer$hours >= shade_min_hours
  summer[summer == 0] <- NA
  shade_poly <- st_as_sf(as.polygons(summer, dissolve = TRUE))
  p <- ggplot() +
    geom_sf(data = parcel, fill = KED$gold[1], color = NA) +
    geom_raster(data = df, aes(x, y, fill = rel), interpolate = TRUE) +
    heat_fill_scale()
  if (nrow(shade_poly) > 0) {
    p <- p + geom_sf(data = shade_poly, fill = scales::alpha(KED$understory[3], 0.6), color = NA)
  }
  p + layer_buildings(list(own = mc$own, neighbors = mc$neighbors)) +
    layer_parcel(list(parcel = parcel)) +
    layer_street_label(list(parcel = parcel, street_side = mc$street_side)) +
    layer_scale_north() +
    coord_sf(datum = NA, expand = FALSE, xlim = frame[c("xmin", "xmax")], ylim = frame[c("ymin", "ymax")]) +
    theme_ked_map()
}

# ---- 2. seasonal shade -----------------------------------------------------

SHADE_CLASS_FILL <- c(KED$understory[1], KED$understory[2], KED$understory[3], KED$understory[5])

render_shade_pair_ked <- function(mc, frame_buffer_ft = 20) {
  parcel <- mc$parcel
  frame <- st_bbox(st_buffer(parcel, frame_buffer_ft))
  panels <- lapply(c("winter", "summer"), function(s) {
    sh <- mc$shade[[s]]
    cls <- shade_class_polys(sh$hours)
    cls$fill <- SHADE_CLASS_FILL[cls$class]
    title <- if (s == "winter") "Winter solstice, Dec 21" else "Summer solstice, Jun 21"
    sub <- sprintf("sun %d\u00b0 high at noon, %d ft shadow from a %d ft wall",
                   round(sh$noon$altitude), round(mc$building_height_ft / tan(sh$noon$altitude * pi / 180)),
                   mc$building_height_ft)
    ggplot() +
      geom_sf(data = parcel, fill = KED$gold[1], color = NA) +
      geom_sf(data = cls, aes(fill = fill), color = NA) +
      scale_fill_identity() +
      layer_buildings(list(own = mc$own, neighbors = mc$neighbors)) +
      layer_parcel(list(parcel = parcel)) +
      labs(title = title, subtitle = sub) +
      coord_sf(datum = NA, expand = FALSE, xlim = frame[c("xmin", "xmax")], ylim = frame[c("ymin", "ymax")]) +
      theme_ked_map() +
      theme(plot.title = element_text(family = KED_FONT, size = 9, color = KED$ink, hjust = 0),
            plot.subtitle = element_text(family = KED_FONT, size = 7.5, color = KED$muted, hjust = 0),
            plot.margin = margin(4, 6, 4, 6))
  })
  cowplot::plot_grid(panels[[1]], panels[[2]], ncol = 2, align = "hv")
}

# ---- statistics for the report ---------------------------------------------

microclimate_stats <- function(mc, topo) {
  rose <- aspect_rose_data(topo)
  south <- round(sum(rose$pct[rose$dir %in% c("SE", "S", "SW")]))
  hot <- values(mc$hli_rel); hot <- hot[!is.na(hot)]
  w <- mc$shade$winter; su <- mc$shade$summer
  list(
    building_footprint_sqft = mc$building_sqft,
    open_ground_sqft = mc$open_ground_sqft,
    south_facing_pct = south,
    warm_ground_pct = round(mean(hot > 1.05) * 100),      # heat load over 5% above flat ground
    cool_ground_pct = round(mean(hot < 0.95) * 100),
    building_height_ft_assumed = mc$building_height_ft,
    shade_hours_window = mc$hours,
    winter_noon_sun_deg = round(w$noon$altitude),
    winter_full_sun_pct = w$full_sun_pct,
    winter_shade_2h_pct = w$shade_2h_pct,
    winter_shade_4h_pct = w$shade_4h_pct,
    summer_noon_sun_deg = round(su$noon$altitude),
    summer_full_sun_pct = su$full_sun_pct,
    summer_shade_2h_pct = su$shade_2h_pct,
    summer_shade_4h_pct = su$shade_4h_pct
  )
}
