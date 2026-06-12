# Frontend Design

## 职责

- 负责 scene-level 组合，但不绑定具体 renderer。
- 执行 object transform、camera transform、projection、culling、方向光和 scene-wide shadow visibility 编排。
- 输出简洁的 projected triangle commands。

## 边界

`DrawList` 是 frontend 与 backend 的稳定边界。当前 TUI 与 Canvas backend 都消费
这一结构，未来 image 或 diagnostic backend 也可以复用它。

当前内部 shadow map 使用固定分辨率和 face sampling；仍没有 material system、texture、physics 或 BVH。
