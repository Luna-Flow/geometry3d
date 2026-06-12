///|
pub fn draw_list_to_tui_luma(
  draw_list : @frontend.DrawList,
  config : TuiRenderConfig,
) -> @frontend.LumaBuffer {
  let buffer = @frontend.LumaBuffer::new(config.width, config.height)
  for triangle in draw_list.triangles {
    buffer.draw_triangle(
      @frontend.DrawTriangle::new(
        apply_terminal_y_scale(
          triangle.p0,
          config.height,
          config.terminal_y_scale,
        ),
        apply_terminal_y_scale(
          triangle.p1,
          config.height,
          config.terminal_y_scale,
        ),
        apply_terminal_y_scale(
          triangle.p2,
          config.height,
          config.terminal_y_scale,
        ),
        triangle.intensity,
      ),
    )
  }
  buffer
}

///|
pub fn render_luma_buffer(
  buffer : @frontend.LumaBuffer,
  config : TuiRenderConfig,
) -> FrameBuffer {
  let out = FrameBuffer::new(
    config.width,
    config.height,
    config.background_pattern,
  )
  let width = if buffer.width < config.width {
    buffer.width
  } else {
    config.width
  }
  let height = if buffer.height < config.height {
    buffer.height
  } else {
    config.height
  }
  for y in 0..<height {
    for x in 0..<width {
      let value = buffer.get(x, y)
      if value > 0.0 {
        out.set_pixel_if_closer(
          x,
          y,
          buffer.depths[buffer.index(x, y)],
          shade_char(config.shade_ramp, value),
        )
      }
    }
  }
  out
}

///|
pub fn render_luma_frame(
  buffer : @frontend.LumaBuffer,
  config : TuiRenderConfig,
) -> String {
  render_luma_buffer(buffer, config).to_string()
}
