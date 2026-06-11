# Demo API

demo は package entry point と terminal runner です。

## Functions

- `demo_mesh(args)`: `--sphere` があれば sphere、なければ cube を返します。
- `demo_should_rotate(args)`: cube は default で回転し、sphere は default で静止します。
- `mesh_frame(mesh, angle_x, angle_y, angle_z)`: 1 frame の string を描画します。
- `render_once(mesh, angle_x, angle_y, angle_z)`: terminal を clear して 1 frame を出力します。
- `run_animation(mesh, rotate, frame_limit)`: frame loop を実行します。
- `main`: `--sphere` と `--once` を処理します。

## CLI

```sh
moon run . --target native
moon run . --target native -- --once
moon run . --target native -- --sphere
moon run . --target native -- --sphere --once
```
