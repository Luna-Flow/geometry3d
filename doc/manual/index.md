# geometry3d

This manual documents version `0.5.1` of `Luna-Flow/geometry3d` as it stands on `main` after its migration to MoonBit 0.10.

## Overview

`Luna-Flow/geometry3d` is a small 3D rendering pipeline for MoonBit, built on `Luna-Flow/linear-algebra`. It takes quad meshes through homogeneous transforms, a look-at camera with a physical lens model, perspective projection, back-face culling, Lambert shading and shadow mapping, and draws the result in a terminal, on an HTML canvas or as animated SVG. It is deliberately not a game engine: every stage is short enough to read and is documented with the mathematics it implements.

- Points are $(p, 1)$ and directions $(d, 0)$ in homogeneous coordinates; transforms are 4×4 matrices composed in application order.
- Camera space has $x$ right, $y$ up and $z$ forward (the left-handed convention of Direct3D), and depth is the camera-space $z$.
- The frontend hands every backend the same list of projected, shaded triangles; the terminal and canvas backends resolve occlusion with a depth buffer, the SVG backend by drawing order.

> [!WARNING]
> `cylinder_mesh`, `cone_mesh` and `triangular_pyramid_mesh` currently wind their faces inwards, so these solids render inside out. The [core API](api/core.md#cube_mesh-sphere_mesh-cylinder_mesh-cone_mesh-triangular_pyramid_mesh-torus_mesh) explains the effect and a workaround.

## Install

```sh
moon add Luna-Flow/geometry3d@0.5.1
moon add Luna-Flow/linear-algebra@0.4.7
```

Then import the packages you use in your `moon.pkg`:

```moonbit nocheck
import {
  "Luna-Flow/geometry3d/core",
  "Luna-Flow/geometry3d/view",
  "Luna-Flow/geometry3d/frontend",
  "Luna-Flow/geometry3d/backend/tui",
  "Luna-Flow/linear-algebra/mutable" @la,
}
```

`linear-algebra` is needed in your own module only if you name its types, for example `@la.Vector[Double]` in a signature. The browser backends also need `moonbit-community/rabbita@0.12.4`. The module requires MoonBit with `moonc` 0.10 or later. `core`, `view`, `frontend` and `backend/tui` build on every target (`wasm-gc`, `wasm`, `js`, `native`). `backend/canvas`, `backend/gsap`, `demo_canvas` and `demo_gsap` build only for `js`, and the terminal demo is meant for `native`.

## Pages

The library packages form a chain: each depends only on the ones above it. The executables at the bottom are demos; their API pages describe a command line or an HTML page contract instead of MoonBit items. Package paths are `Luna-Flow/geometry3d/<package>`.

| Part | Tutorial | API | Design |
| --- | --- | --- | --- |
| `core`: vectors, quad meshes and generators, face normals, visibility, Lambert intensity, 4×4 transforms | [tutorial](tutorial/core.md) | [API](api/core.md) | [design](design/core.md) |
| `view`: look-at camera, perspective and orthographic projection, perspective-correct depth, sensor and lens model | [tutorial](tutorial/view.md) | [API](api/view.md) | [design](design/view.md) |
| `frontend`: scenes, the backend-neutral `DrawList`, shadow mapping, the luma depth buffer, exposure, optical flow, timelines | [tutorial](tutorial/frontend.md) | [API](api/frontend.md) | [design](design/frontend.md) |
| `backend/tui`: character frame buffer, shade ramp, terminal aspect correction, `.tuiimg` and `.tui3d` files | [tutorial](tutorial/backend/tui.md) | [API](api/backend/tui.md) | [design](design/backend/tui.md) |
| `backend/canvas`: HTML canvas output with exact occlusion (`js` only) | [tutorial](tutorial/backend/canvas.md) | [API](api/backend/canvas.md) | [design](design/backend/canvas.md) |
| `backend/gsap`: SVG polygons in painter's order and a GSAP playback controller (`js` only) | [tutorial](tutorial/backend/gsap.md) | [API](api/backend/gsap.md) | [design](design/backend/gsap.md) |
| `demo`: terminal demo with scenes, exposure effects, recording and playback (`native`) | [tutorial](tutorial/demo.md) | [CLI](api/demo.md) | [design](design/demo.md) |
| `demo_canvas`: browser demo of the Canvas backend (`js`) | [tutorial](tutorial/demo_canvas.md) | [page](api/demo_canvas.md) | [design](design/demo_canvas.md) |
| `demo_gsap`: browser player for the GSAP SVG backend (`js`) | [tutorial](tutorial/demo_gsap.md) | [page](api/demo_gsap.md) | [design](design/demo_gsap.md) |
| Guides | [migration from v0.1](migration_v0_2.md) | [conventions](conventions.md) | [architecture](architecture.md) |

## Exported items

### Geometry (`core`)

- Vectors: `vec3`, `vec4`, `sub_vec`, `cross_vec`, `vec_length`, `normalize_vec`, `min3`, `max3`, `DEPTH_EPSILON`
- Meshes: `Mesh`, `QuadFace`, `TriangleFace`, the generators `cube_mesh`, `sphere_mesh`, `cylinder_mesh`, `cone_mesh`, `triangular_pyramid_mesh`, `torus_mesh`, and `face_vertices`, `triangulate_quad`
- Faces: `face_center`, `face_normal`, `face_is_visible`, `face_intensity`
- Transforms: `Transform3` and the matrix builders `identity_matrix4`, `translation_matrix`, `scale_matrix`, `rotation_x`, `rotation_y`, `rotation_z`, `rotation_matrix`

### Camera and projection (`view`)

- `Camera3`, `Viewport`, `ProjectedVertex`, `PerspectiveProjection`, `OrthographicProjection`, `interpolate_perspective_depth`
- The physical camera: `ScientificCamera`, `SensorSpec`, `LensSpec`, `WorldUnit`

### Rendering (`frontend` and the backends)

- Scenes and draw lists: `Scene`, `SceneObject`, `Light`, `RenderView`, `build_draw_list`, `DrawList`, `DrawTriangle`
- Buffers and time: `LumaBuffer`, `ExposureSettings`, `ShutterSpeed`, optical flow, `Timeline`, `ScalarTrack`
- Output: `render_scene` and the file formats of `backend/tui`, the Canvas renderer, and the GSAP SVG renderer and player

## Where to read next

The [architecture guide](architecture.md) follows one frame through the packages. The design pages of `core`, `view` and `frontend` derive every formula from first principles, and each backend design states what its output guarantees.

- New to 3D graphics: read the [core tutorial](tutorial/core.md), then the [view tutorial](tutorial/view.md), then run the [terminal demo](tutorial/demo.md).
- Using it in a library: start with the [frontend tutorial](tutorial/frontend.md) and pick a backend tutorial: [TUI](tutorial/backend/tui.md), [Canvas](tutorial/backend/canvas.md) or [GSAP SVG](tutorial/backend/gsap.md); keep the [core API](api/core.md) and the [view API](api/view.md) at hand.
- Contributing: read the [architecture guide](architecture.md), the [repository conventions](conventions.md) and the design pages of the packages you touch. The [migration guide](migration_v0_2.md) explains the package split of version 0.2.

`Luna-Flow/linear-algebra` provides the vector and matrix types (<https://lunaflow.cn/en/linear-algebra/>), and `Luna-Flow/luna-generic` and `Luna-Flow/arithmetic` provide the numeric traits used internally (<https://lunaflow.cn/en/luna-generic/>, <https://lunaflow.cn/en/arithmetic/>).

## Validation

Recommended release checks:

```sh
moon check --target all
bash ./run_test.sh
```

`run_test.sh` runs the test suite on every target and smoke-tests the demo.
