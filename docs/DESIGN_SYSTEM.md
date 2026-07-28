---
author: peter
created: '2026-07-28'
modified: '2026-07-28'
status: development
tags:
  - domain/design
  - domain/data-science
title: Site Assessment — Output Design System
type: project
---
# Output Design System

This document is about the **finished-output visual design** — page chrome, typography, color, layout rhythm — for the client-facing deliverable. It is deliberately separate from `docs/ILLUSTRATION_NOTES.md`, which covers *what data goes into* each illustration and the judgment calls behind it, not how the surrounding page looks.

**Status: early, prototype-derived, not approved.** These tokens came out of one quick scroll-simulation mockup (2026-07-28), built to test whether the two settled regional/neighborhood illustrations read well in sequence. Peter confirmed the styling direction is "worth preserving" — that's a green light to keep building on it, not a sign-off on a finished brand system. Treat everything below as the current working direction, not a locked spec.

**Origin:** modeled on the `cursor.com/insights` report reviewed at the start of this translate-phase work — restrained editorial register, one accent color, generous whitespace, card-per-section rhythm. See `docs/ILLUSTRATION_NOTES.md` for how that reference shaped the individual illustrations; this document is the page-chrome half of the same conversation.

---

## Design principle

**The page's accent color comes from the data, not from a separate brand decision.** The one accent used in the mockup (a warm brown, `#9a6a2f` light / `#c99a5c` dark) is the exact color already used for the watershed-boundary line in both illustrations — chosen deliberately so page chrome (eyebrow labels, dividers) speaks the same color language as the maps themselves, rather than competing with an unrelated brand color. If the palette below changes, keep this principle: pull the accent from whatever the data visualization already uses, don't invent one separately.

## Color tokens

| Token | Light | Dark | Use |
|---|---|---|---|
| `--bg` | `#faf9f5` | `#1c1b18` | Page background — warm, not pure white/black |
| `--ink` | `#2b2a26` | `#eeece5` | Primary text |
| `--muted` | `#8c8579` | `#9a9488` | Captions, secondary text |
| `--accent` | `#9a6a2f` | `#c99a5c` | Eyebrow labels, dividers — pulled from the watershed-boundary map color, see principle above |
| `--card` | `#ffffff` | `#242220` | Card background behind each illustration |
| `--border` | `#e8e4db` | `#3a3733` | Card borders, dividers |

Both themes defined via CSS custom properties, redefined under `@media (prefers-color-scheme: dark)` and `:root[data-theme="dark|light"]` so the viewer's explicit toggle always wins over the OS preference. See the mockup source for the exact pattern.

## Typography

System sans stack only so far: `-apple-system, BlinkMacSystemFont, "Segoe UI", "Helvetica Neue", Arial, sans-serif`. Deliberate choice, not a placeholder — avoids the font-CDN restrictions Artifacts run under, and avoids reaching for Inter/Space Grotesk as a default. **Open question:** whether production (Quarto/HTML, not an Artifact) should use a real embedded webfont instead, since Quarto isn't under the same CSP restriction. Not decided.

Scale used so far: eyebrow labels ~0.7rem, uppercase, 0.12em letter-spacing; section headings ~1.05rem; body/caption ~0.8-0.92rem; all at 1.6 line-height for readability.

## Layout

- Single column, ~760px max-width, centered — matches "one thing at a time" scroll-telling, not a dashboard
- Each illustration in its own white/dark card: `1px` border, subtle drop shadow (`0 12px 28px -18px`), no rounded-corner-everywhere treatment (a flat 4px radius, not the generic `rounded-lg` look)
- Eyebrow label (numbered — "01 — Regional context") above each card, factual caption below naming the source script, not persuasive copy
- Generous vertical rhythm between sections (~5.5rem) — space is doing the separating, not rules or dividers
- A thin vertical rule runs behind the whole sequence, reinforcing "this is one continuous scroll," not a series of disconnected images

## Motion

One deliberate moment, not scattered effects: each card fades and rises slightly into view on scroll (`IntersectionObserver`, opacity + `translateY(14px)`, 0.6s ease). Respects `prefers-reduced-motion` (skips straight to visible). **Open question:** whether production uses the same technique or something native to whatever rendering stack the Quarto build ends up using (see `docs/ILLUSTRATION_NOTES.md`'s output-format flag — this mockup is HTML/CSS/JS, not necessarily what production renders through).

## Not yet addressed

- No real content hierarchy tested beyond two sections — unknown how this holds up with 5-8 report sections, sub-navigation, or a table of contents
- No mobile/narrow-viewport treatment tested
- No print/export treatment (PRD mentions export capability)
