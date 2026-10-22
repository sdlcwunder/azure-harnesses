# Azure harnesses

Lets a coding agent work against a restricted Azure environment, and documents it with
Slidev decks (one per YouTube episode) and Structurizr C4 diagrams.

## Repo map

- `.devcontainer/docs/` — docs authoring environment (Compose: `docs` + `structurizr` sidecar).
- `docs/slides/` — Slidev project. Decks in `decks/NN-slug/slides.md`, shared images in `public/diagrams/`.
- `docs/architecture/` — Structurizr workspace (`workspace.dsl`; `workspace.json` is UI-managed).
- `docs/README.md` — how to open the environment and the editing workflow.
- `openspec/` — specs and change proposals.
- `.claude/commands`, `.claude/skills`, `.cursor/` — OpenSpec tooling. Do not edit.

## Rules

- Docs tooling (Node, pnpm, Slidev, Structurizr) runs only inside the `.devcontainer/docs`
  environment, never on the host. If you are not in the container, say so instead of installing tools.
- Changes go through OpenSpec: `/opsx:propose`, `/opsx:apply`, `/opsx:archive` (see `openspec/`).
- The harness's own environment (with Azure credentials) comes in a later change. Don't add
  Azure tooling or credentials to the docs environment.

## Claude Code sessions

- Start `claude` from the repo root so `.mcp.json` and `.claude/settings.json` apply.
- `workspaceFolder` in `.devcontainer/docs/devcontainer.json` must stay `/workspaces/azure-harnesses`.
  Session history is keyed by that path; changing it makes `claude --resume` lose earlier sessions.
