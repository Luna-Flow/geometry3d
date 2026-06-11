# Backend TUI Design

## Responsibilities

- projected triangle を terminal character に変換します。
- Z-buffer、shade ramp、background pattern、terminal y-scale を管理します。
- full ASCII frame snapshot ではなく behavior-based tests を優先します。

## Pipeline

```text
DrawList
  -> terminal y-scale adjustment
  -> shade ramp
  -> triangle rasterization
  -> FrameBuffer
  -> String
```

## Limitations

clipping、texture、smooth normal、anti-aliasing、perspective-correct interpolation はありません。
