///|
test "gsap demo selection defaults to torus" {
  assert_true(demo_kind("torus") is Torus)
  assert_true(demo_kind("unknown") is Torus)
  assert_true(demo_kind("dolly") is Dolly)
}

///|
test "gsap dolly scene contains subject and wall" {
  assert_eq(dolly_scene(0.0).objects.length(), 36)
}

///|
test "gsap dolly zoom keeps foreground scale stable" {
  let near = dolly_distance(0.0)
  let far = dolly_distance(1.0)
  let near_ratio = dolly_focal_length_mm(near) / near
  let far_ratio = dolly_focal_length_mm(far) / far
  assert_true((near_ratio - far_ratio).abs() < @core.DEPTH_EPSILON)
}
