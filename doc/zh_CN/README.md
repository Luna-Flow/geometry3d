# kcndev/geometry3d

本文档描述当前仓库 **v0.1.0** 基线。

## 仓库定位

`geometry3d` 是一个基于 `Luna-Flow/linear-algebra` 的小型 MoonBit 3D
geometry layer 与 TUI renderer demo。它展示 mesh、transform、projection、
renderer 的最小管线，不是完整 3D engine。

## 文档结构

- `README.md`：包定位与版本基线。
- `doc_standard.md`：文档维护约定。
- 子系统目录：每个目录包含 `api.md`、`tutorial.md`、`design.md`。

## 子系统概览

- **`core`**：`Mesh`、quad face、向量 helper、法线、可见性、变换。
- **`renderer`**：TUI frame buffer、背景 pattern、Z-buffer、光照、光栅化。
- **`demo`**：cube 与 sphere 终端 demo 入口。

## 文档入口

- API Reference: [core](./core/api.md)
- API Reference: [renderer](./renderer/api.md)
- API Reference: [demo](./demo/api.md)
