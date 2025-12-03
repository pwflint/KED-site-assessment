---
title: Site Assessment Report
author: Peter W. Flint
date: 2025-12-02
note-type: development
status: open
keywords: []
tags: []
aliases:
---
The site assessment is the first step in the design process. The site assessment report is the deliverable product as a result of local and contextual analysis.

Output: 11x17 document or interactive document adapted to a tablet in landscape mode. 

## Report Outline

### **Cover Sheet**

**Purpose:** Establish the report as a professional environmental record.  
**Contents:**

```
---------------------------------------------------
| HEADER: Project Title / Logo / Date             |
|-------------------------------------------------|
| Center Block:                                  |
|   Client Name                                  |
|   Site Address                                 |
|   Lat/Long Coordinates                         |
|   Prepared by / Firm Name                      |
|-------------------------------------------------|
| Footer Sidebar:                                |
|   Data Sources (short list)                    |
|   Small Locator Map Thumbnail (state > parcel) |
---------------------------------------------------
```

- **Client name / project title**
    
- **Site address** (with parcel ID if available)
    
- **Latitude & longitude** (decimal degrees)
    
- **Date of assessment**
    
- **Prepared by / firm name**
    
- **Data sources summary** (brief list, e.g., “USGS DEM, NRCS SSURGO, PRISM Climate Normals 1991–2020, NOAA NCEI Wind Data, EPA Ecoregions, USGS NHD, FEMA Flood Zones”)
    
- Small **site locator map** thumbnail


_Design note:_ clean layout, minimal text, emphasize accuracy and transparency. A visual cue (logo or color band) can set the tone for the whole document.

**Layout:** Simple vertical hierarchy

- Header band with project name and logo
    
- Centered block: client, address, lat/long, date
    
- Sidebar or footer: list of data sources
    
- Small locator map thumbnail (e.g., state → region → parcel inset)
    

**Design logic:** communicates credibility and transparency in one glance

---

### **1. Regional Orientation and Context**

**Purpose:** Situate the parcel ecologically and geographically.  
**Content Blocks:**
```
---------------------------------------------------
| Left Page: Regional Map                        |
|   - Ecoregion color overlay                    |
|   - Watershed boundary                         |
|   - Major landmarks                            |
|   - Parcel outline                             |
|-------------------------------------------------|
| Right Page:                                    |
|   Regional Summary Panel                       |
|     - Watershed name & stats                   |
|     - Ecoregion description                    |
|     - Elevation / Climate summary              |
|   Text Block: interpretive paragraph           |
---------------------------------------------------
```

- **Regional Context Map** — parcel outlined within:
    
    - Watershed boundary
        
    - Ecoregion boundary (EPA Level III/IV)
        
    - Major geographic landmarks (rivers, cities, ridges)
        
- **Summary Panel:**
    
    - Watershed name & size
        
    - Ecoregion description (one paragraph)
        
    - Elevation range of region
        
    - Average annual precipitation & temperature
        
- **Interpretive Note:**
    
    - Short paragraph linking regional setting to landscape character (“The site lies in the transition between the Piedmont uplands and the Triassic Basin, with rolling topography and mixed hardwood-pine vegetation.”)
        

_Visualization Suggestions:_

- Map 1: regional inset with color-coded ecoregions
    
- Map 2: watershed boundary + parcel
    
- Include scale bars and north arrow for orientation

**Layout:** Two-page spread

- **Left page:** Regional context map (parcel outlined within watershed/ecoregion)
    
- **Right page:** Text panel + climate summary box
    

**Visualization options:**

- Multi-scale map: large regional extent, smaller inset zoom
    
- Overlay transparent ecoregion colors + watershed outlines
    
- Simple icons for temperature, precipitation, elevation range
    

**Purpose:** to visually “place” the site in a larger environmental and geographic frame.

---

### **2. Topography and Landform**

**Purpose:** Describe how elevation and slope shape water movement and microclimate.  
**Content Blocks:**

```
---------------------------------------------------
| Top Half: Shaded Relief Map w/ Contours        |
|-------------------------------------------------|
| Lower Left: Slope Map (color gradient)         |
| Lower Center: Aspect Map (directional)         |
| Lower Right: Cross-section profile             |
|-------------------------------------------------|
| Sidebar: Metrics Table + 1-paragraph summary   |
---------------------------------------------------
```

- **Digital Elevation Map (DEM)** — shaded relief with parcel outline
    
- **Slope Map** — color-coded gradient (0–5%, 5–15%, 15%+)
    
- **Aspect Map** — directional shading (north/south/east/west exposure)
    
- **Topographic Section** — simple cross-section through key elevation gradient
    

**Metrics Table (small):**

|Parameter|Value|
|---|---|
|Elevation range|___ ft|
|Average slope|___ %|
|Dominant aspect|___|

**Interpretive Text:**

- Describe terrain form and implication (“The site’s north-facing slope suggests cooler, moister soil conditions, with runoff concentrating toward the southeastern low point.”)
    
**Layout:** One page

- Upper half: shaded relief map + contour lines
    
- Lower half: slope and aspect mini-maps side by side
    
- Right column: metrics table + interpretive paragraph
    

**Visualization options:**

- Subtle hillshade backgrounds
    
- Color-coded slope (greens → browns → reds for steep)
    
- Aspect wheel legend (N/S/E/W tones)


---

### 3. Hydrology and Drainage
**Purpose:** Explain how water enters, moves through, and exits the property.  
**Content Blocks:**

```
---------------------------------------------------
| Main Map: Drainage Flow & Flood Zones          |
|   - Flow arrows                                |
|   - Stream lines (blue)                        |
|   - Depressions highlighted                    |
|-------------------------------------------------|
| Below Map: Local section (A–B profile)         |
| Sidebar: Runoff potential chart + notes        |
---------------------------------------------------
```



- **Watershed Flow Map** — parcel with local drainage network and flow direction arrows
    
- **Flow Accumulation / Runoff Zones** — highlight high-flow areas or depressions
    
- **Floodplain Overlay** (if applicable)
    
- **Nearby Hydrologic Features** — streams, wetlands, storm drains
    

**Metrics Table:**

|Parameter|Value|
|---|---|
|Drainage direction|___|
|Nearest perennial stream|___ distance|
|Hydrologic soil group|___|

**Interpretive Text:**

- “Water drains southeast toward a tributary of ___ Creek. Moderate slopes and well-drained soils indicate good infiltration potential except in the central swale.”

**Layout:** One page

- Central map showing flow direction, local drainage lines, flood zones
    
- Side column with infiltration summary and runoff potential chart
    
- Small cross-section showing drainage gradient (from DEM)
    

**Visualization options:**

- Blue flow lines thickening with accumulation
    
- Transparent floodplain overlay
    
- Arrow symbology for flow direction
    

**Goal:** show water behavior at a glance.


---

### 4. Climate and Wind
**Purpose:** Present regional climate norms and wind patterns visually.  
**Content Blocks:**

```
---------------------------------------------------
| Left Page: Visualizations                      |
|   - Wind Rose (centered)                       |
|   - Precipitation/Temperature Chart            |
|   - Seasonal Moisture Index Bar                |
|-------------------------------------------------|
| Right Page:                                    |
|   Metrics Table (annual means, frost-free etc) |
|   Narrative summary of climate patterns        |
---------------------------------------------------
```


- **Wind Rose Diagram** — direction and frequency by season
    
- **Precipitation and Temperature Chart** — monthly averages (dual-axis)
    
- **Moisture Index Bar or Climate Signature Diagram** — ratio of precipitation to evapotranspiration
    
- **Temperature Range Summary** — mean, high, low, frost-free days
    

**Metrics Table:**

|Parameter|Value|
|---|---|
|Annual precip|___ in|
|Mean annual temp|___ °F|
|Frost-free period|___ days|
|Predominant wind direction|___|
|Avg wind speed|___ mph|

**Interpretive Text:**

- Relate seasonal climate patterns to ecological processes and comfort (“Summer rainfall peaks in July–August; prevailing SW winds offer potential for ventilation and influence soil moisture patterns.”)

**Layout:** Two-page spread

- **Left page:** wind rose, precipitation-temperature dual-axis chart
    
- **Right page:** text and interpretive climate summary
    

**Visualization options:**

- Wind rose in polar coordinates (clean radial chart)
    
- Monthly precipitation bars + temperature line
    
- Icons for frost period, seasonality cues
    

**Goal:** make the temporal pattern of weather immediately legible.

---

### 5. Soils and Infiltration
**Purpose:** Describe soil behavior and implications for drainage and vegetation.  
**Content Blocks:**

```
---------------------------------------------------
| Top: Soil Map (SSURGO polygons + legend)       |
|-------------------------------------------------|
| Lower Left: Infiltration Class Map             |
| Lower Right: Soil Profile Diagram              |
|-------------------------------------------------|
| Sidebar: Table (texture, drainage class)       |
| Text Box: Interpretive summary                 |
---------------------------------------------------
```

- **Soil Map** — SSURGO polygons labeled by map unit
    
- **Drainage / Infiltration Class Map** — simplified color scheme
    
- **Soil Profile Diagram** — representative vertical section
    

**Metrics Table:**

|Soil Unit|Texture|Drainage Class|Hydrologic Group|
|---|---|---|---|
|Example A|Sandy loam|Well-drained|B|
|Example B|Silty clay|Poorly drained|D|

**Interpretive Text:**

- “Soils are predominantly well-drained loams of moderate permeability, suitable for infiltration-based stormwater design. Lower terraces exhibit higher clay content and slower percolation.”

**Layout:** One page

- Upper half: soil polygon map with legend
    
- Lower half: infiltration class map or cross-section
    
- Right side: soil table + short narrative
    

**Visualization options:**

- Simplified color palette (texture families)
    
- Pattern fill for hydrologic groups
    
- Section diagram with layers labeled (A/B horizons)
    

**Goal:** link soil behavior to hydrology and planting potential.

---

### 6. Site Vulnerabilities and Opportunities
**Purpose:** Combine analyses into a spatial synthesis.  
**Content Blocks:**

```
---------------------------------------------------
| Left Page: Composite Overlay Map               |
|   - Combined slope + soil + drainage layers    |
|   - Highlighted opportunity/risk zones         |
|-------------------------------------------------|
| Right Page:                                   |
|   Callout Boxes with notes                    |
|   2–3 short paragraphs synthesizing insights  |
---------------------------------------------------
```



- **Composite Analysis Map** — overlays slope, drainage, and soil to identify:
    
    - Flood-prone zones
        
    - Erosion-prone slopes
        
    - Drought-prone areas (e.g., thin soils, southern exposure)
        
- **Opportunities Layer** — flatter, well-drained, solar-accessible areas suitable for development or planting
    
- **Callout Boxes** for each key insight:
    
    - “Area A: Seasonal water accumulation”
        
    - “Area B: High solar exposure, well-drained soils”
        

**Interpretive Text:**

- A short narrative connecting physical patterns to design potential (“High ground in the northwest corner offers ideal planting conditions, while lower eastern areas require moisture management.”)
    

**Layout:** Two-page spread (the synthesis)

- Left page: composite overlay map (slope + drainage + soil)
    
- Right page: annotated callouts and interpretive narrative
    

**Visualization options:**

- Semi-transparent overlays revealing zones of opportunity/risk
    
- Simple icons or callout markers
    
- “Traffic light” palette (green = stable, yellow = moderate risk, red = high risk)
    

**Goal:** show where the land’s dynamics suggest action or restraint.


### 7. Supporting Data Tables
**Purpose:** Present the quantitative backbone of the report for transparency.  
**Content Blocks:**

```
---------------------------------------------------
| Climate Normals Table                         |
| Wind Data Table                               |
| Soil Data Table                               |
|-------------------------------------------------|
| Source Reference Table (dataset / year / use) |
---------------------------------------------------
```

- **Climate Normals Table** (temperature, precipitation, evapotranspiration by month)
    
- **Wind Data Table** (mean and max speeds, direction frequency)
    
- **Soil Data Table** (as above)
    
- **Summary of Data Sources** (table with dataset name, source, scale, and citation)
    

Example:

|Dataset|Source|Resolution|Year|Use|
|---|---|---|---|---|
|PRISM Climate Normals|PRISM / Oregon State|800 m|1991–2020|Temperature, precipitation|
|NRCS SSURGO|USDA|Polygonal|2023|Soil texture, drainage|
|USGS DEM|USGS|10 m|2024|Elevation, slope|
|NHD|USGS|Line|2023|Streams, waterbodies|
**Layout:** Single or facing page spread

- Plain, clean tables with grid lines removed for readability
    
- Data source summary below (like a bibliography)
    

**Goal:** provide transparency and allow cross-checking of derived metrics.

---

### 8. Summary and Next Steps
**Purpose:** Present the quantitative backbone of the report for transparency.  
**Content Blocks:**

```
---------------------------------------------------
| Text Block: Key Findings Summary               |
| Checklist: Recommended Next Steps              |
| Sidebar: “At-a-Glance” metrics snapshot        |
---------------------------------------------------
```


- **One-page narrative** summarizing the site’s environmental character:
    
    - Key assets (solar, drainage, soil)
        
    - Constraints (erosion risk, flooding, exposure)
        
    - Opportunities for design (infiltration zones, habitat enhancement)
        
- **Suggested Next Steps:**
    
    - Detailed site inventory and analysis
        
    - On-site soil testing and microclimate observation
        
    - Integration into concept design phase

**Layout:** One page

- Short narrative in top two-thirds
    
- Bottom third: “Next Steps” checklist
    
- Optional sidebar with key metrics snapshot (“At a Glance”)
    

**Design tone:** calm and conclusive — transitions from assessment to design.

---

### Appendices
```
---------------------------------------------------
| Raw Data Tables / Glossary / References        |
---------------------------------------------------
```

- Glossary of environmental terms
    
- References and metadata for datasets
    
- Regional climate anomaly maps (if you want to show trends)

**Layout:** plain and utilitarian

- Charts or raw data exports
    
- Glossary of terms

