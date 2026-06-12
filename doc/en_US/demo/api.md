# Demo API

The demo is the package entry point and terminal runner.

## Functions

- `demo_mesh(args : Array[String]) -> Mesh`: selects sphere, torus, or cube geometry.
- `demo_should_rotate(args : Array[String]) -> Bool`: cube rotates by default;
  sphere is static by default.
- `hitchcock_scene()`: central cube plus background cylinder, cone, and triangular pyramid geometry.
- `hitchcock_render_view(frame)`: camera dolly plus scientific focal-length compensation.
- `hitchcock_frame(frame)`: renders one Hitchcock/dolly zoom frame.
- `mesh_frame(mesh, angle_x, angle_y, angle_z) -> String`: renders one frame.
- `exposure_mesh_frame(mesh, angle_x, angle_y, angle_z, use_flow) -> String`:
  renders a pseudo long-exposure frame through `LumaBuffer`.
- `exposure_hitchcock_frame(frame, use_flow) -> String`: Hitchcock exposure demo.
- `render_demo_image(args) -> TuiImage`: renders one static TUI image from the current demo mode.
- `render_demo_sequence(args, timeline) -> TuiSequence`: offline renders a playable TUI sequence.
- `play_sequence(sequence, frame_limit) -> Unit`: plays frames using the sequence fps.
- `render_once(mesh, angle_x, angle_y, angle_z) -> Unit`: clears the terminal
  and prints one frame.
- `run_animation(mesh, rotate, frame_limit, exposure, use_flow, render_view) -> Unit`: runs the frame loop.
- `main`: parses `--sphere`, `--torus`, `--hitchcock`, `--dolly`, `--camera-auto`,
  `--long-exposure`, `--flow-exposure`, `--export-image`, `--show-image`,
  `--record`, `--record-stdout`, `--play`, `--duration`, `--fps`, and `--once`.

## CLI

```sh
moon run src/demo --target native
moon run src/demo --target native -- --once
moon run src/demo --target native -- --sphere
moon run src/demo --target native -- --sphere --once
moon run src/demo --target native -- --torus
moon run src/demo --target native -- --hitchcock
moon run src/demo --target native -- --dolly
moon run src/demo --target native -- --hitchcock --once
moon run src/demo --target native -- --camera-auto --once
moon run src/demo --target native -- --long-exposure --once
moon run src/demo --target native -- --hitchcock --flow-exposure --once
mkdir -p target
moon run src/demo --target native -- --record target/demo.tui3d --duration 3 --fps 30
COLUMNS=240 LINES=91 moon run src/demo --target native -- \
  --dolly --record-stdout --duration 12 --fps 24 > target/dolly.tui3d
python3 tools/tui3d_to_video.py target/dolly.tui3d target/dolly.mp4
moon run src/demo --target native -- --play target/demo.tui3d
moon run src/demo --target native -- --export-image target/demo.tuiimg
moon run src/demo --target native -- --show-image target/demo.tuiimg
```

Use `--record-stdout` for large recordings. It writes frames incrementally and
avoids constructing the complete sequence in memory. Video conversion details
are documented in [`tools/README.md`](../../../tools/README.md).
