# Renderer Design

## Responsibilities

- Convert projected triangles into terminal characters.
- Own TUI-specific configuration: frame size, shade ramp, background pattern,
  terminal y-scale correction, and Z-buffer storage.
- Keep rendering deterministic enough for whitebox tests without requiring full
  character-art snapshots.

## Pipeline

```text
Mesh + Transform3
  -> transformed vertices
  -> projection
  -> terminal y-scale adjustment
  -> face visibility and lighting
  -> quad triangulation
  -> triangle rasterization with Z-buffer
  -> FrameBuffer string
```

## Depth Model

Lower `depth` is closer. `FrameBuffer::set_pixel_if_closer` updates a cell only
when the new depth is closer than the stored depth by `DEPTH_EPSILON`.

## Limitations

- Flat face lighting only.
- No clipping, perspective-correct interpolation, textures, anti-aliasing, or
  smooth normals.
- No backend abstraction trait yet; the current backend is intentionally concrete and small.
