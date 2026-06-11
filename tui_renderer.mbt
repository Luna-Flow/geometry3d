const DEFAULT_WIDTH : Int = 80
const DEFAULT_HEIGHT : Int = 32
const DEFAULT_CAMERA_DISTANCE : Double = 4.5
const DEFAULT_PROJECTION_SCALE : Double = 24.0
const DEFAULT_TERMINAL_Y_SCALE : Double = 0.5
const DEFAULT_SHADE_RAMP : String = " .:-=+*#%@"
const FAR_DEPTH : Double = 1.0e30

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

fn TuiRenderConfig::default() -> TuiRenderConfig {
  {
    width: DEFAULT_WIDTH,
    height: DEFAULT_HEIGHT,
    projection_scale: DEFAULT_PROJECTION_SCALE,
    terminal_y_scale: DEFAULT_TERMINAL_Y_SCALE,
    camera_distance: DEFAULT_CAMERA_DISTANCE,
    shade_ramp: DEFAULT_SHADE_RAMP,
    background_pattern: dotted_background,
    light_direction: normalize_vec(vec3(0.6, 0.7, -1.0)),
  }
}

fn FrameBuffer::new(
  width : Int,
  height : Int,
  background_pattern : (Int, Int, Int, Int) -> Char,
) -> FrameBuffer {
  let buffer = {
    width,
    height,
    cells: Array::make(width * height, ' '),
    depths: Array::make(width * height, FAR_DEPTH),
  }
  for y in 0..<height {
    for x in 0..<width {
      let index = buffer.index(x, y)
      buffer.cells[index] = background_pattern(x, y, width, height)
    }
  }
  buffer
}

fn FrameBuffer::index(self : FrameBuffer, x : Int, y : Int) -> Int {
  y * self.width + x
}

fn FrameBuffer::set_pixel_if_closer(
  self : FrameBuffer,
  x : Int,
  y : Int,
  depth : Double,
  pixel : Char,
) -> Unit {
  if x < 0 || x >= self.width || y < 0 || y >= self.height {
    return
  }
  let index = self.index(x, y)
  if depth + DEPTH_EPSILON < self.depths[index] {
    self.depths[index] = depth
    self.cells[index] = pixel
  }
}

fn clamp01(value : Double) -> Double {
  if value < 0.0 {
    0.0
  } else if value > 1.0 {
    1.0
  } else {
    value
  }
}

fn shade_char(shade_ramp : String, intensity : Double) -> Char {
  let clamped = clamp01(intensity)
  let last_index = shade_ramp.length() - 1
  let index = (clamped * last_index.to_double()).round().to_int()
  shade_ramp[index].unsafe_to_char()
}

fn edge_function(
  ax : Double,
  ay : Double,
  bx : Double,
  by : Double,
  px : Double,
  py : Double,
) -> Double {
  (px - ax) * (by - ay) - (py - ay) * (bx - ax)
}

fn draw_triangle_z(
  buffer : FrameBuffer,
  p0 : ProjectedVertex,
  p1 : ProjectedVertex,
  p2 : ProjectedVertex,
  pixel : Char,
) -> Unit {
  let area = edge_function(p0.x, p0.y, p1.x, p1.y, p2.x, p2.y)
  if area.abs() <= DEPTH_EPSILON {
    return
  }
  let min_x = min3(p0.x, p1.x, p2.x).floor().to_int()
  let max_x = max3(p0.x, p1.x, p2.x).ceil().to_int()
  let min_y = min3(p0.y, p1.y, p2.y).floor().to_int()
  let max_y = max3(p0.y, p1.y, p2.y).ceil().to_int()
  let x_end = max_x + 1
  let y_end = max_y + 1

  for y in min_y..<y_end {
    for x in min_x..<x_end {
      let sample_x = x.to_double() + 0.5
      let sample_y = y.to_double() + 0.5
      let w0 = edge_function(p1.x, p1.y, p2.x, p2.y, sample_x, sample_y)
      let w1 = edge_function(p2.x, p2.y, p0.x, p0.y, sample_x, sample_y)
      let w2 = edge_function(p0.x, p0.y, p1.x, p1.y, sample_x, sample_y)
      let inside = if area > 0.0 {
        w0 >= 0.0 && w1 >= 0.0 && w2 >= 0.0
      } else {
        w0 <= 0.0 && w1 <= 0.0 && w2 <= 0.0
      }
      if inside {
        let inv_area = 1.0 / area
        let depth =
          (w0 * inv_area) * p0.depth +
          (w1 * inv_area) * p1.depth +
          (w2 * inv_area) * p2.depth
        buffer.set_pixel_if_closer(x, y, depth, pixel)
      }
    }
  }
}

fn FrameBuffer::to_string(self : FrameBuffer) -> String {
  let builder = StringBuilder::new()
  for y in 0..<self.height {
    for x in 0..<self.width {
      builder.write_char(self.cells[self.index(x, y)])
    }
    builder.write_char('\n')
  }
  builder.to_string()
}

fn render_mesh(mesh : Mesh, transform : Transform3, config : TuiRenderConfig) -> FrameBuffer {
  let transformed = transform.apply_mesh(mesh)
  let camera = { distance: config.camera_distance }
  let projection = {
    width: config.width,
    height: config.height,
    scale: config.projection_scale,
  }
  let points = project_vertices(transformed.vertices, camera, projection).map(fn(point) {
    apply_terminal_y_scale(point, config.height, config.terminal_y_scale)
  })
  let buffer = FrameBuffer::new(config.width, config.height, config.background_pattern)
  let camera_position = camera.position()
  for face in transformed.faces {
    if face_is_visible(transformed.vertices, face, camera_position) {
      let intensity = face_intensity(transformed.vertices, face, config.light_direction)
      let pixel = shade_char(config.shade_ramp, intensity)
      for triangle in triangulate_quad(face) {
        draw_triangle_z(
          buffer,
          points[triangle.a],
          points[triangle.b],
          points[triangle.c],
          pixel,
        )
      }
    }
  }
  buffer
}

fn render_frame(mesh : Mesh, transform : Transform3, config : TuiRenderConfig) -> String {
  render_mesh(mesh, transform, config).to_string()
}
