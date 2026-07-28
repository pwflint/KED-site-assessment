# Project Config — KED Site Assessment

*Created: 2026-07-24 | Owner: Peter Flint | Status: Active*
*This file is written once at project bootstrap and rarely changed.
It is the agent's stable reference for this project's identity.*

---

## Project

**Name:** KED Site Assessment
**One-line description:** Data-augmented ecological site assessment for KALEIOPE Environmental Design — public data + practitioner field annotation, delivered as an interactive document with export capability, priced at $200-250 as the entry point to a tiered design-services model.
**Repository:** https://github.com/pwflint/KED-site-assessment (public)
**Phase:** Build (Phase 1 prototyping/data acquisition, per `docs/PRD.md` §8) — data-acquisition layer is largely validated; translate/illustrate/synthesis phases are next.

---

## Stack

- **Language:** R (confirmed through nine validated acquisition sources — not a default, a deliberate choice per source: `terra` for raster/DEM work specifically outperforms the alternative that was tried first, see `docs/DATA_SOURCE_RESEARCH.md`)
- **Framework/Runtime:** None — no package/app framework yet. Acquisition code lives as plain functions in `R/acquisition/*.R`, one file per source.
- **Orchestration:** **None yet, deliberately.** `docs/WORKFLOW_SPEC.md` explicitly argues against building an orchestrator/subagent layer before the individual steps it would orchestrate are proven. Longer-term (v2/v3) goal: email/prompt-triggered workflow — not being built now.
- **Database/State:** None. File-based API retrieval; local caching to a configurable directory per source (e.g. `PRISM_CACHE_DIR`, `GHCND_STATIONS_CACHE_DIR`) — CONUS/statewide reference datasets cached once, reused across parcels.
- **External APIs:** NC OneMap (parcels, DEM, imagery), NRCS Soil Data Access + UC Davis SoilWeb, PRISM/Oregon State (climate normals), NOAA NCEI (wind), USGS WBD (watershed), EPA (ecoregions), FEMA NFHL (flood zones), NC Spatial Data Download / sdd.nc.gov (building footprints), NLCD/USFS (canopy cover), OpenStreetMap Overpass + tile server (base maps). Full endpoint-by-endpoint detail in `docs/DATA_SOURCE_RESEARCH.md`.
- **Deployment target:** **Not yet decided.** README states this explicitly — delivery/hosting stack is an open question, separate from the acquisition-layer language (R), which is settled.

---

## Architecture

Two-mode pipeline per `docs/PRD.md`: a pre-visit brief (internal, data-only) and a post-visit client deliverable (data + practitioner annotation + synthesis). The build follows an 8-step workflow (`docs/WORKFLOW_SPEC.md`): define parcel/analysis boundary → acquire data → translate to plain language → illustrate regional/macro context → illustrate raw parcel-level data → analysis → synthesis → design strategies. Steps 1-2 are built and validated (twelve sources, `R/acquisition/`). Step 3/4 (translate, illustrated as a visual-first exercise per Peter — prose is explicitly deferred) has two settled prototypes at regional/neighborhood scale (`R/illustrate/`, findings in `docs/ILLUSTRATION_NOTES.md`); that thread is paused, with parcel-scale illustration (step 5) the next focus. Steps 6-8 remain specced at the level of *what* each must do, not *how*.

---

## Critical Patterns & Conventions

- **Never oversample a raster export.** Requesting more pixels than a bbox supports at native resolution produces fake blocky/grid-patterned artifacts in derived calculations (slope, in particular) that can look like real findings. Always compute pixel size from native resolution before requesting `size` on any `exportImage` call. (Found the hard way on DEM; documented in `docs/DATA_SOURCE_RESEARCH.md`.)
- **Maintain raw field values in acquisition; collapse/classify at translate/synthesis, not at retrieval.** Acquisition functions return raw source fields (e.g., `FLD_ZONE`/`ZONE_SUBTY`/`SFHA_TF` for flood, not a pre-collapsed risk label). Established explicitly during the flood-zone work.
- **Prefer state/county-authoritative sources over generic/global ones, verified per use case, not by default.** OSM is wrong for cadastral parcels, right for base-map roads/places — the same source can be right or wrong depending on what's being asked of it.
- **Verify before presenting, always.** Don't assume a field means what its name suggests (`LIDAR_HAG` looked like building height; wasn't). Don't assume an old "blocked" status is still true (PRISM, watershed, flood zones were all wrongly diagnosed in the prior attempt). Check live, check real values, check known-answer locations as sanity checks.
- **Dual-VCS:** Oak is the agent operational VCS for session work (branch-per-session, checkpoint via `oak commit`/`oak push`); Git/GitHub is the human-promoted archive. See `.cursor/rules/oak-workflow.mdc` and `.cursor/rules/git-workflow.mdc`. Agents don't `git commit`/`git push` or `oak merge` without Peter's explicit ask.
- **Human-in-the-loop during build, by evidence not just preference.** Every real error caught in the acquisition phase was caught by a human reviewing intermediate output, not by the pipeline self-correcting. See `docs/WORKFLOW_SPEC.md`'s "Build discipline" section for the specific track record.

---

## Constraints

- **This repo is public.** No client-identifying site data, real addresses, or credentials in tracked files, ever (`.cursor/rules/git-workflow.mdc`).
- **Test data using the real test parcel (Peter's own address) stays in `/tmp`/scratchpad, not committed** — this is a deliberately deferred decision, not a resolved one. One line already in `docs/DATA_SOURCE_RESEARCH.md` (the address, no owner name) predates this caution and hasn't been revisited.
- **$200-250 price point, targeting $2,000-3,000 perceived value** — every acquisition/processing design choice gets weighed against this economics (`docs/WORKFLOW_SPEC.md`).
- **No survey-grade claims.** The product infers from best-available regional data; it does not conduct a site-specific survey. This must be disclosed in the client-facing brief, not softened later.

---

## Key Files & Reference Docs

| File | Purpose |
|---|---|
| `docs/PRD.md` | Product requirements — problem, users, architecture, data requirements, report sections, phasing |
| `docs/DATA_SOURCE_RESEARCH.md` | Per-source findings: endpoints, gotchas, bugs caught, data-quality caveats |
| `docs/WORKFLOW_SPEC.md` | The 8-step workflow, human-in-the-loop discipline, business framing, deferred items |
| `docs/PROMPT_RUNBOOK.md` | Report-generation prompt jobs (section interpretation vs. synthesis copy-edit) — parked pending more validated sources |
| `docs/ILLUSTRATION_NOTES.md` | Translate/illustrate-step design decisions, judgment calls, rejected approaches — the layer above DATA_SOURCE_RESEARCH.md (sources) |
| `docs/DESIGN_SYSTEM.md` | Finished-output visual design — color/type/layout tokens for the client-facing page itself, separate from illustration content decisions |
| `R/acquisition/*.R` | One file per validated data source: parcel, dem, soil, climate, wind, flood, building_footprint, canopy, watershed, ecoregion, basemap |
| `R/illustrate/*.R` | Prototype illustration functions: `regional_inset.R` (state-scale), `neighborhood_context.R` (neighborhood-scale), `basemap_tiles.R` (shared tile-fetch helper) |
| `.cursor/rules/oak-workflow.mdc`, `.cursor/rules/git-workflow.mdc` | Dual-VCS rules |

---

## Out of Scope (for now)

- **Raw LiDAR point-cloud processing** — considered and explicitly rejected for v1. Would be primary geospatial analysis rather than citing an authoritative existing product, unlike every other source in this pipeline. Structure/canopy height uses a configurable placeholder instead, refined by field observation.
- **Plain-language translation of soils lab/water-balance data** — deferred to a later stage.
- **Impervious surface / runoff / vulnerability-point calculations** — roadmap item.
- **Ground-truthing ("Charlie" iteration)** — physical soil samples, on-site biology testing — future beta consideration.
- **Orchestration/automation of the full workflow** — v2/v3 goal, not being built now.

---

## Agent Memory

*Development runtime only — local agentmemory on Peter's machine, not production. This is the continuity mechanism between agents on this project — a new agent (Fable 5 build session, a future Sonnet session, whatever picks this up next) should not rely on this file alone.*

**A new agent starting on this project must call `memory_smart_search` and/or `memory_recall` on the project tag below before assuming it's starting cold** — per the global memory protocol. This file plus the repo docs cover stable, settled context; memory covers working-session preferences, corrections, and in-progress decisions that haven't been written into a doc yet (or were deliberately scoped to stay out of one).

**Project tag:** `KED-site-assessment` (used as the `project` field in `memory_save` calls this session).

**In memory, not repo:** one feedback-type entry (`mem_mrws8m9e`) on epistemic calibration during data acquisition — verify-before-presenting discipline, scoped to this project/session per Peter's explicit request, not treated as a systemic lesson. A new agent should read this before it repeats the pattern it corrects.

**In repo (not memory):** all data-source findings, workflow design, and build conventions — see Key Files above.

**Graduation:** when phase reaches Production, promote any settled memory-held rules to repo files and sweep matching entries from agentmemory.
