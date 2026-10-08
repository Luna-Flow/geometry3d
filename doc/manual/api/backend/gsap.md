# backend/gsap API

The package `Luna-Flow/geometry3d/backend/gsap` draws a frontend `DrawList` as SVG polygons and drives animations with a [GSAP](https://gsap.com/) timeline. Triangles are ordered far to near (painter's algorithm) and written into reusable `<polygon>` nodes of an `<svg>` element. `GsapPlayer` wraps a GSAP timeline that calls back into MoonBit with the current time. The package supports only the `js` target, uses `moonbit-community/rabbita/dom`, and expects GSAP 3 at `globalThis.gsap`.

```moonbit nocheck
import {
  "Luna-Flow/geometry3d/frontend",
  "Luna-Flow/geometry3d/backend/gsap",
  "moonbit-community/rabbita/dom",
}

supported_targets = "js"
```

The [GSAP design](../../design/backend/gsap.md) explains the ordering and its limits; the [GSAP tutorial](../../tutorial/backend/gsap.md) builds a player page.

## Configuration

### `GsapSvgColor`

`GsapSvgColor` is an RGB colour with channels in $[0, 255]$.

```mbti
pub struct GsapSvgColor {
  red : Int
  green : Int
  blue : Int
}
```

### `GsapSvgColor::rgb`

`GsapSvgColor::rgb(r, g, b)` builds a colour, clamping each channel to $[0, 255]$.

```mbti
pub fn GsapSvgColor::rgb(Int, Int, Int) -> Self
```

### `GsapSvgRenderConfig`

`GsapSvgRenderConfig` is the SVG size, the background colour, the foreground colour and the number of shade levels.

```mbti
pub struct GsapSvgRenderConfig {
  width : Int
  height : Int
  background_color : GsapSvgColor
  foreground_color : GsapSvgColor
  shade_levels : Int
}
```

The fields are read-only outside the package. Each render call normalizes the configuration: non-positive sizes become 640 × 480, channels are clamped, and `shade_levels` is clamped to $[2, 256]$.

### `GsapSvgRenderConfig::default`, `GsapSvgRenderConfig::sized`

`GsapSvgRenderConfig::default()` is 640 × 480 and `GsapSvgRenderConfig::sized(w, h)` uses the given size (non-positive values become 640 or 480). Both use the background `rgb(7, 12, 22)`, the foreground `rgb(112, 226, 255)` and 256 shade levels.

```mbti
pub fn GsapSvgRenderConfig::default() -> Self
pub fn GsapSvgRenderConfig::sized(Int, Int) -> Self
```

```moonbit
test "svg config" {
  let config = @gsap.GsapSvgRenderConfig::sized(-1, 360)
  debug_inspect((config.width, config.height), content="(640, 360)")
  let fg = config.foreground_color
  debug_inspect([fg.red, fg.green, fg.blue], content="[112, 226, 255]")
}
```

## Rendering

### `render_draw_list`

`render_draw_list(svg, list, config)` updates an `<svg>` element to show a draw list.

```mbti
pub fn render_draw_list(@dom.Element, @frontend.DrawList, GsapSvgRenderConfig) -> Unit
```

It sorts the triangles by the mean depth of their three vertices, farthest first, keeping the list order among equal depths. It sets the element's `width`, `height`, `viewBox` (`0 0 W H`), `role="img"` and `data-geometry3d-backend="gsap-svg"` attributes. It makes sure the element has a background `<rect data-gsap-svg-background>` and a group `<g data-gsap-svg-triangles>` as its direct children (replacing all children the first time). It then grows or shrinks the group to one `<polygon>` per triangle and writes each polygon's `points` and `fill`. The fill is the foreground colour scaled by the quantized intensity $q/(L - 1)$, $q = \operatorname{round}(\operatorname{clamp}(I)(L - 1))$, as in the Canvas backend. Polygons are reused between calls, so repeated rendering does not recreate DOM nodes.

### `render_scene`

`render_scene(svg, scene, view, config)` runs `@frontend.build_draw_list` and `render_draw_list`.

```mbti
pub fn render_scene(@dom.Element, @frontend.Scene, @frontend.RenderView, GsapSvgRenderConfig) -> Unit
```

```moonbit
fn draw_on(svg : @dom.Element, angle : Double) -> Unit {
  let view = @frontend.RenderView::perspective(
    @view.Camera3::default(4.5),
    @view.PerspectiveProjection::new(@view.Viewport::new(640, 480), 400.0),
  )
  let scene = @frontend.Scene::single(
    @core.cube_mesh(1.0),
    @core.Transform3::rotation(0.4, angle, 0.0),
    @frontend.Light::default(),
  )
  @gsap.render_scene(svg, scene, view, @gsap.GsapSvgRenderConfig::sized(640, 480))
}
```

## Playback

### `GsapTimeline`

`GsapTimeline` is an opaque handle to a JavaScript GSAP timeline object.

```mbti
type GsapTimeline
```

### `GsapPlayer`

`GsapPlayer` is a paused-by-default GSAP timeline of a fixed duration that reports its time to a MoonBit callback.

```mbti
pub struct GsapPlayer {
  timeline : GsapTimeline
  duration_seconds : Double
}
```

### `GsapPlayer::new`

`GsapPlayer::new(duration, on_frame, repeat?)` creates a paused timeline that tweens a clock from $0$ to `duration` seconds with a linear ease and calls `on_frame(t)` on every update. It also calls `on_frame(0.0)` once immediately.

```mbti
pub fn GsapPlayer::new(Double, (Double) -> Unit, repeat? : Int) -> Self
```

A non-positive duration becomes 1 s. `repeat` is GSAP's repeat count: `-1` (the default) repeats forever, `0` plays once. It aborts with a JavaScript error if `globalThis.gsap.timeline` is not available.

### `GsapPlayer::play`, `GsapPlayer::pause`, `GsapPlayer::reverse`, `GsapPlayer::restart`, `GsapPlayer::kill`

These methods forward to the timeline's `play()`, `pause()`, `reverse()`, `restart()` and `kill()`.

```mbti
pub fn GsapPlayer::play(Self) -> Unit
pub fn GsapPlayer::pause(Self) -> Unit
pub fn GsapPlayer::reverse(Self) -> Unit
pub fn GsapPlayer::restart(Self) -> Unit
pub fn GsapPlayer::kill(Self) -> Unit
```

After `kill` the player must not be used again.

### `GsapPlayer::seek`, `GsapPlayer::time`

`player.seek(t)` moves the playhead to `t` seconds, clamped to $[0, \mathit{duration}]$; `player.time()` returns the playhead's local time.

```mbti
pub fn GsapPlayer::seek(Self, Double) -> Unit
pub fn GsapPlayer::time(Self) -> Double
```

### `GsapPlayer::progress`, `GsapPlayer::set_progress`

`player.progress()` returns the playhead position as a fraction of one iteration; `player.set_progress(p)` sets it, clamping `p` to $[0, 1]$.

```mbti
pub fn GsapPlayer::progress(Self) -> Double
pub fn GsapPlayer::set_progress(Self, Double) -> Unit
```

### `GsapPlayer::time_scale`, `GsapPlayer::set_time_scale`

`player.time_scale()` returns the playback speed factor; `player.set_time_scale(k)` sets it, replacing a non-positive `k` by `1.0`.

```mbti
pub fn GsapPlayer::time_scale(Self) -> Double
pub fn GsapPlayer::set_time_scale(Self, Double) -> Unit
```

Use `reverse` rather than a negative scale to play backwards.

### `GsapPlayer::set_repeat`

`player.set_repeat(n)` sets the repeat count, raising values below `-1` to `-1` (repeat forever).

```mbti
pub fn GsapPlayer::set_repeat(Self, Int) -> Unit
```

### `GsapPlayer::is_paused`

`player.is_paused()` returns whether the timeline is paused.

```mbti
pub fn GsapPlayer::is_paused(Self) -> Bool
```

```moonbit
fn start_player(svg : @dom.Element) -> @gsap.GsapPlayer {
  let player = @gsap.GsapPlayer::new(8.0, fn(t) { draw_on(svg, t * 0.8) }, repeat=-1)
  player.set_time_scale(0.5)
  player.play()
  player
}
```
