---
paths: docs/slides/**
---

# Slides conventions

- One deck per episode: `docs/slides/decks/NN-slug/slides.md` (for example `02-agent-sandbox`).
  A new deck also needs `vite.config.ts` re-exporting `../../vite.shared.ts`, like `decks/01-intro/`.
- Every slide has speaker notes (a trailing HTML comment).
- Images come from `docs/slides/public/diagrams/` and are referenced as `/diagrams/<file>`.
- Extract a shared component only once it is duplicated across decks.
