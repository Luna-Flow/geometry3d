# Canvas Backend Design

## Responsibilities

- Consume the same backend-neutral `DrawList` as the TUI backend.
- Reuse the frontend perspective-correct software Z-buffer.
- Convert visible luma values to quantized RGB shades.
- Merge adjacent equal-shade pixels into horizontal Canvas fill runs.

## Boundary

The package is JS-only and owns browser Canvas details. Core, view, and frontend
do not depend on DOM types. `demo_canvas` owns element lookup, animation frames,
and demo selection.

## Limitations

Rendering is opaque and uses one foreground RGB color scaled by luma. There are
no materials, textures, alpha blending, anti-aliasing, or GPU acceleration.
