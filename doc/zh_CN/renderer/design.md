# Renderer Design

## 职责

- 将 projected triangle 转成终端字符。
- 管理 TUI 配置：frame size、shade ramp、background pattern、terminal y-scale 和 Z-buffer。
- 保持测试稳定，避免依赖完整字符画快照。

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

较小的 `depth` 表示更近。`set_pixel_if_closer` 只有在新 depth 比旧 depth 更近且超过
`DEPTH_EPSILON` 时才更新 cell。

## 限制

- 只有 flat face lighting。
- 没有 clipping、perspective-correct interpolation、texture、anti-aliasing 或 smooth normal。
- 当前 backend 是具体 TUI backend，还没有抽象 backend trait。
