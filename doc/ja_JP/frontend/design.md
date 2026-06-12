# Frontend Design

## Responsibilities

- scene-level composition を扱いますが、concrete renderer には依存しません。
- object transform、camera transform、projection、culling、directional lighting、scene-wide shadow visibility を編成します。
- compact な projected triangle commands を出力します。

## Boundary

`DrawList` が frontend と backend の安定した境界です。現在の TUI backend と
Canvas backend がこの構造を消費し、将来の image / diagnostic backend も再利用できます。

internal shadow map は fixed resolution と face sampling を使います。material system、texture、physics、BVH はありません。
