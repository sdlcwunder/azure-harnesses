# Architecture diagrams

The C4 model of the Azure harness, written in [Structurizr DSL](https://docs.structurizr.com/dsl).

- `workspace.dsl` — the model and views. Edit this.
- `workspace.json` — written by the Structurizr UI; holds the manual layout. Commit it, never edit it by hand.

## Open the UI

Open the `docs` devcontainer (see [../README.md](../README.md)). The `structurizr` sidecar starts with it.
In the host browser, go to http://localhost:8080. Pick a view from the **Diagrams** list:
`SystemContext` or `Containers`.

The UI only works on `localhost` URLs. It is published on the host's loopback address, so it isn't
reachable from other machines or from inside the `docs` container.

## Auto-refresh

The UI checks for DSL changes every 2 seconds (`STRUCTURIZR_AUTOREFRESHINTERVAL=2000`). Save
`workspace.dsl` and the open view reloads by itself. The reload is skipped while the UI has unsaved
layout changes.

## Auto-save of the layout

Drag elements to arrange a view. The UI saves the layout to `workspace.json` automatically within
about 5 seconds of the change (or press **Save**). `workspace.json` then shows up as modified in
`git status`; commit it together with the matching `workspace.dsl` change.

## Export a diagram for the slides

1. Open the view in the UI.
2. Use the export button in the diagram toolbar and choose **PNG** (or **SVG**).
3. Save the file into `docs/slides/public/diagrams/` in your checkout, named after the view,
   for example `containers.png`.
4. Reference it from a deck as `![Containers](/diagrams/containers.png)`.

Re-export after every model change that affects the view; the image doesn't update by itself.
