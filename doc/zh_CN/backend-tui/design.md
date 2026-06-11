# Backend TUI Design

## 职责

- 将 projected triangle 转为终端字符。
- 管理 Z-buffer、shade ramp、background pattern 和 terminal y-scale。
- 测试以行为断言为主，不依赖完整 ASCII frame snapshot。

## Pipeline

```text
DrawList
  -> terminal y-scale adjustment
  -> shade ramp
  -> perspective-correct depth triangle rasterization
  -> FrameBuffer
  -> String
```

## 限制

没有 clipping、texture、smooth normal 或 anti-aliasing。
