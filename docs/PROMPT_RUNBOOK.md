# Report Generation — Prompt Runbook

**Scope (this version):** the generation step only — turning acquired site data, practitioner annotation, and the synthesis voice memo into report section text. Starts from "exact address confirmed, data acquired, site visit done, voice memo transcribed." Does not yet cover client intake, purchase confirmation, or delivery — those get folded in as this expands into a full intake-to-delivery runbook (see [Open extension](#open-extension) at the end).

**Execution context (this version):** manual. No pipeline exists yet. Peter runs these prompts by hand in a chat tool (Fable 5 or equivalent) per site, using freshly acquired data and his own transcripts as input. Once the pipeline is built, this spec becomes the design for its automated prompt calls — the content rules don't change, only who executes them.

---

## Before using this with a real client site

The parcel query that validated the data source ([`docs/DATA_SOURCE_RESEARCH.md`](DATA_SOURCE_RESEARCH.md)) returned the owner's real name and exact address. Every future data pull will too. Pasting that into a cloud chat tool is exactly the risk the PRD already flagged and left unresolved:

> **LLM policy:** ...the policy governing which model is used, what text transits the network, and whether client site data is ever sent to a cloud provider must be established before production use. (PRD §11)

That decision isn't made by this runbook. Until it is, treat any prompt below as **not yet cleared for a real client's data** — test with your own address (as we've been doing), not a paying client's, until you've decided what's acceptable to send to Fable 5 or any other cloud tool.

---

## Two distinct generation jobs

The PRD's three data layers (§3) split into two different prompt jobs with opposite rules:

| Job | Source layer | What the prompt is allowed to do |
|---|---|---|
| **Section interpretation** | Layer 1 (public data) + Layer 2 (annotation) | Generate plain-language interpretive text from data. This is real generation. |
| **Synthesis copy-edit** | Layer 3 (practitioner's own voice memo) | Grammar/structure/clarity only. **Not** generation — the practitioner's words, lightly edited. Rewriting or reinterpreting violates PRD §7's voice-preservation requirement. |

Conflating these two is the most likely way this goes wrong: if the same prompt that drafts topography interpretation also touches the vulnerabilities/opportunities section, the synthesis section stops sounding like Peter. Keep them as separate prompts, always.

---

## Job 1: Section interpretation

**Governing constraints (PRD §5, §12) — every prompt for this job must encode these, not just be told them once and trusted to remember across a long session:**

- Plain language only. No technical indices (K-factor, cm/hr infiltration rates, PRISM grid IDs) in output — translate them.
- Every data-derived claim must be traceable to a source (PRD's transparency requirement) — the prompt should be told which source produced each fact so it can cite it, not asked to invent a citation.
- Legibility over precision (§12) — approximate, understandable framing beats precise jargon.
- Ecological function over aesthetics (§12) — describe what the land is doing, not what it could look like.
- Honest negative findings (§12) — if data contradicts what the client wants, say so plainly. This is not a sales document.

**Template — one section at a time, not the whole report in one call:**

```
You are drafting one section of an ecological site assessment for a homeowner client.
Audience: non-technical. They should understand this without the practitioner present.

SECTION: {section_name}   e.g. "Regional Orientation"

SITE DATA (source-tagged — cite the source name when you state a fact):
{structured data for this section only, each fact tagged with its source,
 e.g. "county: Wake (source: NC OneMap NC1Map_Parcels)"}

PRACTITIONER ANNOTATION (calibrations to how the data should be framed —
do not quote this verbatim in the output, use it to adjust interpretation):
{annotation notes for this section, or "none"}

RULES:
- Plain language only. No technical units/indices — translate them.
- State only what the data supports. If data is missing or inconclusive, say so.
- Cite the source of each factual claim inline, e.g. "(NC OneMap)".
- 2-4 sentences. This accompanies a visualization, it does not replace one.

Draft the interpretive text for this section.
```

**Worked example — the only section we can currently fill with real data**, since parcel data is the only Tier-1 source built so far:

```
SECTION: Regional Orientation (parcel context only — ecoregion/watershed pending)

SITE DATA:
- county: Wake (source: NC OneMap NC1Map_Parcels)
- parcel size: 0.14 acres (source: NC OneMap NC1Map_Parcels, gisacres field)
- land use: single family residential, tax code "R" (source: NC OneMap NC1Map_Parcels)

PRACTITIONER ANNOTATION: none

RULES: [as above]
```
Expected output shape: a short paragraph stating the parcel is a small, sub-quarter-acre residential lot in Wake County — nothing more, since ecoregion/watershed data doesn't exist yet. If a draft run invents ecoregion or climate claims not present in the data, that's the prompt failing, not the site.

---

## Job 2: Synthesis copy-edit

**Governing constraint (PRD §7):** "The synthesis section must sound like the practitioner, not like generated content. Algorithmic polishing is copy-editing only."

**Template:**

```
This is a transcript of a practitioner's voice memo, recorded in the field
after a site visit. It becomes the "Vulnerabilities and Opportunities"
section of a client-facing report, in the practitioner's own voice.

Copy-edit ONLY:
- Fix grammar, run-ons, filler words ("um," "so yeah")
- Break into paragraphs if needed
- Do NOT add claims, interpretation, or content not in the transcript
- Do NOT rewrite sentences for style — preserve word choice and voice
- Do NOT summarize or shorten unless the transcript is genuinely repetitive

TRANSCRIPT:
{voice memo transcript}

Return only the copy-edited text, no commentary.
```

Peter reviews and approves before it goes in the report (PRD §7, step 4) — this prompt drafts, it doesn't finalize.

---

## Open extension

This runbook currently starts at "data acquired, site visit done." Expanding it into the full intake-to-delivery runbook means adding, in order: client purchase confirmation → address receipt → pre-visit brief generation (a third, simpler prompt job — internal only, gap-checklist format, PRD §6) → site visit → the two jobs above → assembly into the interactive report. Add those sections here as each becomes real rather than speccing them ahead of having a pipeline to run them in.
