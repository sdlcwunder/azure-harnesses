---
paths: docs/architecture/**
---

# C4 DSL conventions

- Name elements by what they are, in Title Case ("Coding agent", "GitHub repository"). Identifiers are
  lowerCamelCase and hierarchical (`harness.agent`).
- Every element has a description; every container and component also has a technology.
  Relationships have a description, and a technology when there is one.
- One view per audience: system context for non-technical viewers, container view for engineers.
  Don't add a view that shows the same thing to the same audience.
- Never edit `workspace.json` by hand. The Structurizr UI writes it (manual layout). Change the model in
  `workspace.dsl` only.
- Split the model with `!include model/*.dsl` once `workspace.dsl` grows past one screen.
