# Frontend Design

## Responsibilities

- Own scene-level composition without owning a concrete renderer.
- Apply object transforms, camera transforms, projection, culling, directional
  lighting, and scene-wide shadow visibility.
- Emit compact projected triangle commands.

## Backend Boundary

Frontend output is a `DrawList`. This is the stable boundary for TUI today and
for future SVG, Canvas, image, or diagnostic backends.

## Non-Goals

The internal shadow map is fixed-resolution and face-sampled; there is no material
system, scene graph hierarchy, textures, asset loading, physics, or BVH.
