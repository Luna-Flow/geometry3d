# Backend TUI Tutorial

```moonbit
let draw_list = @frontend.build_draw_list(scene, render_view)
let config = @tui.TuiRenderConfig::default()
let frame = @tui.render_frame(draw_list, config)
println(frame)
```

替换背景：

```moonbit
let config = { @tui.TuiRenderConfig::default(), background_pattern: @tui.blank_background }
```

`terminal_y_scale` 属于 TUI backend，因为它补偿的是终端字符格形状，而不是几何或相机数学。
