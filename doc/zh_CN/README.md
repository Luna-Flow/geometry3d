# Luna-Flow/geometry3d

本文档描述当前仓库 **v0.4.0** 基线。

## 仓库定位

`geometry3d` 是一个基于 `Luna-Flow/linear-algebra` 的小型 MoonBit 3D
geometry 基础库。它分离 core geometry、camera/view、frontend draw-list 和具体 renderer backend。

## 文档结构

- `README.md`：包定位与版本基线。
- `doc_standard.md`：文档维护约定。
- 子系统目录：每个目录包含 `api.md`、`tutorial.md`、`design.md`。

## 子系统概览

- **`core`**：`Mesh`、quad face、向量 helper、法线、可见性、4x4 TRS transform。
- **`view`**：camera、`look_at`、viewport、perspective 和 orthographic projection。
- **`frontend`**：`Scene`、`RenderView`、backend-neutral `DrawList`。
- **`backend-tui`**：TUI frame buffer、背景 pattern、Z-buffer、terminal y-scale、光栅化。
- **`backend-canvas`**：使用 frontend 软件 Z-buffer 的浏览器 Canvas 2D 输出。
- **`demo`**：终端 demo 与 TUI 导出/回放辅助命令；`demo_canvas` 提供 Torus 和 Dolly 浏览器 demo。

## 文档入口

- API Reference: [core](./core/api.md)
- API Reference: [view](./view/api.md)
- API Reference: [frontend](./frontend/api.md)
- API Reference: [backend-tui](./backend-tui/api.md)
- Backend Canvas: [API](./backend-canvas/api.md), [Tutorial](./backend-canvas/tutorial.md), [Design](./backend-canvas/design.md)
- API Reference: [demo](./demo/api.md)
- Migration: [v0.1 to v0.2](./migration_v0_2.md)
