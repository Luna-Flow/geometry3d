# View Design

## 职责

- 将 world-space point/direction 转换到 camera space。
- 将 camera-space point 投影到 viewport 坐标。
- 不包含 terminal、ANSI 或 backend 细节。

## 约定

camera space 中正 `z` 方向表示在相机前方。`look_at` 基于 `right`、`true_up`、
`forward` 三个基向量生成 view transform。
