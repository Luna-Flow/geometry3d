# Renderer API

renderer 层将投影后的几何数据转换为字符 frame buffer。TUI 相关职责只属于这里。

## 类型

```moonbit
struct Camera { distance : Double }
struct Projection { width : Int; height : Int; scale : Double }
struct ProjectedVertex { x : Double; y : Double; depth : Double }
```

`TuiRenderConfig` 包含宽高、投影 scale、`terminal_y_scale`、camera distance、
shade ramp、background pattern 和 light direction。

`FrameBuffer` 包含字符 cells 与 depths，depth 用于 Z-buffer。

## Projection

- `Camera::position()`：返回 `(0, 0, -distance)`。
- `project_vertex` / `project_vertices`：纯数学透视投影，不做终端 y 轴补偿。
- `apply_terminal_y_scale`：renderer 层的终端宽高比补偿。

## Background Patterns

- `dotted_background`
- `blank_background`
- `checker_background`

`FrameBuffer::new(width, height, background_pattern)` 会用 pattern 初始化所有 cell。

## Rasterization

- `set_pixel_if_closer`：深度测试并写入字符。
- `draw_triangle_z`：基于重心坐标和插值 depth 填充 triangle。
- `render_mesh`：完整渲染 mesh 到 frame buffer。
- `render_frame`：直接返回字符串帧。
