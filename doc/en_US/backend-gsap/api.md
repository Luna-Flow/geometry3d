# GSAP SVG Backend API

The JS-only GSAP backend renders frontend `DrawList` triangles as SVG polygons
and wraps a host-provided `globalThis.gsap` timeline.

## Rendering

- `GsapSvgColor::rgb(red, green, blue)` clamps channels to `0..255`.
- `GsapSvgRenderConfig::default()` and `sized(width, height)` create configs.
- `render_draw_list(svg, draw_list, config)` updates reusable polygon nodes.
- `render_scene(svg, scene, render_view, config)` builds and renders a draw list.

Triangles are ordered by average depth from far to near. Equal-depth triangles
keep their source order.

## Playback

`GsapPlayer::new(duration_seconds, on_frame, repeat=-1)` creates a paused linear
timeline. It supports `play`, `pause`, `reverse`, `restart`, `seek`, progress and
time access, time scale, repeat, paused-state queries, and `kill`.

Creating a player without `globalThis.gsap` throws a JavaScript error.
