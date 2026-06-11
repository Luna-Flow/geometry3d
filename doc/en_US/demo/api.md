# Demo API

The demo is the package entry point and terminal runner.

## Functions

- `demo_mesh(args : Array[String]) -> Mesh`: returns a sphere when `--sphere`
  is present, otherwise a cube.
- `demo_should_rotate(args : Array[String]) -> Bool`: cube rotates by default;
  sphere is static by default.
- `mesh_frame(mesh, angle_x, angle_y, angle_z) -> String`: renders one frame.
- `render_once(mesh, angle_x, angle_y, angle_z) -> Unit`: clears the terminal
  and prints one frame.
- `run_animation(mesh, rotate, frame_limit) -> Unit`: runs the frame loop.
- `main`: parses `--sphere` and `--once`.

## CLI

```sh
moon run . --target native
moon run . --target native -- --once
moon run . --target native -- --sphere
moon run . --target native -- --sphere --once
```
