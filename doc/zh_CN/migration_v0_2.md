# v0.1 到 v0.2 迁移

`v0.2.0` 是 breaking architecture release。

## Package Paths

- 旧单包：`Luna-Flow/geometry3d`
- 新包：
  - `Luna-Flow/geometry3d/core`
  - `Luna-Flow/geometry3d/view`
  - `Luna-Flow/geometry3d/frontend`
  - `Luna-Flow/geometry3d/backend/tui`
  - `Luna-Flow/geometry3d/demo`

## Demo 命令

```sh
moon run src/demo --target native
moon run src/demo --target native -- --sphere --once
```

## 渲染流程

旧的 `render_mesh(mesh, transform, config)` TUI 入口改为：

```text
Scene + RenderView
  -> frontend build_draw_list
  -> backend/tui render_draw_list
```

terminal y-scale 已完全移入 `backend/tui`。
