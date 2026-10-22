# Design

## Context

- Greenfield: the repo only holds OpenSpec scaffolding (`.claude/commands|skills`, `.cursor/`, `openspec/`), a `LICENSE`, an empty `docs/` and the source plan `docs-environment-plan.md`. No existing specs.
- Host is Windows 11 + Docker Desktop; files are bind-mounted from an NTFS checkout, so symlinks and CRLF are hazards.
- The source plan is the baseline. This design keeps its decisions 1–6 and the ports table, and records only where it deviates or adds detail. Motivation: see proposal.md – Why.

## Goals / Non-Goals

**Goals:**
- Every relative path in the plan resolves to the intended location (audit below).
- Claude Code login, global config **and** session history survive any rebuild or recreation short of explicitly deleting one named volume.
- Docker resources have stable, repo-specific names.

**Non-Goals:**
- Backing up the Claude volume off-host, or syncing it between machines.
- Pinning the Claude Code CLI version (the feature installs latest; auto-update stays on).
- Persisting shell (bash) history.

## Decisions

### D1. Path audit of the source plan

| Plan item | Resolves to | Verdict |
|---|---|---|
| compose `build: .` | `.devcontainer/docs/` → `Dockerfile` there | ✓ |
| `../..:/workspaces/azure-harnesses` | repo root (relative to the compose file's dir) | ✓ |
| `../../docs/architecture:/usr/local/structurizr` | `docs/architecture/`; `/usr/local/structurizr` is the image's documented data dir | ✓ |
| `.env` next to the compose file | Compose's default project dir = dir of the first `-f` file | ✓, but silently falls back to an empty tag if the CLI ever changes project dir → add a `:?` guard (D5) |
| `postCreateCommand` `docs/slides/...` | runs with cwd = `workspaceFolder` | ✓ |
| task `pnpm --dir docs/slides dev` | task cwd = workspace folder | ✓ |
| script `slidev decks/01-intro/slides.md` | pnpm runs scripts in `docs/slides/` | ✓ |
| `docs/slides/public/diagrams/` used from decks | Slidev sets Vite `publicDir = <dirname(entry)>/public` → `decks/01-intro/public/` | ✗ **broken** → D4 |
| rule front-matter `paths: docs/...` | relative to project root | ✓ |
| `.mcp.json` at repo root | project scope when `claude` starts at repo root | ✓ (documented in CLAUDE.md) |
| `claude-docs:/home/node/.claude` | correct home for `remoteUser: node` | ✓ path, ✗ incomplete: `~/.claude.json` lives *outside* `~/.claude` → D2 |
| named volumes `slides-node-modules`, `claude-docs` | devcontainer CLI names the compose project after the compose file's folder → `docs_slides-node-modules`, `docs_claude-docs` | ✗ generic, collision-prone → D3 |
| skill at `docs/slides/.claude/skills/slidev/` | `npx skills add` defaults to symlinking from `.agents/skills/` | ⚠ use copy mode → D6 |
| README export target `docs/slides/public/diagrams/` | follows the broken path above | ✗ → `docs/slides/diagrams/` |

### D2. Claude Code state: external volume + `CLAUDE_CONFIG_DIR` + stable workspace path

Claude Code keeps its state in two places: `~/.claude/` (credentials, user settings, `history.jsonl`, `projects/<encoded-cwd>/*.jsonl` transcripts) and `~/.claude.json` (account, onboarding done, per-project trust, user MCP servers). Mounting a volume only at `~/.claude` loses `.claude.json` on every recreation, so Claude repeats onboarding/trust and may ask to log in again.

The approach has four parts:
1. **`CLAUDE_CONFIG_DIR=/home/node/.claude`**, set in the compose `environment` of the `docs` service. Claude Code then writes `.claude.json` inside the volume as well. This is the approach in Anthropic's devcontainer docs. Setting it in compose instead of `containerEnv` also covers shells opened with `docker compose exec`.
2. **External, explicitly named volume** `azure-harnesses-claude-docs`, declared as `external: true` with `name:` in the compose file. It is created idempotently on the host by `initializeCommand: ["docker", "volume", "create", "azure-harnesses-claude-docs"]`. The array form needs no shell, so it behaves the same from cmd, PowerShell and sh. Because Compose doesn't own the volume, `docker compose down -v`, "Rebuild Without Cache" and compose project renames cannot delete it. Only `docker volume rm azure-harnesses-claude-docs` can.
3. **Correct ownership on first mount**: the Dockerfile runs `mkdir -p /home/node/.claude && chown node:node` it. Docker copies the image directory's ownership into an empty named volume the first time it is mounted, so the volume starts out owned by `node`. `postCreateCommand` keeps a *non-recursive* `sudo chown node:node` as a safety net for volumes created before this fix. The plan's `chown -R` is dropped because recursion over a growing transcript store is unnecessary.
4. **Stable workspace path** `/workspaces/azure-harnesses`. Transcripts are keyed by the encoded cwd (`-workspaces-azure-harnesses`). Keeping this path fixed is what makes `claude --resume` and `--continue` find earlier sessions after recreation. It is noted in `docs/README.md` as "do not change".

The volume is specific to this repo and this environment, so the future harness container (with Azure credentials) never sees these credentials. This keeps the plan's decision 6.

Alternatives considered:
- *Bind-mount host `~/.claude`*: shares host credentials and history with the container. That crosses the trust boundary and gives Windows path encodings in transcript keys. Rejected.
- *Compose-managed volume (non-external)*: simpler, but `down -v` and some "clean" actions delete it. Rejected for Claude state. It's still used for `node_modules` (D3).
- *`source=claude-code-config-${devcontainerId}` via devcontainer `mounts`*: per-workspace isolation, but the ID changes if the folder path changes, which silently orphans history. A fixed explicit name is easier to find, back up and reason about.
- *Symlinking `~/.claude.json` into the volume in postCreate*: brittle (Claude rewrites the file atomically). `CLAUDE_CONFIG_DIR` is the supported mechanism.

### D3. Explicit compose project and volume names

- Top-level `name: azure-harnesses-docs` in `docker-compose.yml`, so containers are `azure-harnesses-docs-docs-1` and so on instead of `docs-...`.
- `node_modules` volume: key `slides-node-modules`, `name: azure-harnesses-docs-node-modules`, owned by Compose (not external). It's a disposable cache, and deleting it only costs a reinstall.
- Explicit `name:` on the volumes makes them independent of whatever project name the devcontainer CLI computes.

### D4. Shared diagrams at `docs/slides/diagrams/`, referenced relatively

Slidev uses `dirname(entry)` as `userRoot` and sets Vite's `publicDir` to `<userRoot>/public`. With one deck per folder, a package-level `public/` is never served. Diagrams therefore live in `docs/slides/diagrams/` (not named `public` to avoid confusion), and decks reference them as `![...](../../diagrams/<file>.png)`. Vite resolves relative asset URLs in the compiled slide templates, so they work in both dev and build, and they get fingerprinted.
- *Fallback* if relative resolution fails in build: a shared `docs/slides/vite.shared.ts` that sets `publicDir` to the absolute path of `docs/slides/public/`, re-exported by a one-line `vite.config.ts` in each deck folder. Diagrams then move to `public/diagrams/` and are referenced as `/diagrams/<file>`. This isn't the primary approach because it adds a file per deck.
- *Rejected:* a per-deck `public` symlink. Symlinks don't survive a Windows checkout.
- **Spike outcome (task 3.4): fallback adopted.** In the build, `../../diagrams/x.svg` was fingerprinted correctly. In dev it failed: the compiled slide module lives at `/slides.md__slidev_N.md`, so the URL collapsed to `/diagrams/x.svg`, which the SPA fallback answered with HTML. Diagrams now live in `docs/slides/public/diagrams/` and are referenced as `/diagrams/<file>`. `docs/slides/package.json` sets `"type": "module"` so the TS config files load as ESM.

### D8. Findings from implementation

- **No file-change events on the bind mount.** Docker Desktop mounts the Windows checkout over 9p (drvfs), and no inotify events reach the container, even for writes made inside it. `vite.shared.ts` therefore sets `server.watch.usePolling: true`, without which Slidev hot reload doesn't work. Structurizr is unaffected because it compares file mtimes on each `/workspace/lastModified` poll.
- **pnpm store location.** pnpm puts its store at the root of the project's filesystem by default, which is the bind-mounted checkout (`/workspaces/azure-harnesses/.pnpm-store`, about 500 MB on the host). `docs/slides/pnpm-workspace.yaml` sets `storeDir: /home/node/.local/share/pnpm/store`, which is in the container. pnpm 10+ reads settings like `storeDir` there, not from `.npmrc`. After a rebuild the store is empty but `node_modules` (volume) is intact, so `install --frozen-lockfile` reports "Lockfile is up to date" and downloads nothing.
- **pnpm version pinned.** Without a `packageManager` field, corepack fetches the latest pnpm in every new container. `docs/slides/package.json` pins `pnpm@12.10.1`.
- **Build output is per deck.** `slidev build` writes to `<deck>/dist/`, so `.gitignore` uses `docs/slides/**/dist/` instead of `docs/slides/dist/`.
- **Dev server only on IPv6 loopback.** Slidev hardcodes `server.host: "localhost"` (unless `--remote`, which also enables remote control), and it overrides `server.host` from the user Vite config. In the container Node resolves `localhost` to `::1`, so the server listened only on `[::1]:3030` and VS Code's port forward, which connects over IPv4, couldn't reach it. The `dev` script prepends `--dns-result-order=ipv4first` to `NODE_OPTIONS`, so the server listens on `127.0.0.1:3030`. `localhost` still works for the MCP URL.
- **Structurizr server state.** The `local` server creates `docs/architecture/.structurizr/` (search index, logs) and writes `workspace.json` on startup. The directory is ignored.

### D5. Structurizr service

- Image `structurizr/structurizr:${STRUCTURIZR_VERSION:?set STRUCTURIZR_VERSION in .devcontainer/docs/.env}-noble`, with `.env` holding `STRUCTURIZR_VERSION=2026.09.19`. The `2026.09.19-noble` tag was confirmed to exist on Docker Hub. The `:?` guard makes a missing variable fail loudly instead of resolving to the tag `-noble`.
- `STRUCTURIZR_AUTOREFRESHINTERVAL=2000`: a documented env var for `structurizr.autoRefreshInterval`, which is off by default.
- `restart: unless-stopped`, `ports: "127.0.0.1:8080:8080"`, `command: local`. These are unchanged from the plan.

### D6. Slidev skill vendored as plain files

Run `npx skills add slidevjs/slidev` from `docs/slides/`, choose Claude Code only and the **copy** install method. The result must be real files under `docs/slides/.claude/skills/slidev/`, with no `.agents/` directory and no symlinks, before it is committed.

### D7. Everything else follows the plan

The following follow the plan as written: Dockerfile base `mcr.microsoft.com/devcontainers/javascript-node:22` + `corepack enable`; the Claude Code feature `ghcr.io/anthropics/devcontainer-features/claude-code:1.0`; `forwardPorts: [3030]`; the VS Code extensions; `task.allowAutomaticTasks`; the `slidev: dev` folder-open task; `.mcp.json` and `.claude/settings.json` contents; the rules; the CLAUDE.md files; `.gitignore` and `.gitattributes`. The only path changes are `public/diagrams` → `diagrams` in the slides rule, the READMEs and `docs/CLAUDE.md`.

## Risks / Trade-offs

- [The external volume isn't removed when someone "cleans up" the project] → Documented in `docs/README.md` with the exact `docker volume rm` command and a one-line `tar` backup/restore recipe.
- [The `initializeCommand` runs on the host and needs `docker` on PATH] → Docker Desktop provides it. The command is idempotent and prints the volume name on every open.
- [Older devcontainer CLI versions ignore the compose top-level `name`] → Only container names are affected. Volumes carry explicit names (D3).
- [`task.allowAutomaticTasks` may not be honoured from devcontainer settings in every VS Code version] → VS Code then asks once to allow automatic tasks. The README mentions it.
- [Relative image paths in Slidev fail in `build`] → Verified explicitly in tasks. If they fail, use the D4 fallback.
- [The Claude volume holds OAuth credentials in plain files] → It is reachable only from this container, and the harness environment uses its own volume. Never mount it elsewhere.
- [Changing `workspaceFolder` orphans transcripts] → Called out as a fixed value in README and CLAUDE.md.

## Migration Plan

There's nothing to migrate. To roll back, delete the added files. Delete `azure-harnesses-claude-docs` and `azure-harnesses-docs-node-modules` with `docker volume rm` only if the history isn't wanted any more.
