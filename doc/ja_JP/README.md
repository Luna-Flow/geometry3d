# Luna-Flow/geometry3d

このドキュメントは、現在のリポジトリ基準 **v0.1.0** を説明します。

## リポジトリの位置づけ

`geometry3d` は `Luna-Flow/linear-algebra` 上に構築された、小さな
MoonBit 3D geometry layer と TUI renderer demo です。mesh、transform、
projection、renderer の最小パイプラインを示すためのもので、完全な 3D
engine ではありません。

## ドキュメント構成

- `README.md`: パッケージの概要とリリース基準。
- `doc_standard.md`: ドキュメント保守ルール。
- サブシステムごとの `api.md`、`tutorial.md`、`design.md`。

## サブシステム概要

- **`core`**: `Mesh`、quad face、vector helper、normal、visibility、transform。
- **`renderer`**: TUI frame buffer、background pattern、Z-buffer、lighting、rasterization。
- **`demo`**: cube と sphere の terminal demo entry point。

## ドキュメント入口

- API Reference: [core](./core/api.md)
- API Reference: [renderer](./renderer/api.md)
- API Reference: [demo](./demo/api.md)
