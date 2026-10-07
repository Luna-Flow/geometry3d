# GSAP SVG Backend Design

## Responsibilities

- Consume the backend-neutral frontend `DrawList`.
- Serialize projected triangles to reusable SVG polygon nodes.
- Order polygons from far to near by average depth.
- Expose GSAP playback while scene math remains in MoonBit.

## Boundary and Limitations

The package is JS-only and requires `globalThis.gsap`. SVG uses DOM paint order,
not a per-pixel Z-buffer. Intersecting triangles are not split, so occlusion can
differ from Canvas. Rendering is limited to opaque flat-shaded polygons.
