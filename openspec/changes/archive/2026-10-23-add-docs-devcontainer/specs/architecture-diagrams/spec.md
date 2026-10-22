# Spec Delta

## Purpose

Defines the Structurizr C4 workspace that documents the Azure harness, how it is rendered live while editing, how manual layout is persisted, and how diagrams are exported for use in slides.

## ADDED Requirements

### Requirement: C4 workspace for the harness
The repository SHALL contain a Structurizr DSL workspace at `docs/architecture/workspace.dsl` modelling a "Developer" person and an "Azure harness" software system with containers for the dev container, the coding agent, the restricted Azure environment and the GitHub repository, plus a system context view and a container view.

#### Scenario: Views listed in the UI
- **WHEN** the developer opens `http://localhost:8080`
- **THEN** a system context view and a container view of the Azure harness are available

### Requirement: Live refresh on DSL edits
The Structurizr UI SHALL pick up saved changes to `workspace.dsl` within about 2 seconds without a manual browser reload.

#### Scenario: Edit reflected automatically
- **WHEN** the developer saves a change to `workspace.dsl` while the UI is open
- **THEN** the open view refreshes to show the change within about 2 seconds

### Requirement: Manual layout persisted in the repository
Manual layout changes made in the Structurizr UI SHALL be saved by the UI to `docs/architecture/workspace.json`, which SHALL be committed to the repository. `workspace.json` SHALL NOT be edited by hand.

#### Scenario: Layout change saved
- **WHEN** the developer drags an element in a view
- **THEN** `docs/architecture/workspace.json` in the host checkout is updated with the new layout

### Requirement: Diagram export to slides is documented
`docs/architecture/README.md` SHALL describe how to open the UI, how auto-refresh and auto-save behave, and how to export a view as PNG/SVG into `docs/slides/public/diagrams/`.

#### Scenario: Following the README
- **WHEN** a developer follows the export steps in `docs/architecture/README.md`
- **THEN** the exported file lands in `docs/slides/public/diagrams/` and can be referenced from a deck
