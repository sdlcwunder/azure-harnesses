# Proposal

## Why

The repository will document the Azure harness with Slidev decks (one per YouTube episode) and Structurizr C4 diagrams, but neither tool may be installed on the developer's machine. We need a reproducible, containerised authoring environment where both live renderers are viewable from the host browser and Claude Code works alongside the author — with its login **and session history** surviving container rebuilds and recreation.

Source plan: `docs-environment-plan.md` (formerly at the repo root; deleted once this change was implemented). This change turns that plan into an implementable spec, corrects path issues found while reviewing it, and hardens Claude Code state persistence.

## What Changes

- Add a Docker Compose based devcontainer at `.devcontainer/docs/` with two services:
  - `docs` — Node 22 + pnpm + Claude Code, where the author and Claude work; runs the Slidev dev server (port 3030, forwarded).
  - `structurizr` — sidecar running the official `structurizr/structurizr:<version>-noble` image in `local` mode, published on `127.0.0.1:8080`, auto-refreshing on DSL edits.
- Persist Claude Code state in a dedicated, **externally managed** Docker volume (`azure-harnesses-claude-docs`) mounted at `/home/node/.claude`, with `CLAUDE_CONFIG_DIR` pointing at it so `.claude.json` (account, onboarding, project trust) lives in the volume too. A fixed workspace path keeps session transcripts resumable after recreation. The volume survives *Rebuild Container*, *Rebuild Without Cache*, `docker compose down -v`, and compose project renames.
- Give the compose project and all named volumes explicit, repo-specific names instead of the devcontainer CLI default (which would be the generic `docs`, derived from the `.devcontainer/docs/` folder name).
- Add a Slidev project at `docs/slides/` with a first deck at `decks/01-intro/slides.md`, a VS Code task that auto-starts the dev server, the official Slidev agent skill vendored under `docs/slides/.claude/skills/slidev/`, and the Slidev MCP endpoint wired into Claude Code.
- **Path correction vs. the plan:** Slidev resolves `public/` relative to the *entry file's* directory, so `docs/slides/public/diagrams/` would not be served for `decks/01-intro/slides.md`. Shared diagram exports move to `docs/slides/diagrams/` and decks reference them by relative path (`../../diagrams/<file>`).
- Add a Structurizr workspace at `docs/architecture/` (`workspace.dsl`, UI-managed `workspace.json`, README).
- Add Claude Code project configuration: root and `docs/` `CLAUDE.md`, path-scoped rules for C4 DSL and slides, `.mcp.json`, `.claude/settings.json`.
- Add repository hygiene: `.gitignore`, `.gitattributes` (LF), `docs/README.md`.

## Capabilities

### New Capabilities
- `docs-devcontainer`: The containerised docs environment — services, ports, host visibility, version pinning, and persistence of Claude Code state and dependencies across container recreation.
- `slides-authoring`: The Slidev project — deck layout, dev server lifecycle, shared diagram assets, the vendored Slidev skill, and the Slidev MCP connection.
- `architecture-diagrams`: The Structurizr workspace — live rendering, auto-refresh, persisted manual layout, and export of diagrams for slides.
- `docs-agent-config`: Claude Code project guidance for docs work — `CLAUDE.md` files, path-scoped rules, MCP enablement, and permission allowlist.

### Modified Capabilities

None (no existing specs).

## Impact

- **New files:** `.devcontainer/docs/{devcontainer.json,docker-compose.yml,Dockerfile,.env}`, `.vscode/tasks.json`, `.mcp.json`, `.claude/settings.json`, `.claude/rules/{c4-dsl.md,slides-style.md}`, `CLAUDE.md`, `.gitignore`, `.gitattributes`, `docs/**`.
- **Untouched:** existing `.claude/commands`, `.claude/skills` (OpenSpec), `.cursor/`, `openspec/`.
- **Host requirements:** Docker Desktop (or compatible engine) and VS Code with the Dev Containers extension. Nothing else is installed on the host.
- **Docker resources created on the host:** volumes `azure-harnesses-claude-docs` (persistent, external) and `azure-harnesses-docs-node-modules` (disposable cache).
- **Repo layout constraint:** this repo is a submodule of `D:/Content`; its `.git` is currently a real directory (verified), which the devcontainer requires.
- **Out of scope:** the harness's own container/sandbox, agent-run Structurizr validation (no Java/CLI), PNG export automation/Playwright, Cursor setup for the Slidev skill.
