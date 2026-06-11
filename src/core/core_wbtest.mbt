test "cube and sphere mesh factories expose stable topology" {
  let cube = cube_mesh(1.0)
  assert_eq(cube.vertices.length(), 8)
  assert_eq(cube.faces.length(), 6)
  assert_eq(triangulate_quad(cube.faces[0]).length(), 2)

  let sphere = sphere_mesh(1.0, 6, 12)
  assert_eq(sphere.vertices.length(), 62)
  assert_eq(sphere.faces.length(), 72)
}

test "primitive mesh factories expose stable topology" {
  let cylinder = cylinder_mesh(1.0, 2.0, 12)
  assert_eq(cylinder.vertices.length(), 26)
  assert_eq(cylinder.faces.length(), 36)

  let cone = cone_mesh(1.0, 2.0, 12)
  assert_eq(cone.vertices.length(), 14)
  assert_eq(cone.faces.length(), 24)

  let pyramid = triangular_pyramid_mesh(1.0, 2.0)
  assert_eq(pyramid.vertices.length(), 4)
  assert_eq(pyramid.faces.length(), 4)
}

test "identity transform preserves point" {
  let point = vec3(1.0, -2.0, 3.0)
  let out = Transform3::identity().apply_point(point)
  assert_eq(out[0], 1.0)
  assert_eq(out[1], -2.0)
  assert_eq(out[2], 3.0)
}

test "translation affects points but not directions" {
  let transform = Transform3::translation(2.0, 3.0, 4.0)
  let point = transform.apply_point(vec3(1.0, 1.0, 1.0))
  let direction = transform.apply_direction(vec3(1.0, 1.0, 1.0))
  assert_eq(point[0], 3.0)
  assert_eq(point[1], 4.0)
  assert_eq(point[2], 5.0)
  assert_eq(direction[0], 1.0)
  assert_eq(direction[1], 1.0)
  assert_eq(direction[2], 1.0)
}

test "scale transform preserves mesh topology" {
  let mesh = cube_mesh(1.0)
  let scaled = Transform3::scale(2.0, 3.0, 4.0).apply_mesh(mesh)
  assert_eq(scaled.vertices.length(), mesh.vertices.length())
  assert_eq(scaled.faces.length(), mesh.faces.length())
  assert_eq(scaled.vertices[1][0], 2.0)
  assert_eq(scaled.vertices[2][1], 3.0)
}

test "compose applies self then next" {
  let transform = Transform3::translation(1.0, 0.0, 0.0).compose(
    Transform3::scale(2.0, 2.0, 2.0),
  )
  let point = transform.apply_point(vec3(1.0, 1.0, 1.0))
  assert_eq(point[0], 4.0)
  assert_eq(point[1], 2.0)
  assert_eq(point[2], 2.0)
}

test "face normal and visibility remain stable" {
  let mesh = cube_mesh(1.0)
  let front = mesh.faces[0]
  let normal = face_normal(mesh.vertices, front)
  assert_true((normal[2] - -1.0).abs() < DEPTH_EPSILON)
  assert_true(face_is_visible(mesh.vertices, front, vec3(0.0, 0.0, -4.5)))
}
