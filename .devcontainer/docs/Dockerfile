FROM mcr.microsoft.com/devcontainers/javascript-node:22

RUN corepack enable

# Docker copies this directory's ownership into an empty named volume on first mount,
# so the Claude Code state volume starts out owned by node.
RUN mkdir -p /home/node/.claude && chown node:node /home/node/.claude
