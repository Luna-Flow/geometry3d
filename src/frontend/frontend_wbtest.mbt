test "scene builds backend-neutral draw list" {
  let viewport = @view.Viewport::new(40, 20)
  let camera = @view.Camera3::default(4.5)
  let projection = @view.PerspectiveProjection::new(viewport, 18.0)
  let render_view = RenderView::perspective(camera, projection)
  let scene = Scene::single(
    @core.cube_mesh(1.0),
    @core.Transform3::rotation(0.0, 0.0, 0.0),
    Light::default(),
  )
  let draw_list = build_draw_list(scene, render_view)
  assert_true(draw_list.triangles.length() > 0)
  assert_true(draw_list.triangles[0].intensity >= 0.0)
}

test "scene can combine multiple objects" {
  let scene = Scene::new(Light::default())
  scene.add_object(SceneObject::new(@core.cube_mesh(1.0), @core.Transform3::identity()))
  scene.add_object(SceneObject::new(
    @core.sphere_mesh(1.0, 4, 8),
    @core.Transform3::translation(1.5, 0.0, 0.0),
  ))
  assert_eq(scene.objects.length(), 2)
}

test "render view can be built from scientific camera" {
  let viewport = @view.Viewport::new(40, 20)
  let scientific = @view.ScientificCamera::new(
    @view.Camera3::default(4.5),
    @view.SensorSpec::full_frame(),
    @view.LensSpec::new(35.0),
    @view.WorldUnit::unitless(),
  )
  let render_view = RenderView::scientific(scientific, viewport)
  assert_true(render_view.projection.scale > 20.0)
}

test "exposure settings clamp shutter to frame duration" {
  let shutter = ShutterSpeed::reciprocal(30.0)
  let exposure = ExposureSettings::auto(shutter, 1.0 / 60.0)
  assert_true((shutter.seconds - 1.0 / 30.0).abs() < @core.DEPTH_EPSILON)
  assert_true((exposure.shutter.seconds - exposure.frame_dt).abs() < @core.DEPTH_EPSILON)
  assert_eq(exposure.samples, 1)
}

test "draw list converts to luma buffer" {
  let viewport = @view.Viewport::new(40, 20)
  let camera = @view.Camera3::default(4.5)
  let projection = @view.PerspectiveProjection::new(viewport, 18.0)
  let render_view = RenderView::perspective(camera, projection)
  let scene = Scene::single(
    @core.cube_mesh(1.0),
    @core.Transform3::rotation(0.2, 0.3, 0.0),
    Light::default(),
  )
  let buffer = draw_list_to_luma(build_draw_list(scene, render_view), 40, 20)
  let lit = buffer.values.iter().filter(fn(value) { value > 0.0 }).count()
  assert_true(lit > 0)
}

test "luma buffer uses perspective correct depth for sloped triangle" {
  let buffer = LumaBuffer::new(10, 10)
  buffer.draw_triangle(DrawTriangle::new(
    @view.ProjectedVertex::new(1.0, 1.0, 4.0),
    @view.ProjectedVertex::new(7.0, 1.0, 4.0),
    @view.ProjectedVertex::new(4.0, 7.0, 4.0),
    0.2,
  ))
  buffer.draw_triangle(DrawTriangle::new(
    @view.ProjectedVertex::new(1.0, 1.0, 1.0),
    @view.ProjectedVertex::new(7.0, 1.0, 10.0),
    @view.ProjectedVertex::new(4.0, 7.0, 10.0),
    0.9,
  ))

  assert_true(buffer.get(4, 3) > 0.8)
  assert_true(buffer.depth_at(4, 3) < 4.0)
}

test "shadow map path keeps occluded scene renderable" {
  let viewport = @view.Viewport::new(40, 20)
  let camera = @view.Camera3::default(4.5)
  let projection = @view.PerspectiveProjection::new(viewport, 18.0)
  let render_view = RenderView::perspective(camera, projection)
  let light = Light::directional(@core.vec3(0.0, 0.0, -1.0))
  let receiver_transform = @core.Transform3::scale(2.0, 2.0, 0.05).compose(
    @core.Transform3::translation(0.0, 0.0, 3.0),
  )
  let occluder_transform = @core.Transform3::scale(1.5, 1.5, 0.05).compose(
    @core.Transform3::translation(0.0, 0.0, 2.0),
  )

  let receiver_scene = Scene::single(@core.cube_mesh(1.0), receiver_transform, light)
  let receiver_only = build_draw_list(receiver_scene, render_view)
  assert_true(receiver_only.triangles[0].intensity > 0.9)

  let shadowed_scene = Scene::new(light)
  shadowed_scene.add_object(SceneObject::new(@core.cube_mesh(1.0), receiver_transform))
  shadowed_scene.add_object(SceneObject::new(@core.cube_mesh(1.0), occluder_transform))
  let shadowed = build_draw_list(shadowed_scene, render_view)
  let shadowed_buffer = draw_list_to_luma(shadowed, 40, 20)
  let lit = shadowed_buffer.values.iter().filter(fn(value) { value > 0.0 }).count()
  assert_true(shadowed.triangles.length() > receiver_only.triangles.length())
  assert_true(lit > 0)
}

test "optical flow detects translated luma patch" {
  let previous = LumaBuffer::new(9, 9)
  let current = LumaBuffer::new(9, 9)
  previous.values[previous.index(3, 4)] = 1.0
  current.values[current.index(4, 4)] = 1.0
  let flow = estimate_optical_flow(previous, current, 2, 0)
  let vector = flow.get(4, 4)
  assert_eq(vector.dx, -1)
  assert_eq(vector.dy, 0)
}

test "flow accumulation preserves static luma" {
  let previous = LumaBuffer::new(4, 4)
  let current = LumaBuffer::new(4, 4)
  previous.values[previous.index(1, 1)] = 0.8
  current.values[current.index(1, 1)] = 0.8
  let flow = estimate_optical_flow(previous, current, 1, 0)
  let out = accumulate_with_flow(previous, current, flow)
  assert_true((out.get(1, 1) - 0.8).abs() < @core.DEPTH_EPSILON)
}

test "timeline derives frame count and samples" {
  let timeline = Timeline::new(2.0, 30)
  let sample = timeline.sample(15)
  assert_eq(timeline.frame_count(), 60)
  assert_true((sample.time_seconds - 0.5).abs() < @core.DEPTH_EPSILON)
  assert_true((sample.progress - 0.25).abs() < @core.DEPTH_EPSILON)
}

test "scalar track linearly interpolates keyframes" {
  let track = ScalarTrack::new([
    ScalarKeyframe::new(0.0, 10.0),
    ScalarKeyframe::new(2.0, 30.0),
  ])
  assert_true((track.sample(1.0) - 20.0).abs() < @core.DEPTH_EPSILON)
  assert_eq(track.sample(-1.0), 10.0)
  assert_eq(track.sample(3.0), 30.0)
}
