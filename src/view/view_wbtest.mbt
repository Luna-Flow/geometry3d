test "look_at maps target in front of camera" {
  let camera = Camera3::default(4.5)
  let target = camera.world_to_camera_point(@core.vec3(0.0, 0.0, 0.0))
  assert_true((target[0] - 0.0).abs() < @core.DEPTH_EPSILON)
  assert_true((target[1] - 0.0).abs() < @core.DEPTH_EPSILON)
  assert_true((target[2] - 4.5).abs() < @core.DEPTH_EPSILON)
}

test "perspective projection emits expected depth" {
  let projection = PerspectiveProjection::new(Viewport::new(80, 32), 24.0)
  let point = projection.project_point(@core.vec3(0.0, 1.0, 4.5))
  let expected_y = 32.0 / 2.0 - 24.0 / 4.5
  assert_true((point.depth - 4.5).abs() < @core.DEPTH_EPSILON)
  assert_true((point.y - expected_y).abs() < @core.DEPTH_EPSILON)
}

test "orthographic and perspective projections differ with depth" {
  let viewport = Viewport::new(80, 32)
  let perspective = PerspectiveProjection::new(viewport, 24.0)
  let orthographic = OrthographicProjection::new(viewport, 24.0)
  let point = @core.vec3(1.0, 0.0, 4.0)
  let p = perspective.project_point(point)
  let o = orthographic.project_point(point)
  assert_true((p.x - o.x).abs() > 1.0)
}

test "perspective depth interpolation differs from linear depth on sloped triangle" {
  let p0 = ProjectedVertex::new(1.0, 1.0, 1.0)
  let p1 = ProjectedVertex::new(7.0, 1.0, 10.0)
  let p2 = ProjectedVertex::new(4.0, 7.0, 10.0)
  let b0 = 0.20833333333333334
  let b1 = 0.375
  let b2 = 0.4166666666666667
  let linear = b0 * p0.depth + b1 * p1.depth + b2 * p2.depth
  let corrected = interpolate_perspective_depth(p0, p1, p2, b0, b1, b2)
  assert_true(linear > 8.0)
  assert_true(corrected < 4.0)
}

test "sensor presets and custom dimensions are positive" {
  let apsc = SensorSpec::apsc()
  let full = SensorSpec::full_frame()
  let medium = SensorSpec::medium_format()
  let custom = SensorSpec::custom(-1.0, 0.0)
  assert_true(apsc.width_mm > 20.0 && apsc.height_mm > 10.0)
  assert_eq(full.width_mm, 36.0)
  assert_eq(full.height_mm, 24.0)
  assert_true(medium.width_mm > full.width_mm)
  assert_eq(custom.width_mm, 1.0)
  assert_eq(custom.height_mm, 1.0)
}

test "50mm full frame field of view is plausible" {
  let sensor = SensorSpec::full_frame()
  let lens = LensSpec::new(50.0)
  let h_fov = lens.horizontal_fov(sensor)
  let v_fov = lens.vertical_fov(sensor)
  assert_true(h_fov > 0.65 && h_fov < 0.75)
  assert_true(v_fov > 0.45 && v_fov < 0.50)
}

test "scientific camera derives perspective scale" {
  let viewport = Viewport::new(80, 32)
  let scientific = ScientificCamera::auto(viewport)
  let projection = scientific.to_perspective_projection(viewport)
  assert_true(projection.scale > 60.0)
}

test "world unit converts focal length into world units" {
  let camera = ScientificCamera::new(
    Camera3::default(4.5),
    SensorSpec::full_frame(),
    LensSpec::new(50.0),
    WorldUnit::new(0.01),
  )
  assert_true((camera.focal_length_world_units() - 5.0).abs() < @core.DEPTH_EPSILON)
}
