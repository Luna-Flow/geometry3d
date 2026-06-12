///|
pub struct CanvasColor {
  red : Int
  green : Int
  blue : Int
}

///|
pub struct CanvasRenderConfig {
  width : Int
  height : Int
  background_color : CanvasColor
  foreground_color : CanvasColor
  shade_levels : Int
}

///|
priv struct ScanlineRun {
  x : Int
  y : Int
  width : Int
  shade : Int
}

///|
pub fn CanvasColor::rgb(red : Int, green : Int, blue : Int) -> CanvasColor {
  {
    red: clamp_channel(red),
    green: clamp_channel(green),
    blue: clamp_channel(blue),
  }
}

///|
pub fn CanvasRenderConfig::default() -> CanvasRenderConfig {
  CanvasRenderConfig::sized(640, 480)
}

///|
pub fn CanvasRenderConfig::sized(
  width : Int,
  height : Int,
) -> CanvasRenderConfig {
  {
    width: if width > 0 {
      width
    } else {
      640
    },
    height: if height > 0 {
      height
    } else {
      480
    },
    background_color: CanvasColor::rgb(7, 12, 22),
    foreground_color: CanvasColor::rgb(112, 226, 255),
    shade_levels: 256,
  }
}

///|
fn clamp_channel(value : Int) -> Int {
  if value < 0 {
    0
  } else if value > 255 {
    255
  } else {
    value
  }
}

///|
fn clamp01(value : Double) -> Double {
  if value < 0.0 {
    0.0
  } else if value > 1.0 {
    1.0
  } else {
    value
  }
}

///|
fn normalized_shade_levels(levels : Int) -> Int {
  if levels < 2 {
    2
  } else if levels > 256 {
    256
  } else {
    levels
  }
}

///|
fn quantize_luma(value : Double, levels : Int) -> Int {
  let count = normalized_shade_levels(levels)
  (clamp01(value) * (count - 1).to_double()).round().to_int()
}

///|
fn color_css(color : CanvasColor) -> String {
  "rgb(\{color.red}, \{color.green}, \{color.blue})"
}

///|
fn shade_css(color : CanvasColor, shade : Int, levels : Int) -> String {
  let last = normalized_shade_levels(levels) - 1
  let clamped = if shade < 0 { 0 } else if shade > last { last } else { shade }
  let scale = clamped.to_double() / last.to_double()
  color_css(
    CanvasColor::rgb(
      (color.red.to_double() * scale).round().to_int(),
      (color.green.to_double() * scale).round().to_int(),
      (color.blue.to_double() * scale).round().to_int(),
    ),
  )
}

///|
fn scanline_runs(
  buffer : @frontend.LumaBuffer,
  shade_levels : Int,
) -> Array[ScanlineRun] {
  let runs : Array[ScanlineRun] = []
  for y in 0..<buffer.height {
    let mut x = 0
    while x < buffer.width {
      if buffer.depth_at(x, y) >= @frontend.LUMA_FAR_DEPTH * 0.5 {
        x += 1
        continue
      }
      let shade = quantize_luma(buffer.get(x, y), shade_levels)
      let start = x
      x += 1
      while x < buffer.width &&
            buffer.depth_at(x, y) < @frontend.LUMA_FAR_DEPTH * 0.5 &&
            quantize_luma(buffer.get(x, y), shade_levels) == shade {
        x += 1
      }
      runs.push({ x: start, y, width: x - start, shade })
    }
  }
  runs
}

///|
fn normalized_config(config : CanvasRenderConfig) -> CanvasRenderConfig {
  {
    width: if config.width > 0 {
      config.width
    } else {
      640
    },
    height: if config.height > 0 {
      config.height
    } else {
      480
    },
    background_color: CanvasColor::rgb(
      config.background_color.red,
      config.background_color.green,
      config.background_color.blue,
    ),
    foreground_color: CanvasColor::rgb(
      config.foreground_color.red,
      config.foreground_color.green,
      config.foreground_color.blue,
    ),
    shade_levels: normalized_shade_levels(config.shade_levels),
  }
}

///|
pub fn render_draw_list(
  context : @dom.CanvasRenderingContext2D,
  draw_list : @frontend.DrawList,
  config : CanvasRenderConfig,
) -> Unit {
  let config = normalized_config(config)
  context.set_fill_style(@js.Union3::from0(color_css(config.background_color)))
  context.fill_rect(
    0.0,
    0.0,
    config.width.to_double(),
    config.height.to_double(),
  )
  let buffer = @frontend.draw_list_to_luma(
    draw_list,
    config.width,
    config.height,
  )
  let mut active_shade = -1
  for run in scanline_runs(buffer, config.shade_levels) {
    if run.shade != active_shade {
      active_shade = run.shade
      context.set_fill_style(
        @js.Union3::from0(
          shade_css(config.foreground_color, run.shade, config.shade_levels),
        ),
      )
    }
    context.fill_rect(
      run.x.to_double(),
      run.y.to_double(),
      run.width.to_double(),
      1.0,
    )
  }
}

///|
pub fn render_scene(
  context : @dom.CanvasRenderingContext2D,
  scene : @frontend.Scene,
  render_view : @frontend.RenderView,
  config : CanvasRenderConfig,
) -> Unit {
  render_draw_list(
    context,
    @frontend.build_draw_list(scene, render_view),
    config,
  )
}

///|
pub fn render_canvas(
  canvas : @dom.HTMLCanvasElement,
  draw_list : @frontend.DrawList,
  config : CanvasRenderConfig,
) -> Unit {
  let config = normalized_config(config)
  canvas.set_attribute("width", config.width.to_string())
  canvas.set_attribute("height", config.height.to_string())
  let context = canvas.get_context("2d").to0().unwrap()
  render_draw_list(context, draw_list, config)
}
