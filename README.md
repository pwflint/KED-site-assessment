# KED Site Assessment

Data-augmented environmental site assessment for KALEIOPE Environmental Design — public data + practitioner field annotation, delivered as an interactive document with export capability.

**Status:** Fresh start, 2026-07-22. The prior R/Quarto/Shiny implementation (2025-01 through 2026-06) is preserved on the [`archive/pre-fresh-start-2026-07`](https://github.com/pwflint/KED-site-assessment/tree/archive/pre-fresh-start-2026-07) branch — three architecture redesigns (scripts → Shiny wrapper → Quarto/interactive HTML), zero completed data acquisition sources. Starting over from the matured product spec rather than the prior scaffold.

## Start here

- [`docs/PRD.md`](docs/PRD.md) — Product Requirements Document v1 (2026-06-08). Canonical spec: problem, users, architecture, data requirements, report sections, phasing.
- [`docs/DATA_SOURCE_RESEARCH.md`](docs/DATA_SOURCE_RESEARCH.md) — per-source API research carried forward from the prior attempt. Six-plus months old as of this fresh start; re-validate before implementing against any source (see PRD §4).
- [`docs/reference/dataViz_temp.jpg`](docs/reference/dataViz_temp.jpg) — visualization style reference carried forward from the prior attempt's templates.
- [`docs/WORKFLOW_SPEC.md`](docs/WORKFLOW_SPEC.md) — the acquire → translate → illustrate workflow, what the illustrations must convey, and what's explicitly deferred.

## No stack decided yet

Language and delivery framework are intentionally unchosen here. The prior attempt spent its time on architecture without ever shipping one working data acquisition source. The next step is a single forcing-test vertical slice — one Tier 1 data source, acquired and rendered end to end — before any stack commitment gets made.

## Workflow

Dual-VCS: **Oak** is the agent operational VCS for day-to-day session work; **Git/GitHub** is the human-promoted source archive. See [`.cursor/rules/oak-workflow.mdc`](.cursor/rules/oak-workflow.mdc) and [`.cursor/rules/git-workflow.mdc`](.cursor/rules/git-workflow.mdc).

**This repo is public.** No client-identifying site data, addresses, or credentials in tracked files, ever.
