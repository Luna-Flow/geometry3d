# Frontend API

frontend package 将 geometry 和 view 状态转换为 backend-neutral draw commands。

## 类型

- `SceneObject`：mesh + transform。
- `Light`：方向光。
- `Scene`：objects + light。
- `RenderView`：camera + projection。
- `DrawTriangle`：projected triangle + intensity。
- `DrawList`：backend 可消费的 triangle 命令列表。
- `ShutterSpeed`：以秒表示的快门时间。
- `ExposureSettings`：快门、帧间隔和推导出的采样数。
- `LumaBuffer`：带 depth 的浮点亮度缓冲。
- `FlowVector` / `FlowField`：图像空间 optical flow。
- `Timeline`：用于离线采样的时长和 fps。
- `TimelineSample`：frame index、秒时间和归一化 progress。
- `ScalarKeyframe` / `ScalarTrack`：线性插值的标量关键帧轨道。

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

`DrawList` 不包含 `Char`、`FrameBuffer`、ANSI 或 terminal aspect ratio。
