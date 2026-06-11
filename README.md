# geometry3d

[![img](https://img.shields.io/badge/Maintainer-KCN--judu-violet)](https://github.com/KCN-judu) [![img](https://img.shields.io/badge/License-Apache%202.0-blue)](https://github.com/Luna-Flow/geometry3d/blob/main/LICENSE) ![img](https://img.shields.io/badge/State-active-success)

## v0.1.0 - Geometry Core, TUI Renderer & Demo

`geometry3d` is a small MoonBit 3D geometry layer built on
`Luna-Flow/linear-algebra`. It is intentionally not a full 3D engine: the goal
is to keep a compact, readable demo that shows vector and matrix operations in a
simple rendering pipeline.

```text
Luna-Flow/linear-algebra
  -> geometry3d core
  -> TUI renderer backend
  -> rotating cube demo
```

## Layers

- Geometry core: meshes, quad faces, vector helpers, face normals, backface
  visibility, and 3D transforms.
- Projection: camera distance and perspective projection into projected
  vertices.
- TUI renderer backend: character frame buffer, Z-buffer, shade ramp,
  background patterns, terminal y-axis scale correction, and triangle
  rasterization.
- Demo: ANSI terminal output and the rotating cube animation.

The geometry core does not know about terminal characters, ANSI output,
backgrounds, or terminal aspect ratio correction.

## Documentation

This repository follows the same documentation shape used by
`Luna-Flow/linear-algebra`: localized docs under `doc/`, a documentation
standard, and subsystem pages for API, tutorial, and design notes.

- English: [doc/en_US](./doc/en_US/README.md)
- 简体中文: [doc/zh_CN](./doc/zh_CN/README.md)
- 日本語: [doc/ja_JP](./doc/ja_JP/README.md)

Subsystem entry points:

- Core: [API](./doc/en_US/core/api.md), [Tutorial](./doc/en_US/core/tutorial.md), [Design](./doc/en_US/core/design.md)
- Renderer: [API](./doc/en_US/renderer/api.md), [Tutorial](./doc/en_US/renderer/tutorial.md), [Design](./doc/en_US/renderer/design.md)
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
moon run . --target native
```

The demo renders an animated 80x32 rotating cube with dotted background,
Z-buffering, backface culling, simple face lighting, and terminal y-scale
correction.

To render a higher-subdivision static sphere demo instead:

```sh
moon run . --target native -- --sphere
```

For a one-frame smoke test:

```sh
moon run . --target native -- --once
moon run . --target native -- --sphere --once
```

## Test

```sh
moon test
bash ./run_test.sh
```

The tests cover mesh construction, transforms, projection, terminal y-scale,
background patterns, frame buffer initialization, Z-buffer behavior, and
foreground rendering without relying on full character-art snapshots.

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
