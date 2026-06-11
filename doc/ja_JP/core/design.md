# Core Design

## Responsibilities

- `Luna-Flow/linear-algebra` の vector を使って小さな 3D mesh を表現します。
- transform、normal、visibility などの geometry logic を backend neutral に保ちます。
- vertex に transform を適用し、face topology は保持します。

## Invariants

- core は `Char`、ANSI、terminal size、background pattern に依存しません。
- mesh factory は原点中心の vertex set を返します。
- quad face が現在の canonical topology で、triangulation は raster backend helper です。

## Limitations

- 現在は rotation transform のみです。
- scene graph、material、texture、clipping、camera orientation、asset loading、physics、BVH はありません。
- sphere cap は degenerate quad で表現し、quad pipeline を単純に保ちます。

## Extension Points

- `Transform3` に translation/scaling を慎重に追加できます。
- `Mesh` topology contract を保ちながら mesh factory を追加できます。
- core を変更せずに非 TUI backend を追加できます。
