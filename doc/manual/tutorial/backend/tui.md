# backend/tui tutorial

This tutorial shows you how to turn scenes into terminal text: rendering a frame, animating it, choosing your own characters and background, making a long exposure, and saving frames and sequences to files.

| I want to | Use |
| --- | --- |
| print a scene in the terminal | `@tui.render_scene(scene, view, config)` |
| size the frame to the terminal | `@tui.TuiRenderConfig::sized(width, height)` |
| draw an existing draw list | `@tui.render_draw_list` or `@tui.render_frame` |
| render a long exposure | `@tui.draw_list_to_tui_luma` and `@tui.render_luma_buffer` |
| save and load frames | `encode_tui_sequence`, `decode_tui_sequence`, `encode_tui_image`, `decode_tui_image` |

## Quick start

Import the TUI backend with the packages that build the scene:

```moonbit nocheck
import {
  "Luna-Flow/geometry3d/core",
  "Luna-Flow/geometry3d/view",
  "Luna-Flow/geometry3d/frontend",
  "Luna-Flow/geometry3d/backend/tui",
}
```

Render a torus into 48 × 16 cells and print it:

```moonbit
fn main {
  let viewport = @view.Viewport::new(48, 16)
  let scene = @frontend.Scene::single(
    @core.torus_mesh(1.6, 0.6, 24, 12),
    @core.Transform3::rotation(1.1, 0.3, 0.0),
    @frontend.Light::default(),
  )
  let view = @frontend.RenderView::perspective(
    @view.Camera3::default(5.0),
    @view.PerspectiveProjection::new(viewport, 24.0),
  )
  let config = @tui.TuiRenderConfig::sized(48, 16)
  println(@tui.render_scene(scene, view, config).to_string())
}
```

Output:

```text
................................................
................................................
....................**%%%@@@....................
.................==*=====%%%%%@.................
...............----=..   +++++%%@...............
...............:::..         +++%%%.............
..............::--: .......    ==##.............
..............::-===.........   ==*#............
................=+**=........ ..==*.............
.................=##@@+....   ..==+.............
................. ++%%%#++=:.::--=..............
.................... ++===--::-:................
................................................
................................................
................................................
................................................
```

The projection uses the same 48 × 16 viewport as the configuration, so the optical axis meets the middle of the frame. The backend squeezed every $y$ coordinate by one half, so the torus looks round on a terminal whose cells are twice as tall as they are wide.

## Everyday tasks

### Size the frame to the terminal

Most shells export the terminal size as `COLUMNS` and `LINES`. Read them (for example with `@env.get_env_vars()` from `moonbitlang/core/env`), keep one line for the prompt, and use the same size for the viewport and the configuration:

```moonbit
fn frame_for_size(columns : Int, lines : Int) -> String {
  let width = if columns > 0 { columns } else { @tui.DEFAULT_WIDTH }
  let height = if lines > 1 { lines - 1 } else { @tui.DEFAULT_HEIGHT }
  let viewport = @view.Viewport::new(width, height)
  let camera = @view.ScientificCamera::new(
    @view.Camera3::default(4.5),
    @view.SensorSpec::full_frame(),
    @view.LensSpec::new(18.0),
    @view.WorldUnit::unitless(),
  )
  let scene = @frontend.Scene::single(
    @core.cube_mesh(1.0),
    @core.Transform3::rotation(0.4, 0.6, 0.0),
    @frontend.Light::default(),
  )
  @tui.render_frame(
    @frontend.build_draw_list(scene, @frontend.RenderView::scientific(camera, viewport)),
    @tui.TuiRenderConfig::sized(width, height),
  )
}

test "terminal size" {
  let frame = frame_for_size(100, 31)
  inspect(frame.length(), content="3030")
}
```

### Animate

Render one frame per timeline sample and clear the screen between frames with the ANSI sequence `ESC [2J ESC [H`. Collect the frames in a `TuiSequence` if you also want to save them:

```moonbit
fn spin_sequence(seconds : Double, fps : Int) -> @tui.TuiSequence {
  let config = @tui.TuiRenderConfig::sized(40, 14)
  let view = @frontend.RenderView::perspective(
    @view.Camera3::default(4.5),
    @view.PerspectiveProjection::new(@view.Viewport::new(40, 14), 20.0),
  )
  let timeline = @frontend.Timeline::new(seconds, fps)
  let sequence = @tui.TuiSequence::new(40, 14, fps)
  for k in 0..<timeline.frame_count() {
    let t = timeline.sample(k).time_seconds
    let scene = @frontend.Scene::single(
      @core.cube_mesh(1.0),
      @core.Transform3::rotation(1.5 * t, 1.05 * t, 0.6 * t),
      @frontend.Light::default(),
    )
    sequence.push_frame(@tui.render_frame(@frontend.build_draw_list(scene, view), config))
  }
  sequence
}

fn play(sequence : @tui.TuiSequence) -> Unit {
  for frame in sequence.frames {
    println("\u{1b}[2J\u{1b}[H\{frame.content}")
    // wait 1000 / sequence.fps milliseconds here
  }
}

test "animate" {
  let sequence = spin_sequence(1.0, 12)
  inspect(sequence.frames.length(), content="12")
  inspect(sequence.frames[0].content != sequence.frames[6].content, content="true")
}
```

### Choose your own characters and background

`TuiRenderConfig` cannot be changed from your package, but the building blocks are public: create a `FrameBuffer` with any background function, squeeze the vertices with `apply_terminal_y_scale`, pick characters with `shade_char` from any ramp, and rasterize with `draw_triangle_z`:

```moonbit
fn render_with(list : @frontend.DrawList, width : Int, height : Int, ramp : String) -> String {
  let buffer = @tui.FrameBuffer::new(width, height, fn(x, y, _, _) {
    if (x + 2 * y) % 7 == 0 { '\'' } else { ' ' }
  })
  for t in list.triangles {
    @tui.draw_triangle_z(
      buffer,
      @tui.apply_terminal_y_scale(t.p0, height, 0.5),
      @tui.apply_terminal_y_scale(t.p1, height, 0.5),
      @tui.apply_terminal_y_scale(t.p2, height, 0.5),
      @tui.shade_char(ramp, t.intensity),
    )
  }
  buffer.to_string()
}

test "custom ramp" {
  let scene = @frontend.Scene::single(
    @core.sphere_mesh(1.2, 8, 12),
    @core.Transform3::identity(),
    @frontend.Light::default(),
  )
  let view = @frontend.RenderView::perspective(
    @view.Camera3::default(4.0),
    @view.PerspectiveProjection::new(@view.Viewport::new(32, 12), 16.0),
  )
  let text = render_with(@frontend.build_draw_list(scene, view), 32, 12, "_-~=oO0@")
  inspect(text.contains("O") || text.contains("0"), content="true")
}
```

### Make a long exposure

Rasterize several moments into luma buffers with `draw_list_to_tui_luma`, average them, and quantize once with `render_luma_frame`. Averaging before quantizing gives the blurred edges in-between shades:

```moonbit
fn exposure_frame(samples : Int) -> String {
  let config = @tui.TuiRenderConfig::sized(40, 14)
  let view = @frontend.RenderView::perspective(
    @view.Camera3::default(4.5),
    @view.PerspectiveProjection::new(@view.Viewport::new(40, 14), 20.0),
  )
  let acc = @frontend.LumaBuffer::new(40, 14)
  for k in 0..<samples {
    let angle = 0.6 + k.to_double() * 0.06
    let scene = @frontend.Scene::single(
      @core.cube_mesh(1.0),
      @core.Transform3::rotation(0.4, angle, 0.0),
      @frontend.Light::default(),
    )
    let sample = @tui.draw_list_to_tui_luma(@frontend.build_draw_list(scene, view), config)
    acc.add_weighted_sample(sample, 1.0 / samples.to_double())
  }
  @tui.render_luma_frame(acc, config)
}

test "long exposure" {
  inspect(exposure_frame(1) != exposure_frame(8), content="true")
}
```

### Save and load frames

`.tuiimg` holds one frame and `.tui3d` a sequence; both are plain text. Write the encoded string with any file API (the demo uses `moonbitlang/x/fs`):

```moonbit
test "save and load" {
  let sequence = spin_sequence(0.5, 4)
  let text = @tui.encode_tui_sequence(sequence)
  inspect(text.has_prefix("GEOMETRY3D_TUI_SEQUENCE v1\nwidth=40\nheight=14\nfps=4\nframes=2\n"), content="true")
  let back = @tui.decode_tui_sequence(text)
  inspect(back.frames.length(), content="2")
  inspect(back.frames[1].content == sequence.frames[1].content, content="true")
  let image = @tui.TuiImage::new(40, 14, sequence.frames[0].content)
  let loaded = @tui.decode_tui_image(@tui.encode_tui_image(image))
  inspect(loaded.content == image.content, content="true")
}
```

## Going further

### Turn recordings into video

`tools/tui3d_to_video.py` in the repository converts a `.tui3d` file into an H.264 MP4 or a ProRes MOV. It draws each cell with a 1:2 aspect ratio, which matches the default `terminal_y_scale` of `0.5`, so the video shows the same proportions as the scene. See [`tools/README.md`](../../../../tools/README.md) for the options.

### Another cell shape

Some fonts have cells closer to 1:1.8 or 1:2.2. `apply_terminal_y_scale` takes any factor, so the low-level path above lets you use $k = w_{\text{cell}} / h_{\text{cell}}$ for your font.

### Performance

A frame costs the frontend pipeline plus one pass over the bounding box of every triangle, so it grows with the number of covered cells. At 80 × 32 the demos render a few thousand triangles per frame comfortably. Keep geometry away from the eye: a triangle that comes very close projects to a huge bounding box, and the rasterizer walks all of it.

## Common pitfalls

- **Two sizes.** Use the same width and height for the projection's viewport and for `TuiRenderConfig`; otherwise the picture is off-centre or cropped.
- **Unlit faces are spaces.** On the direct path a face with intensity 0 is drawn with the first ramp character, a space; on the luma path it shows the background. Both still hide what is behind them.
- **Empty ramps.** `shade_char` with an empty ramp aborts. Use characters from the Basic Multilingual Plane; each ramp entry is one UTF-16 code unit.
- **Read-only configuration.** A record literal or `{ ..config, shade_ramp: ... }` for `TuiRenderConfig` does not compile outside the package; use the low-level functions instead.
- **Extra blank line.** `FrameBuffer::to_string` ends with a newline, and `println` adds another, so printed frames are followed by an empty line.
- **Unknown file content.** The decoders never fail; a file without the magic line decodes to an empty 80 × 32 image or sequence. Check the frame count if you need to detect bad input.

## Next steps

- The [TUI API](../../api/backend/tui.md) lists every function and the file formats.
- The [TUI design](../../design/backend/tui.md) derives the aspect correction, the field of view in a terminal and the quantization error.
- The [demo tutorial](../demo.md) shows the full terminal player built on this package.
