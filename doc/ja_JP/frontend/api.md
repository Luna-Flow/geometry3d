# Frontend API

frontend package は geometry と view state を backend-neutral draw commands に変換します。

## Types

- `SceneObject`: mesh + transform。
- `Light`: directional light。
- `Scene`: objects + light。
- `RenderView`: camera + projection。
- `DrawTriangle`: projected triangle + intensity。
- `DrawList`: backend が消費する triangle command list。
- `ShutterSpeed`: seconds 単位の shutter duration。
- `ExposureSettings`: shutter、frame interval、derived sample count。
- `LumaBuffer`: depth 付き floating-point luma buffer。
- `FlowVector` / `FlowField`: image-space optical flow。
- `Timeline`: offline sampling 用の duration と fps。
- `TimelineSample`: frame index、seconds、normalized progress。
- `ScalarKeyframe` / `ScalarTrack`: linear interpolation する scalar keyframe track。

## API

- `Scene::new` / `Scene::single`
- `Scene::add_object`
- `RenderView::perspective`
- `RenderView::scientific`
- `build_draw_list`
- `ShutterSpeed::seconds` / `ShutterSpeed::reciprocal`
- `ExposureSettings::auto`
- `draw_list_to_luma`
- `estimate_optical_flow`
- `accumulate_with_flow` / `average_luma`
- `Timeline::new` / `frame_count` / `sample`
- `ScalarTrack::sample`

`DrawList` は `Char`、`FrameBuffer`、ANSI、terminal aspect ratio を含みません。
