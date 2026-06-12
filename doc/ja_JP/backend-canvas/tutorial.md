# Canvas Backend Tutorial

browser demo を build して起動します。

```sh
just canvas-serve
```

`http://localhost:8080` を開き、selector で Torus と Dolly zoom を切り替えます。
build output は `target/canvas-demo` に作成されます。

application code では `moonbit-community/rabbita/dom` から
`CanvasRenderingContext2D` を取得し、frontend draw list を作成して
`render_draw_list` を呼びます。`Scene` と `RenderView` から描画する場合は
`render_scene` を使用します。
