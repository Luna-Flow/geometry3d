# Renderer API

renderer layer は projected geometry を character frame buffer に変換します。
TUI に関する責務はここに置きます。

## Types

```moonbit
struct Camera { distance : Double }
struct Projection { width : Int; height : Int; scale : Double }
struct ProjectedVertex { x : Double; y : Double; depth : Double }
```

`TuiRenderConfig` は width、height、projection scale、`terminal_y_scale`、
camera distance、shade ramp、background pattern、light direction を保持します。

`FrameBuffer` は character cells と Z-buffer 用 depths を保持します。

## Projection

- `Camera::position()`: `(0, 0, -distance)` を返します。
- `project_vertex` / `project_vertices`: terminal y-scale を含まない perspective projection。
- `apply_terminal_y_scale`: renderer layer の terminal aspect correction。

## Background Patterns

- `dotted_background`
- `blank_background`
- `checker_background`

`FrameBuffer::new(width, height, background_pattern)` は pattern で全 cell を初期化します。

## Rasterization

- `set_pixel_if_closer`: depth test と character write。
- `draw_triangle_z`: barycentric coordinate と interpolated depth で triangle を塗ります。
- `render_mesh`: mesh を frame buffer に描画します。
- `render_frame`: string frame を返します。
