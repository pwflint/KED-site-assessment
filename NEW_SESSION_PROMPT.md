# New Session Starting Prompt — KED Site Assessment

*Paste this (or the gist of it) to bootstrap a fresh agent session on this project — a new Fable 5 build session, a new Sonnet planning session, whatever picks this up next.*

---

You're picking up work on KED Site Assessment — a data-augmented ecological site assessment product for KALEIOPE Environmental Design (public data + practitioner field annotation, delivered as an interactive document, $200-250 price point). This is not a cold start; a lot of validated work already exists. Do these things before writing any code or making any claims:

1. **Read `project_config.md` and `workflow_state.md` in the repo root first.** They're the stable reference and the live state tracker, respectively. `workflow_state.md`'s Log section has a dated, compressed history of what's been built and what broke along the way — read it before re-deriving anything.
2. **Query agentmemory before assuming you're starting cold.** Call `memory_smart_search` and/or `memory_recall` on project tag `KED-site-assessment`. There's at least one feedback entry on epistemic calibration during data acquisition that you should read and not repeat the pattern it corrects.
3. **Read `docs/DATA_SOURCE_RESEARCH.md` before touching any data source.** Twelve sources are already validated with real bugs caught and fixed — re-discovering a bug that's already documented wastes a session. If a source isn't in that doc yet, it hasn't been validated, regardless of what the PRD assumes.
4. **Read `docs/WORKFLOW_SPEC.md` for the actual build sequence and its discipline.** In particular: don't build an orchestrator before individual steps are proven; keep a human in the loop at every stage for now, not because it's a rule but because every real error caught in this project so far was caught that way, not by the pipeline; never request more raster pixels than native resolution supports (see the DEM incident).
5. **Read `docs/ILLUSTRATION_NOTES.md` before touching any translate/illustrate visual.** Two prototypes (regional-scale, neighborhood-scale) are settled with real bugs and rejected approaches documented — including a full DEM-raster-shading approach that was tried and explicitly rejected at neighborhood scale. Don't re-attempt it there; it's reserved for parcel scale instead.
6. **Read `docs/DESIGN_SYSTEM.md` before styling any output page.** Early, prototype-derived color/type/layout tokens for the finished client-facing output — separate from illustration content decisions.

**As of this bootstrap (2026-07-28):** acquisition (steps 1-2) is fully built and validated, twelve sources (`R/acquisition/*.R`). Translate/illustrate (steps 3-4) has two settled, tested, reusable prototypes at regional and neighborhood scale (`R/illustrate/*.R`) — paused deliberately, not abandoned, while focus shifts to **parcel-scale illustration (step 5), the current active focus.** Prose for any section remains explicitly deferred by Peter until the writing approach itself is validated — do not draft client-facing copy unprompted.

**Genuinely open, not just unwritten — don't invent answers, and don't silently re-decide these:**
- Delivery/deployment stack
- Whether real test-parcel data (a real address) is acceptable in this public repo's committed fixtures
- Basemap tile provider for illustrations (currently Carto's no-labels tiles; Peter has flagged a real, unresolved stability concern about Carto as a smaller/earlier-stage provider vs. Esri — explicitly deferred to when this project starts testing additional parcels)
- Standard display-extent sizing for neighborhood-scale images (current 2,500ft buffer worked for one test parcel sitting near its watershed boundary; untested against a parcel that doesn't)
- Final output format — every illustration to date is a static PNG; production target is HTML/vector/scroll-native, not decided how to get there

Ask before assuming. This project has a specific, hard-won discipline around verifying data before presenting it as a finding — match it, don't skip it for speed.
