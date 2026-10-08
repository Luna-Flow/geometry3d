# backend/canvas API

The package `Luna-Flow/geometry3d/backend/canvas` draws a frontend `DrawList` on an HTML `<canvas>` with the 2D context. It rasterizes the list into the frontend's software depth buffer, quantizes each pixel's intensity to a shade of one foreground colour, and paints horizontal runs of equal shade with `fillRect`. It supports only the `js` target and uses the DOM bindings of `moonbit-community/rabbita`.

```moonbit nocheck
import {
  "Luna-Flow/geometry3d/frontend",
  "Luna-Flow/geometry3d/backend/canvas",
  "moonbit-community/rabbita/dom",
}

supported_targets = "js"
```

Add `moonbit-community/rabbita` to your module (`moon add moonbit-community/rabbita@0.12.4`). The [Canvas design](../../design/backend/canvas.md) explains the shading and the run merging; the [Canvas tutorial](../../tutorial/backend/canvas.md) builds a page around it.

## Configuration

### `CanvasColor`

`CanvasColor` is an RGB colour with channels in $[0, 255]$.

```mbti
pub struct CanvasColor {
  red : Int
  green : Int
  blue : Int
}
```

### `CanvasColor::rgb`

`CanvasColor::rgb(r, g, b)` builds a colour, clamping each channel to $[0, 255]$.

```mbti
pub fn CanvasColor::rgb(Int, Int, Int) -> Self
```

### `CanvasRenderConfig`

`CanvasRenderConfig` is the canvas size, the background colour, the foreground colour and the number of shade levels.

```mbti
pub struct CanvasRenderConfig {
  width : Int
  height : Int
  background_color : CanvasColor
  foreground_color : CanvasColor
  shade_levels : Int
}
```

The fields are read-only outside the package, so a configuration comes from the constructors below. Every render call normalizes it again: non-positive sizes become 640 × 480, channels are clamped, and `shade_levels` is clamped to $[2, 256]$.

### `CanvasRenderConfig::default`, `CanvasRenderConfig::sized`

`CanvasRenderConfig::default()` is 640 × 480; `CanvasRenderConfig::sized(w, h)` uses the given size (non-positive values become 640 or 480). Both use the background `rgb(7, 12, 22)`, the foreground `rgb(112, 226, 255)` and 256 shade levels.

```mbti
pub fn CanvasRenderConfig::default() -> Self
pub fn CanvasRenderConfig::sized(Int, Int) -> Self
```

`default` is an ordinary constructor, not an implementation of the `Default` trait.

```moonbit
test "canvas config" {
  let config = @canvas.CanvasRenderConfig::sized(320, 0)
  debug_inspect((config.width, config.height, config.shade_levels), content="(320, 480, 256)")
  let c = @canvas.CanvasColor::rgb(-5, 128, 300)
  debug_inspect([c.red, c.green, c.blue], content="[0, 128, 255]")
}
```

## Rendering

### `render_draw_list`

`render_draw_list(context, list, config)` paints a draw list on a 2D context.

```mbti
pub fn render_draw_list(@dom.CanvasRenderingContext2D, @frontend.DrawList, CanvasRenderConfig) -> Unit
```

It fills the whole configured area with the background colour, rasterizes the list with `@frontend.draw_list_to_luma` at the configured size, and for each covered pixel computes the shade $q = \operatorname{round}(\operatorname{clamp}(I)\,(L - 1))$ with $L$ shade levels. It then paints each maximal horizontal run of covered pixels with equal $q$ as one 1-pixel-high `fillRect` in the colour $\operatorname{round}(\mathit{fg} \cdot q / (L - 1))$. The fill style is set only when the shade changes between consecutive runs. A covered pixel with intensity 0 is painted black, not with the background colour. The draw list should have been projected into a viewport of the configured size.

### `render_scene`

`render_scene(context, scene, view, config)` runs `@frontend.build_draw_list` and `render_draw_list`.

```mbti
pub fn render_scene(@dom.CanvasRenderingContext2D, @frontend.Scene, @frontend.RenderView, CanvasRenderConfig) -> Unit
```

### `render_canvas`

`render_canvas(canvas, list, config)` sets the canvas element's `width` and `height` attributes to the configured size, gets its 2D context and calls `render_draw_list`.

```mbti
pub fn render_canvas(@dom.HTMLCanvasElement, @frontend.DrawList, CanvasRenderConfig) -> Unit
```

It aborts if the element has no 2D context.

```moonbit
fn draw_cube_on(canvas : @dom.HTMLCanvasElement, angle : Double) -> Unit {
  let config = @canvas.CanvasRenderConfig::sized(320, 240)
  let view = @frontend.RenderView::perspective(
    @view.Camera3::default(4.5),
    @view.PerspectiveProjection::new(@view.Viewport::new(320, 240), 200.0),
  )
  let scene = @frontend.Scene::single(
    @core.cube_mesh(1.0),
    @core.Transform3::rotation(0.4, angle, 0.0),
    @frontend.Light::default(),
  )
  @canvas.render_canvas(canvas, @frontend.build_draw_list(scene, view), config)
}
```
