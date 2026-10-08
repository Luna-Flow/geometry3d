# geometry3d

`Luna-Flow/geometry3d` is a small 3D rendering pipeline for MoonBit, built on `Luna-Flow/linear-algebra`. It takes quad meshes through homogeneous transforms, a look-at camera with a physical lens model, perspective projection, back-face culling, Lambert shading and shadow mapping, and draws the result in a terminal, on an HTML canvas or as animated SVG. It is deliberately not a game engine: every stage is short enough to read and is documented with the mathematics it implements.

This manual describes version 0.5.1 of the module, migrated to MoonBit 0.10.

## Packages

The library packages form a chain: each depends only on the ones above it. The executables at the bottom are demos.

| Package | Role | Pages |
| --- | --- | --- |
| `core` | Vectors, quad meshes and generators, face normals, visibility, Lambert intensity, 4×4 transforms | [API](api/core.md) · [tutorial](tutorial/core.md) · [design](design/core.md) |
| `view` | Look-at camera, perspective and orthographic projection, perspective-correct depth, sensor and lens model | [API](api/view.md) · [tutorial](tutorial/view.md) · [design](design/view.md) |
| `frontend` | Scenes, the backend-neutral `DrawList`, shadow mapping, the luma depth buffer, exposure, optical flow, timelines | [API](api/frontend.md) · [tutorial](tutorial/frontend.md) · [design](design/frontend.md) |
| `backend/tui` | Character frame buffer, shade ramp, terminal aspect correction, `.tuiimg` and `.tui3d` files | [API](api/backend/tui.md) · [tutorial](tutorial/backend/tui.md) · [design](design/backend/tui.md) |
| `backend/canvas` | HTML canvas output with exact occlusion (`js` only) | [API](api/backend/canvas.md) · [tutorial](tutorial/backend/canvas.md) · [design](design/backend/canvas.md) |
| `backend/gsap` | SVG polygons in painter's order and a GSAP playback controller (`js` only) | [API](api/backend/gsap.md) · [tutorial](tutorial/backend/gsap.md) · [design](design/backend/gsap.md) |
| `demo` | Terminal demo: scenes, exposure effects, recording and playback (`native`) | [CLI](api/demo.md) · [tutorial](tutorial/demo.md) · [design](design/demo.md) |
| `demo_canvas` | Browser demo of the Canvas backend (`js`) | [page](api/demo_canvas.md) · [tutorial](tutorial/demo_canvas.md) · [design](design/demo_canvas.md) |
| `demo_gsap` | Browser player for the GSAP SVG backend (`js`) | [page](api/demo_gsap.md) · [tutorial](tutorial/demo_gsap.md) · [design](design/demo_gsap.md) |

Package paths are `Luna-Flow/geometry3d/<package>`. The [architecture guide](architecture.md) shows how a frame flows through them.

## Reading paths

- **New to 3D graphics.** Read the [core tutorial](tutorial/core.md), then the [view tutorial](tutorial/view.md), then run the [terminal demo](tutorial/demo.md). The design pages of `core` and `view` derive each formula from first principles.
- **Rendering a scene.** Start with the [frontend tutorial](tutorial/frontend.md) and pick a backend tutorial: [TUI](tutorial/backend/tui.md), [Canvas](tutorial/backend/canvas.md) or [GSAP SVG](tutorial/backend/gsap.md).
- **Contributing.** Read the [architecture guide](architecture.md), the [repository conventions](conventions.md) and the design pages of the packages you touch. The [migration guide](migration_v0_2.md) explains the package split of version 0.2.

## Install

```sh
moon add Luna-Flow/geometry3d@0.5.1
moon add Luna-Flow/linear-algebra@0.4.2
```

`linear-algebra` is needed in your own module only if you name its types, for example `@la.Vector[Double]` in a signature. The browser backends also need `moonbit-community/rabbita@0.12.4`.

## Toolchain

The module requires MoonBit with `moonc` 0.10 or later. `core`, `view`, `frontend` and `backend/tui` build on every target (`wasm-gc`, `wasm`, `js`, `native`). `backend/canvas`, `backend/gsap`, `demo_canvas` and `demo_gsap` build only for `js`, and the terminal demo is meant for `native`.

```sh
moon check --target all
bash ./run_test.sh
```

`run_test.sh` runs the test suite on every target and smoke-tests the demo.

## Related projects

- `Luna-Flow/linear-algebra` provides the vector and matrix types: <https://lunaflow.cn/en/linear-algebra/>.
- `Luna-Flow/luna-generic` and `Luna-Flow/arithmetic` provide the numeric traits used internally: <https://lunaflow.cn/en/luna-generic/>, <https://lunaflow.cn/en/arithmetic/>.
