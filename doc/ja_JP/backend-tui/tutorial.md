# Backend TUI Tutorial

```moonbit
let draw_list = @frontend.build_draw_list(scene, render_view)
let config = @tui.TuiRenderConfig::default()
let frame = @tui.render_frame(draw_list, config)
println(frame)
```

background を差し替える:

```moonbit
let config = { @tui.TuiRenderConfig::default(), background_pattern: @tui.blank_background }
```

`terminal_y_scale` は terminal cell shape の補正なので、geometry や camera math ではなく
TUI backend に属します。
