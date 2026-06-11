# Frontend Design

## 职责

- 负责 scene-level 组合，但不绑定具体 renderer。
- 执行 object transform、camera transform、projection、culling 和 lighting 编排。
- 输出简洁的 projected triangle commands。

## 边界

`DrawList` 是 frontend 与 backend 的稳定边界。当前 TUI backend 消费它，未来 SVG、
Canvas、image backend 也可以消费同一结构。
