# Luna-Flow/geometry3d

This documentation tracks the current repository baseline for **v0.5.1**.

The current baseline includes the Luna-Flow template-style maintenance scripts
and compatibility with `Luna-Flow/linear-algebra@0.4.2`.

## Repository positioning

`geometry3d` is a compact MoonBit 3D geometry foundation built on
`Luna-Flow/linear-algebra`. It separates core geometry, camera/view math,
frontend draw-list generation, and concrete renderer backends.

## Packages

Each package has an API reference, a design note and a tutorial.

| Package | Contents |
| --- | --- |
| [`core`](api/core.md) | `Mesh`, quad faces, vector helpers, normals, visibility, and 4x4 TRS transforms. |
| [`view`](api/view.md) | Camera, `look_at`, viewport, perspective projection, and orthographic projection. |
| [`frontend`](api/frontend.md) | `Scene`, `RenderView`, and backend-neutral `DrawList`. |
| [`backend/tui`](api/backend/tui.md) | TUI frame buffer, background patterns, Z-buffer, terminal y-scale, and rasterization. |
| [`backend/canvas`](api/backend/canvas.md) | Browser Canvas 2D output using the frontend software Z-buffer. |
| [`backend/gsap`](api/backend/gsap.md) | SVG polygon output with painter ordering and GSAP playback control. |
| [`demo`](api/demo.md) | Terminal demos and export helpers; `demo_canvas` and `demo_gsap` provide browser demos. |

## Guides

- [Migration from v0.1 to v0.2](migration_v0_2.md) maps the old single package
  and its TUI entry point onto the current packages.
- [Repository conventions](conventions.md) lists what each package's
  documentation may and may not cover.
