# backend/gsap tutorial

This tutorial shows you how to render a scene as SVG and control its animation with GSAP: loading GSAP on the page, drawing into an `<svg>`, driving the drawing from a `GsapPlayer`, and wiring play, pause, seek and speed controls.

## Quick start

The package needs the `js` target, `rabbita` for the DOM, and GSAP 3 on the page. Install the modules as for the [Canvas backend](canvas.md), then declare an executable package:

```moonbit nocheck
import {
  "Luna-Flow/geometry3d/core",
  "Luna-Flow/geometry3d/view",
  "Luna-Flow/geometry3d/frontend",
  "Luna-Flow/geometry3d/backend/gsap",
  "moonbit-community/rabbita/dom",
}

supported_targets = "js"

pkgtype(kind: "executable")
```

The page loads GSAP, publishes it as `globalThis.gsap`, and only then loads the MoonBit output:

```html
<!doctype html>
<svg id="scene" xmlns="http://www.w3.org/2000/svg"></svg>
<script type="module">
  import { gsap } from "https://cdn.jsdelivr.net/npm/gsap@3.13.0/+esm";
  globalThis.gsap = gsap;
  await import("./main.js");
</script>
```

The program spins a torus once every eight seconds, forever:

```moonbit
fn main {
  let svg = @dom.document().get_element_by_id("scene").to_option().unwrap()
  let config = @gsap.GsapSvgRenderConfig::sized(640, 480)
  let view = @frontend.RenderView::perspective(
    @view.Camera3::default(6.0),
    @view.PerspectiveProjection::new(@view.Viewport::new(640, 480), 380.0),
  )
  let player = @gsap.GsapPlayer::new(8.0, fn(t) {
    let angle = t / 8.0 * 2.0 * @math.PI
    let scene = @frontend.Scene::single(
      @core.torus_mesh(1.7, 0.58, 32, 18),
      @core.Transform3::rotation(0.7 * angle, angle, 0.25 * angle),
      @frontend.Light::default(),
    )
    @gsap.render_scene(svg, scene, view, config)
  })
  player.play()
}
```

The player calls the function with the timeline time on every animation frame, and the backend updates the polygons in place. Because the frame is a function of `t` only, the animation loops seamlessly at $t = 8$.

## Everyday tasks

### Wire playback controls

Every control maps to one method. Keep the player in a variable and call it from event handlers (here with `add_event_listener` from `rabbita`):

```moonbit
fn bind_button(id : String, action : () -> Unit) -> Unit {
  let element = @dom.document().get_element_by_id(id).to_option().unwrap()
  element.add_event_listener("click", fn(_) { action() })
}

fn wire(player : @gsap.GsapPlayer) -> Unit {
  bind_button("toggle", fn() {
    if player.is_paused() { player.play() } else { player.pause() }
  })
  bind_button("reverse", fn() { player.reverse() })
  bind_button("restart", fn() { player.restart() })
  bind_button("half-speed", fn() { player.set_time_scale(0.5) })
  bind_button("once", fn() { player.set_repeat(0) })
  bind_button("middle", fn() { player.set_progress(0.5) })
}
```

`seek` and `set_progress` clamp their arguments to the timeline, `set_time_scale` ignores non-positive factors, and `set_repeat` treats anything below `-1` as "forever".

### Show a timeline position

Read `time()` and `progress()` inside the frame callback to update a readout or a range input. The `demo_gsap` package does this with a small JavaScript function; in MoonBit you can format the text yourself:

```moonbit
fn readout(time : Double, duration : Double) -> String {
  let tenths = (time * 10.0).round().to_int()
  "\{tenths / 10}.\{tenths % 10} / \{duration.to_int()} s"
}

test "readout" {
  inspect(readout(3.14159, 8.0), content="3.1 / 8 s")
}
```

### Choose the scene at run time

Keep the current choice in a `Ref` and read it in the callback; after changing it, redraw the current time so that a paused player shows the new scene at once:

```moonbit
fn scene_for(kind : String, t : Double) -> @frontend.Scene {
  let mesh = if kind == "cube" { @core.cube_mesh(1.2) } else { @core.torus_mesh(1.7, 0.58, 32, 18) }
  @frontend.Scene::single(
    mesh,
    @core.Transform3::rotation(0.5 * t, 0.8 * t, 0.0),
    @frontend.Light::default(),
  )
}

fn start_with_selection(svg : @dom.Element, view : @frontend.RenderView) -> (@gsap.GsapPlayer, Ref[String]) {
  let config = @gsap.GsapSvgRenderConfig::sized(640, 480)
  let kind = Ref("torus")
  let player = @gsap.GsapPlayer::new(8.0, fn(t) {
    @gsap.render_scene(svg, scene_for(kind.val, t), view, config)
  })
  (player, kind)
}

fn select(player : @gsap.GsapPlayer, kind : Ref[String], value : String, svg : @dom.Element, view : @frontend.RenderView) -> Unit {
  kind.val = value
  @gsap.render_scene(svg, scene_for(value, player.time()), view, @gsap.GsapSvgRenderConfig::sized(640, 480))
}
```

## Going further

### Exactness of the drawing order

Polygons are sorted far to near by mean depth. A single convex object (cube, sphere, cylinder, cone, pyramid) is always drawn correctly; the torus and multi-object scenes can show brief ordering errors where triangles overlap in depth, and intersecting objects are never resolved. The [GSAP design](../../design/backend/gsap.md) proves when the order is exact. Use the [Canvas backend](canvas.md) when exact occlusion matters more than vector output.

### Styling the output

The SVG is ordinary DOM: scale it with CSS (`width: 100%; height: auto` keeps the `viewBox` aspect ratio), add filters, or export it by serializing the element. The backend only touches its own background rectangle and triangle group.

## Common pitfalls

- **GSAP not loaded.** `GsapPlayer::new` throws "geometry3d GSAP backend requires globalThis.gsap" when GSAP is missing. Import GSAP before the MoonBit module, as in the page above.
- **Wrong target.** The package only builds for `js`; add `supported_targets = "js"` to every package that imports it.
- **Foreign children.** The first render replaces all children of an `<svg>` that lacks the backend's marker nodes. Give the backend its own `<svg>` element.
- **Time scale for reverse.** Use `reverse()`, not a negative time scale; `set_time_scale` replaces non-positive factors by `1.0`.
- **Seams.** Browsers anti-alias each polygon separately, so faint lines can appear between adjacent triangles of the same face.

## Next steps

- The [GSAP API](../../api/backend/gsap.md) lists the renderer and every player method.
- The [GSAP design](../../design/backend/gsap.md) analyses the painter's ordering.
- The [demo_gsap tutorial](../demo_gsap.md) walks through the repository's complete player page.
