# backend/canvas tutorial

This tutorial shows you how to put a `geometry3d` scene on a web page: set up a JavaScript-target package, draw a frame on a `<canvas>`, animate it with `requestAnimationFrame`, and write a variant with your own colours.

| I want to | Use |
| --- | --- |
| draw a scene on a `<canvas>` | `@canvas.render_scene(context, scene, view, config)` |
| animate it | `requestAnimationFrame` through `@dom.window()` |
| choose the size and colours | `@canvas.CanvasRenderConfig::sized`, `CanvasColor::rgb` |
| draw an existing draw list | `@canvas.render_draw_list` |

## Quick start

The backend needs the `js` target and the DOM bindings of `rabbita`:

```sh
moon add Luna-Flow/geometry3d@0.5.1
moon add Luna-Flow/linear-algebra@0.4.2
moon add moonbit-community/rabbita@0.12.4
```

Declare an executable package for the browser in `moon.pkg`:

```moonbit nocheck
import {
  "Luna-Flow/geometry3d/core",
  "Luna-Flow/geometry3d/view",
  "Luna-Flow/geometry3d/frontend",
  "Luna-Flow/geometry3d/backend/canvas",
  "moonbit-community/rabbita/dom",
}

supported_targets = "js"

pkgtype(kind: "executable")
```

Draw one frame into the element with id `scene`:

```moonbit
fn main {
  let canvas = @dom.document()
    .get_element_by_id("scene")
    .to_option()
    .unwrap()
    .to_html_canvas_element()
    .unwrap()
  let view = @frontend.RenderView::perspective(
    @view.Camera3::default(4.5),
    @view.PerspectiveProjection::new(@view.Viewport::new(480, 360), 300.0),
  )
  let scene = @frontend.Scene::single(
    @core.torus_mesh(1.6, 0.55, 32, 18),
    @core.Transform3::rotation(1.0, 0.4, 0.0),
    @frontend.Light::default(),
  )
  let list = @frontend.build_draw_list(scene, view)
  @canvas.render_canvas(canvas, list, @canvas.CanvasRenderConfig::sized(480, 360))
}
```

Build it with `moon build --target js` and load the generated JavaScript file from a page that contains `<canvas id="scene"></canvas>`:

```html
<!doctype html>
<canvas id="scene"></canvas>
<script type="module" src="./main.js"></script>
```

The page shows a cyan, flat-shaded torus on a dark blue background. The repository's `just canvas-build` recipe shows where `moon` puts the output (`_build/js/debug/build/<package>/<package>.js`) and copies it next to an `index.html`.

## Everyday tasks

### Animate with `requestAnimationFrame`

Ask the browser for a callback before every repaint, render the scene for the given timestamp (in milliseconds), and ask again:

```moonbit
fn start_animation(context : @dom.CanvasRenderingContext2D) -> Unit {
  let config = @canvas.CanvasRenderConfig::sized(480, 360)
  let view = @frontend.RenderView::perspective(
    @view.Camera3::default(4.5),
    @view.PerspectiveProjection::new(@view.Viewport::new(480, 360), 300.0),
  )
  let window = @dom.window()
  fn frame(timestamp : Double) -> Unit {
    let angle = timestamp * 0.001
    let scene = @frontend.Scene::single(
      @core.cube_mesh(1.0),
      @core.Transform3::rotation(0.7 * angle, angle, 0.25 * angle),
      @frontend.Light::default(),
    )
    @canvas.render_scene(context, scene, view, config)
    ignore(window.request_animation_frame(frame))
  }
  ignore(window.request_animation_frame(frame))
}
```

Get the context once with `canvas.get_context("2d").to0().unwrap()` after setting the canvas's `width` and `height` attributes to the configured size; `render_canvas` does both for a single frame.

### Frame the scene with a lens

Use a `ScientificCamera` so that the framing follows from a focal length rather than a hand-tuned scale. With a 640 × 480 canvas and a full-frame sensor, a 35 mm lens shows a vertical field of about 38°:

```moonbit
fn lens_view(focal_mm : Double) -> @frontend.RenderView {
  let camera = @view.ScientificCamera::new(
    @view.Camera3::default(6.2),
    @view.SensorSpec::full_frame(),
    @view.LensSpec::new(focal_mm),
    @view.WorldUnit::unitless(),
  )
  @frontend.RenderView::scientific(camera, @view.Viewport::new(640, 480))
}

test "lens view" {
  let degrees = @view.LensSpec::new(35.0).vertical_fov(@view.SensorSpec::full_frame()) * 180.0 / @math.PI
  inspect(degrees.round(), content="38")
  inspect(lens_view(35.0).projection.scale, content="700")
}
```

### Paint with your own colours

`CanvasRenderConfig` fixes the colours, and its fields cannot be set from your package. When you need another palette, rasterize with the frontend yourself and paint the pixels:

```moonbit
fn paint_amber(context : @dom.CanvasRenderingContext2D, list : @frontend.DrawList, w : Int, h : Int) -> Unit {
  context.set_fill_style(@js.Union3::from0("rgb(20, 10, 0)"))
  context.fill_rect(0.0, 0.0, w.to_double(), h.to_double())
  let luma = @frontend.draw_list_to_luma(list, w, h)
  for y in 0..<h {
    for x in 0..<w {
      if luma.depth_at(x, y) < @frontend.LUMA_FAR_DEPTH * 0.5 {
        let v = luma.get(x, y)
        let r = (255.0 * v).round().to_int()
        let g = (176.0 * v).round().to_int()
        context.set_fill_style(@js.Union3::from0("rgb(\{r}, \{g}, 0)"))
        context.fill_rect(x.to_double(), y.to_double(), 1.0, 1.0)
      }
    }
  }
}
```

This sketch makes one call per pixel; the backend groups equal neighbours into runs to do far fewer, as its [design](../../design/backend/canvas.md) explains. The import of `moonbit-community/rabbita/js` provides `@js.Union3`.

## Going further

### Switch scenes from the page

The `demo_canvas` package of the repository keeps the selected scene in a `Ref`, updates it from a `<select>` element's `change` event, and reads it inside the animation callback. The [demo_canvas tutorial](../demo_canvas.md) walks through it.

### Performance

Each frame rasterizes the whole canvas in MoonBit and then issues one `fillRect` per run of equal shade. Flat-shaded scenes have long runs, so 640 × 480 animates smoothly in current browsers. Rendering cost grows with the canvas area; to save time, render a smaller canvas and scale it with CSS (`image-rendering: pixelated` keeps the pixels sharp).

## Common pitfalls

- **Wrong target.** The package only builds for `js`. Add `supported_targets = "js"` to every package that imports it, or the build fails on other targets.
- **Two sizes.** Use the same size for the projection's viewport and for `CanvasRenderConfig`, and for the canvas element's `width` and `height` attributes. CSS size alone only stretches the bitmap.
- **No 2D context.** `render_canvas` aborts when `getContext("2d")` fails, for example on a canvas already used for WebGL.
- **Black is not background.** Faces turned away from the light are painted black, distinct from the background colour.
- **Read-only configuration.** You cannot change colours or shade levels through `CanvasRenderConfig`; paint the luma buffer yourself as shown above.

## Next steps

- The [Canvas API](../../api/backend/canvas.md) lists the configuration and the render functions.
- The [Canvas design](../../design/backend/canvas.md) explains the shading and the run-length painting.
- Compare with the [GSAP SVG backend](gsap.md), which keeps vector polygons instead of pixels.
