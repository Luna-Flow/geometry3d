# Renderer Tutorial

## Render A Mesh Once

```moonbit
let mesh = sphere_mesh(2.4, 18, 36)
let transform = Transform3::rotation(0.0, 0.0, 0.0)
let config = TuiRenderConfig::default()
let frame = render_frame(mesh, transform, config)
println(frame)
```

## Swap The Background

```moonbit
let config = { TuiRenderConfig::default(), background_pattern: blank_background }
let buffer = render_mesh(cube_mesh(1.0), Transform3::rotation(0.0, 0.0, 0.0), config)
```

Backgrounds are pure functions. `FrameBuffer::new` never hardcodes the default
character.

## Control Terminal Shape

Use `terminal_y_scale` in `TuiRenderConfig` to compensate for terminal cell
aspect ratio. The projection math itself stays backend neutral.
