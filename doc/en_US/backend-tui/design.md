# Backend TUI Design

## Responsibilities

- Convert projected triangles into terminal characters.
- Own Z-buffer, shade ramp, background pattern, and terminal y-scale correction.
- Keep tests behavioral instead of snapshotting full ASCII frames.

## Pipeline

```text
DrawList
  -> terminal y-scale adjustment
  -> shade ramp
  -> triangle rasterization with perspective-correct depth
  -> FrameBuffer
  -> String
```

## Limitations

No clipping, textures, smooth normals, or anti-aliasing.
