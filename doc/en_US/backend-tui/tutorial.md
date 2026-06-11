# Backend TUI Tutorial

```moonbit
let draw_list = @frontend.build_draw_list(scene, render_view)
let config = @tui.TuiRenderConfig::default()
let frame = @tui.render_frame(draw_list, config)
println(frame)
```

Use `TuiRenderConfig::sized(width, height)` when dimensions come from the current terminal.

To change the background:

```moonbit
let config = { @tui.TuiRenderConfig::default(), background_pattern: @tui.blank_background }
```

`terminal_y_scale` belongs to this backend because it compensates for terminal
cell shape rather than geometry or camera math.
