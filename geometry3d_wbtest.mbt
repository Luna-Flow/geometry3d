test "cube mesh has eight vertices and six faces" {
  let mesh = cube_mesh(1.0)
  assert_eq(mesh.vertices.length(), 8)
  assert_eq(mesh.faces.length(), 6)
  assert_eq(triangulate_quad(mesh.faces[0]).length(), 2)
}

test "sphere mesh has expected rings and segments" {
  let mesh = sphere_mesh(1.0, 6, 12)
  assert_eq(mesh.vertices.length(), 62)
  assert_eq(mesh.faces.length(), 72)
  assert_eq(triangulate_quad(mesh.faces[0]).length(), 2)
}

test "zero rotation preserves vertex" {
  let vertex = vec3(1.0, -2.0, 3.0)
  let rotated = Transform3::rotation(0.0, 0.0, 0.0).apply_vertex(vertex)
  assert_eq(rotated[0], 1.0)
  assert_eq(rotated[1], -2.0)
  assert_eq(rotated[2], 3.0)
}

test "transform mesh preserves vertex count" {
  let mesh = cube_mesh(1.0)
  let transformed = Transform3::rotation(0.2, 0.3, 0.1).apply_mesh(mesh)
  assert_eq(transformed.vertices.length(), mesh.vertices.length())
  assert_eq(transformed.faces.length(), mesh.faces.length())
}

test "face normal and visibility are stable" {
  let mesh = cube_mesh(1.0)
  let front = mesh.faces[0]
  let normal = face_normal(mesh.vertices, front)
  assert_true((normal[0] - 0.0).abs() < DEPTH_EPSILON)
  assert_true((normal[1] - 0.0).abs() < DEPTH_EPSILON)
  assert_true((normal[2] - -1.0).abs() < DEPTH_EPSILON)
  assert_true(face_is_visible(mesh.vertices, front, vec3(0.0, 0.0, -4.5)))
}

test "projection emits expected projected vertices" {
  let mesh = cube_mesh(1.0)
  let camera = { distance: 4.5 }
  let projection = { width: 80, height: 32, scale: 24.0 }
  let points = project_vertices(mesh.vertices, camera, projection)
  assert_eq(points.length(), 8)
  assert_true((points[0].depth - 3.5).abs() < DEPTH_EPSILON)
}

test "terminal y scale is applied in tui layer" {
  let camera = { distance: 4.5 }
  let projection = { width: 80, height: 32, scale: 24.0 }
  let projected = project_vertex(vec3(0.0, 1.0, 0.0), camera, projection)
  let scaled = apply_terminal_y_scale(projected, projection.height, 0.5)
  let expected_core_y = projection.height.to_double() / 2.0 - 24.0 / 4.5
  let expected_scaled_y = projection.height.to_double() / 2.0 - (24.0 / 4.5) * 0.5
  assert_true((projected.y - expected_core_y).abs() < DEPTH_EPSILON)
  assert_true((scaled.y - expected_scaled_y).abs() < DEPTH_EPSILON)
}

test "background patterns generate expected chars" {
  for y in 0..<4 {
    for x in 0..<4 {
      assert_eq(dotted_background(x, y, 4, 4), '.')
      assert_eq(blank_background(x, y, 4, 4), ' ')
    }
  }
}

test "frame buffer initializes from pattern" {
  let dotted = FrameBuffer::new(8, 8, dotted_background)
  let dotted_count = dotted.cells.iter().filter(fn(ch) { ch == '.' }).count()
  let untouched_depths = dotted.depths.iter().filter(fn(depth) { depth == FAR_DEPTH }).count()
  assert_eq(dotted_count, dotted.cells.length())
  assert_eq(untouched_depths, dotted.depths.length())

  let blank = FrameBuffer::new(8, 8, blank_background)
  let blank_count = blank.cells.iter().filter(fn(ch) { ch == ' ' }).count()
  assert_eq(blank_count, blank.cells.length())
}

test "z buffer prefers nearer triangle" {
  let buffer = FrameBuffer::new(8, 8, blank_background)
  let far_a = { x: 1.0, y: 1.0, depth: 5.0 }
  let far_b = { x: 6.0, y: 1.0, depth: 5.0 }
  let far_c = { x: 3.0, y: 6.0, depth: 5.0 }
  let near_a = { x: 1.0, y: 1.0, depth: 2.0 }
  let near_b = { x: 6.0, y: 1.0, depth: 2.0 }
  let near_c = { x: 3.0, y: 6.0, depth: 2.0 }

  draw_triangle_z(buffer, far_a, far_b, far_c, '.')
  let index = buffer.index(3, 3)
  assert_eq(buffer.cells[index], '.')

  draw_triangle_z(buffer, near_a, near_b, near_c, '#')
  assert_eq(buffer.cells[index], '#')
  assert_true(buffer.depths[index] < 5.0)
}

test "render mesh produces foreground pixels" {
  let mesh = cube_mesh(1.0)
  let config = {
    width: 40,
    height: 20,
    projection_scale: 18.0,
    terminal_y_scale: 0.5,
    camera_distance: 4.5,
    shade_ramp: DEFAULT_SHADE_RAMP,
    background_pattern: dotted_background,
    light_direction: normalize_vec(vec3(0.6, 0.7, -1.0)),
  }
  let buffer = render_mesh(mesh, Transform3::rotation(0.0, 0.0, 0.0), config)
  let foreground = buffer.depths.iter().filter(fn(depth) { depth < FAR_DEPTH }).count()
  assert_true(foreground > 0)
}

test "render sphere mesh produces foreground pixels" {
  let mesh = sphere_mesh(1.25, 8, 16)
  let config = {
    width: 40,
    height: 20,
    projection_scale: 18.0,
    terminal_y_scale: 0.5,
    camera_distance: 4.5,
    shade_ramp: DEFAULT_SHADE_RAMP,
    background_pattern: dotted_background,
    light_direction: normalize_vec(vec3(0.6, 0.7, -1.0)),
  }
  let buffer = render_mesh(mesh, Transform3::rotation(0.2, 0.4, 0.0), config)
  let foreground = buffer.depths.iter().filter(fn(depth) { depth < FAR_DEPTH }).count()
  assert_true(foreground > 0)
}
