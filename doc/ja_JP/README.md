# Luna-Flow/geometry3d

このドキュメントは、現在のリポジトリ基準 **v0.4.1** を説明します。

## リポジトリの位置づけ

`geometry3d` は `Luna-Flow/linear-algebra` 上に構築された小さな MoonBit
3D geometry foundation です。core geometry、camera/view、frontend draw-list、
renderer backend を分離します。

## ドキュメント構成

- `README.md`: パッケージの概要とリリース基準。
- `doc_standard.md`: ドキュメント保守ルール。
- サブシステムごとの `api.md`、`tutorial.md`、`design.md`。

## サブシステム概要

- **`core`**: `Mesh`、quad face、vector helper、normal、visibility、4x4 TRS transform。
- **`view`**: camera、`look_at`、viewport、perspective / orthographic projection。
- **`frontend`**: `Scene`、`RenderView`、backend-neutral `DrawList`。
- **`backend-tui`**: TUI frame buffer、background pattern、Z-buffer、terminal y-scale、rasterization。
- **`backend-canvas`**: frontend software Z-buffer を使用する browser Canvas 2D 出力。
- **`backend-gsap`**: painter ordering を使う SVG polygon output と GSAP playback control。
- **`demo`**: terminal demo と export helper。`demo_canvas` と `demo_gsap` は browser demo を提供します。

## ドキュメント入口

- API Reference: [core](./core/api.md)
- API Reference: [view](./view/api.md)
- API Reference: [frontend](./frontend/api.md)
- API Reference: [backend-tui](./backend-tui/api.md)
- Backend Canvas: [API](./backend-canvas/api.md), [Tutorial](./backend-canvas/tutorial.md), [Design](./backend-canvas/design.md)
- Backend GSAP: [API](./backend-gsap/api.md), [Tutorial](./backend-gsap/tutorial.md), [Design](./backend-gsap/design.md)
- API Reference: [demo](./demo/api.md)
- Migration: [v0.1 to v0.2](./migration_v0_2.md)
