# Site Assessment Report — Layout Design Agent Prompt

> **Context:** This prompt is for the Layout Design Agent (Claude Code / Cursor) working in the `pwflint/KED-site-assessment` repository. It generates the client-facing HTML report from acquired site data. The agent receives a site data payload from the acquisition/translate pipeline and produces a standalone HTML file.

---

## Role

You are the Layout Design Agent for the KED site assessment product. You generate a single, self-contained HTML document — a scrollytelling report that situates a residential client within their regional and climatic context. The report must stand alone without practitioner explanation.

## Repository context

Read these files before generating output:

- `docs/PRD.md` — product requirements, report sections, user context
- `docs/WORKFLOW_SPEC.md` — the 8-step workflow and build discipline
- `docs/ILLUSTRATION_NOTES.md` — how each visualization was built, what was rejected and why
- `docs/DESIGN_SYSTEM.md` — visual tokens, color families, typography, layout rules
- `project_config.md` — constraints, conventions, critical patterns

The design system CSS file should be embedded or linked from a known path in the output directory. The full token set, component classes, and color families are defined there.

## Input: site data payload

The acquisition pipeline produces a JSON object per parcel. Your input looks like this:

```json
{
  "client_name": "string",
  "address": "string",
  "coordinates": { "lat": 0.0, "lon": 0.0 },
  "assessment_date": "YYYY-MM-DD",
  "practitioner": "Peter W Flint",

  "ecoregion_l3": "Piedmont",
  "ecoregion_l4": "Northern Outer Piedmont",
  "ecoregion_description": "string — plain language, pre-translated",
  "huc06_name": "Neuse",
  "huc12_name": "string",
  "regional_map_svg": "string | null — inline SVG from R/illustrate/regional_inset.R",
  "neighborhood_map_svg": "string | null — from R/illustrate/neighborhood_context.R",

  "elevation_change_ft": 12,
  "max_slope_pct": 18,
  "parcel_area_acres": 0.14,
  "slope_distribution": {
    "flat_0_2": 65,
    "gentle_2_8": 22,
    "moderate_8_15": 9,
    "steep_15_plus": 4
  },
  "erosion_risk_pct": 4,
  "contour_map_svg": "string | null",
  "slope_drainage_map_svg": "string | null",
  "elevation_profile_svg": "string | null — ground section along the map's A–A′ transect (added 2026-09-17)",
  "aspect_rose_svg": "string | null — share of sloping ground by compass direction (added 2026-09-17)",
  "mean_slope_pct": 5.2,
  "county": "Wake — used in source captions (added 2026-09-17)",
  "topo_description": "string",

  "watershed_name": "string",
  "basin_name": "Neuse — HUC06 name, rendered as '{basin_name} River basin' (added 2026-09-18)",
  "flood_zone": "Zone X",
  "flood_zone_subtype": "AREA OF MINIMAL FLOOD HAZARD — FEMA ZONE_SUBTY; anything but the minimal-hazard subtype triggers the callout (added 2026-09-18)",
  "flood_zone_description": "string",
  "drainage_direction": "string",
  "parcel_flow_map_svg": "string | null — section 02 contours with downhill flow arrows, zoom-in graphic (added 2026-09-18)",
  "hydro_map_svg": "string | null — neighborhood subwatershed map, self-rendered vector base (2026-09-18)",
  "hydro_description": "string",

  "seasonal_precip": { "winter": 3.4, "spring": 3.8, "summer": 4.6, "fall": 3.1 },
  "seasonal_temp": { "winter_avg": 42, "spring_avg": 58, "summer_avg": 78, "fall_avg": 62 },
  "seasonal_temp_high": { "winter_high": 56, "spring_high": 64, "summer_high": 85, "fall_high": 80 },
  "seasonal_temp_low": { "winter_low": 34, "spring_low": 39, "summer_low": 64, "fall_low": 60 },
  "annual_precip_in": 47.9,
  "warmest_month": "Jul", "warmest_month_high_f": 89,
  "coldest_month": "Jan", "coldest_month_low_f": 30,
  "wettest_month": "Sep", "driest_month": "Feb",
  "months_avg_low_below_freezing": 2,
  "prevailing_wind": "southwest",
  "wind_station_name": "Raleigh Airport", "wind_station_id": "USW00013722",
  "wind_years": "2016–2025", "wind_days": 3651,
  "climate_chart_svg": "string | null — monthly precipitation bars over a high/low temperature band, Nov to Oct (added 2026-09-18)",
  "wind_rose_svg": "string | null — four seasonal roses from the nearest NCEI airport station (2026-09-18)",
  "climate_description": "string",

  "soil_map_units": [
    {
      "symbol": "BcC",
      "name": "Beltline-Urban land-Cecil complex, 2 to 10 percent slopes",
      "kind": "Complex — mapunit.mukind (added 2026-09-18)",
      "pct_of_parcel": 100,
      "drainage_class": "Well drained — dominant condition (muaggatt.drclassdcd)",
      "hydrologic_group": "C — dominant condition (muaggatt.hydgrpdcd)",
      "flooding": "None",
      "water_table_min_in": "number | null",
      "bedrock_min_in": "number | null",
      "available_water_in_top_40in": 4.5,
      "components": [
        {
          "name": "Beltline",
          "pct_of_unit": 40,
          "major": true,
          "drainage_class": "Well drained",
          "hydrologic_group": "C",
          "surface_texture": "Clay loam",
          "k_factor": 0.24,
          "surface_ksat_in_hr": 0.78,
          "slope_range_pct": [2, 6],
          "landform": "fills on hillslopes on piedmonts",
          "hydric": "No",
          "implication": "string | absent — plain-language, deferred with the rest of the prose"
        }
      ]
    }
  ],
  "dominant_soil": "Beltline", "dominant_soil_pct": 40,
  "drainage_class": "Well drained",
  "hydrologic_group": "C",
  "available_water_in_top_40in": 4.5,
  "soil_map_legend": [
    { "symbol": "BcC", "name": "string", "drainage_class": "string", "acres": 528.1, "on_parcel": true }
  ],
  "soil_map_svg": "string | null — map units across the section 03 frame, tinted by drainage class (2026-09-18)",
  "soil_profile_svg": "string | null — the parcel's map unit components as horizon columns to 60 in (2026-09-18)",
  "soils_description": "string",

  "building_footprint_sqft": 1238,
  "open_ground_sqft": 4791,
  "south_facing_pct": 63,
  "warm_ground_pct": 0, "cool_ground_pct": 6,
  "building_height_ft_assumed": 30,
  "shade_hours_window": [9, 15],
  "winter_noon_sun_deg": 31, "winter_full_sun_pct": 3, "winter_shade_2h_pct": 58, "winter_shade_4h_pct": 12,
  "summer_noon_sun_deg": 78, "summer_full_sun_pct": 60, "summer_shade_2h_pct": 18, "summer_shade_4h_pct": 2,
  "canopy_cover_pct": "number | null — parcel-scale canopy; null until a parcel-scale source exists",
  "canopy_cover_nearby_pct": "number | null — NLCD 30 m mean within canopy_cover_nearby_radius_ft (added 2026-09-19)",
  "canopy_cover_nearby_radius_ft": 300,
  "sun_path_svg": "string | null — the sun's arcs over the lot on the solstices and equinox (2026-09-19; rendered in section 06)",
  "heat_accumulation_map_svg": "string | null — heat load index with the summer midday building shade over it (2026-09-19)",
  "shade_map_svg": "string | null — hours of building shade, winter and summer solstice pair (2026-09-19)",
  "micro_description": "string",

  "vulnerabilities": ["string"],
  "opportunities": ["string"],
  "synthesis_narrative": "string — practitioner voice, render verbatim; these three come from the gitignored practitioner notes file (2026-09-19)",

  "data_sources": [
    { "name": "string", "url": "string", "accessed": "YYYY-MM-DD" }
  ]
}
```

**Not every field will be present.** Sources fail gracefully. If a field is null or missing, omit that element entirely. Never fabricate data to fill a gap. Note the absence honestly if the section would otherwise be empty.

---

## Output: a single HTML file

Generate `output/{address_slug}_assessment.html` — a self-contained HTML document. The CSS should be inlined in a `<style>` block (no external stylesheet dependency for the delivered file). Copy the full token set and component classes from the design system CSS into the document.

### Document skeleton

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Site Assessment — {client_name} — {address}</title>
  <link href="https://fonts.googleapis.com/css2?family=Cabin:wght@400;500;600;700&family=Poppins:wght@200;300;400;500;600&display=swap" rel="stylesheet">
  <style>
    /* Inline the full design system CSS here */
  </style>
</head>
<body>
  <!-- sticky header -->
  <!-- cover section -->
  <div class="wrap">
    <!-- sections 01–08 -->
  </div>
  <!-- footer -->
  <script>
    // IntersectionObserver for scroll-reveal
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(e => {
        if (e.isIntersecting) { e.target.classList.add('is-visible'); observer.unobserve(e.target); }
      });
    }, { threshold: 0.15 });
    document.querySelectorAll('.scroll-reveal').forEach(el => observer.observe(el));

    // Dark mode: OS preference unless manually toggled
    if (!document.documentElement.dataset.theme &&
        matchMedia('(prefers-color-scheme:dark)').matches) {
      document.documentElement.dataset.theme = 'dark';
    }

    // Theme toggle handler (wire to the hamburger menu's dark mode option)
    function toggleTheme() {
      const html = document.documentElement;
      html.dataset.theme = html.dataset.theme === 'dark' ? 'light' : 'dark';
    }
  </script>
</body>
</html>
```

---

## Design system — token reference

These are the values. Inline them in the `<style>` block. The full CSS is in `docs/DESIGN_SYSTEM.md` and the design-system project; what follows is the working summary.

### Ground and chrome

| Token | Light | Dark |
|-------|-------|------|
| `--bg` | `#f0ece3` | `#1e1b16` |
| `--surface` | `#f7f4ed` | `#282420` |
| `--surface-elevated` | `#fbf9f5` | `#322e28` |
| `--ink` | `#2c2620` | `#e8e2d6` |
| `--heading` | `#3a3228` | `#d8d0c2` |
| `--muted` | `#887d6c` | `#9a9488` |
| `--caption` | `#9e9484` | `#7a7468` |
| `--line` | `#d4cab4` | `#3a3733` |
| `--accent` | `#9a6a2f` | `#c99a5c` |

No hue in chrome beyond the ochre accent. No gradients. No tinted section backgrounds.

### Typography

| Role | Face | Weight | Size |
|------|------|--------|------|
| Headings | Cabin | 700 | h1: clamp(1.85rem, 4.5vw, 2.75rem), h2: clamp(1.5rem, 3.5vw, 2rem), h3: clamp(1.2rem, 2.5vw, 1.5rem) |
| Body | Poppins | 300 | 1.0625rem, line-height 1.6 |
| Eyebrow | Poppins | 500 | 0.7rem, uppercase, letter-spacing 0.12em, accent color |
| Caption | Poppins | 300 | 0.85rem, caption color |
| Stat values | Cabin | 700 | h2 size |

### Data visualization palette

Ten hue families from the KED paper tier. Each has eight steps (01 lightest → 08 darkest).

**Domain → family mapping:**

| Domain | Family | Fill range | Text on fill |
|--------|--------|-----------|--------------|
| Soil / earth / topography | ochre | 03–05 | 07 |
| Erosion / thermal stress | ember | 03–05 | 07 |
| Water / drainage / precipitation | water | 03–05 | 07 |
| Sunlight / solar exposure | gold | 03–05 | 07 |
| Vegetation / tree cover | canopy | 03–05 | 07 |
| Shade / ground cover | understory | 03–05 | 07 |
| Species diversity | coneflower | 03–05 | 07 |
| Structures / hardscape | material-warm | 03–05 | 07 |
| Highlights only (markers) | bloom | any | — |

**Rules:**
1. One dominant family per visualization. Max three families per graphic.
2. Steps 01–02 for background tints, 03–05 for fills, 06–08 for text on fills.
3. Labels on fills use the fill's own family -07 step, not `--ink`.
4. Bloom is highlights only — a "you are here" dot, never a fill or chart series.
5. Pair every color-encoded value with a text label. Never color alone.

**Seasonal rotation** (climate section):
- Winter: water family
- Spring: canopy family
- Summer: gold family
- Fall: ember family

**Drainage class gradient** (soils section):
- Well drained: understory-03
- Moderately well: canopy-02
- Somewhat poor: gold-03
- Poorly drained: ember-03

### Shape

- Radii: 12px cards/buttons, 8px media/inputs, 999px pill tags
- Shadows: `0 12px 28px -18px rgba(44, 38, 32, 0.18)` on viz cards; `0 16px 48px rgba(44, 38, 32, 0.22)` on dialogs
- Motion: scroll-reveal only — fade + translateY(14px), 0.6s ease. Respect `prefers-reduced-motion`.

### Layout

- Single centered column, 760px max-width (`max-width: 760px; margin: 0 auto; padding: 0 1.5rem`)
- Each section: full-viewport fold (`min-height: 100svh; display: flex; flex-direction: column; justify-content: center; padding: 3rem 0`)
- Section dividers: `border-top: 1px solid var(--line-light)`
- Viz cards: elevated surface with shadow, 12px radius, 1.5rem padding

---

## Section-by-section build instructions

### Header (sticky)

```html
<header style="position:sticky;top:0;z-index:50;display:flex;align-items:center;justify-content:space-between;padding:0.75rem 1.5rem;background:var(--bg);border-bottom:1px solid var(--line-light)">
  <button onclick="/* menu toggle */" style="background:none;border:none;cursor:pointer;padding:0.5rem;color:var(--ink);font-size:20px;line-height:1" aria-label="Menu">&#9776;</button>
  <a href="https://kaleiope.design" style="text-decoration:none">
    <!-- KED wordmark SVG or text fallback -->
    <span style="font-family:Cabin,sans-serif;font-weight:700;font-size:14px;letter-spacing:0.06em;color:var(--muted)">KALEIOPE</span>
  </a>
</header>
```

### Cover

Full viewport, centered. Eyebrow "Site Assessment" in accent. `client_name` as h1. `address` as muted body. `assessment_date` as caption.

### 01 — Regional context

- Eyebrow: `01 — Regional context`
- Title: derive from ecoregion, e.g. "Your place in the {ecoregion_l3}" — adapt to actual data
- Body: `ecoregion_description`
- Stat row (added 2026-09-18): ecoregion (L3), local ecoregion (L4), river basin (HUC06), watershed (HUC12)
- Viz card: embed `regional_map_svg` inline. If null, show placeholder with canopy-01 background.
- If `neighborhood_map_svg` present: second viz card. As of 2026-09-18 this is the neighborhood *orientation* map (named streets, buildings, the parcel outlined and labeled with its address; no data display), produced by `R/illustrate/regional_orientation.R`. The contour/hydrology neighborhood graphic moved to section 03.
- Caption: "Source: EPA Level III/IV Ecoregions, NHD Flowlines. Parcel boundary from {county} GIS."

### 02 — Topography and landform

- Eyebrow: `02 — Topography and landform`
- Stat row: elevation change, max slope, parcel area — use `.stat-row` layout
- Body: `topo_description`
- Viz card: `contour_map_svg`
- If `slope_drainage_map_svg` present: second viz card
- If `slope_distribution` present: build horizontal bar chart with ochre family — ochre-02 (flat) through ochre-05 (steep). Add ember-04 legend item for erosion risk zone if `erosion_risk_pct > 0`.
- If `elevation_profile_svg` or `aspect_rose_svg` present: a two-card row (`.viz-pair`, 3:2, stacking below 600px), each with an h3 title and caption. The slope/drainage card carries an HTML `.legend` (slope classes, erosion zone, arrow key) below the graphic. Added 2026-09-17; implemented in `R/report/render_report.R`, produced by `R/illustrate/parcel_topography.R`.
- Caption: "Source: NCOneMap 1m DEM. Building footprint masked before terrain computation."

### 03 — Hydrology and drainage

- Body: `hydro_description`. Include watershed name and flood zone status.
- Stat row: watershed (HUC12 name), river basin (HUC06), FEMA flood zone, ground drains toward (dominant aspect of sloping ground)
- Zoom in, then zoom out (Peter, 2026-09-18): first card `parcel_flow_map_svg` (the section 02 contour base with flow arrows; longer = steeper), second card `hydro_map_svg` (the parcel's HUC12 tinted, boundary dashed and labeled on both sides, major reaches with flow arrows labeled "to {watershed}", roads and buildings as a quiet self-rendered base, flood polygon in ember when present)
- If flood zone is *not* "Zone X" or "Zone X (unshaded)", or `flood_zone_subtype` is anything but the minimal-hazard subtype: render a callout with ember-03 tint noting the flood designation
- Caption: cite USGS WBD, local hydrology source, FEMA NFHL, OpenStreetMap, NC footprints

### 04 — Climate and wind

- Body: `climate_description`
- Stat row (added 2026-09-18): precipitation in a year, average high of the warmest month, average low of the coldest month, prevailing wind
- Four seasonal cards in a grid:
  ```
  Winter (Nov–Jan): water-02 bg, water-06 label, water-07 value
  Spring (Feb–Apr): canopy-02 bg, canopy-06 label, canopy-07 value
  Summer (May–Jul): gold-02 bg, gold-06 label, gold-07 value
  Fall (Aug–Oct): ember-02 bg, ember-06 label, ember-07 value
  ```
  Show `seasonal_precip` values (inches in an average month of the season). If `seasonal_temp` available, show temperature below precipitation; if `seasonal_temp_high`/`_low` are present, a "high / low" line follows (2026-09-18).
- If `climate_chart_svg` present: viz card. Produced by `R/illustrate/climate_wind.R`: precipitation bars over an average high/low band, the year running November to October so each season is one contiguous block, tinted with its season family (2026-09-18).
- If `wind_rose_svg` present: additional viz card; the caption names the station (`wind_station_name`), the years and the day count, and says the roses bin the direction of each day's strongest two-minute wind (NCEI `WDF2`), not an hourly prevailing wind.
- Caption: "Source: PRISM 30-year normals (1991–2020), Oregon State University." and "Source: NOAA NCEI GHCN-Daily."

### 05 — Soils and infiltration

- Body: `soils_description`
- Stat row (added 2026-09-18): soil map unit symbol, largest soil in the unit with its share, drainage class, hydrologic soil group
- Viz card: `soil_map_svg` (the section 03 frame; units tinted by dominant drainage class, labeled with their symbol). Under it the drainage legend (understory-03 → canopy-02 → gold-03 → ember-03) and `soil_map_legend` as a list: swatch, symbol, name, "(your parcel)" where `on_parcel`.
- If `soil_profile_svg` present: second viz card, titled "The soils of map unit {symbol}, side by side"
- Table from `soil_map_units` (rewritten 2026-09-18 for real SSURGO data, where a unit is usually a *complex* of several soils whose shares describe the whole unit, not the lot): one heading per unit on the parcel (symbol, name, % of parcel), then one row per component:

  | Soil | Share | Drainage | Hydrologic group | Surface texture | K-factor | (Implication, only when any component has one) |

  Use the `.table` class. A caption explains share-of-unit, hydrologic group A–D and K-factor in one sentence each; `landform` stays in the payload but out of the table (it made the table overflow and reads as jargon).
- Caption: "Source: NRCS SSURGO via Soil Data Access."

### 06 — Microclimate

- Body: `micro_description`
- Stat row (added 2026-09-19): building footprint, sloping ground facing south, open ground in full midday sun in summer, open ground shaded 2+ hours in winter
- Viz card "The sun's path over the lot": `sun_path_svg` (optional), first card in the section (moved from 07 at review, 2026-09-19). Produced by `R/illustrate/site_synthesis.R`.
- Canopy line: if `canopy_cover_nearby_pct` is present, say tree canopy is not mapped at parcel scale and give the NLCD figure within its radius as a coarse one that includes the surrounding lots; else if `canopy_cover_pct` is null, note "Canopy cover data is not available at sufficient resolution for this parcel."
- Viz card "Summer sun and shade": `heat_accumulation_map_svg` (gold to ember heat load index from the masked DEM, understory overlay where buildings shade the ground 2+ hours at midday in summer), with an HTML legend. Produced by `R/illustrate/parcel_microclimate.R`.
- Viz card "Hours of building shade, winter and summer": `shade_map_svg`, a solstice pair with a four-class HTML legend.
- Both captions state the inferences: every building at `building_height_ft_assumed` until measured; tree shade not included; the `shade_hours_window` in solar time.
- Caption sources: NC OneMap DEM, NC building footprints; NLCD Tree Canopy Cover for the nearby figure.

### 07 — Vulnerabilities and opportunities

- Eyebrow: `07 — Vulnerabilities and opportunities`
- Body: `synthesis_narrative` — render **verbatim**. This is the practitioner's voice. The build script reads it, the two lists and the zone parameters from a gitignored notes file (`output/{slug}_notes.json` or `KED_PRACTITIONER_NOTES`), never from the repo (2026-09-19).
- No graphics (review 2026-09-19): the drafted opportunities plan was rejected (an assessment is not a design) and the sun path moved to section 06.
- If `vulnerabilities` array: render as a styled list under an h3
- If `opportunities` array: render as a styled list under an h3
- **No source citation.** This section is professional judgment, not data.

### 08 — Supporting data

- Title: "Sources and methods"
- Intro: "All data in this assessment is derived from publicly available sources. Visualizations are generated from these sources; practitioner observations are noted separately in the synthesis section above."
- Render `data_sources` as a list or table: name as linked text (`<a href="{url}">`), access date in caption color
- Include the epistemic disclosure: "This assessment infers site-specific conditions from the most granular regional data available. It does not constitute a site-specific survey."

### Footer

```html
<footer style="border-top:1px solid var(--line);padding:2rem 1.5rem;text-align:center">
  <div style="font-size:0.85rem;color:var(--caption)">
    <a href="https://kaleiope.design" style="color:var(--caption);text-decoration:none">KALEIOPE Environmental Design</a>
  </div>
  <div style="font-size:0.8rem;margin-top:0.25rem">
    <a href="mailto:info@kaleiope.design" style="color:var(--accent)">info@kaleiope.design</a>
  </div>
</footer>
```

---

## SVG / image embedding

Visualizations from the R pipeline arrive as inline SVG strings or base64-encoded PNGs.

- **Inline SVG**: Place directly inside the `.viz-card` div. Ensure `width="100%"` and wrap in a div with `border-radius: 8px; overflow: hidden`.
- **Base64 PNG**: `<img src="data:image/png;base64,..." style="width:100%;border-radius:8px">`
- **Null/missing**: Placeholder div:
  ```html
  <div style="background:var(--{family}-01);aspect-ratio:5/3;border-radius:8px;display:flex;align-items:center;justify-content:center;color:var(--{family}-05);font-size:0.85rem">
    Data not available for this parcel
  </div>
  ```
  Use the section's dominant color family for the placeholder tint.

---

## Content rules

1. **Do not invent data.** Every number, map, and claim comes from the payload.
2. **Do not rewrite practitioner text.** `synthesis_narrative`, `vulnerabilities`, `opportunities` are the practitioner's voice. Format (paragraphs, lists) but do not edit the words.
3. **Pre-translated descriptions** (`*_description` fields) are already in plain language. Use directly.
4. **Source transparency.** Every data section links to its source.
5. **Honest about absence.** Note missing data explicitly. Don't hide gaps.
6. **No marketing language.** Avoid: "sustainable," "eco-friendly," "lush," "transform," "curated," "bespoke," "elevate." Direct, specific, ecologically literate.
7. **No emoji.** Not in text, not as bullets, not as decoration.

## Print

Include print styles:

```css
@media print {
  body { background: white; color: #2c2620; }
  .scroll-reveal { opacity: 1 !important; transform: none !important; }
  header { position: static; }
  .viz-card { break-inside: avoid; box-shadow: none; border: 1px solid #d4cab4; }
  section { min-height: auto; page-break-before: always; }
  section:first-of-type { page-break-before: auto; }
}
```

## Responsive

- Seasonal grid: `grid-template-columns: repeat(4, 1fr)` → `repeat(2, 1fr)` below 500px
- Stat row: flex-wrap handles naturally
- Tables: wrap in `<div style="overflow-x:auto">` below 600px
- Viz cards: full width, padding from the `.wrap` container
