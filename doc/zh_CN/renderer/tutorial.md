# Renderer Tutorial

## 渲染一帧

```moonbit
let mesh = sphere_mesh(2.4, 18, 36)
let transform = Transform3::rotation(0.0, 0.0, 0.0)
let config = TuiRenderConfig::default()
let frame = render_frame(mesh, transform, config)
println(frame)
```

## 替换背景

```moonbit
let config = { TuiRenderConfig::default(), background_pattern: blank_background }
let buffer = render_mesh(cube_mesh(1.0), Transform3::rotation(0.0, 0.0, 0.0), config)
```

背景是纯函数。`FrameBuffer::new` 不硬编码默认字符。

## 调整终端比例

通过 `TuiRenderConfig.terminal_y_scale` 补偿终端字符格的宽高差异。projection core
本身保持 backend neutral。
