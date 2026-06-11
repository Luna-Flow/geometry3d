# Backend TUI API

TUI backend は `@frontend.DrawList` を消費し、character frame を出力します。

## Types

- `TuiRenderConfig`: width、height、terminal y-scale、shade ramp、background pattern。
- `FrameBuffer`: character cells と depth buffer。
- `TuiImage`: static rendered character image。
- `TuiFrame`: rendered character frame。
- `TuiSequence`: width、height、fps、複数の `TuiFrame`。

## API

- `FrameBuffer::new`
- `TuiRenderConfig::sized(width, height)`: explicit viewport size と default TUI styling。
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
