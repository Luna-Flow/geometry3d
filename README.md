# geometry3d

[![img](https://img.shields.io/badge/Maintainer-KCN--judu-violet)](https://github.com/KCN-judu) [![img](https://img.shields.io/badge/License-Apache%202.0-blue)](https://github.com/Luna-Flow/geometry3d/blob/main/LICENSE) ![img](https://img.shields.io/badge/State-active-success)

## v0.2.0 - Geometry Frontend, View Layer & TUI Backend

`geometry3d` is a small MoonBit 3D geometry foundation built on
`Luna-Flow/linear-algebra`. It is intentionally not a full 3D engine: the goal
is to show how the Luna-Flow math base can quickly support reliable geometry,
view, frontend, and backend packages.

```text
Luna-Flow/linear-algebra
  -> geometry3d core
  -> geometry3d view
  -> geometry3d frontend
  -> backend/tui
  -> demo
```

## Packages

- `Luna-Flow/geometry3d/core`: meshes, quad faces, vector helpers, face normals,
  backface visibility, and 4x4 TRS transforms.
- `Luna-Flow/geometry3d/view`: camera, scientific sensor/lens model, viewport,
  perspective and orthographic projection.
- `Luna-Flow/geometry3d/frontend`: `Scene`, `RenderView`, and backend-neutral
  `DrawList`, `LumaBuffer`, exposure settings, and demo-grade optical flow.
- `Luna-Flow/geometry3d/backend/tui`: character frame buffer, Z-buffer, shade
  ramp, background patterns, terminal y-axis correction, and triangle rasterization.
- `Luna-Flow/geometry3d/demo`: ANSI terminal showcase for cube and sphere scenes.

The core and frontend packages do not know about terminal characters, ANSI
output, backgrounds, or terminal aspect ratio correction.

## Documentation

This repository follows the same documentation shape used by
`Luna-Flow/linear-algebra`: localized docs under `doc/`, a documentation
standard, and subsystem pages for API, tutorial, and design notes.

- English: [doc/en_US](./doc/en_US/README.md)
- 简体中文: [doc/zh_CN](./doc/zh_CN/README.md)
- 日本語: [doc/ja_JP](./doc/ja_JP/README.md)

Subsystem entry points:

- Core: [API](./doc/en_US/core/api.md), [Tutorial](./doc/en_US/core/tutorial.md), [Design](./doc/en_US/core/design.md)
- View: [API](./doc/en_US/view/api.md), [Tutorial](./doc/en_US/view/tutorial.md), [Design](./doc/en_US/view/design.md)
- Frontend: [API](./doc/en_US/frontend/api.md), [Tutorial](./doc/en_US/frontend/tutorial.md), [Design](./doc/en_US/frontend/design.md)
- Backend TUI: [API](./doc/en_US/backend-tui/api.md), [Tutorial](./doc/en_US/backend-tui/tutorial.md), [Design](./doc/en_US/backend-tui/design.md)
- Demo: [API](./doc/en_US/demo/api.md), [Tutorial](./doc/en_US/demo/tutorial.md), [Design](./doc/en_US/demo/design.md)

## Background Patterns

Backgrounds are pure functions:

```moonbit
fn dotted_background(x : Int, y : Int, width : Int, height : Int) -> Char
```

`FrameBuffer::new` receives a pattern function and uses it to initialize every
cell. The demo defaults to `dotted_background`, and `blank_background` is also
provided for tests or alternate renderers.

## Run

```sh
moon run src/demo --target native
```

The demo renders an animated 80x32 rotating cube with dotted background,
Z-buffering, backface culling, simple face lighting, and terminal y-scale
correction.

To render a higher-subdivision static sphere demo instead:

```sh
moon run src/demo --target native -- --sphere
```

To render a multi-object Hitchcock/dolly zoom scene:

```sh
moon run src/demo --target native -- --hitchcock
```

The default and Hitchcock demos now derive perspective scale from
`ScientificCamera` sensor/lens parameters. Long-exposure smoke demos are also
available:

```sh
moon run src/demo --target native -- --camera-auto --once
moon run src/demo --target native -- --long-exposure --once
moon run src/demo --target native -- --hitchcock --flow-exposure --once
```

To record a playable TUI sequence and play it back:

```sh
mkdir -p target
moon run src/demo --target native -- --record target/demo.tui3d --duration 3 --fps 30
moon run src/demo --target native -- --play target/demo.tui3d
```

The `.tui3d` sequence is a simple text format containing width, height, fps,
and rendered character frames. Timeline sampling lives in the frontend package;
file IO and playback live only in the demo runner.

To export a static TUI image and show it later:

```sh
mkdir -p target
moon run src/demo --target native -- --export-image target/demo.tuiimg
moon run src/demo --target native -- --show-image target/demo.tuiimg
```

The `.tuiimg` format is the single-frame counterpart to `.tui3d`: width, height,
and one rendered character frame.

For a one-frame smoke test:

```sh
moon run src/demo --target native -- --once
moon run src/demo --target native -- --sphere --once
moon run src/demo --target native -- --hitchcock --once
moon run src/demo --target native -- --hitchcock --flow-exposure --once
moon run src/demo --target native -- --play target/demo.tui3d --once
moon run src/demo --target native -- --show-image target/demo.tuiimg
```

## Test

```sh
moon test
bash ./run_test.sh
```

The tests cover mesh construction, TRS transforms, camera/view/projection,
backend-neutral draw lists, scientific camera scale/FOV, shutter sample counts,
luma buffers, optical-flow accumulation, terminal y-scale, background patterns,
timeline sampling, TUI sequence/image encode/decode, frame buffer
initialization, Z-buffer behavior, and foreground rendering without relying on
full character-art snapshots.

`run_test.sh` mirrors the publish workflow and runs the test suite across
`wasm-gc`, `js`, `native`, and `wasm` targets.

## Publish

Publishing is handled by `.github/workflows/publish.yml`, matching the
`linear-algebra` manual workflow:

1. Install MoonBit.
2. Read `moon.mod` version.
3. Run `moon update`.
4. Run `moon check --target all`.
5. Run `bash ./run_test.sh`.
6. Publish with `moon publish` using the `LUNA_MOONCAKE` repository secret.
