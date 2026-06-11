# Demo Design

## 职责

- 将 core 和 TUI renderer 组合起来。
- 保持 CLI 行为小而可预测。
- 展示 linear algebra 管线，而不是引入 engine 概念。

## 默认值

- Cube：旋转，尺寸 `1.0`。
- Sphere：静止，半径 `2.4`，`18` rings，`36` segments。
- Torus：旋转，主半径 `2.1`、管半径 `0.72`，面绕序朝外。
- Hitchcock：中心 cube，加背景圆柱、圆锥、三棱锥及其旋转变体。
- Renderer：优先使用终端尺寸并回退到 `80x32`，dotted background，scientific-camera projection，terminal y-scale `0.5`。

## 非目标

- Runtime UI、复杂命令解析、配置文件或交互控制。
- 持久化 scene 或 asset loading。
- 依赖完整 ASCII art 的 snapshot 测试。
