# Demo API

demo は package entry point と terminal runner です。

## Functions

- `demo_mesh(args)`: args から sphere、torus、cube を選択します。
- `demo_should_rotate(args)`: cube は default で回転し、sphere は default で静止します。
- `hitchcock_scene()`: central cube と background cylinder、cone、triangular pyramid geometry。
- `hitchcock_render_view(frame)`: camera dolly と scientific focal-length compensation。
- `hitchcock_frame(frame)`: Hitchcock/dolly zoom scene を 1 frame 描画します。
- `mesh_frame(mesh, angle_x, angle_y, angle_z)`: 1 frame の string を描画します。
- `exposure_mesh_frame(mesh, angle_x, angle_y, angle_z, use_flow)`: `LumaBuffer` で pseudo long-exposure frame を描画します。
- `exposure_hitchcock_frame(frame, use_flow)`: Hitchcock exposure demo。
- `render_demo_image(args)`: current demo mode から static TUI image を描画します。
- `render_demo_sequence(args, timeline)`: playable TUI sequence を offline render します。
- `play_sequence(sequence, frame_limit)`: sequence fps に従って character frames を再生します。
- `render_once(mesh, angle_x, angle_y, angle_z)`: terminal を clear して 1 frame を出力します。
- `run_animation(mesh, rotate, frame_limit, exposure, use_flow, render_view)`: frame loop を実行します。
- `main`: `--sphere`、`--torus`、`--hitchcock`、`--camera-auto`、`--long-exposure`、`--flow-exposure`、`--export-image`、`--show-image`、`--record`、`--play`、`--duration`、`--fps`、`--once` を処理します。

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
