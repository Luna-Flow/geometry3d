# Frontend API

The frontend package turns geometry and view state into backend-neutral draw commands.

## Types

- `SceneObject`: mesh plus transform.
- `Light`: directional light.
- `Scene`: objects plus light.
- `RenderView`: camera plus perspective projection.
- `DrawTriangle`: projected triangle plus intensity.
- `DrawList`: ordered triangle commands for backends.
- `ShutterSpeed`: exposure duration in seconds.
- `ExposureSettings`: shutter, frame interval, and derived sample count.
- `LumaBuffer`: floating-point intensity buffer with depth values.
- `FlowVector` / `FlowField`: image-space optical-flow estimate.
- `Timeline`: duration and fps for deterministic offline sampling.
- `TimelineSample`: frame index, time in seconds, and normalized progress.
- `ScalarKeyframe` / `ScalarTrack`: scalar keyframes with linear interpolation.

## Functions

- `Scene::new(light)` / `Scene::single(mesh, transform, light)`.
- `Scene::add_object(object)`.
- `RenderView::perspective(camera, projection)`.
- `RenderView::scientific(camera, viewport)`.
- `build_draw_list(scene, render_view)`: transforms and culls geometry, builds a
  directional-light shadow map, and emits lit projected triangles.
- `ShutterSpeed::seconds(seconds)` / `ShutterSpeed::reciprocal(denominator)`.
- `ExposureSettings::auto(shutter, frame_dt)`.
- `draw_list_to_luma(draw_list, width, height)`.
- `estimate_optical_flow(previous, current, search_radius, patch_radius)`.
- `accumulate_with_flow(previous, current, flow)` / `average_luma(a, b)`.
- `Timeline::new(duration_seconds, fps)` / `frame_count` / `sample(frame_index)`.
- `ScalarTrack::sample(time_seconds)`.

`DrawList` does not contain `Char`, `FrameBuffer`, ANSI, or terminal aspect ratio details.
