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
viz_card <- function(media, family, caption = NULL, required = TRUE) {
  if (!has(media)) {
    if (!required) return("")
    body <- placeholder(family)
  } else {
    body <- viz_media(media)
  }
  cap <- if (has(caption)) sprintf('<div class="viz-caption">%s</div>', caption) else ""
  sprintf('<div class="viz-card scroll-reveal">%s%s</div>', body, cap)
}

stat <- function(value, label) {
  if (is.null(value)) return("")
  sprintf('<div class="stat"><div class="stat-value">%s</div><div class="stat-label">%s</div></div>',
          esc(value), esc(label))
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
season_cards <- function(precip, temp) {
  if (!has(precip)) return(NULL)
  seasons <- list(
    list(key = "winter", label = "Winter", range = "Nov – Jan", fam = "water",  tkey = "winter_avg"),
    list(key = "spring", label = "Spring", range = "Feb – Apr", fam = "canopy", tkey = "spring_avg"),
    list(key = "summer", label = "Summer", range = "May – Jul", fam = "gold",   tkey = "summer_avg"),
    list(key = "fall",   label = "Fall",   range = "Aug – Oct", fam = "ember",  tkey = "fall_avg"))
  cards <- vapply(seasons, function(s) {
    pv <- precip[[s$key]]
    tv <- if (has(temp)) temp[[s$tkey]] else NULL
    sprintf('<div class="season-card" style="background:var(--%1$s-02)"><div class="label" style="color:var(--%1$s-06)">%2$s</div><div class="value" style="color:var(--%1$s-07)">%3$s</div><div class="sub" style="color:var(--%1$s-06)">%4$s</div>%5$s</div>',
            s$fam, s$label,
            if (has(pv)) paste0(fmt(pv, 1), "&quot;") else "n/a",
            s$range,
            if (has(tv)) sprintf('<div class="sub" style="color:var(--%s-06)">%s°F avg</div>', s$fam, fmt(tv)) else "")
  }, character(1))
  paste0('<div class="viz-card scroll-reveal"><h3>Average monthly precipitation</h3><div class="season-grid">',
         paste(cards, collapse = "\n"), '</div>',
         '<div class="viz-caption">Source: PRISM 30-year normals (1991–2020), Oregon State University.</div></div>')
}

soil_table <- function(units) {
  if (!has(units)) return("")
  rows <- vapply(units, function(u) {
    sprintf('<tr><td><span class="unit-symbol">%s</span><div class="unit-name">%s</div></td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>',
            esc(u$symbol %||% ""), esc(u$name %||% ""), drainage_swatch(u$drainage_class),
            fmt(u$k_factor, 2) %||% "", if (has(u$pct_of_parcel)) paste0(fmt(u$pct_of_parcel), "%") else "",
            esc(u$implication %||% ""))
  }, character(1))
  paste0('<div class="table-scroll scroll-reveal"><table class="table"><thead><tr><th>Map unit</th><th>Drainage class</th><th>K-factor</th><th>% of parcel</th><th>Implication</th></tr></thead><tbody>',
         paste(rows, collapse = "\n"), '</tbody></table></div>')
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
  section("regional", "01 — Regional context", title,
    paras(p$ecoregion_description, "lede"),
    viz_card(p$regional_map_svg, "canopy",
             sprintf("Source: EPA Level III/IV Ecoregions, NHD Flowlines. Parcel boundary from %s.", county)),
    viz_card(p$neighborhood_map_svg, "canopy",
             "Neighborhood context. Source: NCOneMap 1m DEM contours, local hydrology, USGS Watershed Boundary Dataset (HUC12).",
             required = FALSE))
}

sec_topography <- function(p) {
  section("topography", "02 — Topography and landform", "Reading the ground",
    stat_row(stat(fmt(p$elevation_change_ft, 0, " ft"), "Elevation change"),
             stat(fmt(p$max_slope_pct, 0, "%"), "Max slope"),
             stat(fmt(p$parcel_area_acres, 2, " ac"), "Parcel area")),
    paras(p$topo_description, "lede"),
    viz_card(p$contour_map_svg, "ochre",
             "Source: NCOneMap 1m DEM. Building footprint masked before terrain computation."),
    viz_card(p$slope_drainage_map_svg, "ochre",
             "Slope and drainage direction across open ground, from the same masked DEM. Arrow length scales with grade.",
             required = FALSE),
    slope_chart(p$slope_distribution, p$erosion_risk_pct))
}

sec_hydrology <- function(p) {
  fz <- p$flood_zone
  minimal <- !has(fz) || fz %in% c("Zone X", "Zone X (unshaded)")
  flood <- if (!minimal) {
    sprintf('<div class="callout scroll-reveal"><div class="eyebrow callout-eyebrow">Flood designation: %s</div>%s</div>',
            esc(fz), paras(p$flood_zone_description))
  } else paras(p$flood_zone_description, "lede")
  section("hydrology", "03 — Hydrology and drainage", "Where the water goes",
    paras(p$hydro_description, "lede"),
    stat_row(stat(p$watershed_name, "Watershed"),
             stat(fz, "FEMA flood zone"),
             stat(p$drainage_direction, "Drains toward")),
    flood,
    viz_card(p$hydro_map_svg, "water",
             "Source: USGS Watershed Boundary Dataset (HUC12), local hydrology, FEMA National Flood Hazard Layer."))
}

sec_climate <- function(p) {
  seasons <- season_cards(p$seasonal_precip, p$seasonal_temp)
  section("climate", "04 — Climate and wind", "Seasonal rhythms",
    paras(p$climate_description, "lede"),
    seasons %||% viz_card(NULL, "water", "Source: PRISM 30-year normals (1991–2020), Oregon State University."),
    viz_card(p$wind_rose_svg, "water", "Seasonal wind rose. Source: NOAA NCEI station normals.", required = FALSE))
}

sec_soils <- function(p) {
  section("soils", "05 — Soils and infiltration", "What lies beneath",
    paras(p$soils_description, "lede"),
    viz_card(p$soil_map_svg, "ochre", "Source: NRCS SSURGO via Soil Data Access."),
    viz_card(p$soil_profile_svg, "ochre", "Soil profile for the dominant map unit. Source: NRCS SSURGO via Soil Data Access.",
             required = FALSE),
    soil_table(p$soil_map_units),
    if (has(p$soil_map_units)) drainage_legend else "")
}

sec_microclimate <- function(p) {
  building <- if (has(p$building_footprint_sqft))
    sprintf("<p class=\"lede\">The primary structure covers about %s sq ft of the parcel.</p>", fmt(p$building_footprint_sqft))
  else ""
  canopy <- if (!has(p$canopy_cover_pct))
    '<p class="lede">Canopy cover data is not available at sufficient resolution for this parcel.</p>'
  else sprintf('<p class="lede">Tree canopy covers about %s%% of the parcel.</p>', fmt(p$canopy_cover_pct))
  section("microclimate", "06 — Microclimate", "Heat, shade, and air",
    paras(p$micro_description, "lede"),
    building, canopy,
    viz_card(p$heat_accumulation_map_svg, "gold",
             "Source: Derived from DEM aspect, NLCD canopy cover, and building footprint geometry.",
             required = FALSE))
}

# Practitioner's voice: rendered verbatim, no source citation.
sec_synthesis <- function(p) {
  section("synthesis", "07 — Vulnerabilities and opportunities", "What this site is telling us",
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
.drainage-legend { margin-top: var(--space-4); }
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
