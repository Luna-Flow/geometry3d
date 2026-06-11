# Backend TUI API

TUI backend 消费 `@frontend.DrawList` 并输出字符帧。

## 类型

- `TuiRenderConfig`：width、height、terminal y-scale、shade ramp、background pattern。
- `FrameBuffer`：字符 cells 和 depth buffer。
- `TuiImage`：一张静态字符图。
- `TuiFrame`：一帧已渲染字符画。
- `TuiSequence`：width、height、fps 和多帧 `TuiFrame`。

## API

- `FrameBuffer::new`
- `TuiRenderConfig::sized(width, height)`：使用指定 viewport 尺寸和默认 TUI 样式。
- `FrameBuffer::set_pixel_if_closer`
- `apply_terminal_y_scale`
- `draw_triangle_z`
- `render_draw_list`
- `render_frame`
- `render_scene`
- `render_luma_buffer`
- `render_luma_frame`
- `TuiImage::new`
- `encode_tui_image` / `decode_tui_image`
- `TuiSequence::new` / `push_frame`
- `encode_tui_sequence` / `decode_tui_sequence`

## Patterns

- `dotted_background`
- `blank_background`
- `checker_background`
