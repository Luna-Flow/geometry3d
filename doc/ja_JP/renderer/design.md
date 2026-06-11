# Renderer Design

## Responsibilities

- projected triangle を terminal character に変換します。
- frame size、shade ramp、background pattern、terminal y-scale、Z-buffer を管理します。
- full character-art snapshot に依存せず、whitebox test しやすい構造を保ちます。

## Pipeline

```text
Mesh + Transform3
  -> transformed vertices
  -> projection
  -> terminal y-scale adjustment
  -> face visibility and lighting
  -> quad triangulation
  -> triangle rasterization with Z-buffer
  -> FrameBuffer string
```

## Depth

小さい `depth` が近い点を表します。`set_pixel_if_closer` は新しい depth が
`DEPTH_EPSILON` を超えて近い場合だけ cell を更新します。

## Limitations

- flat face lighting のみです。
- clipping、perspective-correct interpolation、texture、anti-aliasing、smooth normal はありません。
- 現在の backend は concrete TUI backend で、backend trait はまだありません。
