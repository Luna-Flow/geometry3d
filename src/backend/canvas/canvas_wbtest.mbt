///|
test "canvas config normalizes dimensions and colors" {
  let config = normalized_config({
    width: 0,
    height: -1,
    background_color: { red: -1, green: 20, blue: 300 },
    foreground_color: { red: 12, green: 34, blue: 56 },
    shade_levels: 1,
  })
  assert_eq(config.width, 640)
  assert_eq(config.height, 480)
  assert_eq(config.background_color.red, 0)
  assert_eq(config.background_color.blue, 255)
  assert_eq(config.shade_levels, 2)
}

///|
test "canvas shades clamp and quantize luma" {
  let color = CanvasColor::rgb(100, 200, 250)
  assert_eq(shade_css(color, 0, 256), "rgb(0, 0, 0)")
  assert_eq(shade_css(color, 255, 256), "rgb(100, 200, 250)")
  assert_eq(quantize_luma(-1.0, 256), 0)
  assert_eq(quantize_luma(2.0, 256), 255)
}

///|
test "canvas scanlines merge adjacent pixels with equal shade" {
  let buffer = @frontend.LumaBuffer::new(5, 1)
  buffer.set_if_closer(0, 0, 2.0, 0.5)
  buffer.set_if_closer(1, 0, 2.0, 0.5)
  buffer.set_if_closer(2, 0, 2.0, 1.0)
  buffer.set_if_closer(4, 0, 2.0, 0.0)
  let runs = scanline_runs(buffer, 256)
  assert_eq(runs.length(), 3)
  assert_eq(runs[0].x, 0)
  assert_eq(runs[0].width, 2)
  assert_eq(runs[1].x, 2)
  assert_eq(runs[2].x, 4)
  assert_eq(runs[2].shade, 0)
}

///|
test "canvas luma buffer preserves nearest triangle" {
  let draw_list = @frontend.DrawList::new()
  draw_list.push_triangle(
    @frontend.DrawTriangle::new(
      @view.ProjectedVertex::new(1.0, 1.0, 5.0),
      @view.ProjectedVertex::new(6.0, 1.0, 5.0),
      @view.ProjectedVertex::new(3.0, 6.0, 5.0),
      0.2,
    ),
  )
  draw_list.push_triangle(
    @frontend.DrawTriangle::new(
      @view.ProjectedVertex::new(1.0, 1.0, 2.0),
      @view.ProjectedVertex::new(6.0, 1.0, 2.0),
      @view.ProjectedVertex::new(3.0, 6.0, 2.0),
      0.9,
    ),
  )
  let buffer = @frontend.draw_list_to_luma(draw_list, 8, 8)
  assert_true(buffer.get(3, 3) > 0.8)
  assert_true(buffer.depth_at(3, 3) < 5.0)
}
