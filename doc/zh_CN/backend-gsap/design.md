# GSAP SVG 后端设计

## 职责

- 消费 backend-neutral frontend `DrawList`。
- 将投影三角形写入可复用 SVG polygon 节点。
- 按平均深度从远到近排序。
- 提供 GSAP 播放能力，场景数学仍保留在 MoonBit。

## 边界与限制

该 package 仅支持 JS target，并要求 `globalThis.gsap`。SVG 使用 DOM 绘制顺序，
不使用逐像素 Z-buffer；相交三角形不会沿交线拆分。当前只支持不透明平面着色。
