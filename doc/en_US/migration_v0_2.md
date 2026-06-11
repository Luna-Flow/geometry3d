# Migration v0.1 to v0.2

`v0.2.0` is a breaking architecture release.

## Package Paths

- Old single package: `Luna-Flow/geometry3d`
- New packages:
  - `Luna-Flow/geometry3d/core`
  - `Luna-Flow/geometry3d/view`
  - `Luna-Flow/geometry3d/frontend`
  - `Luna-Flow/geometry3d/backend/tui`
  - `Luna-Flow/geometry3d/demo`

## Demo Command

```sh
moon run src/demo --target native
moon run src/demo --target native -- --sphere --once
```

## Rendering Flow

The old `render_mesh(mesh, transform, config)` TUI entry point is replaced by:

```text
Scene + RenderView
  -> frontend build_draw_list
  -> backend/tui render_draw_list
```

Terminal y-scale moved fully into `backend/tui`.
