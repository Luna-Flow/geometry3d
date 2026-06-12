///|
pub fn apply_terminal_y_scale(
  point : @view.ProjectedVertex,
  height : Int,
  terminal_y_scale : Double,
) -> @view.ProjectedVertex {
  let center_y = height.to_double() / 2.0
  @view.ProjectedVertex::new(
    point.x,
    center_y + (point.y - center_y) * terminal_y_scale,
    point.depth,
  )
}

///|
pub fn clamp01(value : Double) -> Double {
  if value < 0.0 {
    0.0
  } else if value > 1.0 {
    1.0
  } else {
    value
  }
}

///|
pub fn shade_char(shade_ramp : String, intensity : Double) -> Char {
  let clamped = clamp01(intensity)
  let last_index = shade_ramp.length() - 1
  let index = (clamped * last_index.to_double()).round().to_int()
  shade_ramp[index].unsafe_to_char()
}

///|
pub fn edge_function(
  ax : Double,
  ay : Double,
  bx : Double,
  by : Double,
  px : Double,
  py : Double,
) -> Double {
  (px - ax) * (by - ay) - (py - ay) * (bx - ax)
}

///|
pub fn draw_triangle_z(
  buffer : FrameBuffer,
  p0 : @view.ProjectedVertex,
  p1 : @view.ProjectedVertex,
  p2 : @view.ProjectedVertex,
  pixel : Char,
) -> Unit {
  let area = edge_function(p0.x, p0.y, p1.x, p1.y, p2.x, p2.y)
  if area.abs() <= @core.DEPTH_EPSILON {
    return
  }
  let min_x = @core.min3(p0.x, p1.x, p2.x).floor().to_int()
  let max_x = @core.max3(p0.x, p1.x, p2.x).ceil().to_int()
  let min_y = @core.min3(p0.y, p1.y, p2.y).floor().to_int()
  let max_y = @core.max3(p0.y, p1.y, p2.y).ceil().to_int()
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
        let b0 = w0 * inv_area
        let b1 = w1 * inv_area
        let b2 = w2 * inv_area
        let depth = @view.interpolate_perspective_depth(p0, p1, p2, b0, b1, b2)
        buffer.set_pixel_if_closer(x, y, depth, pixel)
      }
    }
  }
}
