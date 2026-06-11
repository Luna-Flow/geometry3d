# Frontend Design

## Responsibilities

- scene-level composition を扱いますが、concrete renderer には依存しません。
- object transform、camera transform、projection、culling、directional lighting、scene-wide shadow visibility を編成します。
- compact な projected triangle commands を出力します。

## Boundary

`DrawList` が frontend と backend の安定した境界です。現在は TUI backend が消費し、
将来 SVG、Canvas、image backend も同じ構造を消費できます。

internal shadow map は fixed resolution と face sampling を使います。material system、texture、physics、BVH はありません。
