# Tasks

> Docs tooling never runs on the host. Steps that run `pnpm`, `npx` or `claude` are done **inside the `docs` container**. Steps that only write files can be done from either side.

## 1. Repository hygiene

- [x] 1.1 Add `.gitattributes` (`* text=auto eol=lf`) and run `git add --renormalize .`. Verify that `git ls-files --eol` shows `i/lf` for all text files.
- [x] 1.2 Add `.gitignore` with `node_modules/`, `docs/slides/**/dist/` (build output is per deck, see D8), `.slidev/`, `CLAUDE.local.md`, `.claude/settings.local.json`. Verify with `git check-ignore -v docs/slides/node_modules CLAUDE.local.md .claude/settings.local.json`, which should report a rule for each.

## 2. Devcontainer and Compose

- [x] 2.1 Create `.devcontainer/docs/.env` with `STRUCTURIZR_VERSION=2026.09.19`.
- [x] 2.2 Create `.devcontainer/docs/Dockerfile`: `FROM mcr.microsoft.com/devcontainers/javascript-node:22`, `RUN corepack enable`, and `RUN mkdir -p /home/node/.claude && chown node:node /home/node/.claude` (design D2.3). Verify that `docker build .devcontainer/docs` succeeds.
- [x] 2.3 Create `.devcontainer/docs/docker-compose.yml` with:
  - top-level `name: azure-harnesses-docs`;
  - a `docs` service: `build: .`, `command: sleep infinity`, `environment: CLAUDE_CONFIG_DIR: /home/node/.claude`, and volumes `../..:/workspaces/azure-harnesses:cached`, `slides-node-modules:/workspaces/azure-harnesses/docs/slides/node_modules`, `claude-docs:/home/node/.claude`;
  - a `structurizr` service: image `structurizr/structurizr:${STRUCTURIZR_VERSION:?set STRUCTURIZR_VERSION in .devcontainer/docs/.env}-noble`, `command: local`, `restart: unless-stopped`, `STRUCTURIZR_AUTOREFRESHINTERVAL: "2000"`, `../../docs/architecture:/usr/local/structurizr`, `127.0.0.1:8080:8080`;
  - volumes `slides-node-modules: {name: azure-harnesses-docs-node-modules}` and `claude-docs: {external: true, name: azure-harnesses-claude-docs}`.

  Verify that `docker compose -f .devcontainer/docs/docker-compose.yml config` resolves the image to `…:2026.09.19-noble` and both bind sources to absolute repo paths. Then temporarily rename `.env` and confirm that `config` fails with a message naming `STRUCTURIZR_VERSION`.
- [x] 2.4 Create `.devcontainer/docs/devcontainer.json` with:
  - `name`, `dockerComposeFile`, `service: docs`, `runServices: ["docs","structurizr"]`, `workspaceFolder: /workspaces/azure-harnesses`, `remoteUser: node`;
  - `initializeCommand: ["docker","volume","create","azure-harnesses-claude-docs"]`;
  - feature `ghcr.io/anthropics/devcontainer-features/claude-code:1.0`;
  - `forwardPorts: [3030]`, with `portsAttributes` labelling 3030 "Slidev";
  - `postCreateCommand: sudo chown node:node /home/node/.claude docs/slides/node_modules && pnpm --dir docs/slides install --frozen-lockfile` (fall back to plain `install` until the lockfile exists in 3.2);
  - extensions `antfu.slidev`, `systemticks.c4-dsl-extension`, `anthropic.claude-code`, and the setting `"task.allowAutomaticTasks": "on"`.

  Verify that the JSON parses and that "Reopen in Container" lists a `docs` configuration.
- [ ] 2.5 Open the devcontainer. Verify that `docker ps` shows `azure-harnesses-docs-docs-1` and `azure-harnesses-docs-structurizr-1` running, that `docker volume ls` shows both `azure-harnesses-*` volumes, and that inside the container `echo $CLAUDE_CONFIG_DIR` prints `/home/node/.claude`, `stat -c %U /home/node/.claude` prints `node`, and `git status` works.

## 3. Slidev project

- [x] 3.1 Create `docs/slides/package.json` (private, devDependencies `@slidev/cli` and `@slidev/theme-default`, scripts `dev: slidev decks/01-intro/slides.md --port 3030` and `build: slidev build decks/01-intro/slides.md`), plus `docs/slides/diagrams/.gitkeep`.
- [x] 3.2 Inside the container, run `pnpm --dir docs/slides install` and commit `docs/slides/pnpm-lock.yaml`. Then switch `postCreateCommand` to `--frozen-lockfile`. Verify that the lockfile is tracked and that the host's `docs/slides/node_modules` is an empty mount-point directory.
- [x] 3.3 Write `docs/slides/decks/01-intro/slides.md` with a title slide, an agenda slide, a diagram slide using `![…](../../diagrams/<placeholder>.svg)` with a placeholder SVG committed in `diagrams/`, and speaker notes on every slide. Verify that the deck renders at `http://localhost:3030` and that the speaker notes show in `/presenter`.
- [x] 3.4 Spike the diagram path (design D4). Run `pnpm --dir docs/slides build` and serve or inspect `dist/`. Verify that the diagram image loads in both dev and build output. If it fails, apply the D4 fallback (shared `vite.shared.ts` + per-deck `vite.config.ts`, diagrams under `public/diagrams/`) and update every reference to `diagrams/` in later tasks.
- [ ] 3.5 Create `.vscode/tasks.json` with the `slidev: dev` task (`type: shell`, `command: pnpm --dir docs/slides dev`, `isBackground: true`, `problemMatcher: []`, `runOptions.runOn: folderOpen`). Verify that reloading the window starts the task automatically and that editing `slides.md` hot-reloads the browser.
- [x] 3.6 Inside the container, from `docs/slides/`, run `npx skills add slidevjs/slidev`, choosing Claude Code only and the **copy** install method. Review `SKILL.md`. Verify that `docs/slides/.claude/skills/slidev/SKILL.md` is a regular file, that `find docs/slides -type l` prints nothing, and that no `.agents/` directory was created. Then commit.

## 4. Structurizr workspace

- [x] 4.1 Write `docs/architecture/workspace.dsl`: person "Developer"; software system "Azure harness" with the containers Dev container, Coding agent, Restricted Azure environment and GitHub repository, each with a description and technology; a system context view and a container view. Verify that `http://localhost:8080` shows both views and that a saved DSL edit appears within about 2 s without a reload.
- [ ] 4.2 Drag an element in the UI. Verify that `docs/architecture/workspace.json` appears or updates on the host, then commit it. If the server created `docs/architecture/.structurizr/`, add it to `.gitignore` and check that `git status` is clean afterwards.
- [ ] 4.3 Export a PNG of the container view from the UI into `docs/slides/public/diagrams/`. Replace the placeholder reference in `01-intro`. Verify that it renders in the deck.
- [ ] 4.4 Write `docs/architecture/README.md` covering: opening the UI, auto-refresh (2 s), auto-save of `workspace.json`, and the export steps into `docs/slides/public/diagrams/`. Verify by following the steps from 4.3 as written.

## 5. Claude Code configuration

- [x] 5.1 Write the root `CLAUDE.md` (under 100 lines). It covers the repo map, the rule that docs tooling only runs in `.devcontainer/docs`, OpenSpec via `/opsx:*`, the harness environment coming later, starting `claude` from the repo root, and that `workspaceFolder` must stay `/workspaces/azure-harnesses` so session history stays resumable. Verify with `wc -l CLAUDE.md`.
- [x] 5.2 Write `docs/CLAUDE.md`. It covers how the dev server starts (folder-open task), the URLs 3030 and 8080, diagrams going via `docs/slides/public/diagrams/`, and that Claude cannot see the Structurizr UI and must ask the developer to check rendered diagrams.
- [x] 5.3 Write `.claude/rules/c4-dsl.md` (front-matter `paths: docs/architecture/**`) and `.claude/rules/slides-style.md` (`paths: docs/slides/**`, with images from `public/diagrams/`, referenced as `/diagrams/<file>`). Verify that `git diff --stat .claude/commands .claude/skills .cursor` is empty.
- [ ] 5.4 Write `.mcp.json` (`slidev` → `http://localhost:3030/__mcp`, type `http`) and `.claude/settings.json` (`enabledMcpjsonServers: ["slidev"]`, `permissions.allow: ["Bash(pnpm --dir docs/slides:*)"]`). Inside the container, verify that `/mcp` shows `slidev` connected and that Claude can list the deck's slides.

## 6. Developer documentation

- [ ] 6.1 Write `docs/README.md` covering:
  - opening the devcontainer (`docs` config);
  - the URLs;
  - the slide and diagram editing workflow;
  - the requirement that `.git` is a directory, not an absorbed-submodule file;
  - the one-time "allow automatic tasks" prompt;
  - **Claude state persistence**: what the `azure-harnesses-claude-docs` volume holds, that it survives rebuilds and `down -v`, how to delete it (`docker volume rm azure-harnesses-claude-docs`), and a backup/restore one-liner (`docker run --rm -v azure-harnesses-claude-docs:/v -v "$PWD":/b alpine tar czf /b/claude-docs.tgz -C /v .`).

  Verify by running the backup one-liner on the host and confirming the archive contains `.claude.json`.

## 7. End-to-end verification

- [ ] 7.1 Persistence across recreation. Inside the container, log in to `claude`, have a short session, and exit. Then run "Rebuild Without Cache". Verify that `claude` starts logged in with no onboarding or trust prompt, and that `claude --resume` lists the earlier session.
- [ ] 7.2 Survive volume cleanup. Run `docker compose -p azure-harnesses-docs down -v` on the host, then reopen the devcontainer. Verify that the Claude login and history are still there and that `node_modules` was reinstalled from the lockfile.
- [ ] 7.3 Rule and skill loading. In a fresh `claude` session, edit a file under `docs/slides/` and verify that the `slidev` skill, the `slides-style` rule and `docs/CLAUDE.md` load. Then edit `docs/architecture/workspace.dsl` and verify that the `c4-dsl` rule loads.
- [x] 7.4 Host isolation. Verify that `curl http://<host-LAN-IP>:8080` from another device is refused while `http://localhost:8080` works on the host.
- [x] 7.5 Remove or archive `docs-environment-plan.md` (superseded by this change). Confirm the choice with the user first.
