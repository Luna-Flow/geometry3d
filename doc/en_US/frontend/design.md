# Frontend Design

## Responsibilities

- Own scene-level composition without owning a concrete renderer.
- Apply object transforms, camera transforms, projection, culling, and lighting.
- Emit compact projected triangle commands.

## Backend Boundary

Frontend output is a `DrawList`. This is the stable boundary for TUI today and
for future SVG, Canvas, image, or diagnostic backends.

## Non-Goals

No material system, scene graph hierarchy, textures, asset loading, physics, or BVH.
