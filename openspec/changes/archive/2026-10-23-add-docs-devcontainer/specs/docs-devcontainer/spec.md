# Spec Delta

## Purpose

Provides a containerised docs authoring environment so slides and architecture diagrams can be authored, previewed and worked on with Claude Code without installing any docs tooling on the developer's machine.

## ADDED Requirements

### Requirement: Docs tooling runs only in containers
The docs environment SHALL provide Node.js 22, pnpm, Slidev (as a project dependency), Claude Code and the Structurizr renderer entirely inside containers. The host SHALL need only a Docker engine and an editor that supports the Dev Containers spec.

#### Scenario: Fresh host opens the environment
- **WHEN** a developer with only Docker and VS Code (with the Dev Containers extension) opens the repository and selects "Reopen in Container" with the `docs` configuration
- **THEN** the environment builds and starts without requiring Node, pnpm, Java, Slidev, Structurizr or Claude Code on the host

### Requirement: Two services start together
Opening the `docs` devcontainer SHALL start a `docs` workspace service and a `structurizr` renderer service. The `structurizr` service SHALL restart automatically if it exits unexpectedly.

#### Scenario: Both services running after open
- **WHEN** the devcontainer finishes starting
- **THEN** both the `docs` and the `structurizr` containers are running

#### Scenario: Renderer crash recovery
- **WHEN** the `structurizr` process exits unexpectedly while the environment is up
- **THEN** the container runtime restarts the `structurizr` service without developer action

### Requirement: Renderers visible from the host browser
The Slidev dev server SHALL be reachable from the host at `http://localhost:3030`, and the Structurizr UI SHALL be reachable from the host at `http://localhost:8080`. The Structurizr port SHALL be bound only to the host's loopback interface.

#### Scenario: Host opens both URLs
- **WHEN** the environment is running and the Slidev dev server has started
- **THEN** `http://localhost:3030` serves the current deck and `http://localhost:8080` serves the Structurizr UI in the host browser

#### Scenario: Structurizr not exposed on the network
- **WHEN** another machine on the developer's network requests port 8080 on the developer's host
- **THEN** the connection is refused

### Requirement: Single place for the Structurizr version
The Structurizr image version SHALL be pinned in exactly one file in the repository. If that value is not available when the environment starts, startup SHALL fail with an error that names the missing variable, rather than pulling an unpinned image.

#### Scenario: Version bump
- **WHEN** a developer changes the pinned Structurizr version in that one file and rebuilds
- **THEN** the `structurizr` service runs the new version and no other file needs editing

#### Scenario: Version variable missing
- **WHEN** the environment is started without the pinned version value being resolvable
- **THEN** startup stops with an error mentioning `STRUCTURIZR_VERSION`

### Requirement: Claude Code state survives container recreation
Claude Code's authentication, global configuration (account, onboarding completion, per-project trust), user settings, prompt history and session transcripts SHALL persist across container rebuilds and recreation. Previous sessions SHALL remain resumable after recreation. This state SHALL be stored in a Docker volume dedicated to the docs environment and SHALL NOT be shared with any other environment (in particular, the future harness container).

#### Scenario: Rebuild keeps login and onboarding
- **WHEN** the developer has logged in to Claude Code, then runs "Rebuild Container" (or "Rebuild Without Cache") and starts `claude` again
- **THEN** Claude Code starts already logged in and does not repeat first-launch setup or the folder-trust prompt

#### Scenario: Session history resumable after recreation
- **WHEN** the developer had a Claude Code session in the workspace, the containers are removed and recreated, and the developer runs `claude --resume`
- **THEN** the earlier session is listed and can be resumed

#### Scenario: State survives compose volume cleanup
- **WHEN** the compose project is torn down including its volumes (e.g. `docker compose down -v`) and the devcontainer is opened again
- **THEN** the Claude Code login and session history are still present

#### Scenario: State not shared with other environments
- **WHEN** a different devcontainer (such as the future harness environment) is started on the same host
- **THEN** it does not see the docs environment's Claude Code credentials or history

### Requirement: Dependency cache survives rebuilds
Slidev's installed dependencies SHALL persist across container rebuilds in a volume, and SHALL NOT be written into the host's working tree.

#### Scenario: Rebuild reuses dependencies
- **WHEN** the container is rebuilt after a successful first install
- **THEN** the post-create install completes without re-downloading the full dependency set, and no dependency files appear in the host checkout beyond an empty mount-point directory

### Requirement: Docker resources are uniquely named
The compose project and every Docker volume created by the docs environment SHALL carry a repository-specific name, so they cannot collide with other repositories that also use a `.devcontainer/docs/` folder.

#### Scenario: Volumes identifiable on the host
- **WHEN** the developer lists Docker volumes on the host after opening the environment
- **THEN** the docs environment's volumes are named with an `azure-harnesses` prefix

### Requirement: Repository git directory available in the container
The devcontainer SHALL mount only this repository. Git operations inside the container SHALL work, which requires the repository's `.git` to be a directory inside the repository rather than a file pointing outside it.

#### Scenario: Git works inside the container
- **WHEN** the developer runs `git status` in the `docs` container
- **THEN** git reports the repository status without "not a git repository" errors
