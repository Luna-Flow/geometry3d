# Migration from v0.1 to v0.2

`v0.2.0` is a breaking architecture release.

## Package paths

- Old single package: `Luna-Flow/geometry3d`
- New packages:
  - `Luna-Flow/geometry3d/core`
  - `Luna-Flow/geometry3d/view`
  - `Luna-Flow/geometry3d/frontend`
  - `Luna-Flow/geometry3d/backend/tui`
  - `Luna-Flow/geometry3d/demo`

## Demo command

```sh
moon run src/demo --target native
moon run src/demo --target native -- --sphere --once
```

## Rendering flow

The old `render_mesh(mesh, transform, config)` TUI entry point is replaced by:

```text
Scene + RenderView
  -> frontend build_draw_list
  -> backend/tui render_draw_list
```

Terminal y-scale moved fully into `backend/tui`.
