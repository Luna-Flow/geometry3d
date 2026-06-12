# Canvas Backend API

Canvas backend は JS target 専用です。`@frontend.DrawList` を frontend の
perspective-correct Z-buffer で rasterize し、同色の水平 run を browser の
`CanvasRenderingContext2D` に描画します。

## Types

- `CanvasColor::rgb(red, green, blue)`: RGB channel を `0..255` に clamp します。
- `CanvasRenderConfig::default()`: `640 x 480` の default config を作成します。
- `CanvasRenderConfig::sized(width, height)`: 指定サイズの dark background と cyan foreground を設定します。

## Rendering

- `render_draw_list(context, draw_list, config)`: draw list を既存 context に描画します。
- `render_scene(context, scene, render_view, config)`: draw list を生成して描画します。
- `render_canvas(canvas, draw_list, config)`: Canvas pixel size を設定して描画します。

`just canvas-serve` を実行し、`http://localhost:8080` を開きます。demo selector
では rotating torus と Dolly zoom scene を切り替えられます。Dolly は terminal
demo と同じ rotating cube、35-disc wall、camera distance curve、focal-length
compensation を使用します。
