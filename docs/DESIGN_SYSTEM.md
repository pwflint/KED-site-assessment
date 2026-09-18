---
author: peter
created: '2026-07-28'
modified: '2026-09-17'
status: development
tags:
  - domain/design
  - domain/data-science
title: Site Assessment — Output Design System
type: project
---
# Output Design System

This document is the **design system specification** for the client-facing site assessment deliverable. It covers page chrome, typography, color, layout, data visualization palette, and component inventory. It is deliberately separate from `docs/ILLUSTRATION_NOTES.md`, which covers *what data goes into* each illustration and the judgment calls behind it.

**Status:** Active development. Built in a dedicated design-system project (Omelette) that merges the KED marketing system's paper-tier palette with a warmer, engagement-first ground. The system is the binding visual reference for any agent generating report output.

**Origin:** The KED marketing site is monochrome chrome — black, white, neutral gray. The site assessment product breaks from that intentionally: the document is warmer, more engaging, and uses color purposefully for data differentiation. The paper-tier color families from the KED spec package (originally designed as Vectorworks fills) become the data visualization palette. The marketing system's Amatic SC display face is replaced with Cabin — a humanist sans that reads as calm and professional for an assessment context.

**Design system project:** The full token set, component classes, specimen pages, and a scrollytelling template live in the Omelette design-system project titled "KED Site Assessment." Any agent building report output should bind that design system and use its tokens and classes rather than inventing values.

---

## Design principle

**The page's accent color comes from the data, not from a separate brand decision.** The UI accent (`#9a6a2f`, a warm ochre) is the same color used for watershed-boundary lines in the map illustrations. Page chrome — eyebrow labels, links, focus rings — speaks the same color language as the visualizations. If the data palette changes, the accent follows.

---

## Color

### Ground and chrome

| Token | Light | Dark | Use |
|---|---|---|---|
| `--bg` | `#f0ece3` | `#1e1b16` | Page background — warm stone |
| `--surface` | `#f7f4ed` | `#282420` | Card/section backgrounds |
| `--surface-elevated` | `#fbf9f5` | `#322e28` | Viz card backgrounds |
| `--ink` | `#2c2620` | `#e8e2d6` | Primary text |
| `--heading` | `#3a3228` | `#d8d0c2` | All headings |
| `--muted` | `#887d6c` | `#9a9488` | Secondary text |
| `--caption` | `#9e9484` | `#7a7468` | Captions, source citations |
| `--line` | `#d4cab4` | `#3a3733` | Borders, dividers |
| `--accent` | `#9a6a2f` | `#c99a5c` | Links, eyebrows, focus rings |

No brand hue in chrome beyond the ochre accent. No gradients, no tinted section backgrounds.

### Data visualization palette — paper tier

Ten hue families × eight steps (01 lightest → 08 darkest), each named for a landscape element:

| Family | Data domain | Typical fill range |
|---|---|---|
| Ember | Erosion risk, thermal stress, soil heat | 03–05 |
| Ochre | Earth, grade, topography | 03–05 |
| Gold | Sunlight, solar exposure | 03–05 |
| Canopy | Tree cover, vegetation | 03–05 |
| Groundcover | Turf, sedum, lowest layer | 03–05 |
| Understory | Shade, fern, deep cover | 03–05 |
| Chicory | Reserved | 03–05 |
| Coneflower | Species diversity, bloom | 03–05 |
| Water | Hydrology, drainage, precipitation | 03–05 |
| Bloom | Bright highlights only — never fills | any |

**Step rules:** 01–02 for background tints. 03–05 for primary fills (readable on the warm ground). 06–08 for text labels on filled areas.

**Screen-tier accents** (full-strength: `--screen-ember`, `--screen-canopy`, `--screen-water`, etc.) are for emphasis inside visualizations only — callout highlights, active data points. Never for backgrounds or chrome.

### Semantic aliases

Pre-mapped tokens for the most common data domains:

```
--viz-soil       (ochre-04)
--viz-erosion    (ember-04)
--viz-water      (water-04)
--viz-sun        (gold-04)
--viz-vegetation (canopy-04)
--viz-shade      (understory-04)
--viz-diversity  (coneflower-04)
--viz-cost       (ochre-05)
```

Each also has `-fill` (step 02, for light tints) and `-text` (step 07, for labels on fills) variants.

---

## Typography

| Role | Face | Weight | Size |
|---|---|---|---|
| Display / headings | Cabin | 700 | `--size-h1` through `--size-h3` (fluid clamps) |
| Body | Poppins | 300 | 1.0625rem / 1.6 line-height |
| Eyebrow labels | Poppins | 500 | 0.7rem, uppercase, 0.12em tracking |
| Captions | Poppins | 300 | 0.85rem |
| Stat values | Cabin | 700 | `--size-h2` |
| *(report override, 2026-09-18)* Stat values | Cabin | 700 | `--size-h3`, label above value — set in `R/report/render_report.R`, not yet synced to the design project |
| Chart axis labels | Poppins | 400 | `--size-small` |
| Chart titles | Cabin | 700 | `--size-h3` |

Cabin loaded via Google Fonts. Poppins self-hosted from font files.

---

## Layout

- Single centered column at 760px (`--measure`), with 960px (`--measure-wide`) for wide visualizations
- Each report section is a full-viewport scroll fold (`.scroll-section`)
- Generous vertical rhythm: 5.5rem between sections (`--space-8`)
- Every visualization sits in a `.viz-card` — elevated surface with subtle shadow
- Numbered eyebrow labels above each section ("01 — Regional context")
- Sticky header with hamburger nav (left) and KED wordmark (right)
- Subtle footer: company name linked to website, info@ email

---

## Shape and elevation

- **Radii:** 12px cards and buttons, 8px media and inputs, 999px pills for tags
- **Elevation:** `--shadow-viz` on viz cards, `--shadow-dialog` on modals, no shadow at rest on content cards
- **Motion:** Scroll-reveal animation (fade + rise 14px, 0.6s), color transitions at 0.2s. Respects `prefers-reduced-motion`. No transforms, scale, bounce, or parallax.

---

## Icons

Lucide icons where functional (navigation, export, theme toggle). Stroke-width 2, `currentColor`. No decorative icons, no emoji.

---

## Data visualization directions

### General rules

1. **One dominant family per visualization.** A soil chart uses ochre; a drainage map uses water. Second family for comparison. Three families maximum per graphic.
2. **Step consistency.** Same step range across all categories in a graphic.
3. **Labels on fills** use the -07/-08 step of the fill's own family, not `--ink`.
4. **Bloom is highlights only** — a marker, a data point. Never a fill.
5. **Pair color with text.** Never color alone.
6. **White/elevated surfaces frame visualizations** — every graphic in a `.viz-card`.

### By section

- **Regional Orientation:** Canopy-02 fill, water-04 rivers, bloom-05 parcel marker
- **Topography:** Ochre family for slope categories (01 flat → 05 steep)
- **Hydrology:** Water family throughout, ember-03 for flood zones
- **Climate:** Rotate by season — Water (winter), Canopy (spring), Gold (summer), Ember (fall)
- **Soils:** Ochre fills, understory → ember gradient for drainage quality
- **Microclimate:** Gold → Ember for heat accumulation, canopy for tree cover
- **Species Diversity:** Coneflower primary, canopy secondary
- **Budget:** Ochre-05 base, gold for comparisons

---

## Dark mode

Both light and dark themes defined via CSS custom properties, toggled by `data-theme="dark"` on `:root`. For automatic OS detection, include:

```js
if (!document.documentElement.dataset.theme && matchMedia('(prefers-color-scheme:dark)').matches) document.documentElement.dataset.theme = 'dark';
```

---

## Components

| Class | Purpose |
|---|---|
| `.wrap` / `.wrap-wide` | Centered content measure |
| `.eyebrow` | Numbered section label |
| `.scroll-section` | Full-viewport story fold |
| `.viz-card` + `.viz-caption` | Illustration container |
| `.stat` + `.stat-value` + `.stat-label` + `.stat-row` | Metric callout |
| `.legend` + `.legend-item` + `.legend-swatch` | Data legend |
| `.btn` + `.btn-primary/secondary/ghost` | Actions |
| `.card` | Content card |
| `.table` | Data table |
| `.dialog-backdrop` + `.dialog` | Modal overlay |
| `.tag` + `.tag-soil/water/vegetation/sun/erosion/diversity` | Domain tags |
| `.scroll-reveal` | Scroll entrance animation |

---

## Open questions (carried from prior version)

1. Content hierarchy untested beyond two sections — how does this hold with 5–8 sections, sub-navigation, or a table of contents?
2. Mobile/narrow-viewport treatment not yet tested
3. Print/export treatment for 11×17 tabloid not built
4. Whether HTML interactivity supersedes the printed format
