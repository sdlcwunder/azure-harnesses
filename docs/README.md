# Docs

Slides (Slidev) and architecture diagrams (Structurizr) for the Azure harness. All docs tooling runs
in a devcontainer; the host only needs Docker and VS Code with the Dev Containers extension.

## Open the environment

1. Open the repository folder in VS Code.
2. Run **Dev Containers: Reopen in Container** and pick the `docs` configuration.

This starts two containers: `docs` (Node 22, pnpm, Slidev, Claude Code — where you and Claude work)
and `structurizr` (the diagram renderer). The first open installs the Slidev dependencies.

Each time VS Code attaches to the container, it starts the Slidev dev server (`postAttachCommand`)
in a terminal. Nothing starts when the folder is opened locally on the host. If you stop the server,
restart it with the `slidev: dev` task (**Tasks: Run Task**).

### `.git` must be a directory

The devcontainer mounts only this repository, so its `.git` must be a directory inside it. If this
repo is checked out as a submodule with an absorbed git dir (a `.git` *file* pointing at
`../../.git/modules/...`), git won't work in the container. Move the git dir into the submodule first.

## URLs

| URL | What | Notes |
|---|---|---|
| http://localhost:3030 | Slidev deck | Also `/presenter` (speaker notes) and `/overview`. Forwarded from `docs`. |
| http://localhost:3030/__mcp | Slidev MCP | Used by Claude Code inside `docs`. |
| http://localhost:8080 | Structurizr UI | Bound to the host's `127.0.0.1` only. |

## Editing slides

- Each episode has its own deck: `docs/slides/decks/NN-slug/slides.md`. The dev server serves the deck
  named in the `dev` script of `docs/slides/package.json`; change it to work on another deck.
- Save `slides.md` and the browser hot-reloads.
- Put images in `docs/slides/public/diagrams/` and reference them as `/diagrams/<file>`. Every deck
  folder needs a `vite.config.ts` re-exporting `../../vite.shared.ts` (copy the one in `01-intro`),
  which shares that folder across decks.
- Build a static copy with `pnpm --dir docs/slides build` (output in the deck's `dist/`).

## Editing diagrams

Edit `docs/architecture/workspace.dsl`; the UI refreshes within 2 seconds. Arrange views by dragging
in the UI, which saves the layout to `workspace.json`. Export views into
`docs/slides/public/diagrams/` for the slides. Details: [architecture/README.md](architecture/README.md).

## Claude Code state

Claude Code's state lives in the Docker volume `azure-harnesses-claude-docs`, mounted at
`/home/node/.claude` (with `CLAUDE_CONFIG_DIR` pointing there). It holds your login, `.claude.json`
(account, onboarding, folder trust), user settings, prompt history and session transcripts.

- The volume is created on the host before the container starts and is not owned by Compose. It
  survives **Rebuild Container**, **Rebuild Without Cache** and `docker compose down -v`.
- Only the docs environment mounts it; the future harness environment gets its own.
- Do not change `workspaceFolder` (`/workspaces/azure-harnesses`) in `devcontainer.json`: transcripts
  are keyed by that path, and `claude --resume` won't find earlier sessions under a new one.
- To delete it (logs you out and removes all history): `docker volume rm azure-harnesses-claude-docs`.
- There is no backup. The volume holds login credentials, so don't copy it out of Docker; if it is
  lost, log in again.

The Slidev dependencies live in a second volume, `azure-harnesses-docs-node-modules`. It is a cache:
deleting it only costs a reinstall on the next open.
