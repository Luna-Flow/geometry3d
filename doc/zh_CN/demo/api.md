# Demo API

demo 是包入口和终端 runner。

## 函数

- `demo_mesh(args)`：根据参数选择 sphere、torus 或 cube。
- `demo_should_rotate(args)`：cube 默认旋转，sphere 默认静止。
- `hitchcock_scene()`：中心 cube + 背景圆柱、圆锥、三棱锥几何体。
- `hitchcock_render_view(frame)`：camera dolly 与科学相机焦距补偿。
- `hitchcock_frame(frame)`：渲染一帧 Hitchcock/dolly zoom 场景。
- `mesh_frame(mesh, angle_x, angle_y, angle_z)`：渲染一帧字符串。
- `exposure_mesh_frame(mesh, angle_x, angle_y, angle_z, use_flow)`：通过 `LumaBuffer` 渲染伪长曝光帧。
- `exposure_hitchcock_frame(frame, use_flow)`：Hitchcock 伪长曝光 demo。
- `render_demo_image(args)`：按当前 demo 模式渲染一张静态 TUI 图。
- `render_demo_sequence(args, timeline)`：离线渲染可播放的 TUI 序列。
- `play_sequence(sequence, frame_limit)`：按序列 fps 播放字符帧。
- `render_once(mesh, angle_x, angle_y, angle_z)`：清屏并输出一帧。
- `run_animation(mesh, rotate, frame_limit, exposure, use_flow, render_view)`：运行帧循环。
- `main`：解析 `--sphere`、`--torus`、`--hitchcock`、`--camera-auto`、`--long-exposure`、`--flow-exposure`、`--export-image`、`--show-image`、`--record`、`--play`、`--duration`、`--fps` 和 `--once`。

## CLI

```sh
moon run src/demo --target native
moon run src/demo --target native -- --once
moon run src/demo --target native -- --sphere
moon run src/demo --target native -- --sphere --once
moon run src/demo --target native -- --torus
moon run src/demo --target native -- --hitchcock
moon run src/demo --target native -- --hitchcock --once
moon run src/demo --target native -- --camera-auto --once
moon run src/demo --target native -- --long-exposure --once
moon run src/demo --target native -- --hitchcock --flow-exposure --once
mkdir -p target
moon run src/demo --target native -- --record target/demo.tui3d --duration 3 --fps 30
moon run src/demo --target native -- --play target/demo.tui3d
moon run src/demo --target native -- --export-image target/demo.tuiimg
moon run src/demo --target native -- --show-image target/demo.tuiimg
```
