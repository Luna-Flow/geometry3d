# v0.1 から v0.2 への移行

`v0.2.0` は breaking architecture release です。

## Package Paths

- 旧 single package: `Luna-Flow/geometry3d`
- 新 package:
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

旧 `render_mesh(mesh, transform, config)` TUI entry point は次に置き換わります。

```text
Scene + RenderView
  -> frontend build_draw_list
  -> backend/tui render_draw_list
```

terminal y-scale は完全に `backend/tui` に移動しました。
