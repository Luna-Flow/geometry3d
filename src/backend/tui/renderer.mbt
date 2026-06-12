///|
pub const DEFAULT_WIDTH : Int = 80

///|
pub const DEFAULT_HEIGHT : Int = 32

///|
pub const DEFAULT_TERMINAL_Y_SCALE : Double = 0.5

///|
pub const DEFAULT_SHADE_RAMP : String = " .:-=+*#%@"

///|
pub struct TuiRenderConfig {
  width : Int
  height : Int
  terminal_y_scale : Double
  shade_ramp : String
  background_pattern : (Int, Int, Int, Int) -> Char
}

///|
pub fn TuiRenderConfig::default() -> TuiRenderConfig {
  {
    width: DEFAULT_WIDTH,
    height: DEFAULT_HEIGHT,
    terminal_y_scale: DEFAULT_TERMINAL_Y_SCALE,
    shade_ramp: DEFAULT_SHADE_RAMP,
    background_pattern: dotted_background,
  }
}

///|
pub fn TuiRenderConfig::sized(width : Int, height : Int) -> TuiRenderConfig {
  {
    width: if width > 0 {
      width
    } else {
      DEFAULT_WIDTH
    },
    height: if height > 0 {
      height
    } else {
      DEFAULT_HEIGHT
    },
    terminal_y_scale: DEFAULT_TERMINAL_Y_SCALE,
    shade_ramp: DEFAULT_SHADE_RAMP,
    background_pattern: dotted_background,
  }
}

///|
pub fn render_draw_list(
  draw_list : @frontend.DrawList,
  config : TuiRenderConfig,
) -> FrameBuffer {
  let buffer = FrameBuffer::new(
    config.width,
    config.height,
    config.background_pattern,
  )
  for triangle in draw_list.triangles {
    let p0 = apply_terminal_y_scale(
      triangle.p0,
      config.height,
      config.terminal_y_scale,
    )
    let p1 = apply_terminal_y_scale(
      triangle.p1,
      config.height,
      config.terminal_y_scale,
    )
    let p2 = apply_terminal_y_scale(
      triangle.p2,
      config.height,
      config.terminal_y_scale,
    )
    draw_triangle_z(
      buffer,
      p0,
      p1,
      p2,
      shade_char(config.shade_ramp, triangle.intensity),
    )
  }
  buffer
}

///|
pub fn render_frame(
  draw_list : @frontend.DrawList,
  config : TuiRenderConfig,
) -> String {
  render_draw_list(draw_list, config).to_string()
}

///|
pub fn render_scene(
  scene : @frontend.Scene,
  render_view : @frontend.RenderView,
  config : TuiRenderConfig,
) -> FrameBuffer {
  render_draw_list(@frontend.build_draw_list(scene, render_view), config)
}
