# geometry3d

[![img](https://img.shields.io/badge/Maintainer-KCN--judu-violet)](https://github.com/KCN-judu) [![img](https://img.shields.io/badge/License-Apache%202.0-blue)](https://github.com/Luna-Flow/geometry3d/blob/main/LICENSE) ![img](https://img.shields.io/badge/State-active-success)

## v0.4.1 - TUI and Canvas Rendering Pipelines

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
  -> backend/canvas
  -> backend/gsap
  -> demo
```

## Packages

- `Luna-Flow/geometry3d/core`: meshes, quad faces, vector helpers, face normals,
  backface visibility, and 4x4 TRS transforms.
- `Luna-Flow/geometry3d/view`: camera, scientific sensor/lens model, viewport,
  perspective and orthographic projection, plus perspective-correct depth interpolation.
- `Luna-Flow/geometry3d/frontend`: `Scene`, `RenderView`, and backend-neutral
  `DrawList`, directional-light shadow mapping, `LumaBuffer`, exposure settings,
  and demo-grade optical flow.
- `Luna-Flow/geometry3d/backend/tui`: character frame buffer, Z-buffer, shade
  ramp, background patterns, terminal y-axis correction, and perspective-correct
  triangle rasterization.
- `Luna-Flow/geometry3d/backend/canvas`: browser Canvas 2D rendering backed by
  the frontend software Z-buffer, quantized RGB shading, and merged scanline runs.
- `Luna-Flow/geometry3d/backend/gsap`: JS-only SVG polygon rendering with
  painter-order depth sorting and a GSAP timeline playback controller.
- `Luna-Flow/geometry3d/demo`: ANSI terminal showcase for cube, torus, and Hitchcock scenes.

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
- Backend Canvas: [API](./doc/en_US/backend-canvas/api.md), [Tutorial](./doc/en_US/backend-canvas/tutorial.md), [Design](./doc/en_US/backend-canvas/design.md)
- Backend GSAP: [API](./doc/en_US/backend-gsap/api.md), [Tutorial](./doc/en_US/backend-gsap/tutorial.md), [Design](./doc/en_US/backend-gsap/design.md)
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
just torus
```

The default `just` entry points auto-detect terminal dimensions with `stty`
and `tput`, then pass `LINES` and `COLUMNS` to the demo runner. `just torus`
renders a rotating torus with dotted background, Z-buffering, backface culling,
directional lighting and shadows, and terminal y-scale correction.

To render a multi-object Hitchcock/dolly zoom scene:

```sh
just hitchcock
```

The default and Hitchcock demos now derive perspective scale from
`ScientificCamera` sensor/lens parameters.

You can still invoke the raw demo entry directly when needed:

```sh
moon run src/demo --target native -- --torus
moon run src/demo --target native -- --hitchcock
```

To build and serve the browser Canvas demos:

```sh
just canvas-serve
```

Then open `http://localhost:8080`. The Canvas backend is JS-only and uses
`moonbit-community/rabbita/dom`, the maintained successor to the DOM package
used by MoonBit's official browser examples. Use the page selector to switch
between the rotating torus and the scientific-camera Dolly zoom scene.

To build and serve the GSAP-driven SVG demo:

```sh
just gsap-serve
```

Open `http://localhost:8081`. The demo loads GSAP 3.13.0 from jsDelivr and
provides play, pause, reverse, restart, seek, speed, loop, and scene controls.
The backend emits reusable SVG polygons ordered from far to near. Intersecting
triangles use painter-order approximation instead of a per-pixel Z-buffer.

To record a playable TUI sequence and play it back:

```sh
just record
```

The `.tui3d` sequence is a simple text format containing width, height, fps,
and rendered character frames. Timeline sampling lives in the frontend package;
file IO and playback live only in the demo runner.

Any `.tui3d` sequence can be converted to H.264 MP4 or ProRes MOV with the
generic video export tool. See [tools/README.md](./tools/README.md) for recording,
conversion, aspect-ratio, dependency, and Dolly demo examples.

To export a static TUI image and show it later:

```sh
just export-image
just show-image
```

The `.tuiimg` format is the single-frame counterpart to `.tui3d`: width, height,
and one rendered character frame.

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
full character-art snapshots. Canvas tests cover color quantization, scanline
merging, zero-luma foregrounds, and depth ordering. GSAP SVG tests cover config
normalization, polygon serialization, color quantization, and stable painter
ordering. Torus tests also enforce outward face winding so
backface culling cannot regress to displaying the inner wall.

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
