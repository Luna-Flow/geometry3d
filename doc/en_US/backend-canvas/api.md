# Canvas Backend API

The JS-only Canvas backend consumes `@frontend.DrawList`, rasterizes it through
the frontend perspective-correct Z-buffer, and writes merged horizontal runs to
a browser `CanvasRenderingContext2D`.

## Types

- `CanvasColor::rgb(red, green, blue)` clamps RGB channels to `0..255`.
- `CanvasRenderConfig::default()` creates a `640 x 480` configuration.
- `CanvasRenderConfig::sized(width, height)` creates a configuration with the
  default dark background, cyan foreground, and 256 shade levels.

## Rendering

- `render_draw_list(context, draw_list, config)` renders into an existing 2D context.
- `render_scene(context, scene, render_view, config)` builds and renders a draw list.
- `render_canvas(canvas, draw_list, config)` sets the canvas pixel size, obtains
  its 2D context, and renders the draw list.

Run `just canvas-serve` and open `http://localhost:8080`. The demo selector
switches between a rotating torus and the Dolly zoom scene. Dolly uses the same
rotating cube, 35-disc wall, camera-distance curve, and focal-length compensation
as the terminal demo.
