# Core Design

## 职责

- 使用 `Luna-Flow/linear-algebra` 的向量表示小型 3D mesh。
- 保持 transform、normal、visibility 等几何逻辑与 backend 无关。
- 对 vertex 应用 transform，同时保留 face 拓扑。

## 不变量

- core 不依赖 `Char`、ANSI、终端尺寸或背景 pattern。
- mesh factory 返回以原点为中心的顶点集合。
- quad face 是当前 canonical topology，triangulation 只是 raster backend helper。

## 限制

- 当前只实现旋转变换。
- 没有 scene graph、material、texture、clipping、camera orientation、asset loading、physics 或 BVH。
- sphere 极点使用退化 quad，以保持当前 quad pipeline 简单。

## 扩展点

- 可以谨慎扩展 `Transform3` 支持 translation/scaling。
- 可以新增 mesh factory，但应保持 `Mesh` 拓扑契约。
- 可以新增非 TUI backend，而不修改 core。
