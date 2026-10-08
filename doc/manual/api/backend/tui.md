# backend/tui API

## Purpose

The package `Luna-Flow/geometry3d/backend/tui` draws a frontend `DrawList` as text: a character frame buffer with a depth buffer, a shade ramp that maps intensity to characters, background patterns, the correction for tall terminal cells, and plain-text file formats for single images (`.tuiimg`) and animated sequences (`.tui3d`). It runs on every target and produces strings; printing them is up to the caller.

## Importing

```moonbit nocheck
import {
  "Luna-Flow/geometry3d/view",
  "Luna-Flow/geometry3d/frontend",
  "Luna-Flow/geometry3d/backend/tui",
}
```

The [TUI design](../../design/backend/tui.md) explains the aspect correction and the quantization; the [TUI tutorial](../../tutorial/backend/tui.md) renders scenes step by step.

## Configuration

### `DEFAULT_WIDTH`, `DEFAULT_HEIGHT`

The fallback output size, 80 columns by 32 rows.

```mbti
pub const DEFAULT_WIDTH : Int = 80
pub const DEFAULT_HEIGHT : Int = 32
```

### `DEFAULT_TERMINAL_Y_SCALE`

The default vertical squeeze, `0.5`, for terminal cells about twice as tall as they are wide.

```mbti
pub const DEFAULT_TERMINAL_Y_SCALE : Double = 0.5
```

### `DEFAULT_SHADE_RAMP`

The default ramp `" .:-=+*#%@"`, ten characters from darkest to brightest.

```mbti
pub const DEFAULT_SHADE_RAMP : String = " .:-=+*#%@"
```

### `TuiRenderConfig`

`TuiRenderConfig` is the output size, the vertical squeeze, the shade ramp and the background pattern.

```mbti
pub struct TuiRenderConfig {
  width : Int
  height : Int
  terminal_y_scale : Double
  shade_ramp : String
  background_pattern : (Int, Int, Int, Int) -> Char
}
```

The fields are read-only outside the package; obtain a configuration from the two constructors below. To draw with another ramp or background, use `FrameBuffer`, `shade_char` and `draw_triangle_z` directly, as shown in the tutorial.

### `TuiRenderConfig::default`, `TuiRenderConfig::sized`

`TuiRenderConfig::default()` is 80 × 32 with the default scale, ramp and `dotted_background`; `TuiRenderConfig::sized(w, h)` is the same with the given size, replacing a non-positive dimension by the default.

```mbti
pub fn TuiRenderConfig::default() -> Self
pub fn TuiRenderConfig::sized(Int, Int) -> Self
```

`default` is an ordinary constructor, not an implementation of the `Default` trait.

## Rendering

### `render_draw_list`

`render_draw_list(list, config)` creates a frame buffer filled with the background pattern and draws every triangle of the list: it squeezes the vertices vertically, picks the character for the triangle's intensity, and rasterizes with the depth test.

```mbti
pub fn render_draw_list(@frontend.DrawList, TuiRenderConfig) -> FrameBuffer
```

The draw list should have been projected into a viewport of the same size as the configuration. A triangle of intensity 0 is drawn with the first ramp character (a space by default), so unlit faces still hide what is behind them.

### `render_frame`

`render_frame(list, config)` is `render_draw_list(list, config).to_string()`.

```mbti
pub fn render_frame(@frontend.DrawList, TuiRenderConfig) -> String
```

### `render_scene`

`render_scene(scene, view, config)` runs `build_draw_list` and `render_draw_list` in one call.

```mbti
pub fn render_scene(@frontend.Scene, @frontend.RenderView, TuiRenderConfig) -> FrameBuffer
```

```moonbit
test "render a scene" {
  let config = @tui.TuiRenderConfig::sized(20, 8)
  let scene = @frontend.Scene::single(
    @core.cube_mesh(1.0),
    @core.Transform3::rotation(0.5, 0.7, 0.0),
    @frontend.Light::default(),
  )
  let view = @frontend.RenderView::perspective(
    @view.Camera3::default(4.0),
    @view.PerspectiveProjection::new(@view.Viewport::new(20, 8), 10.0),
  )
  let frame = @tui.render_scene(scene, view, config).to_string()
  inspect(
    frame,
    content=(
      #|....................
      #|....................
      #|........===##.......
      #|.......===####......
      #|......====###.......
      #|..........  #.......
      #|....................
      #|....................
      #|
    ),
  )
}
```

### `draw_list_to_tui_luma`

`draw_list_to_tui_luma(list, config)` rasterizes the list into a frontend `LumaBuffer` of the configured size, applying the same vertical squeeze. Use it to accumulate exposures before turning them into characters.

```mbti
pub fn draw_list_to_tui_luma(@frontend.DrawList, TuiRenderConfig) -> @frontend.LumaBuffer
```

### `render_luma_buffer`

`render_luma_buffer(buffer, config)` turns a luma buffer into a frame buffer: every pixel with a value above `0.0` gets the ramp character for its value and keeps its depth; other pixels show the background.

```mbti
pub fn render_luma_buffer(@frontend.LumaBuffer, TuiRenderConfig) -> FrameBuffer
```

Only the overlap of the buffer and the configured size is used.

### `render_luma_frame`

`render_luma_frame(buffer, config)` is `render_luma_buffer(buffer, config).to_string()`.

```mbti
pub fn render_luma_frame(@frontend.LumaBuffer, TuiRenderConfig) -> String
```

```moonbit
test "luma path" {
  let config = @tui.TuiRenderConfig::sized(10, 4)
  let list = @frontend.DrawList::new()
  list.push_triangle(
    @frontend.DrawTriangle::new(
      @view.ProjectedVertex::new(0.0, 0.0, 1.0),
      @view.ProjectedVertex::new(10.0, 0.0, 1.0),
      @view.ProjectedVertex::new(0.0, 8.0, 1.0),
      1.0,
    ),
  )
  let luma = @tui.draw_list_to_tui_luma(list, config)
  inspect(
    @tui.render_luma_frame(luma, config),
    content=(
      #|..........
      #|@@@@@@@@@.
      #|@@@@@@....
      #|@@@@......
      #|
    ),
  )
}
```

## Frame buffer

### `FAR_DEPTH`

`FAR_DEPTH` is the depth of a background cell, $10^{30}$.

```mbti
pub const FAR_DEPTH : Double = 1.0e30
```

### `FrameBuffer`

`FrameBuffer` is a row-major grid of characters with a depth per cell.

```mbti
pub struct FrameBuffer {
  width : Int
  height : Int
  cells : Array[Char]
  depths : Array[Double]
}
```

### `FrameBuffer::new`

`FrameBuffer::new(width, height, pattern)` fills every cell $(x, y)$ with `pattern(x, y, width, height)` at depth `FAR_DEPTH`.

```mbti
pub fn FrameBuffer::new(Int, Int, (Int, Int, Int, Int) -> Char) -> Self
```

### `FrameBuffer::index`

`buffer.index(x, y)` returns `y * width + x`, without bounds checks.

```mbti
pub fn FrameBuffer::index(Self, Int, Int) -> Int
```

### `FrameBuffer::set_pixel_if_closer`

`buffer.set_pixel_if_closer(x, y, depth, ch)` writes `ch` if `depth + DEPTH_EPSILON` is less than the stored depth; writes outside the buffer are ignored.

```mbti
pub fn FrameBuffer::set_pixel_if_closer(Self, Int, Int, Double, Char) -> Unit
```

### `FrameBuffer::to_string`

`buffer.to_string()` returns the rows joined, each followed by `'\n'`; the result has `height * (width + 1)` characters.

```mbti
pub fn FrameBuffer::to_string(Self) -> String
```

It is a method, not an implementation of `Show`.

```moonbit
test "frame buffer" {
  let buffer = @tui.FrameBuffer::new(4, 2, @tui.blank_background)
  buffer.set_pixel_if_closer(1, 0, 5.0, 'a')
  buffer.set_pixel_if_closer(1, 0, 7.0, 'b') // farther: ignored
  buffer.set_pixel_if_closer(9, 9, 1.0, 'c') // outside: ignored
  inspect(buffer.to_string(), content=" a  \n    \n")
}
```

## Backgrounds

### `dotted_background`, `blank_background`, `checker_background`

These patterns fill every cell with `'.'`, with `' '`, or alternately with `'.'` and `' '` when $x + y$ is even or odd.

```mbti
pub fn dotted_background(Int, Int, Int, Int) -> Char
pub fn blank_background(Int, Int, Int, Int) -> Char
pub fn checker_background(Int, Int, Int, Int) -> Char
```

A pattern is any function `(x, y, width, height) -> Char`, so you can write your own.

```moonbit
test "backgrounds" {
  inspect(@tui.FrameBuffer::new(4, 2, @tui.checker_background).to_string(), content=". . \n . .\n")
  let border = fn(x : Int, y : Int, w : Int, h : Int) -> Char {
    if x == 0 || y == 0 || x == w - 1 || y == h - 1 { '#' } else { ' ' }
  }
  inspect(@tui.FrameBuffer::new(4, 3, border).to_string(), content="####\n#  #\n####\n")
}
```

## Rasterization helpers

### `apply_terminal_y_scale`

`apply_terminal_y_scale(p, height, k)` squeezes a projected vertex towards the middle row: $y' = H/2 + (y - H/2)\,k$; `x` and `depth` are unchanged.

```mbti
pub fn apply_terminal_y_scale(@view.ProjectedVertex, Int, Double) -> @view.ProjectedVertex
```

### `clamp01`

`clamp01(v)` clamps a number to $[0, 1]$.

```mbti
pub fn clamp01(Double) -> Double
```

### `shade_char`

`shade_char(ramp, intensity)` returns the character at index $\operatorname{round}(\operatorname{clamp01}(I) \cdot (n - 1))$ of a ramp of $n$ characters.

```mbti
pub fn shade_char(String, Double) -> Char
```

The ramp must not be empty, and should consist of characters from the Basic Multilingual Plane (one UTF-16 unit each).

### `edge_function`

`edge_function(ax, ay, bx, by, px, py)` returns $(p_x - a_x)(b_y - a_y) - (p_y - a_y)(b_x - a_x)$, the signed doubled area that decides on which side of the line $ab$ the point $p$ lies.

```mbti
pub fn edge_function(Double, Double, Double, Double, Double, Double) -> Double
```

### `draw_triangle_z`

`draw_triangle_z(buffer, p0, p1, p2, ch)` rasterizes one triangle into a frame buffer with character `ch`, sampling cell centres and using the perspective-correct depth for the depth test.

```mbti
pub fn draw_triangle_z(FrameBuffer, @view.ProjectedVertex, @view.ProjectedVertex, @view.ProjectedVertex, Char) -> Unit
```

Either winding is accepted; triangles with an area of at most `DEPTH_EPSILON` are skipped. Vertices are used as given, without the vertical squeeze.

```moonbit
test "rasterization helpers" {
  inspect(@tui.shade_char(@tui.DEFAULT_SHADE_RAMP, 0.0), content=" ")
  inspect(@tui.shade_char(@tui.DEFAULT_SHADE_RAMP, 0.5), content="+")
  inspect(@tui.shade_char("ab", 2.0), content="b")
  let p = @tui.apply_terminal_y_scale(@view.ProjectedVertex::new(3.0, 20.0, 1.0), 20, 0.5)
  inspect(p.y, content="15")
  inspect(@tui.edge_function(0.0, 0.0, 1.0, 0.0, 0.0, 1.0), content="-1")
  let buffer = @tui.FrameBuffer::new(4, 2, @tui.dotted_background)
  @tui.draw_triangle_z(
    buffer,
    @view.ProjectedVertex::new(0.0, 0.0, 1.0),
    @view.ProjectedVertex::new(4.0, 0.0, 1.0),
    @view.ProjectedVertex::new(0.0, 2.0, 1.0),
    '#',
  )
  inspect(buffer.to_string(), content="###.\n#...\n")
}
```

## Images and sequences

### `TuiImage`

`TuiImage` is one rendered frame with its size.

```mbti
pub struct TuiImage {
  width : Int
  height : Int
  content : String
}
```

### `TuiImage::new`

`TuiImage::new(width, height, content)` builds an image, raising a dimension below 1 to 1.

```mbti
pub fn TuiImage::new(Int, Int, String) -> Self
```

### `encode_tui_image`, `decode_tui_image`

`encode_tui_image(image)` writes the `.tuiimg` text format; `decode_tui_image(text)` reads it back.

```mbti
pub fn encode_tui_image(TuiImage) -> String
pub fn decode_tui_image(String) -> TuiImage
```

The format is the line `GEOMETRY3D_TUI_IMAGE v1`, the lines `width=W` and `height=H`, the line `---image---`, and the content, terminated by a newline. The decoder reads at most `H` content lines and drops `'\r'`. It never fails: unreadable numbers fall back to the defaults, and a missing magic line gives an empty 80 × 32 image.

### `TuiFrame`

`TuiFrame` is one frame of a sequence.

```mbti
pub struct TuiFrame {
  content : String
}
```

### `TuiFrame::new`

`TuiFrame::new(content)` wraps a frame.

```mbti
pub fn TuiFrame::new(String) -> Self
```

### `TuiSequence`

`TuiSequence` is an animation: size, frame rate and frames.

```mbti
pub struct TuiSequence {
  width : Int
  height : Int
  fps : Int
  frames : Array[TuiFrame]
}
```

### `TuiSequence::new`, `TuiSequence::push_frame`

`TuiSequence::new(width, height, fps)` builds an empty sequence, raising values below 1 to 1; `sequence.push_frame(content)` appends a frame in place.

```mbti
pub fn TuiSequence::new(Int, Int, Int) -> Self
pub fn TuiSequence::push_frame(Self, String) -> Unit
```

### `encode_tui_sequence`, `decode_tui_sequence`

`encode_tui_sequence(sequence)` writes the `.tui3d` text format; `decode_tui_sequence(text)` reads it back.

```mbti
pub fn encode_tui_sequence(TuiSequence) -> String
pub fn decode_tui_sequence(String) -> TuiSequence
```

The format is the line `GEOMETRY3D_TUI_SEQUENCE v1`, the lines `width=W`, `height=H`, `fps=F` and `frames=N`, and for each frame the line `---frame---` followed by its content and a newline. The decoder takes up to `H` lines after each marker as a frame and ignores the `frames=` count. A missing magic line gives an empty 80 × 32 sequence at 30 fps.

```moonbit
test "files" {
  let sequence = @tui.TuiSequence::new(3, 1, 12)
  sequence.push_frame("abc\n")
  sequence.push_frame("def\n")
  let text = @tui.encode_tui_sequence(sequence)
  inspect(
    text,
    content=(
      #|GEOMETRY3D_TUI_SEQUENCE v1
      #|width=3
      #|height=1
      #|fps=12
      #|frames=2
      #|---frame---
      #|abc
      #|---frame---
      #|def
      #|
    ),
  )
  let back = @tui.decode_tui_sequence(text)
  inspect(back.frames[1].content, content="def\n")
  let image = @tui.decode_tui_image(@tui.encode_tui_image(@tui.TuiImage::new(3, 1, "xyz")))
  inspect(image.content, content="xyz\n")
}
```
