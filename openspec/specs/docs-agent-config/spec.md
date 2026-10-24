# docs-agent-config Specification

## Purpose

Gives Claude Code the project knowledge, path-scoped conventions, MCP connection and minimal permissions it needs to work on slides and architecture docs consistently.

## Requirements

### Requirement: Root project guidance
A root `CLAUDE.md` of fewer than 100 lines SHALL describe the repository map, state that docs tooling runs only in the `.devcontainer/docs` environment and never on the host, state that changes go through OpenSpec (`/opsx:*`), and note that the harness environment arrives in a later change.

#### Scenario: Guidance loaded at session start
- **WHEN** Claude Code starts in the repository root
- **THEN** the root `CLAUDE.md` is loaded and is under 100 lines

### Requirement: Docs guidance loaded lazily
`docs/CLAUDE.md` SHALL describe how the Slidev dev server is started, the URLs of both renderers, how diagrams reach slides, and that Claude cannot see the Structurizr UI and must ask the developer to check rendered diagrams. It SHALL load only when Claude works under `docs/`.

#### Scenario: Docs guidance on demand
- **WHEN** Claude Code reads or edits a file under `docs/`
- **THEN** `docs/CLAUDE.md` is loaded into context

### Requirement: Path-scoped authoring rules
The repository SHALL provide a C4 DSL rule scoped to `docs/architecture/**` (element naming, description and technology on every element, one view per audience, never hand-edit `workspace.json`) and a slides rule scoped to `docs/slides/**` (one deck per episode in `decks/NN-slug/slides.md`, speaker notes on every slide, images from `public/diagrams/`, extract shared components only when duplicated).

#### Scenario: C4 rule applies to DSL edits
- **WHEN** Claude Code edits `docs/architecture/workspace.dsl`
- **THEN** the C4 DSL rule is loaded and the slides rule is not

#### Scenario: Slides rule applies to deck edits
- **WHEN** Claude Code edits a file under `docs/slides/`
- **THEN** the slides rule is loaded

### Requirement: Project MCP and permission defaults
The project SHALL declare the `slidev` HTTP MCP server in a committed `.mcp.json`, enable it in committed project settings so no approval prompt is needed, and allow `pnpm --dir docs/slides …` commands without prompting. Personal overrides (`.claude/settings.local.json`, `CLAUDE.local.md`) SHALL stay untracked.

#### Scenario: No prompts for routine slide commands
- **WHEN** Claude Code runs `pnpm --dir docs/slides build`
- **THEN** no permission prompt is shown

#### Scenario: Local overrides ignored by git
- **WHEN** a developer creates `.claude/settings.local.json` or `CLAUDE.local.md`
- **THEN** `git status` does not list them

### Requirement: Existing OpenSpec tooling untouched
The change SHALL NOT modify the existing OpenSpec commands and skills under `.claude/` or `.cursor/`.

#### Scenario: OpenSpec commands still work
- **WHEN** the developer runs `/opsx:propose` after the change
- **THEN** the command behaves as before
