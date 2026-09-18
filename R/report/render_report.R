# Site assessment report renderer — the "Layout Design Agent" specified in
# docs/BUILD_AGENT_PROMPT.md, implemented as a reproducible script rather than a
# one-off generation so every report is built the same way.
#
# Input:  a per-parcel site data payload (JSON; field list and section rules in
#         docs/BUILD_AGENT_PROMPT.md). Missing/null fields are omitted, never invented.
# Output: output/{address_slug}_assessment.html — one self-contained file. The design
#         system CSS is inlined, fonts come from Google Fonts, and visualizations are
#         embedded inline (SVG text or base64 PNG).
#
# Design tokens and component classes come from R/report/assets/styles.css, vendored
# from the "KED Site Assessment" design-system project. Don't hand-edit values there;
# change them in the design project and re-sync.
#
# Usage (from the repo root):
#   source("R/report/render_report.R")
#   render_site_assessment("path/to/payload.json")              # returns the output path
#   render_site_assessment(payload_list, out_dir = "output")     # an already-parsed list works too

suppressPackageStartupMessages(library(jsonlite))

# Headless Rscript runs (no LANG set) fall into the C locale, where gsub() on the
# non-ASCII characters in this file (em dashes, degree sign) emits "<e2><80><94>"
# byte escapes instead of the character. Force a UTF-8 character type when needed.
if (!isTRUE(l10n_info()[["UTF-8"]])) suppressWarnings(Sys.setlocale("LC_CTYPE", "en_US.UTF-8"))

`%||%` <- function(a, b) if (is.null(a)) b else a

# ---- helpers ---------------------------------------------------------------

has <- function(x) {
  if (is.null(x) || length(x) == 0) return(FALSE)
  if (is.list(x)) return(TRUE)
  if (all(is.na(x))) return(FALSE)
  if (is.character(x)) return(any(nzchar(trimws(x))))
  TRUE
}

esc <- function(x) {
  x <- as.character(unlist(x))
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  gsub("\"", "&quot;", x, fixed = TRUE)
}

# Plain-text payload field -> one <p> per blank-line-separated paragraph.
# Text is escaped: payload prose is never treated as HTML.
paras <- function(text, class = NULL) {
  if (!has(text)) return("")
  chunks <- trimws(strsplit(paste(text, collapse = "\n"), "\n\\s*\n")[[1]])
  chunks <- chunks[nzchar(chunks)]
  attr <- if (is.null(class)) "" else sprintf(' class="%s"', class)
  paste0(sprintf("<p%s>%s</p>", attr, esc(chunks)), collapse = "\n")
}

fmt <- function(x, digits = 0, unit = "") {
  if (!has(x)) return(NULL)
  paste0(formatC(as.numeric(x), format = "f", digits = digits, big.mark = ","), unit)
}

fmt_date <- function(x) {
  if (!has(x)) return(NULL)
  d <- tryCatch(as.Date(x), error = function(e) NA)
  if (is.na(d)) return(as.character(x))
  gsub("  ", " ", format(d, "%B %e, %Y"))
}

address_slug <- function(address) {
  s <- tolower(iconv(address %||% "site", to = "ASCII//TRANSLIT", sub = ""))
  s <- gsub("[^a-z0-9]+", "-", s)
  s <- gsub("^-+|-+$", "", s)
  if (!nzchar(s)) "site" else s
}

# Visualizations arrive from the R pipeline as inline SVG text or a base64 PNG
# (with or without a data: prefix).
viz_media <- function(v) {
  v <- trimws(v)
  if (startsWith(v, "<svg") || startsWith(v, "<?xml")) {
    return(sprintf('<div class="viz-frame">%s</div>', v))
  }
  src <- if (startsWith(v, "data:")) v else paste0("data:image/png;base64,", v)
  sprintf('<img src="%s" alt="">', src)
}

placeholder <- function(family) {
  sprintf('<div class="viz-placeholder" style="background:var(--%s-01);color:var(--%s-05)">Data not available for this parcel</div>',
          family, family)
}

# A .viz-card. When media is missing: the section's primary graphic gets the
# design system's tinted placeholder; a secondary graphic is omitted entirely.
viz_card <- function(media, family, caption = NULL, required = TRUE, extra = "", title = NULL) {
  if (!has(media)) {
    if (!required) return("")
    body <- placeholder(family)
  } else {
    body <- viz_media(media)
  }
  head <- if (has(title)) sprintf("<h3>%s</h3>", esc(title)) else ""
  cap <- if (has(caption)) sprintf('<div class="viz-caption">%s</div>', caption) else ""
  sprintf('<div class="viz-card scroll-reveal">%s%s%s%s</div>', head, body, extra, cap)
}

# Label above value (Peter, 2026-09-18): the label names the concept, the
# value answers it, so "Ground drains toward / Southeast" reads in order.
stat <- function(value, label) {
  if (is.null(value)) return("")
  sprintf('<div class="stat"><div class="stat-label">%s</div><div class="stat-value">%s</div></div>',
          esc(label), esc(value))
}

stat_row <- function(...) {
  stats <- paste0(c(...), collapse = "")
  if (!nzchar(stats)) return("")
  sprintf('<div class="stat-row scroll-reveal">%s</div>', stats)
}

section <- function(id, eyebrow, title, ..., full_height = TRUE) {
  sprintf('<section id="%s" class="scroll-section%s">\n<div class="eyebrow">%s</div>\n<h2>%s</h2>\n%s\n</section>',
          id, if (full_height) "" else " scroll-section-short", esc(eyebrow), esc(title),
          paste(c(...), collapse = "\n"))
}

bullet_list <- function(items, heading) {
  if (!has(items)) return("")
  sprintf('<h3>%s</h3>\n<ul class="finding-list">%s</ul>', esc(heading),
          paste0("<li>", esc(items), "</li>", collapse = "\n"))
}

# Drainage-class gradient from the design system: understory (well) -> ember (poorly).
drainage_swatch <- function(drainage_class) {
  if (!has(drainage_class)) return("")
  d <- tolower(drainage_class)
  tok <- if (grepl("moderately well", d)) "canopy-02"
         else if (grepl("somewhat poor", d)) "gold-03"
         else if (grepl("poor", d)) "ember-03"
         else if (grepl("well|excessive", d)) "understory-03"
         else NA
  if (is.na(tok)) return(esc(drainage_class))
  sprintf('<span class="legend-item"><span class="legend-swatch" style="background:var(--%s)"></span>%s</span>',
          tok, esc(drainage_class))
}

drainage_legend <- '<div class="legend drainage-legend">
<div class="legend-item"><div class="legend-swatch" style="background:var(--understory-03)"></div>Well drained</div>
<div class="legend-item"><div class="legend-swatch" style="background:var(--canopy-02)"></div>Moderately well</div>
<div class="legend-item"><div class="legend-swatch" style="background:var(--gold-03)"></div>Somewhat poor</div>
<div class="legend-item"><div class="legend-swatch" style="background:var(--ember-03)"></div>Poorly drained</div>
</div>'

# ---- data-viz fragments ----------------------------------------------------

# Slope classes as a horizontal bar chart, ochre family (02 flat -> 05 steep).
# Labels on 02/03 use ochre-07; on the darker 04/05 fills ochre-01 stays in-family
# and readable (the family-07 step does not clear contrast on those two).
slope_chart <- function(dist, erosion_pct) {
  if (!has(dist)) return("")
  rows <- list(
    list(key = "flat_0_2",      label = "Flat (0–2%)",      fill = "ochre-02", text = "ochre-07"),
    list(key = "gentle_2_8",    label = "Gentle (2–8%)",    fill = "ochre-03", text = "ochre-07"),
    list(key = "moderate_8_15", label = "Moderate (8–15%)", fill = "ochre-04", text = "ochre-01"),
    list(key = "steep_15_plus", label = "Steep (15%+)",     fill = "ochre-05", text = "ochre-01"))
  bars <- vapply(rows, function(r) {
    v <- dist[[r$key]]
    if (!has(v)) return("")
    w <- max(0, min(100, as.numeric(v)))
    sprintf('<div class="bar-row"><div class="bar-label">%s</div><div class="bar" style="width:%s%%;background:var(--%s);color:var(--%s)">%s%%</div></div>',
            r$label, w, r$fill, r$text, fmt(v))
  }, character(1))
  if (!any(nzchar(bars))) return("")
  legend <- if (has(erosion_pct) && as.numeric(erosion_pct) > 0) {
    sprintf('<div class="legend chart-legend"><div class="legend-item"><div class="legend-swatch" style="background:var(--ember-04)"></div>Erosion risk zone (grade over 20%%): %s%% of parcel</div></div>',
            fmt(erosion_pct))
  } else ""
  paste0('<div class="viz-card scroll-reveal"><h3>Slope distribution</h3>',
         paste(bars, collapse = ""), legend,
         '<div class="viz-caption">Share of the parcel in each slope class, computed from the DEM with the building footprint masked.</div></div>')
}

# Four seasonal cards, families rotating water -> canopy -> gold -> ember.
# Precipitation is the average for one month of that season; the temperature
# line is the season's average, then its average daily high and low when the
# payload carries them (added 2026-09-18).
season_cards <- function(precip, temp, temp_high = NULL, temp_low = NULL) {
  if (!has(precip)) return(NULL)
  seasons <- list(
    list(key = "winter", label = "Winter", range = "Nov – Jan", fam = "water"),
    list(key = "spring", label = "Spring", range = "Feb – Apr", fam = "canopy"),
    list(key = "summer", label = "Summer", range = "May – Jul", fam = "gold"),
    list(key = "fall",   label = "Fall",   range = "Aug – Oct", fam = "ember"))
  cards <- vapply(seasons, function(s) {
    pv <- precip[[s$key]]
    tv <- if (has(temp)) temp[[paste0(s$key, "_avg")]] else NULL
    th <- if (has(temp_high)) temp_high[[paste0(s$key, "_high")]] else NULL
    tl <- if (has(temp_low)) temp_low[[paste0(s$key, "_low")]] else NULL
    temp_line <- if (has(tv)) sprintf('<div class="sub" style="color:var(--%s-06)">%s°F avg</div>', s$fam, fmt(tv)) else ""
    range_line <- if (has(th) && has(tl))
      sprintf('<div class="sub" style="color:var(--%s-06)">high %s° / low %s°</div>', s$fam, fmt(th), fmt(tl)) else ""
    sprintf('<div class="season-card" style="background:var(--%1$s-02)"><div class="label" style="color:var(--%1$s-06)">%2$s</div><div class="value" style="color:var(--%1$s-07)">%3$s</div><div class="sub" style="color:var(--%1$s-06)">%4$s</div>%5$s%6$s</div>',
            s$fam, s$label,
            if (has(pv)) paste0(fmt(pv, 1), "&quot;") else "n/a",
            s$range, temp_line, range_line)
  }, character(1))
  paste0('<div class="viz-card scroll-reveal"><h3>Average monthly precipitation, by season</h3><div class="season-grid">',
         paste(cards, collapse = "\n"), '</div>',
         '<div class="viz-caption">Inches of precipitation in an average month of each season, with the season\u2019s average temperature and average daily high and low. Source: PRISM 30-year normals (1991\u20132020), Oregon State University.</div></div>')
}

# Soils, section 05 (rewritten 2026-09-18 for real SSURGO data): a map unit
# is the survey's smallest delineation and is often a complex of two or more
# soils whose shares describe the whole unit, not the lot. So the table lists
# each unit on the parcel as a heading and its components as rows.
soil_units_html <- function(units) {
  if (!has(units)) return("")
  blocks <- vapply(units, function(u) {
    comps <- u$components
    if (!has(comps)) return("")
    show_impl <- any(vapply(comps, function(c) has(c$implication), logical(1)))
    rows <- vapply(comps, function(c) {
      sprintf('<tr><td><span class="unit-symbol">%s</span></td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td>%s</tr>',
              esc(c$name %||% ""),
              if (has(c$pct_of_unit)) paste0(fmt(c$pct_of_unit), "%") else "",
              drainage_swatch(c$drainage_class),
              esc(c$hydrologic_group %||% ""),
              esc(tolower(c$surface_texture %||% "")),
              fmt(c$k_factor, 2) %||% "",
              if (show_impl) sprintf("<td>%s</td>", esc(c$implication %||% "")) else "")
    }, character(1))
    heading <- sprintf('<h3 class="unit-heading"><span class="unit-symbol">%s</span> %s%s</h3>',
                       esc(u$symbol %||% ""), esc(u$name %||% ""),
                       if (has(u$pct_of_parcel)) sprintf(' <span class="unit-share">%s%% of the parcel</span>', fmt(u$pct_of_parcel)) else "")
    paste0(heading,
           '<div class="table-scroll"><table class="table soil-table"><thead><tr><th>Soil</th><th>Share</th><th>Drainage</th><th>Hydrologic group</th><th>Surface texture</th><th>K-factor</th>',
           if (show_impl) "<th>Implication</th>" else "", '</tr></thead><tbody>',
           paste(rows, collapse = "\n"), '</tbody></table></div>')
  }, character(1))
  paste0('<div class="soil-units scroll-reveal">', paste(blocks, collapse = "\n"),
         '<div class="viz-caption">Share of unit is how much of the map unit each soil makes up across its whole extent; the survey does not locate them within a lot. Hydrologic group runs A (water soaks in fastest) to D (slowest). K-factor is the surface soil\u2019s erodibility, from about 0.02 to 0.69; higher erodes more easily. Source: NRCS SSURGO via Soil Data Access.</div></div>')
}

# Every map unit in the soil map\u2019s frame, largest first, with the drainage
# color it was drawn in
soil_map_legend <- function(legend) {
  if (!has(legend)) return("")
  items <- vapply(legend, function(l) {
    sprintf('<li>%s<span><span class="unit-symbol">%s</span> <span class="unit-name">%s</span>%s</span></li>',
            drainage_swatch_only(l$drainage_class), esc(l$symbol %||% ""), esc(l$name %||% ""),
            if (isTRUE(l$on_parcel)) ' <span class="unit-share">(your parcel)</span>' else "")
  }, character(1))
  sprintf('<ul class="unit-list">%s</ul>', paste(items, collapse = "\n"))
}

drainage_swatch_only <- function(drainage_class) {
  d <- tolower(drainage_class %||% "")
  tok <- if (grepl("moderately well", d)) "canopy-02"
         else if (grepl("somewhat poor", d)) "gold-03"
         else if (grepl("poor", d)) "ember-03"
         else if (grepl("well|excessive", d)) "understory-03"
         else "material-warm-02"
  sprintf('<span class="legend-swatch" style="background:var(--%s)"></span>', tok)
}

source_list <- function(srcs) {
  if (!has(srcs)) return('<p class="lede">No data sources were recorded for this assessment.</p>')
  items <- vapply(srcs, function(s) {
    name <- esc(s$name %||% s$url %||% "Source")
    link <- if (has(s$url)) sprintf('<a href="%s" rel="noopener">%s</a>', esc(s$url), name) else name
    acc <- if (has(s$accessed)) sprintf('<span class="accessed">accessed %s</span>', esc(s$accessed)) else ""
    sprintf("<li>%s%s</li>", link, acc)
  }, character(1))
  sprintf('<ul class="source-list">%s</ul>', paste(items, collapse = "\n"))
}

# ---- sections (docs/BUILD_AGENT_PROMPT.md, "Section-by-section build instructions")

sec_regional <- function(p) {
  title <- if (has(p$ecoregion_l3)) sprintf("Your place in the %s", p$ecoregion_l3) else "Regional context"
  county <- if (has(p$county)) sprintf("%s County GIS", esc(p$county)) else "county GIS"
  basin <- if (has(p$huc06_name)) sprintf("%s River basin", p$huc06_name) else NULL
  section("regional", "01 — Regional context", title,
    paras(p$ecoregion_description, "lede"),
    stat_row(stat(p$ecoregion_l3, "Ecoregion"),
             stat(p$ecoregion_l4, "Local ecoregion"),
             stat(basin, "River basin"),
             stat(p$huc12_name, "Watershed")),
    viz_card(p$regional_map_svg, "canopy",
             sprintf("The parcel in its region: the %s ecoregion (EPA Level III, light green) and the %s ecoregion within it (Level IV, darker), both clipped to the state, with the %s. Source: EPA Ecoregions, USGS National Hydrography Dataset, US Census state boundary.",
                     esc(p$ecoregion_l3 %||% "Level III"), esc(p$ecoregion_l4 %||% "Level IV"),
                     if (has(p$huc06_name)) esc(paste(p$huc06_name, "River")) else "principal river")),
    viz_card(p$neighborhood_map_svg, "canopy",
             sprintf("The block around the parcel: named streets and buildings, the parcel outlined. Roads from OpenStreetMap, buildings from the NC statewide footprint inventory, parcel line from %s.", county),
             required = FALSE))
}

slope_legend <- function(erosion_pct) {
  items <- c(
    '<div class="legend-item"><div class="legend-swatch" style="background:var(--ochre-01);border:1px solid var(--line)"></div>Flat, under 2%</div>',
    '<div class="legend-item"><div class="legend-swatch" style="background:var(--ochre-02)"></div>Gentle, 2 to 8%</div>',
    '<div class="legend-item"><div class="legend-swatch" style="background:var(--ochre-03)"></div>Moderate, 8 to 15%</div>',
    '<div class="legend-item"><div class="legend-swatch" style="background:var(--ochre-04)"></div>Steep, over 15%</div>',
    if (has(erosion_pct) && as.numeric(erosion_pct) > 0)
      '<div class="legend-item"><div class="legend-swatch" style="background:var(--ember-03);border:1px solid var(--ember-05)"></div>Erosion risk, over 20%</div>',
    '<div class="legend-item"><span class="legend-arrow" aria-hidden="true"></span>Arrows point downhill; longer means steeper</div>')
  sprintf('<div class="legend viz-legend">%s</div>', paste(items, collapse = "\n"))
}

sec_topography <- function(p) {
  county <- if (has(p$county)) sprintf("%s County GIS", esc(p$county)) else "county GIS"
  pair <- if (has(p$elevation_profile_svg) || has(p$aspect_rose_svg)) {
    sprintf('<div class="viz-pair">%s%s</div>',
      viz_card(p$elevation_profile_svg, "ochre", title = "Ground profile, street to back of lot",
               caption = "Ground elevation along the A to A\u2032 line on the map above, relative to its lowest point. The dashed segment under the house is interpolated between the ground at its walls.",
               required = FALSE),
      viz_card(p$aspect_rose_svg, "gold", title = "Which way the ground faces",
               caption = "Share of the sloping ground (over 1.5% grade) by the compass direction it faces. South-facing directions get the most sun.",
               required = FALSE))
  } else ""
  section("topography", "02 — Topography and landform", "Reading the ground",
    stat_row(stat(fmt(p$elevation_change_ft, 1, " ft"), "Elevation change"),
             stat(fmt(p$max_slope_pct, 0, "%"), "Steepest grade"),
             stat(fmt(p$mean_slope_pct, 1, "%"), "Average grade"),
             stat(fmt(p$parcel_area_acres, 2, " ac"), "Parcel area")),
    paras(p$topo_description, "lede"),
    viz_card(p$contour_map_svg, "ochre",
             sprintf("Contours every 0.25 ft, darker lines every 1 ft, smoothed from the NC OneMap 3 ft bare-earth DEM with the building footprint masked before any terrain computation. Buildings from the NC statewide footprint inventory; parcel line from %s.", county)),
    viz_card(p$slope_drainage_map_svg, "ochre",
             "Slope classes and downhill direction across open ground, from the same masked DEM. Percentages are the local grade at each arrow.",
             required = FALSE, extra = slope_legend(p$erosion_risk_pct)),
    pair,
    slope_chart(p$slope_distribution, p$erosion_risk_pct))
}

sec_hydrology <- function(p) {
  fz <- p$flood_zone
  minimal <- !has(fz) || fz %in% c("Zone X", "Zone X (unshaded)")
  if (has(p$flood_zone_subtype) && !grepl("MINIMAL", toupper(p$flood_zone_subtype))) minimal <- FALSE
  fz_label <- if (has(fz) && has(p$flood_zone_subtype)) sprintf("%s, %s", fz, tolower(p$flood_zone_subtype)) else fz
  flood <- if (!minimal && has(fz)) {
    sprintf('<div class="callout scroll-reveal"><div class="eyebrow callout-eyebrow">Flood designation: %s</div>%s</div>',
            esc(fz_label), paras(p$flood_zone_description))
  } else paras(p$flood_zone_description, "lede")
  basin <- if (has(p$basin_name)) sprintf("%s River basin", p$basin_name) else NULL
  section("hydrology", "03 — Hydrology and drainage", "Where the water goes",
    paras(p$hydro_description, "lede"),
    stat_row(stat(p$watershed_name, "Watershed"),
             stat(basin, "River basin"),
             stat(fz, "FEMA flood zone"),
             stat(if (has(p$drainage_direction)) tools::toTitleCase(p$drainage_direction) else NULL, "Ground drains toward")),
    flood,
    viz_card(p$parcel_flow_map_svg, "water",
             "Where water moves across the lot: the section 02 contours with downhill flow arrows over them. Longer arrows mean steeper ground. Same masked DEM, same 0.25 ft contours.",
             required = FALSE),
    viz_card(p$hydro_map_svg, "water",
             sprintf("The parcel in its subwatershed. Tint: the %s watershed (USGS HUC12); dashed line: its boundary; blue: mapped stream reaches with flow direction; contours every 2 ft. Roads from OpenStreetMap, buildings from the NC statewide footprint inventory, flood zones from FEMA NFHL.",
                     esc(p$watershed_name %||% "parcel's"))))
}

month_long <- function(abb) {
  if (!has(abb)) return(NULL)
  i <- match(abb, month.abb)
  if (is.na(i)) abb else month.name[i]
}

sec_climate <- function(p) {
  seasons <- season_cards(p$seasonal_precip, p$seasonal_temp, p$seasonal_temp_high, p$seasonal_temp_low)
  warm <- if (has(p$warmest_month_high_f)) sprintf("%s\u00b0F, %s", fmt(p$warmest_month_high_f), month_long(p$warmest_month)) else NULL
  cold <- if (has(p$coldest_month_low_f)) sprintf("%s\u00b0F, %s", fmt(p$coldest_month_low_f), month_long(p$coldest_month)) else NULL
  wind_cap <- sprintf("How often each day\u2019s strongest two-minute wind came from each of eight directions, by season, with the season\u2019s average wind speed. %s%s Source: NOAA NCEI Global Historical Climatology Network daily summaries.",
                      if (has(p$wind_station_name)) sprintf("Observed at %s, the nearest full weather station. ", esc(p$wind_station_name)) else "",
                      if (has(p$wind_years)) sprintf("Years %s, %s days with a recorded direction.", esc(p$wind_years), fmt(p$wind_days)) else "")
  section("climate", "04 \u2014 Climate and wind", "Seasonal rhythms",
    paras(p$climate_description, "lede"),
    stat_row(stat(fmt(p$annual_precip_in, 1, " in"), "Precipitation in a year"),
             stat(warm, "Average high, warmest month"),
             stat(cold, "Average low, coldest month"),
             stat(if (has(p$prevailing_wind)) tools::toTitleCase(p$prevailing_wind) else NULL, "Prevailing wind")),
    seasons %||% viz_card(NULL, "water", "Source: PRISM 30-year normals (1991\u20132020), Oregon State University."),
    viz_card(p$climate_chart_svg, "water",
             "Month by month: average precipitation above, average daily high and low temperature below, the dashed line between them the daily mean. The year runs November to October so each season is one block. Source: PRISM 30-year normals (1991\u20132020), Oregon State University, 4 km grid cell containing the parcel.",
             required = FALSE),
    viz_card(p$wind_rose_svg, "water", wind_cap, required = FALSE))
}

sec_soils <- function(p) {
  units <- p$soil_map_units
  u1 <- if (has(units)) units[[1]] else NULL
  largest <- if (has(p$dominant_soil)) sprintf("%s, %s%%", p$dominant_soil, fmt(p$dominant_soil_pct)) else NULL
  section("soils", "05 \u2014 Soils and infiltration", "What lies beneath",
    paras(p$soils_description, "lede"),
    stat_row(stat(u1$symbol, "Soil map unit"),
             stat(largest, "Largest soil in the unit"),
             stat(p$drainage_class, "Drainage class"),
             stat(p$hydrologic_group, "Hydrologic soil group")),
    viz_card(p$soil_map_svg, "ochre",
             "Soil map units across the same frame as the watershed map in section 03, each tinted by the drainage class of its dominant soil, labeled with its map unit symbol. Blue lines are mapped stream reaches; the floodplain soils follow them. Source: NRCS SSURGO via Soil Data Access; roads from OpenStreetMap; City of Raleigh Hydrology.",
             extra = paste0(if (has(p$soil_map_legend)) drainage_legend else "", soil_map_legend(p$soil_map_legend))),
    viz_card(p$soil_profile_svg, "ochre",
             title = if (has(u1$symbol)) sprintf("The soils of map unit %s, side by side", u1$symbol) else "Soil profiles",
             caption = "Each column is one soil in the map unit, its width the soil\u2019s share of the unit, drawn to 60 in. Bands are horizons, darker with more clay, labeled with the horizon name and texture. \u201cFill\u201d marks material moved by people, in the survey\u2019s own notation. The dashed line marks the first horizon where water moves slowly (under 1 micrometer per second, about 0.14 in per hour). Source: NRCS SSURGO representative values via Soil Data Access.",
             required = FALSE),
    soil_units_html(units))
}

# Section 06 (rewritten 2026-09-19 for real data): sun and shade from the DEM
# and the building footprints. Tree shade is not drawn; the canopy figure is
# the coarse NLCD read around the parcel, labeled as such.
heat_legend <- function(shade_min_hours) {
  sprintf('<div class="legend viz-legend">
<div class="legend-item"><div class="legend-swatch" style="background:var(--gold-01);border:1px solid var(--line)"></div>Faces away from the sun, cooler</div>
<div class="legend-item"><div class="legend-swatch" style="background:var(--gold-02)"></div>Level ground</div>
<div class="legend-item"><div class="legend-swatch" style="background:var(--ember-03)"></div>Faces the afternoon sun, warmer</div>
<div class="legend-item"><div class="legend-swatch" style="background:var(--understory-03)"></div>Shaded by a building %s hours or more at midday in summer</div>
</div>', fmt(shade_min_hours))
}

shade_legend <- '<div class="legend viz-legend">
<div class="legend-item"><div class="legend-swatch" style="background:var(--understory-01);border:1px solid var(--line)"></div>Under 1 hour</div>
<div class="legend-item"><div class="legend-swatch" style="background:var(--understory-02)"></div>1 to 2 hours</div>
<div class="legend-item"><div class="legend-swatch" style="background:var(--understory-03)"></div>2 to 4 hours</div>
<div class="legend-item"><div class="legend-swatch" style="background:var(--understory-05)"></div>4 to 6 hours</div>
</div>'

sec_microclimate <- function(p) {
  canopy <- if (has(p$canopy_cover_nearby_pct))
    sprintf('<p class="lede">Tree canopy is not mapped at parcel scale in the public data. The national 30 m canopy survey puts tree cover within %s ft of the parcel at about %s%%, a coarse figure that includes the surrounding lots and street trees.</p>',
            fmt(p$canopy_cover_nearby_radius_ft), fmt(p$canopy_cover_nearby_pct))
  else if (!has(p$canopy_cover_pct))
    '<p class="lede">Canopy cover data is not available at sufficient resolution for this parcel.</p>'
  else sprintf('<p class="lede">Tree canopy covers about %s%% of the parcel.</p>', fmt(p$canopy_cover_pct))
  h <- p$building_height_ft_assumed
  hours <- p$shade_hours_window
  window <- if (has(hours) && length(hours) == 2) sprintf("%s am to %s pm solar time", fmt(hours[[1]]), fmt(as.numeric(hours[[2]]) - 12)) else "the middle of the day"
  infer <- if (has(h)) sprintf(" Building heights are not in the public inventory; every building is drawn %s ft tall until measured on site. Tree shade is not included.", fmt(h)) else ""
  section("microclimate", "06 \u2014 Microclimate", "Heat, shade, and air",
    paras(p$micro_description, "lede"),
    stat_row(stat(fmt(p$building_footprint_sqft, 0, " sq ft"), "Building footprint"),
             stat(fmt(p$south_facing_pct, 0, "%"), "Sloping ground facing south"),
             stat(fmt(p$summer_full_sun_pct, 0, "%"), "Open ground in full midday sun, summer"),
             stat(fmt(p$winter_shade_2h_pct, 0, "%"), "Open ground shaded 2+ hours, winter")),
    canopy,
    viz_card(p$sun_path_svg, "gold", title = "The sun\u2019s path over the lot",
             caption = "The sun\u2019s daily arc on the summer solstice, the equinoxes and the winter solstice, seen from above: direction around the ring, height by distance from the house (a low sun sits far out, a high sun close in). Sunrise and sunset are solar time. The same geometry holds for every lot at this latitude; what changes is what stands in the way. Understanding this arc is the first step in reading sun and shade through the seasons (moved here from section 07 at Peter\u2019s review, 2026-09-19).",
             required = FALSE),
    viz_card(p$heat_accumulation_map_svg, "gold", title = "Summer sun and shade",
             caption = sprintf("How strongly each part of the open ground faces the sun, from the slope and aspect of the masked DEM (McCune and Keon heat load index, relative to level ground), with the ground the buildings shade for two or more hours between %s on the summer solstice laid over it.%s Source: NC OneMap DEM, NC building footprints.", window, infer),
             extra = heat_legend(2)),
    viz_card(p$shade_map_svg, "understory", title = "Hours of building shade, winter and summer",
             caption = sprintf("Hours each part of the open ground sits in a building\u2019s shadow between %s on the two solstices, from the sun\u2019s path at this latitude. The neighbors\u2019 buildings count too; a house to the south shades a lot most in winter, when the sun is low.%s Source: NC building footprints.", window, infer),
             extra = shade_legend, required = FALSE))
}

# Practitioner's voice: rendered as given, no source citation. The drafted
# opportunities plan built 2026-09-19 was rejected at review the same day
# (this is an assessment, not a design; the drawing was too busy to read) and
# the sun-path diagram moved to section 06. The plan code stays in
# R/illustrate/site_synthesis.R as a record; the renderer no longer draws it.
sec_synthesis <- function(p) {
  section("synthesis", "07 \u2014 Vulnerabilities and opportunities", "What this site is telling us",
    paras(p$synthesis_narrative, "lede"),
    bullet_list(p$vulnerabilities, "Vulnerabilities"),
    bullet_list(p$opportunities, "Opportunities"))
}

sec_sources <- function(p) {
  section("sources", "08 — Supporting data", "Sources and methods",
    '<p class="lede sources-intro">All data in this assessment is derived from publicly available sources. Visualizations are generated from these sources; practitioner observations are noted separately in the synthesis section above.</p>',
    source_list(p$data_sources),
    '<p class="disclosure">This assessment infers site-specific conditions from the most granular regional data available. It does not constitute a site-specific survey.</p>',
    full_height = FALSE)
}

# ---- page chrome -----------------------------------------------------------

SECTION_NAV <- data.frame(
  id    = c("regional", "topography", "hydrology", "climate", "soils", "microclimate", "synthesis", "sources"),
  label = c("01 Regional context", "02 Topography and landform", "03 Hydrology and drainage",
            "04 Climate and wind", "05 Soils and infiltration", "06 Microclimate",
            "07 Vulnerabilities and opportunities", "08 Supporting data"),
  stringsAsFactors = FALSE)

header_html <- function(mark) {
  links <- paste0(sprintf('<a href="#%s">%s</a>', SECTION_NAV$id, esc(SECTION_NAV$label)), collapse = "\n")
  paste0('<header class="site-header">
<button class="menu-btn" type="button" aria-label="Menu" aria-expanded="false" aria-controls="menu" onclick="toggleMenu()">&#9776;</button>
<a class="wordmark" href="https://kaleiope.design" aria-label="KALEIOPE Environmental Design">', mark, '</a>
</header>
<nav id="menu" class="menu" aria-label="Report sections">
<div class="eyebrow">Contents</div>
', links, '
<div class="menu-actions">
<button class="btn btn-secondary" type="button" onclick="toggleTheme()">Toggle dark mode</button>
<button class="btn btn-ghost" type="button" onclick="window.print()">Print</button>
</div>
</nav>')
}

cover_html <- function(p) {
  paste0('<div class="cover">
<div class="eyebrow">Site Assessment</div>
<h1>', esc(p$client_name %||% "Site Assessment"), '</h1>
', if (has(p$address)) paste0('<p class="cover-address">', esc(p$address), '</p>') else "", '
', if (has(p$assessment_date)) paste0('<p class="cover-date">', esc(fmt_date(p$assessment_date)), '</p>') else "", '
</div>')
}

FOOTER_HTML <- '<footer class="site-footer">
<div class="footer-name"><a href="https://kaleiope.design">KALEIOPE Environmental Design</a></div>
<div class="footer-mail"><a href="mailto:info@kaleiope.design">info@kaleiope.design</a></div>
</footer>'

# Runs in <head>, before first paint, so a dark-OS viewer never sees a light flash.
# The explicit data-theme toggle always wins over the OS preference.
THEME_SCRIPT <- "if (!document.documentElement.dataset.theme && matchMedia('(prefers-color-scheme:dark)').matches) { document.documentElement.dataset.theme = 'dark'; }"

PAGE_SCRIPT <- "const observer = new IntersectionObserver((entries) => {
  entries.forEach(e => {
    if (e.isIntersecting) { e.target.classList.add('is-visible'); observer.unobserve(e.target); }
  });
}, { threshold: 0.15 });
document.querySelectorAll('.scroll-reveal').forEach(el => observer.observe(el));

function toggleTheme() {
  const html = document.documentElement;
  html.dataset.theme = html.dataset.theme === 'dark' ? 'light' : 'dark';
}

function toggleMenu(open) {
  const menu = document.getElementById('menu');
  const btn = document.querySelector('.menu-btn');
  const next = open === undefined ? !menu.hasAttribute('data-open') : open;
  menu.toggleAttribute('data-open', next);
  btn.setAttribute('aria-expanded', String(next));
}
document.getElementById('menu').addEventListener('click', e => { if (e.target.closest('a')) toggleMenu(false); });
document.addEventListener('keydown', e => { if (e.key === 'Escape') toggleMenu(false); });"

# Report-specific layout on top of the design system's tokens and classes.
REPORT_CSS <- "/* ── Report layout (on top of the design system) ── */
.site-header { position: sticky; top: 0; z-index: 50; display: flex; align-items: center; justify-content: space-between; padding: var(--space-3) var(--wrap-padding); background: var(--bg); border-bottom: 1px solid var(--line-light); }
.menu-btn { background: none; border: none; cursor: pointer; padding: var(--space-2); color: var(--ink); font-size: 20px; line-height: 1; }
.wordmark { display: block; color: var(--muted); height: 28px; }
.wordmark svg { height: 28px; width: auto; display: block; }
.menu { position: fixed; top: 0; left: 0; bottom: 0; width: min(320px, 85vw); z-index: 60; display: flex; flex-direction: column; gap: var(--space-1); padding: var(--space-6) var(--space-5); background: var(--surface-elevated); border-right: 1px solid var(--line); box-shadow: var(--shadow-dialog); transform: translateX(-100%); transition: transform var(--duration) var(--ease); overflow-y: auto; }
.menu[data-open] { transform: none; }
.menu a { color: var(--ink); text-decoration: none; font-size: var(--size-caption); padding: var(--space-2) 0; border-bottom: 1px solid var(--line-light); }
.menu a:hover { color: var(--accent); }
.menu-actions { display: flex; flex-wrap: wrap; gap: var(--space-2); margin-top: var(--space-4); }
.cover { min-height: 100svh; display: flex; flex-direction: column; justify-content: center; align-items: center; padding: var(--space-7) var(--wrap-padding); text-align: center; }
.cover h1 { font-size: clamp(2.5rem, 6vw, 4rem); margin-bottom: var(--space-3); }
.cover-address { font-size: var(--size-body); color: var(--muted); margin: 0; }
.cover-date { font-size: var(--size-caption); color: var(--caption); margin-top: var(--space-2); }
.scroll-section-short { min-height: auto; }
.lede { max-width: 560px; }
.scroll-section .viz-card { margin-top: var(--space-4); }
.scroll-section .viz-card + .viz-card { margin-top: var(--space-5); }
.stat-row { margin: var(--space-4) 0 var(--space-5); }
/* Stats are subheadings under the section title, not peers of it (Peter, 2026-09-18): h3 size, label first */
.stat-value { font-size: var(--size-h3); }
.stat-label { order: -1; }
.viz-placeholder { aspect-ratio: 5 / 3; border-radius: var(--radius-media); display: flex; align-items: center; justify-content: center; font-size: var(--size-caption); }
.viz-frame { border-radius: var(--radius-media); overflow: hidden; }
.viz-frame svg { width: 100%; height: auto; display: block; }
.viz-card h3 { margin-bottom: var(--space-4); }
.season-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; }
.season-card { border-radius: var(--radius-media); padding: 16px; text-align: center; }
.season-card .label { font-size: var(--size-eyebrow); font-weight: var(--weight-medium); letter-spacing: 0.08em; text-transform: uppercase; margin-bottom: 4px; }
.season-card .value { font-family: var(--font-display); font-weight: var(--weight-display); font-size: var(--size-h3); }
.season-card .sub { font-size: 11px; margin-top: 4px; }
.bar-row { display: flex; align-items: center; gap: 10px; margin-bottom: 8px; font-size: var(--size-small); }
.bar-label { width: 120px; text-align: right; color: var(--muted); flex-shrink: 0; }
.bar { height: 28px; border-radius: 4px; display: flex; align-items: center; padding-left: 8px; font-size: 11px; font-weight: var(--weight-medium); min-width: 32px; }
.chart-legend { margin-top: 12px; }
.viz-legend { margin-top: var(--space-3); }
.legend-arrow { display: inline-block; width: 18px; height: 0; border-top: 2px solid var(--water-05); position: relative; flex-shrink: 0; }
.legend-arrow::after { content: ''; position: absolute; right: -1px; top: -4px; border: 3px solid transparent; border-left: 6px solid var(--water-05); }
.viz-pair { display: grid; grid-template-columns: 3fr 2fr; gap: var(--space-4); margin-top: var(--space-5); }
.viz-pair .viz-card { margin-top: 0; }
.viz-card h3 { font-size: 1rem; margin-bottom: var(--space-3); }
.drainage-legend { margin-top: var(--space-4); }
.unit-list { list-style: none; padding: 0; margin: var(--space-3) 0 0; font-size: var(--size-small); }
.unit-list li { display: flex; align-items: baseline; gap: var(--space-2); padding: 3px 0; }
.unit-list .legend-swatch { flex-shrink: 0; position: relative; top: 2px; }
.unit-list .unit-name { font-size: var(--size-small); }
.unit-share { color: var(--caption); font-weight: var(--weight-body); font-size: var(--size-caption); font-family: var(--font-body); }
.soil-units { margin-top: var(--space-5); }
.unit-heading { font-size: 1rem; margin-top: var(--space-5); margin-bottom: 0; }
.soil-units .table-scroll { margin-top: var(--space-3); }
.soil-table th:nth-child(1), .soil-table td:nth-child(1), .soil-table th:nth-child(6), .soil-table td:nth-child(6) { white-space: nowrap; }
.callout { background: var(--ember-02); color: var(--ember-07); border-radius: var(--radius-media); padding: var(--space-4) var(--space-5); margin: 0 0 var(--space-4); max-width: 560px; }
.callout-eyebrow { color: var(--ember-06); }
.callout p { margin: 0; }
.finding-list { padding-left: 1.2em; margin: 0 0 var(--space-5); max-width: 560px; }
.finding-list li { margin-bottom: var(--space-2); }
.table-scroll { overflow-x: auto; margin-top: var(--space-5); }
.table th:nth-child(3), .table td:nth-child(3), .table th:nth-child(4), .table td:nth-child(4) { white-space: nowrap; }
.unit-symbol { font-weight: var(--weight-medium); }
.unit-name { font-size: var(--size-small); color: var(--muted); }
.sources-intro { font-size: var(--size-caption); color: var(--caption); }
.source-list { list-style: none; padding: 0; margin: 0; max-width: 560px; }
.source-list li { padding: var(--space-2) 0; border-bottom: 1px solid var(--line-light); font-size: var(--size-caption); }
.source-list .accessed { font-size: var(--size-small); color: var(--caption); margin-left: var(--space-2); }
.disclosure { font-size: var(--size-caption); color: var(--muted); border-top: 1px solid var(--line); padding-top: var(--space-4); margin-top: var(--space-5); max-width: 560px; }
.site-footer { border-top: 1px solid var(--line); padding: var(--space-6) var(--wrap-padding); text-align: center; }
.footer-name { font-size: var(--size-caption); }
.footer-name a { color: var(--caption); text-decoration: none; }
.footer-mail { font-size: var(--size-small); margin-top: var(--space-1); }

@media (max-width: 600px) {
  .viz-pair { grid-template-columns: 1fr; }
}
@media (max-width: 500px) {
  .season-grid { grid-template-columns: repeat(2, 1fr); }
  .bar-label { width: 96px; }
}

@media print {
  .site-header { position: static; }
  .menu, .menu-btn { display: none !important; }
  .scroll-section { min-height: auto; page-break-before: always; }
  .scroll-section:first-of-type { page-break-before: auto; }
  .cover { min-height: auto; }
}"

# ---- assembly --------------------------------------------------------------

# The delivered file is self-contained: drop the stylesheet's own font loading (an
# @import of Cabin and @font-face rules pointing at self-hosted Poppins files) in
# favor of one Google Fonts link in <head> that carries both families.
design_system_css <- function(assets_dir) {
  css <- readLines(file.path(assets_dir, "styles.css"), warn = FALSE, encoding = "UTF-8")
  css <- css[!grepl("^\\s*@import\\b|^\\s*@font-face\\b", css)]
  paste(css, collapse = "\n")
}

build_document <- function(p, css, mark) {
  title <- paste(c("Site Assessment", p$client_name, p$address), collapse = " — ")
  sections <- paste(
    sec_regional(p), sec_topography(p), sec_hydrology(p), sec_climate(p),
    sec_soils(p), sec_microclimate(p), sec_synthesis(p), sec_sources(p),
    sep = "\n\n")
  paste0('<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>', esc(title), '</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Cabin:wght@400;500;600;700&family=Poppins:wght@200;300;400;500;600&display=swap" rel="stylesheet">
<script>', THEME_SCRIPT, '</script>
<style>
', css, '

', REPORT_CSS, '
</style>
<noscript><style>.scroll-reveal { opacity: 1; transform: none; }</style></noscript>
</head>
<body>
', header_html(mark), '
', cover_html(p), '
<div class="wrap">

', sections, '

</div>
', FOOTER_HTML, '
<script>
', PAGE_SCRIPT, '
</script>
</body>
</html>
')
}

render_site_assessment <- function(payload, out_dir = "output", assets_dir = "R/report/assets") {
  p <- if (is.character(payload)) jsonlite::fromJSON(payload, simplifyVector = FALSE) else payload
  css  <- design_system_css(assets_dir)
  mark <- paste(readLines(file.path(assets_dir, "letterhead-small.svg"), warn = FALSE, encoding = "UTF-8"), collapse = "")
  html <- build_document(p, css, mark)
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  out <- file.path(out_dir, paste0(address_slug(p$address), "_assessment.html"))
  writeLines(enc2utf8(html), out, useBytes = TRUE)
  invisible(out)
}
