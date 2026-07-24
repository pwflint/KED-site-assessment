# New Session Starting Prompt — KED Site Assessment

*Paste this (or the gist of it) to bootstrap a fresh agent session on this project — a new Fable 5 build session, a new Sonnet planning session, whatever picks this up next.*

---

You're picking up work on KED Site Assessment — a data-augmented ecological site assessment product for KALEIOPE Environmental Design (public data + practitioner field annotation, delivered as an interactive document, $200-250 price point). This is not a cold start; a lot of validated work already exists. Do these things before writing any code or making any claims:

1. **Read `project_config.md` and `workflow_state.md` in the repo root first.** They're the stable reference and the live state tracker, respectively. `workflow_state.md`'s Log section has a dated, compressed history of what's been built and what broke along the way — read it before re-deriving anything.
2. **Query agentmemory before assuming you're starting cold.** Call `memory_smart_search` and/or `memory_recall` on project tag `KED-site-assessment`. There's at least one feedback entry on epistemic calibration during data acquisition that you should read and not repeat the pattern it corrects.
3. **Read `docs/DATA_SOURCE_RESEARCH.md` before touching any data source.** Nine sources are already validated with real bugs caught and fixed — re-discovering a bug that's already documented wastes a session. If a source isn't in that doc yet, it hasn't been validated, regardless of what the PRD assumes.
4. **Read `docs/WORKFLOW_SPEC.md` for the actual build sequence and its discipline.** In particular: don't build an orchestrator before individual steps are proven; keep a human in the loop at every stage for now, not because it's a rule but because every real error caught in this project so far was caught that way, not by the pipeline; never request more raster pixels than native resolution supports (see the DEM incident).

**As of this bootstrap (2026-07-24):** acquisition (steps 1-2) is built and validated for parcel, DEM, soils, PRISM climate, wind, flood zones, building footprints, and canopy. Watershed, ecoregions, and base maps are source-validated but not yet built as `R/acquisition/*.R` functions. The next planned focus is the translate step (step 3) — turning acquired technical data into plain-language, source-cited description. Nothing past step 3 is specced beyond "what it must convey."

**Two things are genuinely open, not just unwritten — don't invent answers for them:** the delivery/deployment stack, and whether real test-parcel data (a real address) is acceptable in this public repo's committed fixtures.

Ask before assuming. This project has a specific, hard-won discipline around verifying data before presenting it as a finding — match it, don't skip it for speed.
