# Site Analysis Workflow — Spec v1

**Phase:** Data acquisition. Product scope is being refined concurrently as acquisition proceeds — this spec reflects what's been learned validating parcel, DEM, and soils sources, not a fixed design decided in advance.

## The workflow

1. **Define the parcel and the limit of analysis.** Parcel geometry (NC1Map_Parcels) is the anchor. Analysis rasters (slope, aspect, drainage) are clipped to a short buffer beyond the parcel boundary, not a wide contextual area — see `DATA_SOURCE_RESEARCH.md` for the tight-clip rationale.
2. **Acquire data.** Validated and built: parcel, DEM/topography, soils, PRISM climate, wind, FEMA flood zones, building footprints, canopy extent, watershed, ecoregions, base map roads. All step 4 prerequisite sources are now built.
3. **Translate.** Convert acquired technical data into plain-language, source-cited description. Not yet specced in detail — the focus of the next working session.
4. **Visualize regional and macro context.** Likely page/section one of the report. Covers: ecoregion context, watershed context, floodplain context, and an orientation visual whose specific job is confirming to the client that the location being assessed is the correct one — not navigation, not data display, just "yes, this is your parcel." Feasible now on the data side, but needs real design thinking before it can be built, not just retrieval — the grayscale/orientation-not-navigation base-map question (see OpenStreetMap section, `DATA_SOURCE_RESEARCH.md`) is a live example of that design work, not a separate concern.
5. **Visualize climate, soil, and parcel-level raw data** — what is actually there, not yet interpreted. Likely 2-3 visual sections rather than one: a tiled set of graphs for climate data, a tiled set for spatial/soil data. More buildable than step 4 right now, since climate, soils, DEM-derived slope/aspect, and wind already exist as validated functions.
6. **Analysis.** How the acquired data informs constraints and opportunities on the site. Illustration approach not decided.
7. **Synthesis.** Practitioner-authored, per the PRD's Layer 3 — see `PROMPT_RUNBOOK.md`'s synthesis-copy-edit job. Illustration approach not decided.
8. **Design strategies.** Illustration approach not decided.

Steps 4 and 5 together are what the PRD calls illustration. What's fixed regardless of final visual design, across both:

- **How water moves** across the parcel
- **How microclimate shifts across seasons**
- **How sun, shade, wind, and air circulation** affect the parcel

Everything else (soil composition, topography, drainage class) is input to these three, not a fourth deliverable alongside them. Steps 6-8 are named to keep the full sequence visible, not specced — deliberately left open until 1-5 are further along.

## Build discipline: human-in-the-loop, by evidence not just preference

Every real error caught in the data-acquisition phase (steps 1-2) was caught because a human reviewed intermediate output and asked a follow-up question, not because the pipeline self-corrected: a wrong function-name guess, a NULL-dropping row-misalignment bug, a DEM oversampling artifact that fabricated a grid-patterned "erosion risk" finding, a field that looked like building height but wasn't, and a flood-zone check-first assumption that was wrong twice over (first on feature-presence, then again on which "Zone X" subtypes actually mean "no risk"). None of these were caught by the automation — all of them were caught by a human reading the output before it went further.

**For steps 4-8, during the first several build iterations, a human is in the loop at every stage** — same discipline as steps 1-2, not a lesser standard. This is a build-phase practice, not a claim about the eventual production workflow: validating that a piece of logic is correct (once) is different from re-checking it on every future assessment. The PRD's own per-assessment human touchpoints (pre-visit brief review, field annotation, synthesis approval before delivery) remain the production-time checkpoints; they don't require re-litigating already-validated acquisition/translation logic each time.

**Longer-term automation goal (v2/v3, not now):** trigger the full site-assessment workflow from an email/prompt, no manual step-by-step invocation. Not being built yet — steps 4-8 don't exist yet to automate — but the eventual direction, worth keeping in view so early design choices don't quietly foreclose it.

## Epistemic framing — required disclosure

The product infers site-specific conditions from the most granular regional data available — 1m DEM, climate data tied to the relevant grid/station, SSURGO map units — it does not conduct a site-specific survey. No soil boring, no on-site monitoring, no core samples in this phase.

**This must be stated explicitly in the client-facing brief:** the underlying data is real; the parcel-specific results are inferred, not surveyed. This is not a caveat to soften later — it's load-bearing for the product's honesty, consistent with the PRD's "Transparency over authority" principle.

## Business framing

Price point: $200–250. Target perceived value: $2,000–3,000. That gap is closed by inference from existing regional data sources — not by the cost of a full ecological survey. Every design decision in this workflow should be evaluated against whether it moves the product toward or away from that economics.

## Requirement: automated soil data retrieval

Given a parcel's map unit(s), the workflow needs a function that automatically retrieves and assembles, per named component:

- SDA tabular data (mapunit/component — validated this session, `sdmdataaccess.nrcs.usda.gov/Tabular/post.rest`)
- UC Davis SoilWeb / Series Data Explorer data per series — lab data, water balance, and whatever else proves useful (endpoints found this session: `get_mapunit_data.php`, `list_components.php`, `/sde/?series=<name>`)

This is an acquisition automation requirement, not a manual research step — the agent pulls it, a human doesn't paste links per parcel.

## Explicitly deferred

Not in scope for this phase — noted so they aren't rediscovered as surprises later:

- **Translating soils lab/water-balance data into layperson language.** Postponed. Peter's 4–6 inch / 96-hour rainfall-to-runoff observation is one example of the *kind* of translation to explore later (e.g., "this amount of water" framing against the water-balance model), not a spec to implement now.
- **Impervious surface calculations** — parcel impervious area, expected roof runoff volume, and how resulting flow points map to vulnerability locations on the parcel. Roadmap item.
- **Ground-truthing ("Charlie" iteration)** — physical soil samples sent to the State Agronomy Office, on-site soil-biology testing at select locations. Future beta consideration, not v1.
