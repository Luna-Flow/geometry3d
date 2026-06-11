# Backend TUI API

The TUI backend consumes `@frontend.DrawList` and emits character frames.

## Types

- `TuiRenderConfig`: width, height, terminal y-scale, shade ramp, and background pattern.
- `FrameBuffer`: cells plus depth buffer.
- `TuiImage`: one static rendered character image.
- `TuiFrame`: one rendered character frame.
- `TuiSequence`: width, height, fps, and a list of `TuiFrame`s.

## Functions

- `FrameBuffer::new(width, height, background_pattern)`.
- `FrameBuffer::set_pixel_if_closer(x, y, depth, pixel)`.
- `apply_terminal_y_scale(point, height, terminal_y_scale)`.
- `draw_triangle_z(buffer, p0, p1, p2, pixel)`.
- `render_draw_list(draw_list, config)`.
- `render_frame(draw_list, config)`.
- `render_scene(scene, render_view, config)`.
- `render_luma_buffer(buffer, config)`.
- `render_luma_frame(buffer, config)`.
- `TuiImage::new(width, height, content)`.
- `encode_tui_image(image)` / `decode_tui_image(text)`.
- `TuiSequence::new(width, height, fps)` / `push_frame(content)`.
- `encode_tui_sequence(sequence)` / `decode_tui_sequence(text)`.

## Patterns

- `dotted_background`
- `blank_background`
- `checker_background`
