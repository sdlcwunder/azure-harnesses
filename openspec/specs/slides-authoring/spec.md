# slides-authoring Specification

## Purpose

Defines how Slidev decks for the YouTube series are organised, previewed live, fed with architecture diagrams, and made workable for Claude Code through the official skill and the Slidev MCP endpoint.

## Requirements

### Requirement: One deck per episode
Each episode SHALL have its own deck at `docs/slides/decks/NN-slug/slides.md`. The repository SHALL ship an initial deck `decks/01-intro/slides.md` containing a title slide, an agenda slide, a slide that shows a shared diagram image, and speaker notes.

#### Scenario: Initial deck renders
- **WHEN** the dev server is running
- **THEN** `http://localhost:3030` shows the `01-intro` deck with its title, agenda and diagram slides, and `/presenter` shows the speaker notes

### Requirement: Dev server starts automatically
The Slidev dev server SHALL start automatically when the workspace folder is opened in the devcontainer, and SHALL NOT be started when the folder is opened locally on the host. It SHALL listen on port 3030 and hot-reload when the deck file changes. `/`, `/presenter` and `/overview` SHALL work.

#### Scenario: Auto-start on folder open
- **WHEN** the developer opens the workspace in the devcontainer
- **THEN** the Slidev dev server is started without manual commands and serves on port 3030

#### Scenario: Nothing starts on the host
- **WHEN** the developer opens the repository folder locally, outside the devcontainer
- **THEN** no Slidev dev server or task is started

#### Scenario: Hot reload
- **WHEN** the developer saves a change to the active deck's `slides.md`
- **THEN** the browser view updates without a manual reload

### Requirement: Shared diagram assets
Diagram images exported from Structurizr SHALL be stored once in `docs/slides/public/diagrams/` and SHALL be usable from any deck (referenced as `/diagrams/<file>`). Images SHALL render both in the dev server and in a production build of the deck.

#### Scenario: Exported diagram renders in a deck
- **WHEN** a PNG or SVG is placed in `docs/slides/public/diagrams/` and referenced from a deck
- **THEN** the image renders in the dev server and in the output of the deck's build script

### Requirement: Locked dependencies
The Slidev project SHALL declare its dependencies in `docs/slides/package.json` and commit `pnpm-lock.yaml`, so that every environment installs identical versions.

#### Scenario: Reproducible install
- **WHEN** dependencies are installed in a fresh container
- **THEN** the install uses the committed lockfile without modifying it

### Requirement: Slidev MCP available to Claude Code
Claude Code inside the `docs` container SHALL be configured to connect to the Slidev dev server's MCP endpoint at `http://localhost:3030/__mcp` without per-user setup.

#### Scenario: MCP connected
- **WHEN** the dev server is running and the developer runs `/mcp` in Claude Code from the repository root
- **THEN** the `slidev` server is listed as connected and Claude can list the deck's slides through it

#### Scenario: Dev server started after Claude
- **WHEN** Claude Code started before the dev server was up
- **THEN** reconnecting via `/mcp` connects the `slidev` server

### Requirement: Official Slidev skill vendored
The official Slidev agent skill SHALL be committed under `docs/slides/.claude/skills/slidev/` so its version is pinned with the repository, and Claude Code SHALL load it when working on files under `docs/slides/`.

#### Scenario: Skill loads on slide work
- **WHEN** Claude Code edits a file under `docs/slides/`
- **THEN** the `slidev` skill is available in that session
