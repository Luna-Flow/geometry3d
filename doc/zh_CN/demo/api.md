# Demo API

demo 是包入口和终端 runner。

## 函数

- `demo_mesh(args)`：包含 `--sphere` 时返回 sphere，否则返回 cube。
- `demo_should_rotate(args)`：cube 默认旋转，sphere 默认静止。
- `mesh_frame(mesh, angle_x, angle_y, angle_z)`：渲染一帧字符串。
- `render_once(mesh, angle_x, angle_y, angle_z)`：清屏并输出一帧。
- `run_animation(mesh, rotate, frame_limit)`：运行帧循环。
- `main`：解析 `--sphere` 和 `--once`。

## CLI

```sh
moon run . --target native
moon run . --target native -- --once
moon run . --target native -- --sphere
moon run . --target native -- --sphere --once
```
