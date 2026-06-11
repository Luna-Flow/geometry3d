# Renderer Tutorial

## 1 フレームを描画する

```moonbit
let mesh = sphere_mesh(2.4, 18, 36)
let transform = Transform3::rotation(0.0, 0.0, 0.0)
let config = TuiRenderConfig::default()
let frame = render_frame(mesh, transform, config)
println(frame)
```

## Background を差し替える

```moonbit
let config = { TuiRenderConfig::default(), background_pattern: blank_background }
let buffer = render_mesh(cube_mesh(1.0), Transform3::rotation(0.0, 0.0, 0.0), config)
```

background は pure function です。`FrameBuffer::new` は default character を hardcode
しません。

## Terminal Shape を調整する

`TuiRenderConfig.terminal_y_scale` で terminal cell の縦横比を補正します。
projection core は backend neutral のままです。
