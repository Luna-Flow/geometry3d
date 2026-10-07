# Repository conventions

These rules add to the Luna-Flow documentation standard for `geometry3d`.

## Scope

- Document the version on the current branch; the active baseline is **v0.5.1**.
- Do not document speculative engine features such as scene graphs, materials,
  textures, physics, BVH, or asset loaders unless they are implemented.

## Package boundaries

- Keep geometry core documentation free of terminal, ANSI, and TUI concerns.
- Keep terminal y-scale, background patterns, and character rasterization under
  `backend/tui` or `demo`.
- Keep browser DOM, Canvas, scanline, and JS-target details under
  `backend/canvas`, `backend/gsap`, or `demo`.
- When behavior crosses package boundaries, update the API, design, and
  tutorial pages of every affected package together.
