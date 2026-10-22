# Docs

## Slides (`docs/slides/`)

- The dev server starts automatically when VS Code attaches to the devcontainer (`postAttachCommand`
  in `.devcontainer/docs/devcontainer.json`). To start it by hand: `pnpm --dir docs/slides dev`
  or the `slidev: dev` task.
- It serves the deck named in the `dev` script of `docs/slides/package.json` at http://localhost:3030
  (`/presenter`, `/overview`). Its MCP endpoint is http://localhost:3030/__mcp (`slidev` server).
  If `slidev` shows as disconnected, the dev server wasn't up yet: start it, then reconnect via `/mcp`.
- Build: `pnpm --dir docs/slides build`.

## Diagrams (`docs/architecture/`)

- The Structurizr UI runs in the `structurizr` sidecar at http://localhost:8080. It is only reachable
  from the host browser, not from this container.
- You can edit `workspace.dsl`, but you cannot see the rendered result. After a DSL change, ask the
  developer to check the diagram in the UI.
- Diagrams reach slides by manual export from the UI into `docs/slides/public/diagrams/`. Decks
  reference them as `/diagrams/<file>`. Ask the developer to re-export after a diagram change.
