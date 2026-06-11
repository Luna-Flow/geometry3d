# Frontend Design

## 职责

- 负责 scene-level 组合，但不绑定具体 renderer。
- 执行 object transform、camera transform、projection、culling、方向光和 scene-wide shadow visibility 编排。
- 输出简洁的 projected triangle commands。

## 边界

`DrawList` 是 frontend 与 backend 的稳定边界。当前 TUI backend 消费它，未来 SVG、
Canvas、image backend 也可以消费同一结构。

当前内部 shadow map 使用固定分辨率和 face sampling；仍没有 material system、texture、physics 或 BVH。
