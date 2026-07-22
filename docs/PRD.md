# Product Requirements Document
## KALEIOPE Site Assessment — v1
**Prepared by:** Maia (PRD Discovery Assistant, KALEIOPE AI Practice)  
**Discovery session:** June 8, 2026  
**Status:** v1 — Ready for build planning  
**Primary audience:** Daedalus (build agent), Plan Agent (site assessment project)  
**Repo:** https://github.com/pwflint/KED-site-assessment

---

## 1. Executive Summary

### Problem Statement
Homeowners interested in ecologically grounded landscape design have no accessible, affordable way to understand their site's actual environmental conditions before committing to a full design process. Design decisions are made against aesthetics, convention, and contractor availability rather than site-specific data. The consequences — poor stormwater management, urban heat island contribution, biodiversity loss, ecologically inappropriate planting — accumulate at the neighborhood and watershed scale.

### Solution Overview
A data-augmented site assessment product that situates a layperson in their ecoregional context using publicly available environmental data, visualized in terms legible to a non-technical audience. Delivered as an interactive HTML document (with print-to-PDF capability) following a site visit. Priced at $200 — the entry point to a tiered service model that makes professional ecological design accessible at a range of commitment levels.

### Product Position in Service Model
The site assessment is milestone one in a tiered service sequence:

| Milestone | Product | Price |
|-----------|---------|-------|
| 1 | Site Assessment | $200 |
| 2 | Concept Design | TBD |
| 3 | Full Design Services | $3,000–$5,000 |

The assessment converts the full-services commitment into a sequence of smaller, standalone-value steps. It answers the client's implicit question — "Is my idea feasible, and is this the right practitioner for me?" — before either party is locked in.

### Success Metrics
**Primary:** Site assessment generates a request for full design services estimate — client found the assessment credible and wants to proceed.

**Secondary (valid outcome, business loss):** Assessment honestly refutes the client's vision; client does not proceed. This is the product working correctly as an ecological filter, not a product failure.

**Failure mode:** Client receives a beautiful document, says thank you, and proceeds with a conventional landscaper anyway — indicating the report failed to shift how they think about their site.

**Key constraint:** Total practitioner time per assessment must not exceed two hours, including travel, site visit, annotation, and report generation.

### Key Constraints
- Total practitioner time: ≤ 2 hours per assessment (including travel)
- Price point: $200
- Primary geography: NC Piedmont; secondary: NC mountains and coast
- Build environment: R/Quarto pipeline, Cursor as build agent
- Solo practitioner product in v1; designed with awareness of future multi-practitioner scalability

---

## 2. User Context

### Primary Users

**The Practitioner (Peter / future practitioners)**
The practitioner uses the product in two modes: as a pre-visit brief (internal) and as a post-visit client deliverable (external). In v1, the practitioner is the sole author of the annotation and synthesis layers. Technical fluency: comfortable with R, Quarto, and Cursor-assisted development. Domain expertise: ecological landscape design, ecoregional analysis, site hydrology, soil science.

**The Client**
A homeowner with genuine curiosity about their landscape and some openness to an ecological approach. Already past "sod and boxwoods." Perceives that their situation is more complex than they initially realized. Not yet ready to commit $3,000–$5,000 to full design services. Likely has a specific idea or program in mind — a garden, a habitat area, a drainage solution — that they want to test against site reality.

The client is not a technical user. They should be able to read the report without guidance and understand what their site is actually doing environmentally. Visualizations must translate technical data into human-scale terms: drainage behavior, heat accumulation, water movement.

### User Journey

```
Lead contacts via website form
        ↓
Practitioner follows up by email/phone, confirms address
        ↓
Site assessment sale confirmed
        ↓
[PIPELINE: Phase 1] Public data acquisition runs against address + coordinates
        ↓
Practitioner receives pre-visit brief — data summary + gap checklist
        ↓
Practitioner travels to site, conducts visit (≤ 45 min)
        ↓
Practitioner records voice memo in truck — annotations + vulnerabilities/opportunities
        ↓
[PIPELINE: Phase 2] Annotation layer applied; synthesis section polished algorithmically
        ↓
Client receives finished report — interactive HTML, print option
        ↓
Client has 12-month access window to explore report and decide on next steps
```

### Interaction Patterns
- Practitioner interacts with the pipeline primarily via address/coordinates input and annotation input
- Client interacts with the finished report independently, without the practitioner present
- Report must stand alone — client legibility cannot depend on practitioner explanation
- Client may share the report with others (contractors, family members) — it must be self-explanatory

---

## 3. Product Architecture

### Two-Mode Pipeline

The product operates in two distinct modes sharing a common data acquisition layer.

**Mode 1 — Pre-Visit Brief (internal)**
- Input: address, coordinates
- Output: structured summary of public data findings + gap checklist for field confirmation
- Audience: practitioner only
- Purpose: arrive at site knowing what the data says and what it couldn't resolve
- Timing: generated before site visit

**Mode 2 — Post-Visit Client Deliverable (external)**
- Input: public data layer + practitioner annotation layer
- Output: interactive HTML report with print-to-PDF capability
- Audience: client
- Purpose: make site-specific environmental conditions legible; support or refute client's program ideas
- Timing: generated after site visit, delivered to client

### Three Data Layers

**Layer 1 — Public Data**
Acquired automatically from public sources against address and coordinates. Forms the backbone of both modes. All visualizations in the client deliverable are generated from this layer.

**Layer 2 — Annotation**
Practitioner-authored calibrations and corrections to the public data layer. Applied after the site visit. In v1, authored as voice memos and field notes, converted to text, and applied editorially. Does not appear in the client report as raw field notes — informs the interpretive framing of the public data.

**Layer 3 — Synthesis**
The vulnerabilities and opportunities section. Authored by the practitioner as a voice memo after the site visit, algorithmically polished (grammar, structure, clarity). Represents the practitioner's professional judgment synthesizing data findings, site observations, and client program. This section is the primary locus of ecological design guidance in the report.

---

## 4. Data Requirements

### Priority Tier 1 — Required for Pre-Visit Brief

These sources must function reliably. If any Tier 1 source fails, the pre-visit brief is not viable.

| Source | Data | Package / API | Current Status |
|--------|------|---------------|----------------|
| Parcel / base map | Parcel boundary, address, basic context | `osmdata` (OSM Overpass API) | Not yet implemented |
| DEM — 1m | Topography, slope, aspect, hillshade | NCOneMap WCS (`https://services.nconemap.gov/`) | Research complete; not implemented |
| Soils — SSURGO | Soil map units, drainage class, infiltration, erodibility | `FedData` + `soilDB` | Spatial acquisition partial; property extraction not implemented |
| Ecoregion — EPA Level III/IV | Regional ecological context | EPA shapefile or API | Not yet implemented |

**Note on DEM:** Current repo implementation uses `elevatr` at 10m resolution via USGS 3DEP. Target is 1m from NCOneMap. This substitution must be made before production use.

### Priority Tier 2 — Required for Client Deliverable

These sources complete the full report. Graceful failure (null handling, absent section) is acceptable; report ships without the section rather than blocking.

| Source | Data | Package / API | Current Status |
|--------|------|---------------|----------------|
| Climate — PRISM 30-yr normals | Seasonal temperature and precipitation baselines | `prism` package | Blocked — `prism_archive_subset()` returns empty structure; needs debug |
| Wind | Seasonal wind patterns for wind rose | `rWind` (GFS 50km grid) | Research complete; seasonal averaging approach unresolved |
| Watershed — HUC 06/12 | Watershed hierarchy and context | `nhdplusTools` / WBD direct | Blocked — 404 errors; WBD as alternative not tested |
| Flood zones | FEMA flood zone designation | FEMA ArcGIS REST | Blocked — 404 errors; correct layer unknown |
| Canopy height | Canopy geometry and height (optional) | USGS 3DEP LiDAR / NASA GEDI | Deferred; optional for v1 |

### Data Source Validation Requirement
All data sources listed above must be re-validated before implementation begins. The DATA_SOURCE_RESEARCH notes are from December 2025. Six months of API drift, endpoint changes, and package updates may have altered source availability and behavior.

**Percy recommendation:** Before the Plan Agent begins data acquisition implementation, call Percy to conduct a current validation pass on each source — confirm endpoints are live, packages are current, and no superior alternatives have emerged. Particular attention to: NCOneMap WCS authentication requirements, PRISM package debug path, NHDPlus / WBD alternatives, FEMA REST correct layer identification.

### Derived Data Requirements
The following data products are derived from Tier 1 sources and must be computed in the processing layer:

- Slope and aspect rasters (from DEM)
- Hillshade (from DEM, for visualization)
- Flow accumulation / drainage direction (from DEM)
- Drainage class interpretation from SSURGO map units (well-drained / moderately drained / poorly drained / very poorly drained)
- Soil erodibility interpretation from SSURGO K-factor
- Soil nutrition / fertility interpretation from SSURGO organic matter and CEC values
- Plan-view heat accumulation proxy (from aspect + canopy cover; algorithmic approximation)
- Canopy geometry (2D footprint and approximate height where available)

### Field Input Variables
The following variables cannot be derived from public data and must be confirmed or captured during the site visit. The pre-visit brief should surface these explicitly as a gap checklist.

**Likely gap variables (to be validated during prototyping):**
- Canopy presence, condition, and approximate height where lidar is absent or outdated
- Impervious surface extent and condition (where parcel-level data is unavailable)
- Drainage anomalies not reflected in DEM (fill, berms, hardscape drainage)
- Structure height (for airflow and shading modeling)
- Existing vegetation condition (health, invasive presence)
- Observable soil surface conditions (compaction, erosion, organic matter)

**Not required for v1 field capture:**
- House color / albedo (noted as future consideration for microclimate modeling)
- Systematic photos for image analysis (future consideration)
- Soil probe measurements
- Clinometer readings

---

## 5. Report Sections and Visualization Requirements

### Report Structure

| Section | Content | Primary Data Source | Mode |
|---------|---------|---------------------|------|
| Cover | Client name, address, date, KED identity | Metadata | Both |
| Regional Orientation | Ecoregion context, regional map | EPA ecoregions, OSM | Both |
| Topography and Landform | Slope, aspect, hillshade, elevation | DEM (NCOneMap 1m) | Both |
| Hydrology and Drainage | Watershed context, flow direction, flood zone | NHDPlus / WBD, FEMA | Deliverable |
| Climate and Wind | Seasonal temperature/precipitation, wind rose | PRISM, rWind | Deliverable |
| Soils and Infiltration | Soil map units, drainage, erodibility, profile | SSURGO | Both |
| Microclimate | Heat accumulation proxy, canopy geometry, airflow | DEM + canopy + structure | Deliverable |
| Vulnerabilities and Opportunities | Practitioner synthesis | Practitioner-authored | Deliverable |
| Supporting Data Tables | Source data, citations, links to primary sources | All | Deliverable |

### Visualization Concepts by Section

**Topography and Landform**
- Hillshade map of parcel and immediate context
- Slope map with human-legible categories (flat / gentle / moderate / steep)
- Aspect map or rose diagram showing directional exposure
- Elevation profile if topographic variation is significant

**Soils and Infiltration**
- Isometric block diagram of parcel showing soil map units in plan view
- Soil profile section showing horizons for dominant map unit(s), labeled in plain language
- Drainage class table: map unit → drainage behavior → implication for design
- Erodibility and infiltration summary in plain language, not technical indices

**Climate and Wind**
- Seasonal bar charts / histograms for temperature and precipitation (30-year normals)
- Four-season layout: Winter (Nov–Jan), Spring (Feb–Apr), Summer (May–Jul), Fall (Aug–Oct)
- Wind rose diagram by season

**Microclimate**
- Plan-view heat accumulation map derived from aspect and canopy cover
- Canopy geometry overlay showing 2D footprint and height categories
- Building footprint and approximate height for airflow context
- Plain-language interpretation: "This section of the property accumulates heat in summer due to [reason]"

**Regional Orientation**
- NC state inset map showing ecoregion with parcel highlighted
- Local context map showing watershed, adjacent land cover, urban context

**Note on visualization testing:** All visualization concepts require prototyping against variable parcel geometries, data availability states (missing sources, uniform soil, flat topography), and ecoregional contexts outside the Piedmont. Visualization failure modes must be designed before production use.

### Plain Language Requirement
Every visualization must be accompanied by an interpretive sentence or short paragraph in plain language. The visualization shows the data; the text explains what it means for this site. Technical indices (K-factor, infiltration rate in cm/hr, PRISM grid cell ID) do not appear in client-facing content — only their plain-language translations.

### Data Source Transparency
Every data-derived claim in the report is linked to its source. If a client wants to verify a finding independently, they can follow the link to the originating dataset. This is a trust architecture requirement, not optional.

---

## 6. Output Format Requirements

### Primary Deliverable — Interactive HTML
- Hosted for client access for 12 months from assessment date
- Responsive layout for desktop and mobile
- Interactive elements (scope to be determined during prototyping, but at minimum): map zoom and pan, layer toggling on spatial visualizations, data table filtering, linked data source citations
- Client receives access link via email
- No login required for client access (link-based access)

### Secondary Deliverable — Print / PDF
- Generated from the same Quarto pipeline as the HTML
- Target dimensions: 11x17 (tabloid)
- Print-on-demand — client can generate PDF from the interactive report
- Layout must handle variable content length across sections (some sites have more complex soil profiles, wider ecoregion descriptions, etc.)
- KED visual identity applied: black/white primary, spare typography, KED logotype, ink-splash texture elements consistent with existing brand

### Visual Identity Reference
- Primary reference: kaleiope.design and existing site report PDFs (four examples provided in discovery)
- Black and white primary palette; color used purposefully for data differentiation in visualizations
- Spare, confident typography
- KED logotype placement consistent with existing reports
- Quarto is the final design environment — the Affinity Publisher template in the repo is a reference artifact only and does not constrain Quarto layout

### Pre-Visit Brief Format
- Internal document only — not client-facing
- Simple structured layout: data summary by section, gap checklist, field confirmation prompts
- Can be plain HTML, markdown, or simple PDF — design is secondary to legibility and speed
- Must be generatable in under 5 minutes from address input

---

## 7. Annotation and Synthesis Layer

### Annotation Workflow (v1)
1. Practitioner completes site visit
2. Practitioner records voice memo in the field — annotations on public data findings, corrections, observed conditions
3. Voice memo is transcribed (manual or automated transcription)
4. Practitioner reviews transcript and applies calibrations editorially to the report's interpretive layer
5. Annotations inform the framing of data visualizations but do not appear as raw field notes in the client report

**v1 annotation interface:** To be determined during prototyping. Options include a structured form, a build agent conversation, or direct editorial markup in a document. The interface must support ≤ 10 minutes of practitioner time for the annotation step.

### Synthesis Workflow (v1)
1. Practitioner records vulnerabilities and opportunities section as a voice memo after the site visit
2. Voice memo is transcribed
3. Transcript is algorithmically polished (grammar, structure, clarity) — not rewritten or reinterpreted
4. Practitioner reviews and approves before delivery
5. Section appears as practitioner voice in the client report

**Practitioner voice preservation:** The synthesis section must sound like the practitioner, not like generated content. Algorithmic polishing is copy-editing only.

---

## 8. Build Phasing

### Phase 0 — Project Setup
Establish KAI project template in Cursor for the site-assessment repo. Write `project_config.md` and initial `workflow_state.md`. Establish naming conventions for skills and subagents. Document the build agent fleet (Setup, Plan, Build, Layout Design, Interactive Design agents as described in project-overview.md).

### Phase 1 — Prototyping
**Purpose:** Answer the open questions that cannot be resolved without building. Validate data sources, test visualization concepts, establish the annotation interface, and define the minimum viable pipeline.

**Prototyping work packages:**

**1A — Data source validation and acquisition**
- Re-validate all Tier 1 and Tier 2 sources against current API state (Percy research recommended before this phase)
- Implement and test acquisition functions for each source
- Document failure modes and null handling for each source
- Establish graceful degradation: which sections are absent when which sources fail
- Test NCOneMap 1m DEM acquisition and compare against current `elevatr` 10m implementation
- Debug or replace PRISM acquisition
- Test WBD as NHDPlus alternative
- Identify correct FEMA REST layer

**1B — Visualization prototyping**
- Prototype each visualization concept against at least three real parcels in NC Piedmont
- Test against edge cases: flat topography, uniform soil, missing canopy data, irregular parcel geometry
- Identify which concepts work across variable conditions and which require redesign
- Establish the Quarto visual language: type, color, layout, figure style

**1C — Pre-visit brief prototype**
- Build the simplest possible pre-visit brief output from Tier 1 data
- Test the gap checklist concept: does the brief reliably surface what needs field confirmation?
- First production test: Peter's house

**1D — Annotation interface prototype**
- Test at least two annotation interface approaches (structured form vs. build agent conversation)
- Measure practitioner time for annotation step
- Confirm ≤ 10 minute target is achievable

### Phase 2 — Pipeline Build
Implement the full acquisition → processing → visualization → report generation pipeline based on prototyping findings. Build the annotation layer into the pipeline. Implement the synthesis polishing workflow.

### Phase 3 — Output Layer
Build the interactive HTML deliverable. Implement print-to-PDF capability. Apply KED visual identity. Establish client hosting and access link delivery. Define the 12-month access window mechanics.

### Phase 4 — Production Validation
Run the full pipeline on Peter's house as the first production test before any billable use. Validate all sections, all data sources, annotation workflow, synthesis workflow, and client delivery. Document findings and iterate.

---

## 9. Agent Fleet (Build Phase)

As described in project-overview.md, six agents are envisioned:

| Agent | Role | Phase |
|-------|------|-------|
| Setup Agent | Environment, packages, project structure, YAML schema | Phase 0–1 |
| Plan Agent | Architectural decisions before code is written; data strategy per source; section-to-script mapping | Phase 1 |
| Build Agent | R code implementation across acquisition, processing, and visualization scripts | Phase 1–2 |
| Layout Design Agent | Quarto PDF output layer: 11x17, typography, section formatting, visual language | Phase 3 |
| Interactive Design Agent | Quarto HTML output layer: interactivity, shared visual language, divergence where interactivity changes design logic | Phase 3 |
| Acquisition Agent (production) | Executes data acquisition pipeline per site in production; manages caching, error handling, source validation | Phase 4+ |

---

## 10. Technical Stack

| Layer | Technology |
|-------|------------|
| Data acquisition | R — `FedData`, `soilDB`, `elevatr` (→ NCOneMap), `prism`, `rWind`, `nhdplusTools`, `osmdata`, `sf`, `terra` |
| Data processing | R — `tidyverse`, `sf`, `terra` |
| Visualization | R — `ggplot2`, `tmap`, or equivalent; visualization library TBD during prototyping |
| Report generation | Quarto (PDF + HTML from single pipeline) |
| Build environment | Cursor with KAI project template |
| Hosting | TBD — client HTML access via link; 12-month window |
| Input schema | YAML site metadata file (address, coordinates, client name, date) |

---

## 11. Open Questions and Known Risks

### Resolved During Prototyping
- Which annotation interface approach supports ≤ 10 minute practitioner time
- Whether isometric soil block and plan-view heat map concepts are technically achievable in R/Quarto at production quality
- Whether PRISM debug or source replacement is the right path for climate data
- Whether NHDPlus or WBD direct is the reliable watershed source
- Correct FEMA REST layer for flood zone data
- Whether 11x17 PDF and interactive HTML can share a single Quarto pipeline without layout conflicts
- Whether HTML interactivity supersedes the printed format (to be decided during Phase 3 prototyping)

### Known Risks
- **Data source reliability:** Multiple Tier 2 sources have known failures. Graceful degradation must be designed before production use, not after.
- **Visualization consistency:** Concepts developed against typical Piedmont residential parcels may fail on unusual geometries, rural parcels, or mountain/coastal sites. Testing across the full service geography is required.
- **Practitioner time constraint:** The ≤ 2 hour total time target is tight. Any pipeline step that requires unexpected practitioner intervention will break the economics. Automation reliability is a hard requirement.
- **Scalability design debt:** v1 is built around a single practitioner's judgment as the annotation and synthesis layer. Future multi-practitioner use will require redesign of the annotation interface and synthesis workflow. This debt should be documented but not addressed in v1.
- **LLM policy:** The synthesis polishing step uses an LLM. The policy governing which model is used, what text transits the network, and whether client site data is ever sent to a cloud provider must be established before production use. Consistent with KALEIOPE's broader privacy-first posture, local model options should be evaluated alongside cloud options.

---

## 12. Ecological Design Principles

This product is an intervention in how homeowners understand and manage their land. The following principles govern product decisions where technical options are otherwise equivalent:

- **Legibility over precision:** A client who understands approximate drainage behavior will make better decisions than one who has access to precise K-factor values they cannot interpret.
- **Transparency over authority:** Data claims are linked to sources. The report does not assert conclusions the data cannot support.
- **Ecological function over aesthetics:** The report frames site conditions in terms of what the land is doing, not what it could look like. Beauty and ecology are not in opposition, but ecology is the foundation.
- **Honest negative findings:** If the public data layer refutes the client's program idea, the report says so clearly. The report is not a sales document.
- **Pace layer awareness:** Soil chemistry and ecoregional context change over decades. Seasonal microclimate changes over months. The report distinguishes between conditions that are stable baselines and conditions that are variable.

---

*Document prepared following discovery session, June 8, 2026.*  
*Next step: Daedalus to establish KAI project template in site-assessment repo and begin Phase 0.*
