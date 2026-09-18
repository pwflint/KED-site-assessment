library(ggplot2)
library(ggrepel)
library(cowplot)

# Section 04 (Climate and wind) illustrations, styled to the design system.
# Started 2026-09-18. Two graphics plus the numbers behind the four seasonal
# cards the report already draws in HTML:
#
#   1. climate chart - twelve months of PRISM 1991-2020 normals, precipitation
#                      as bars over an average high/low temperature band, the
#                      year running Nov -> Oct so each of the PRD's four seasons
#                      (Nov-Jan, Feb-Apr, May-Jul, Aug-Oct) is one contiguous
#                      block, tinted with its season family
#   2. wind roses    - one rose per season from the nearest NCEI airport
#                      station: how often the day's strongest wind came from
#                      each of eight directions, over ten complete years
#
# The seasonal color rotation (winter water, spring canopy, summer gold, fall
# ember) is the design system's own rule for this section; it is why these
# two graphics carry four families where the rest of the report holds to three.
#
# Caller must source R/acquisition/wind.R (season_of_month, seasonal_wind_rose,
# DIRECTIONS) and R/illustrate/parcel_topography.R (tokens, themes) first.

SEASON_ORDER <- c("winter", "spring", "summer", "fall")
SEASON_LABEL <- c(winter = "Winter", spring = "Spring", summer = "Summer", fall = "Fall")
SEASON_RANGE <- c(winter = "Nov \u2013 Jan", spring = "Feb \u2013 Apr", summer = "May \u2013 Jul", fall = "Aug \u2013 Oct")
COMPASS_WORD <- c(N = "north", NE = "northeast", E = "east", SE = "southeast",
                  S = "south", SW = "southwest", W = "west", NW = "northwest")

season_family <- function(season) {
  switch(season, winter = KED$water, spring = KED$canopy, summer = KED$gold, fall = KED$ember)
}

mm_to_in <- function(x) x / 25.4
c_to_f <- function(x) x * 9 / 5 + 32
ms_to_mph <- function(x) x * 2.23694

# ---- data preparation ------------------------------------------------------

#' @param normals get_seasonal_normals() result (ppt, tmax, tmin, tmean; mm and deg C)
#' @param wind get_wind_data() result (station, daily, seasonal_rose)
prep_climate <- function(normals, wind) {
  m <- data.frame(month = 1:12, abb = month.abb, stringsAsFactors = FALSE)
  m$ppt_in <- mm_to_in(normals$ppt$monthly)
  m$tmax_f <- c_to_f(normals$tmax$monthly)
  m$tmin_f <- c_to_f(normals$tmin$monthly)
  m$tmean_f <- c_to_f(normals$tmean$monthly)
  m$season <- season_of_month(m$month)
  m <- m[match(c(11, 12, 1:10), m$month), ]   # Nov -> Oct: seasons are contiguous
  m$pos <- seq_len(12)

  daily <- wind$daily
  rose <- wind$seasonal_rose
  rose$mean_speed_mph <- ms_to_mph(rose$mean_speed_ms)
  sp <- aggregate(AWND ~ season, daily, mean)
  season_speed_mph <- setNames(ms_to_mph(sp$AWND), sp$season)
  # Prevailing direction over the whole record, not per season
  all_dir <- compass_bin(daily$WDF2[!is.na(daily$WDF2)])
  prevailing <- names(which.max(table(all_dir)))

  list(months = m, rose = rose, season_speed_mph = season_speed_mph, prevailing = prevailing,
       station = wind$station, years = range(as.integer(substr(daily$DATE, 1, 4))),
       n_days = sum(!is.na(daily$WDF2)))
}

# ---- 1. climate chart ------------------------------------------------------

season_bands <- function() {
  b <- data.frame(season = SEASON_ORDER, xmin = c(0.5, 3.5, 6.5, 9.5), xmax = c(3.5, 6.5, 9.5, 12.5),
                  stringsAsFactors = FALSE)
  # 02 step at low alpha: the 01 steps are near-neutral and read as grey
  # slabs on the dark surface; text on the surface is theme-swapped muted
  b$fill <- vapply(b$season, function(s) season_family(s)[2], character(1))
  b$text <- KED$muted
  b$label <- paste0(SEASON_LABEL[b$season], "\n", SEASON_RANGE[b$season])
  b$mid <- (b$xmin + b$xmax) / 2
  b
}

theme_climate_panel <- function() {
  theme_ked_chart() +
    theme(panel.grid.major.x = element_blank(),
          axis.text.x = element_text(color = KED$ink, size = 8),
          plot.title = element_text(family = KED_FONT, size = 9, color = KED$ink, face = "plain",
                                    margin = margin(0, 0, 4, 0)),
          plot.margin = margin(4, 44, 2, 4))
}

render_climate_chart_ked <- function(cl) {
  m <- cl$months
  bands <- season_bands()
  wet <- m[which.max(m$ppt_in), ]; dry <- m[which.min(m$ppt_in), ]
  top_p <- max(m$ppt_in) * 1.45

  p1 <- ggplot(m) +
    geom_rect(data = bands, aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf, fill = fill), alpha = 0.3) +
    geom_col(aes(pos, ppt_in), fill = KED$water[3], width = 0.68) +
    geom_text(data = m[!m$pos %in% c(wet$pos, dry$pos), ], aes(pos, ppt_in, label = sprintf("%.1f", ppt_in)),
              vjust = -0.6, size = 2.4, color = KED$muted, family = KED_FONT) +
    geom_text(data = bands, aes(mid, top_p, label = label, color = text), size = 2.6, family = KED_FONT,
              vjust = 1, lineheight = 0.95) +
    # Wettest and driest months: label on a row above the bars, leader down
    # to the bar so the label never sits on a neighbor's bar
    geom_segment(data = rbind(wet, dry), aes(x = pos, xend = pos, y = ppt_in + top_p * 0.03, yend = top_p * 0.8),
                 color = KED$water[5], linewidth = 0.3) +
    geom_text(data = rbind(wet, dry), aes(pos, top_p * 0.81, label = c(sprintf("wettest month, %.1f in", wet$ppt_in),
                                                                       sprintf("driest month, %.1f in", dry$ppt_in))),
              family = KED_FONT, size = 2.6, color = KED$ink, vjust = 0, lineheight = 0.95) +
    scale_x_continuous(breaks = 1:12, labels = m$abb, expand = c(0, 0)) +
    scale_y_continuous(labels = function(v) paste0(v, " in"), limits = c(0, top_p), expand = c(0, 0),
                       breaks = pretty(c(0, max(m$ppt_in)), 4)) +
    scale_fill_identity() + scale_color_identity() +
    labs(x = NULL, y = NULL, title = "Precipitation, average per month") +
    theme_climate_panel()

  hot <- m[which.max(m$tmax_f), ]; cold <- m[which.min(m$tmin_f), ]
  lo <- min(m$tmin_f, 32) - 8; hi <- max(m$tmax_f) + 10
  ends <- data.frame(y = c(m$tmax_f[12], m$tmean_f[12], m$tmin_f[12]),
                     label = c("avg high", "avg", "avg low"), color = KED$muted)
  p2 <- ggplot(m) +
    geom_rect(data = bands, aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf, fill = fill), alpha = 0.3) +
    geom_ribbon(aes(pos, ymin = tmin_f, ymax = tmax_f), fill = KED$gold[3], alpha = 0.55) +
    geom_line(aes(pos, tmax_f), color = KED$gold[5], linewidth = 0.6) +
    geom_line(aes(pos, tmin_f), color = KED$gold[5], linewidth = 0.6) +
    geom_line(aes(pos, tmean_f), color = KED$gold[6], linewidth = 0.45, linetype = "22") +
    geom_hline(yintercept = 32, color = KED$water[5], linewidth = 0.4, linetype = "42") +
    annotate("text", x = 12.35, y = 32, label = "freezing, 32\u00b0F", hjust = 1, vjust = -0.5, size = 2.4,
             color = KED$muted, family = KED_FONT) +
    geom_point(data = rbind(hot, cold), aes(pos, c(hot$tmax_f, cold$tmin_f)), color = KED$accent, size = 1.6) +
    annotate("text", x = hot$pos, y = hot$tmax_f, label = sprintf("%s high, %.0f\u00b0F", hot$abb, hot$tmax_f),
             vjust = -0.9, size = 2.6, color = KED$accent, family = KED_FONT) +
    annotate("text", x = cold$pos, y = cold$tmin_f, label = sprintf("%s low, %.0f\u00b0F", cold$abb, cold$tmin_f),
             vjust = 1.9, size = 2.6, color = KED$accent, family = KED_FONT) +
    geom_text(data = ends, aes(x = 12.6, y = y, label = label, color = color), hjust = 0, size = 2.4,
              family = KED_FONT) +
    scale_x_continuous(breaks = 1:12, labels = m$abb, expand = c(0, 0)) +
    scale_y_continuous(labels = function(v) paste0(v, "\u00b0F"), limits = c(lo, hi), expand = c(0, 0),
                       breaks = pretty(c(lo, hi), 4)) +
    scale_fill_identity() + scale_color_identity() +
    coord_cartesian(clip = "off") +
    labs(x = NULL, y = NULL, title = "Temperature, average daily high and low") +
    theme_climate_panel()

  # cowplot, not patchwork: patchwork 1.1 breaks against ggplot2 3.5's guide layout
  plot_grid(p1, p2, ncol = 1, align = "v", axis = "lr")
}

# ---- 2. seasonal wind roses ------------------------------------------------

render_wind_rose_ked <- function(cl) {
  r <- cl$rose
  r$dir <- factor(r$dir, levels = DIRECTIONS)
  r$fill <- vapply(r$season, function(s) season_family(s)[4], character(1))
  r$text <- vapply(r$season, function(s) season_family(s)[7], character(1))
  top <- do.call(rbind, lapply(SEASON_ORDER, function(s) { d <- r[r$season == s, ]; d[which.max(d$freq_pct), ] }))
  strip <- sprintf("%s  %s\nfrom the %s on %d%% of days, %.0f mph average",
                   SEASON_LABEL[top$season], SEASON_RANGE[top$season], COMPASS_WORD[as.character(top$dir)],
                   round(top$freq_pct), cl$season_speed_mph[top$season])
  names(strip) <- top$season
  r$season <- factor(r$season, levels = SEASON_ORDER)
  ymax <- max(r$freq_pct)
  rings <- data.frame(y = c(20, 40)); rings <- rings[rings$y < ymax * 1.05, , drop = FALSE]
  dir_labels <- expand.grid(dir = factor(DIRECTIONS, levels = DIRECTIONS), season = factor(SEASON_ORDER, levels = SEASON_ORDER))
  dir_labels$y <- ymax * 1.24
  ggplot(r, aes(dir, freq_pct)) +
    geom_hline(data = rings, aes(yintercept = y), color = KED$line_light, linewidth = 0.3) +
    geom_col(aes(fill = fill), width = 0.85, color = NA) +
    geom_text(data = rings, aes(x = 0.5, y = y, label = paste0(y, "%")), family = KED_FONT,
              size = 2, color = KED$caption, vjust = -0.3, inherit.aes = FALSE) +
    geom_text(data = dir_labels, aes(dir, y, label = dir), family = KED_FONT, size = 2.8, color = KED$ink) +
    geom_text(data = r[r$freq_pct >= 10, ], aes(y = freq_pct * 0.55, label = paste0(round(freq_pct), "%"), color = text),
              family = KED_FONT, size = 2.3) +
    scale_fill_identity() + scale_color_identity() +
    coord_polar(start = -pi / 8) +
    scale_y_continuous(limits = c(0, ymax * 1.36)) +
    facet_wrap(~season, ncol = 2, labeller = labeller(season = strip)) +
    theme_ked_map() +
    theme(strip.text = element_text(family = KED_FONT, size = 8, color = KED$ink, hjust = 0, lineheight = 1.05,
                                    margin = margin(2, 0, 2, 4)),
          panel.spacing = unit(0.6, "lines"), plot.margin = margin(2, 2, 2, 2))
}

# ---- statistics for the report ---------------------------------------------

climate_stats <- function(cl) {
  m <- cl$months
  by_season <- function(v) lapply(setNames(SEASON_ORDER, SEASON_ORDER), function(s) round(mean(v[m$season == s]), 1))
  hot <- m[which.max(m$tmax_f), ]; cold <- m[which.min(m$tmin_f), ]
  wet <- m[which.max(m$ppt_in), ]; dry <- m[which.min(m$ppt_in), ]
  list(
    annual_precip_in = round(sum(m$ppt_in), 1),
    seasonal_precip = by_season(m$ppt_in),
    seasonal_temp = setNames(lapply(by_season(m$tmean_f), round), paste0(SEASON_ORDER, "_avg")),
    seasonal_temp_high = setNames(lapply(by_season(m$tmax_f), round), paste0(SEASON_ORDER, "_high")),
    seasonal_temp_low = setNames(lapply(by_season(m$tmin_f), round), paste0(SEASON_ORDER, "_low")),
    warmest_month = hot$abb, warmest_month_high_f = round(hot$tmax_f),
    coldest_month = cold$abb, coldest_month_low_f = round(cold$tmin_f),
    wettest_month = wet$abb, wettest_month_in = round(wet$ppt_in, 1),
    driest_month = dry$abb, driest_month_in = round(dry$ppt_in, 1),
    months_avg_low_below_freezing = sum(m$tmin_f < 32),
    prevailing_wind = unname(COMPASS_WORD[cl$prevailing]),
    wind_station_name = sub(" Ap$", " Airport", tools::toTitleCase(tolower(cl$station$name))),
    wind_station_id = cl$station$id,
    wind_years = paste(cl$years, collapse = "\u2013"),
    wind_days = cl$n_days
  )
}
