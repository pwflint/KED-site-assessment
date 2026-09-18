library(sf)
library(ggplot2)
library(ggrepel)

# Section 05 (Soils and infiltration) illustrations, styled to the design
# system. Started 2026-09-18. Two graphics, zoom out then zoom in:
#
#   1. soil map      - SSURGO map units across the section 03 neighborhood
#                      frame, each tinted by its dominant drainage class on
#                      the design system's understory -> ember gradient,
#                      labeled with its map unit symbol, over the same quiet
#                      road/building base as section 03, the parcel marked
#   2. soil profiles - the named soils of the parcel's own map unit drawn
#                      side by side as horizon columns to 60 in, column width
#                      proportional to each soil's share of the map unit,
#                      horizon fill by clay content, human-transported fill
#                      horizons (SSURGO's "^" prefix) bracketed
# plus soils_stats() for the stat row, the component table and the map legend.
#
# What SSURGO can and cannot say at parcel scale, stated plainly: a map unit
# is the smallest area the survey delineates (1:24,000 in Wake County). A
# "complex" names two or more soils that occur together in a pattern too
# fine to map separately; their percentages describe the whole unit, not
# this lot. Nothing here locates a component within the parcel.
#
# Caller must source R/acquisition/soil.R and R/illustrate/parcel_topography.R
# (tokens, themes, layer_scale_north) first.

cm_to_in <- function(x) x / 2.54
umps_to_inhr <- function(x) x * 0.141732   # micrometers per second -> inches per hour

# Design system drainage gradient (docs/DESIGN_SYSTEM.md): well drained
# understory-03, moderately well canopy-02, somewhat poor gold-03, poorly
# drained ember-03. Excessively drained shares the well-drained step.
drainage_fill <- function(cls) {
  d <- tolower(ifelse(is.na(cls), "", cls))
  ifelse(grepl("moderately well", d), KED$canopy[2],
  ifelse(grepl("somewhat poor", d), KED$gold[3],
  ifelse(grepl("poor", d), KED$ember[3],
  ifelse(grepl("well|excessive", d), KED$understory[3], KED$material[2]))))
}

# ---- data preparation ------------------------------------------------------

#' @param parcel_sf parcel polygon (any CRS)
#' @param polys get_soil_polygons() over the display frame, EPSG:4326
#' @param ag get_mapunit_aggregates() for every mukey in polys
#' @param comps get_mapunit_components() for every mukey in polys
#' @param hz get_component_horizons() for the parcel's own components
#' @param roads the section 03 road layer (any CRS); buildings are not drawn
#' @param hydro reach linework (FTYPE), EPSG:2264; the floodplain soils follow it
#' @param buffer_ft frame radius, 2,500 ft to match section 03 (same caveat:
#'   chosen for one parcel, not a validated standard)
#' @param label_min_acres units smaller than this in the frame get no label
prep_soils <- function(parcel_sf, polys, ag, comps, hz, roads, hydro = NULL,
                       buffer_ft = 2500, label_min_acres = 1.5) {
  parcel <- st_transform(parcel_sf, 2264)
  frame <- st_as_sfc(st_bbox(st_buffer(parcel, buffer_ft)), crs = 2264)
  clip <- function(x) suppressWarnings(st_intersection(st_transform(x, 2264), frame))

  units <- clip(polys)
  units <- st_collection_extract(units, "POLYGON")
  units$musym <- ag$musym[match(units$mukey, ag$mukey)]
  units$muname <- ag$muname[match(units$mukey, ag$mukey)]
  units$drclassdcd <- ag$drclassdcd[match(units$mukey, ag$mukey)]
  units$fill <- drainage_fill(units$drclassdcd)
  units$acres <- as.numeric(st_area(units)) / 43560
  # One label per map unit, on its largest piece in the frame
  lab <- do.call(rbind, lapply(split(units, units$mukey), function(u) {
    u <- u[which.max(u$acres), ]
    if (u$acres < label_min_acres) return(NULL)
    xy <- st_coordinates(suppressWarnings(st_point_on_surface(st_geometry(u))))
    data.frame(musym = u$musym, x = xy[1], y = xy[2], stringsAsFactors = FALSE)
  }))

  # The parcel's own map unit(s) and their share of the parcel
  own <- suppressWarnings(st_intersection(st_transform(polys, 2264), parcel))
  own$pct_of_parcel <- 100 * as.numeric(st_area(own)) / as.numeric(st_area(parcel))
  own <- aggregate(pct_of_parcel ~ mukey, st_drop_geometry(own), sum)
  own <- own[order(-own$pct_of_parcel), ]
  own_comps <- comps[comps$mukey %in% own$mukey, ]
  own_comps <- own_comps[order(match(own_comps$mukey, own$mukey), -own_comps$comppct_r), ]

  # Horizons in inches, with the surface horizon flagged and fill horizons marked
  hz$top_in <- cm_to_in(hz$hzdept_r); hz$bot_in <- cm_to_in(hz$hzdepb_r)
  hz$is_fill <- startsWith(hz$hzname, "^")
  hz$ksat_inhr <- umps_to_inhr(hz$ksat_r)
  hz$compname <- own_comps$compname[match(hz$cokey, own_comps$cokey)]

  roads <- clip(roads)
  roads$rank <- ifelse(roads$highway %in% c("motorway", "trunk", "primary", "secondary"), 1L,
                       ifelse(roads$highway == "tertiary", 2L, 3L))
  reaches <- NULL
  if (!is.null(hydro)) {
    reaches <- clip(hydro[hydro$FTYPE %in% c("STREAM/RIVER", "CANAL/DITCH"), ])
  }
  # A legend for the HTML: every unit in the frame, largest first
  in_frame <- aggregate(acres ~ mukey + musym + muname + drclassdcd, st_drop_geometry(units), sum)
  in_frame <- in_frame[order(-in_frame$acres), ]
  in_frame$on_parcel <- in_frame$mukey %in% own$mukey

  list(parcel = parcel, frame = frame, units = units, labels = lab, own = own, own_comps = own_comps,
       hz = hz, ag = ag, roads = roads, reaches = reaches, in_frame = in_frame)
}

# ---- 1. soil map -----------------------------------------------------------

render_soil_map_ked <- function(so) {
  bb <- st_bbox(so$frame)
  cen <- st_coordinates(st_centroid(st_geometry(so$parcel)))
  p <- ggplot() +
    geom_sf(data = so$units, aes(fill = fill), color = KED$ochre[5], linewidth = 0.35) +
    scale_fill_identity() +
    # Roads and reaches only: buildings barely showed through the fills and
    # cost ~540 KB of SVG per report (1,600 polygons at this extent)
    geom_sf(data = so$roads[so$roads$rank == 3, ], color = scales::alpha(KED$material[4], 0.6), linewidth = 0.3) +
    geom_sf(data = so$roads[so$roads$rank <= 2, ], color = KED$material[5], linewidth = 0.6)
  if (!is.null(so$reaches) && nrow(so$reaches) > 0) {
    p <- p + geom_sf(data = so$reaches, color = KED$water[4], linewidth = 0.8, lineend = "round")
  }
  p <- p +
    geom_sf(data = so$parcel, fill = KED$bloom_marker, color = KED$ink, linewidth = 0.5) +
    geom_label(data = so$labels, aes(x, y, label = musym), family = KED_FONT, size = 2.8,
               color = KED$ink, fill = scales::alpha(KED$surface, 0.85), label.size = NA,
               label.padding = unit(0.16, "lines")) +
    geom_label_repel(data = data.frame(x = cen[1], y = cen[2], label = "Your parcel"),
                     aes(x = x, y = y, label = label), family = KED_FONT, size = 3, color = KED$ink,
                     fill = scales::alpha(KED$surface, 0.92), label.size = NA, nudge_y = 260,
                     segment.color = KED$ink, segment.size = 0.35, min.segment.length = 0,
                     point.padding = 0.6, seed = 4) +
    layer_scale_north() +
    coord_sf(datum = NA, expand = FALSE, xlim = bb[c("xmin", "xmax")], ylim = bb[c("ymin", "ymax")]) +
    theme_ked_map()
  p
}

# ---- 2. soil profiles ------------------------------------------------------

#' @param max_depth_in profiles are drawn to this depth (SSURGO describes to
#'   200 cm; 60 in is the survey's usual control section and keeps the labels legible)
#' @param slow_ksat_umps horizons with saturated hydraulic conductivity below
#'   this are marked as slow; 1 um/s is the NRCS "moderately low / low" boundary
render_soil_profile_ked <- function(so, max_depth_in = 60, slow_ksat_umps = 1, gap = 4) {
  mu <- so$own[1, ]                                    # the dominant map unit on the parcel
  comps <- so$own_comps[so$own_comps$mukey == mu$mukey, ]
  comps <- comps[order(-comps$comppct_r), ]
  # Columns: width = share of the map unit, in the order SSURGO lists them
  comps$w <- comps$comppct_r
  comps$x0 <- c(0, head(cumsum(comps$w + gap), -1))
  comps$x1 <- comps$x0 + comps$w
  comps$xm <- (comps$x0 + comps$x1) / 2
  hz <- so$hz[so$hz$cokey %in% comps$cokey, ]
  hz <- hz[hz$top_in < max_depth_in, ]
  hz$bot_in <- pmin(hz$bot_in, max_depth_in)
  hz$x0 <- comps$x0[match(hz$cokey, comps$cokey)]
  hz$x1 <- comps$x1[match(hz$cokey, comps$cokey)]
  hz$xm <- (hz$x0 + hz$x1) / 2
  hz$ym <- (hz$top_in + hz$bot_in) / 2
  hz$h <- hz$bot_in - hz$top_in
  # Fill by clay content: ochre-02 (sandy) to ochre-05 (clay)
  clay_scale <- scales::col_numeric(c(KED$ochre[2], KED$ochre[3], KED$ochre[4], KED$ochre[5]), domain = c(0, 60))
  hz$fill <- clay_scale(pmin(hz$claytotal_r, 60))
  # "^" (human-transported material) is dropped from the label; the fill
  # bracket beside the column says the same thing in words
  short <- sub("^\\^", "", hz$hzname)
  hz$label <- ifelse(is.na(hz$texdesc), short, paste0(short, "  ", tolower(hz$texdesc)))
  hz$label_in <- hz$h >= 4 & (hz$x1 - hz$x0) >= 14
  hz$label_color <- ifelse(hz$claytotal_r >= 30, KED$ochre[1], KED$ochre[7])

  # Components with no horizons (Urban land) become a plain block
  no_hz <- comps[!comps$cokey %in% hz$cokey, ]
  # Fill brackets: the contiguous run of "^" horizons at the top of each column
  fill_runs <- do.call(rbind, lapply(split(hz, hz$cokey), function(h) {
    f <- h[h$is_fill, ]
    if (nrow(f) == 0) return(NULL)
    data.frame(x = h$x1[1] + 1.2, top = min(f$top_in), bot = max(f$bot_in))
  }))
  # First slow horizon per column
  slow <- do.call(rbind, lapply(split(hz, hz$cokey), function(h) {
    s <- h[!is.na(h$ksat_r) & h$ksat_r < slow_ksat_umps, ]
    if (nrow(s) == 0) return(NULL)
    data.frame(x0 = h$x0[1], x1 = h$x1[1], y = min(s$top_in))
  }))
  heads <- comps
  heads$title <- sprintf("%s, %d%%", heads$compname, round(heads$comppct_r))
  heads$sub <- ifelse(is.na(heads$drainagecl), "paved or built", tolower(heads$drainagecl))
  width_total <- max(comps$x1)

  p <- ggplot() +
    geom_rect(data = hz, aes(xmin = x0, xmax = x1, ymin = top_in, ymax = bot_in, fill = fill),
              color = KED$surface, linewidth = 0.4) +
    scale_fill_identity()
  if (nrow(no_hz) > 0) {
    p <- p + geom_rect(data = no_hz, aes(xmin = x0, xmax = x1, ymin = 0, ymax = max_depth_in),
                       fill = KED$material[2], color = KED$surface, linewidth = 0.4) +
      geom_text(data = no_hz, aes(xm, max_depth_in * 0.5, label = "not mapped\nas soil"), family = KED_FONT,
                size = 2.5, color = KED$material[6], lineheight = 0.95)
  }
  if (any(hz$label_in)) {
    p <- p + geom_text(data = hz[hz$label_in, ], aes(xm, ym, label = label, color = label_color), family = KED_FONT,
                       size = 2.3, lineheight = 0.9) + scale_color_identity()
  }
  if (!is.null(fill_runs)) {
    p <- p +
      geom_segment(data = fill_runs, aes(x = x, xend = x, y = top + 0.3, yend = bot - 0.3), color = KED$accent, linewidth = 0.5) +
      geom_text(data = fill_runs, aes(x = x + 1.2, y = (top + bot) / 2, label = "fill"), family = KED_FONT,
                size = 2.4, color = KED$accent, angle = -90)
  }
  if (!is.null(slow)) {
    p <- p +
      geom_segment(data = slow, aes(x = x0, xend = x1, y = y, yend = y), color = KED$water[5], linewidth = 0.7,
                   linetype = "22") +
      geom_label(data = slow, aes((x0 + x1) / 2, y, label = sprintf("water moves slowly below %.0f in", y)),
                 family = KED_FONT, size = 2.2, color = KED$ink, fill = scales::alpha(KED$surface, 0.9),
                 label.size = NA, label.padding = unit(0.12, "lines"), vjust = -0.35)
  }
  p +
    geom_text(data = heads, aes(xm, -3.5, label = title), family = KED_FONT, size = 2.9, color = KED$ink, vjust = 0) +
    geom_text(data = heads, aes(xm, -1, label = sub), family = KED_FONT, size = 2.4, color = KED$muted, vjust = 0) +
    scale_y_reverse(breaks = seq(0, max_depth_in, by = 12), labels = function(v) paste0(v, " in"),
                    expand = expansion(mult = c(0.14, 0.01))) +
    scale_x_continuous(expand = expansion(mult = c(0.01, 0.06))) +
    labs(x = NULL, y = NULL) +
    coord_cartesian(clip = "off") +
    theme_ked_chart() +
    theme(panel.grid.major.x = element_blank(), panel.grid.major.y = element_blank(),
          axis.text.x = element_blank(), plot.margin = margin(4, 6, 4, 4))
}

# ---- statistics for the report ---------------------------------------------

soils_stats <- function(so) {
  mu <- so$own[1, ]
  a <- so$ag[so$ag$mukey == mu$mukey, ]
  comps <- so$own_comps
  units <- lapply(seq_len(nrow(so$own)), function(i) {
    u <- so$own[i, ]; au <- so$ag[so$ag$mukey == u$mukey, ]
    cc <- comps[comps$mukey == u$mukey, ]
    components <- lapply(seq_len(nrow(cc)), function(j) {
      c1 <- cc[j, ]
      surface <- so$hz[so$hz$cokey == c1$cokey & so$hz$hzdept_r == 0, ]
      list(
        name = c1$compname,
        pct_of_unit = round(c1$comppct_r),
        major = identical(c1$majcompflag, "Yes"),
        drainage_class = if (is.na(c1$drainagecl)) NULL else c1$drainagecl,
        hydrologic_group = if (is.na(c1$hydgrp)) NULL else c1$hydgrp,
        surface_texture = if (nrow(surface) && !is.na(surface$texdesc[1])) surface$texdesc[1] else NULL,
        k_factor = if (nrow(surface) && !is.na(surface$kffact[1])) as.numeric(surface$kffact[1]) else NULL,
        surface_ksat_in_hr = if (nrow(surface) && !is.na(surface$ksat_inhr[1])) round(surface$ksat_inhr[1], 2) else NULL,
        slope_range_pct = if (is.na(c1$slope_l)) NULL else c(c1$slope_l, c1$slope_h),
        landform = if (is.na(c1$geomdesc)) NULL else c1$geomdesc,
        hydric = if (is.na(c1$hydricrating)) NULL else c1$hydricrating
      )
    })
    list(symbol = au$musym, name = au$muname, kind = au$mukind, pct_of_parcel = round(u$pct_of_parcel),
         drainage_class = au$drclassdcd, hydrologic_group = au$hydgrpdcd,
         flooding = au$flodfreqdcd, water_table_min_in = if (is.na(au$wtdepannmin)) NULL else round(cm_to_in(au$wtdepannmin)),
         bedrock_min_in = if (is.na(au$brockdepmin)) NULL else round(cm_to_in(au$brockdepmin)),
         available_water_in_top_40in = if (is.na(au$aws0100wta)) NULL else round(cm_to_in(au$aws0100wta), 1),
         components = components)
  })
  dom <- comps[comps$mukey == mu$mukey, ][1, ]
  list(
    soil_map_units = units,
    dominant_soil = dom$compname,
    dominant_soil_pct = round(dom$comppct_r),
    drainage_class = a$drclassdcd,
    hydrologic_group = a$hydgrpdcd,
    available_water_in_top_40in = if (is.na(a$aws0100wta)) NULL else round(cm_to_in(a$aws0100wta), 1),
    soil_map_legend = lapply(seq_len(nrow(so$in_frame)), function(i) {
      f <- so$in_frame[i, ]
      list(symbol = f$musym, name = f$muname, drainage_class = f$drclassdcd, acres = round(f$acres, 1),
           on_parcel = f$on_parcel)
    })
  )
}
