# Site Analysis Workflow — Spec v1

**Phase:** Data acquisition. Product scope is being refined concurrently as acquisition proceeds — this spec reflects what's been learned validating parcel, DEM, and soils sources, not a fixed design decided in advance.

## The workflow

1. **Define the parcel and the limit of analysis.** Parcel geometry (NC1Map_Parcels) is the anchor. Analysis rasters (slope, aspect, drainage) are clipped to a short buffer beyond the parcel boundary, not a wide contextual area — see `DATA_SOURCE_RESEARCH.md` for the tight-clip rationale.
2. **Acquire data.** Topography (NC OneMap `DEM03`, validated) and soils (SSURGO via Soil Data Access, validated) are online. Climate is increasingly part of this step but not yet validated.
3. **Translate.** Convert acquired technical data into plain-language, source-cited description.
4–5. **Illustrate.** Visualize the translated findings.

Steps 4 and 5 are illustration — the exact visual form isn't specified here on purpose. What's fixed is *what* the illustrations must convey to a residential client, regardless of final design:

- **How water moves** across the parcel
- **How microclimate shifts across seasons**
- **How sun, shade, wind, and air circulation** affect the parcel

Everything else (soil composition, topography, drainage class) is input to these three, not a fourth deliverable alongside them.

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
