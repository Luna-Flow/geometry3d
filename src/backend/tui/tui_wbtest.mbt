///|
test "background patterns generate expected chars" {
  for y in 0..<4 {
    for x in 0..<4 {
      assert_eq(dotted_background(x, y, 4, 4), '.')
      assert_eq(blank_background(x, y, 4, 4), ' ')
    }
  }
}

///|
test "frame buffer initializes from pattern" {
  let dotted = FrameBuffer::new(8, 8, dotted_background)
  let dotted_count = dotted.cells.iter().filter(fn(ch) { ch == '.' }).count()
  let untouched_depths = dotted.depths
    .iter()
    .filter(fn(depth) { depth == FAR_DEPTH })
    .count()
  assert_eq(dotted_count, dotted.cells.length())
  assert_eq(untouched_depths, dotted.depths.length())
}

///|
test "terminal y scale is backend local" {
  let point = @view.ProjectedVertex::new(10.0, 8.0, 4.5)
  let scaled = apply_terminal_y_scale(point, 20, 0.5)
  assert_eq(scaled.x, 10.0)
  assert_eq(scaled.y, 9.0)
  assert_eq(scaled.depth, 4.5)
}

///|
test "z buffer prefers nearer triangle" {
  let buffer = FrameBuffer::new(8, 8, blank_background)
  let far_a = @view.ProjectedVertex::new(1.0, 1.0, 5.0)
  let far_b = @view.ProjectedVertex::new(6.0, 1.0, 5.0)
  let far_c = @view.ProjectedVertex::new(3.0, 6.0, 5.0)
  let near_a = @view.ProjectedVertex::new(1.0, 1.0, 2.0)
  let near_b = @view.ProjectedVertex::new(6.0, 1.0, 2.0)
  let near_c = @view.ProjectedVertex::new(3.0, 6.0, 2.0)

  draw_triangle_z(buffer, far_a, far_b, far_c, '.')
  let index = buffer.index(3, 3)
  assert_eq(buffer.cells[index], '.')

  draw_triangle_z(buffer, near_a, near_b, near_c, '#')
  assert_eq(buffer.cells[index], '#')
  assert_true(buffer.depths[index] < 5.0)
}

///|
test "z buffer uses perspective correct depth for sloped triangle" {
  let buffer = FrameBuffer::new(10, 10, blank_background)
  let front_a = @view.ProjectedVertex::new(1.0, 1.0, 4.0)
  let front_b = @view.ProjectedVertex::new(7.0, 1.0, 4.0)
  let front_c = @view.ProjectedVertex::new(4.0, 7.0, 4.0)
  let sloped_a = @view.ProjectedVertex::new(1.0, 1.0, 1.0)
  let sloped_b = @view.ProjectedVertex::new(7.0, 1.0, 10.0)
  let sloped_c = @view.ProjectedVertex::new(4.0, 7.0, 10.0)

  draw_triangle_z(buffer, front_a, front_b, front_c, '.')
  draw_triangle_z(buffer, sloped_a, sloped_b, sloped_c, '#')

  let index = buffer.index(4, 3)
  assert_eq(buffer.cells[index], '#')
  assert_true(buffer.depths[index] < 4.0)
}

///|
test "render draw list produces foreground pixels" {
  let draw_list = @frontend.DrawList::new()
  draw_list.push_triangle(
    @frontend.DrawTriangle::new(
      @view.ProjectedVertex::new(4.0, 4.0, 4.0),
      @view.ProjectedVertex::new(16.0, 4.0, 4.0),
      @view.ProjectedVertex::new(10.0, 14.0, 4.0),
      0.9,
    ),
  )
  let config = {
    width: 20,
    height: 16,
    terminal_y_scale: 1.0,
    shade_ramp: DEFAULT_SHADE_RAMP,
    background_pattern: dotted_background,
  }
  let buffer = render_draw_list(draw_list, config)
  let foreground = buffer.depths
    .iter()
    .filter(fn(depth) { depth < FAR_DEPTH })
    .count()
  assert_true(foreground > 0)
}

///|
test "tui luma conversion applies terminal y scale" {
  let draw_list = @frontend.DrawList::new()
  draw_list.push_triangle(
    @frontend.DrawTriangle::new(
      @view.ProjectedVertex::new(4.0, 2.0, 4.0),
      @view.ProjectedVertex::new(16.0, 2.0, 4.0),
      @view.ProjectedVertex::new(10.0, 14.0, 4.0),
      0.9,
    ),
  )
  let raw = @frontend.draw_list_to_luma(draw_list, 20, 16)
  let config = {
    width: 20,
    height: 16,
    terminal_y_scale: 0.5,
    shade_ramp: DEFAULT_SHADE_RAMP,
    background_pattern: dotted_background,
  }
  let corrected = draw_list_to_tui_luma(draw_list, config)
  assert_true(raw.get(10, 12) > 0.0)
  assert_eq(corrected.get(10, 12), 0.0)
}

///|
test "tui sequence encode decode roundtrips metadata and frames" {
  let sequence = TuiSequence::new(4, 2, 12)
  sequence.push_frame("abcd\nefgh\n")
  sequence.push_frame("1234\n5678\n")
  let decoded = decode_tui_sequence(encode_tui_sequence(sequence))
  assert_eq(decoded.width, 4)
  assert_eq(decoded.height, 2)
  assert_eq(decoded.fps, 12)
  assert_eq(decoded.frames.length(), 2)
  assert_eq(decoded.frames[0].content, "abcd\nefgh\n")
  assert_eq(decoded.frames[1].content, "1234\n5678\n")
}

///|
test "tui image encode decode roundtrips static frame" {
  let image = TuiImage::new(4, 2, "abcd\nefgh\n")
  let decoded = decode_tui_image(encode_tui_image(image))
  assert_eq(decoded.width, 4)
  assert_eq(decoded.height, 2)
  assert_eq(decoded.content, "abcd\nefgh\n")
}
