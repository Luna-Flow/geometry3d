# Renderer API

The renderer layer turns projected geometry into a character frame buffer. TUI
concerns live here, not in core.

## Types

```moonbit
struct Camera { distance : Double }
struct Projection { width : Int; height : Int; scale : Double }
struct ProjectedVertex { x : Double; y : Double; depth : Double }

struct TuiRenderConfig {
  width : Int
  height : Int
  projection_scale : Double
  terminal_y_scale : Double
  camera_distance : Double
  shade_ramp : String
  background_pattern : (Int, Int, Int, Int) -> Char
  light_direction : @la.Vector[Double]
}

struct FrameBuffer {
  width : Int
  height : Int
  cells : Array[Char]
  depths : Array[Double]
}
```

## Projection

- `Camera::position()`: returns `(0, 0, -distance)`.
- `project_vertex(vertex, camera, projection)`: perspective projection without
  terminal y-scale correction.
- `project_vertices(vertices, camera, projection)`: maps projection over vertices.
- `apply_terminal_y_scale(point, height, terminal_y_scale)`: renderer-layer aspect correction.

## Background Patterns

- `dotted_background(x, y, width, height) -> Char`
- `blank_background(x, y, width, height) -> Char`
- `checker_background(x, y, width, height) -> Char`

## Frame Buffer And Rasterization

- `FrameBuffer::new(width, height, background_pattern)`: fills cells from the pattern function.
- `FrameBuffer::index(x, y)`: converts 2D coordinates to a flat index.
- `FrameBuffer::set_pixel_if_closer(x, y, depth, pixel)`: Z-buffer depth test.
- `draw_triangle_z(buffer, p0, p1, p2, pixel)`: fills a projected triangle with interpolated depth.
- `FrameBuffer::to_string()`: emits the terminal string.
- `render_mesh(mesh, transform, config)`: full mesh rendering into a frame buffer.
- `render_frame(mesh, transform, config)`: renders directly to a string.
