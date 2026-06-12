# Luna-Flow/geometry3d

This documentation tracks the current repository baseline for **v0.4.0**.

## Repository Positioning

`geometry3d` is a compact MoonBit 3D geometry foundation built on
`Luna-Flow/linear-algebra`. It separates core geometry, camera/view math,
frontend draw-list generation, and concrete renderer backends.

## Documentation Layout

- `README.md` for the package narrative and release baseline.
- `doc_standard.md` for the documentation contract.
- Subsystem folders with `api.md`, `tutorial.md`, and `design.md`.

## Subsystem Overview

- **`core`**: `Mesh`, quad faces, vector helpers, normals, visibility, and 4x4 TRS transforms.
- **`view`**: camera, `look_at`, viewport, perspective projection, and orthographic projection.
- **`frontend`**: `Scene`, `RenderView`, and backend-neutral `DrawList`.
- **`backend-tui`**: TUI frame buffer, background patterns, Z-buffer, terminal y-scale, and rasterization.
- **`backend-canvas`**: browser Canvas 2D output using the frontend software Z-buffer.
- **`demo`**: terminal demos and TUI export/playback helpers; `demo_canvas` provides Torus and Dolly browser demos.

## Documentation Entry Points

- API Reference: [core](./core/api.md)
- API Reference: [view](./view/api.md)
- API Reference: [frontend](./frontend/api.md)
- API Reference: [backend-tui](./backend-tui/api.md)
- Backend Canvas: [API](./backend-canvas/api.md), [Tutorial](./backend-canvas/tutorial.md), [Design](./backend-canvas/design.md)
- API Reference: [demo](./demo/api.md)
- Migration: [v0.1 to v0.2](./migration_v0_2.md)
