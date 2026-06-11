test "hitchcock scene contains central subject and background objects" {
  let scene = hitchcock_scene()
  assert_eq(scene.objects.length(), 6)
}

test "hitchcock zoom keeps subject scale ratio stable" {
  let d0 = hitchcock_distance(0)
  let d1 = hitchcock_distance(60)
  let r0 = hitchcock_focal_length_mm(d0) / d0
  let r1 = hitchcock_focal_length_mm(d1) / d1
  assert_true((r0 - r1).abs() < @core.DEPTH_EPSILON)
}

test "hitchcock scene produces draw commands" {
  let draw_list = @frontend.build_draw_list(hitchcock_scene(), hitchcock_render_view(0))
  assert_true(draw_list.triangles.length() > 0)
}

test "hitchcock frame renders foreground characters" {
  let frame = hitchcock_frame(0)
  let foreground = frame.iter().filter(fn(ch) { ch != '.' && ch != '\n' }).count()
  assert_true(foreground > 0)
}

test "flow exposure mesh frame renders foreground characters" {
  let frame = exposure_mesh_frame(@core.cube_mesh(1.0), 0.2, 0.3, 0.0, true)
  let foreground = frame.iter().filter(fn(ch) { ch != '.' && ch != '\n' }).count()
  assert_true(foreground > 0)
}

test "long exposure mesh frame differs from normal dynamic frame" {
  let mesh = @core.cube_mesh(1.0)
  let normal = mesh_frame(mesh, 0.2, 0.3, 0.0)
  let exposure = exposure_mesh_frame(mesh, 0.2, 0.3, 0.0, false)
  assert_true(normal != exposure)
}

test "flow exposure hitchcock frame renders foreground characters" {
  let frame = exposure_hitchcock_frame(1, true)
  let foreground = frame.iter().filter(fn(ch) { ch != '.' && ch != '\n' }).count()
  assert_true(foreground > 0)
}

test "demo can render a playable tui sequence" {
  let args : Array[String] = []
  let sequence = render_demo_sequence(args, @frontend.Timeline::new(1.0, 2))
  assert_eq(sequence.width, @tui.DEFAULT_WIDTH)
  assert_eq(sequence.height, @tui.DEFAULT_HEIGHT)
  assert_eq(sequence.fps, 2)
  assert_eq(sequence.frames.length(), 2)
  assert_true(sequence.frames[0].content.length() > 0)
}

test "demo can render a static tui image" {
  let args : Array[String] = []
  let image = render_demo_image(args)
  assert_eq(image.width, @tui.DEFAULT_WIDTH)
  assert_eq(image.height, @tui.DEFAULT_HEIGHT)
  assert_true(image.content.length() > 0)
}
