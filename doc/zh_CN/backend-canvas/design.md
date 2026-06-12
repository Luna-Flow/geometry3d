# Canvas 后端设计

## 职责

- 消费与 TUI backend 相同的 backend-neutral `DrawList`。
- 复用 frontend 支持透视校正的软件 Z-buffer。
- 将可见亮度转换为量化 RGB 色阶。
- 将相邻同色色素合并为水平 Canvas fill run。

## 边界

该 package 仅支持 JS target，并负责 browser Canvas 细节。core、view 和 frontend
不依赖 DOM 类型；`demo_canvas` 负责元素查找、动画帧与 demo 选择。

## 限制

当前只支持不透明背景和单一前景 RGB 颜色的亮度缩放，不支持 material、texture、
alpha blending、anti-aliasing 或 GPU acceleration。
