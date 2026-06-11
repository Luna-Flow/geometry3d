# kcndev/geometry3d

This documentation tracks the current repository baseline for **v0.1.0**.

## Repository Positioning

`geometry3d` is a compact MoonBit 3D geometry layer and TUI renderer demo built
on `Luna-Flow/linear-algebra`. It demonstrates a small mesh/transform/projection
pipeline without becoming a full 3D engine.

## Documentation Layout

- `README.md` for the package narrative and release baseline.
- `doc_standard.md` for the documentation contract.
- Subsystem folders with `api.md`, `tutorial.md`, and `design.md`.

## Subsystem Overview

- **`core`**: `Mesh`, quad faces, vector helpers, normals, visibility, and transforms.
- **`renderer`**: TUI frame buffer, background patterns, Z-buffer, lighting, and rasterization.
- **`demo`**: terminal entry point for cube and sphere demos.

## Documentation Entry Points

- API Reference: [core](./core/api.md)
- API Reference: [renderer](./renderer/api.md)
- API Reference: [demo](./demo/api.md)
