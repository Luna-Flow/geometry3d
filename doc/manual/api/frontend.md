# frontend API

## Purpose

The package `Luna-Flow/geometry3d/frontend` turns a scene and a camera into a backend-neutral list of shaded, projected triangles (`DrawList`). It also owns the software depth buffer for scalar images (`LumaBuffer`) used by the Canvas backend and the exposure effects, a block-matching optical-flow estimator, exposure settings and animation timelines. It knows nothing about characters, colours or the DOM.

## Importing

```moonbit nocheck
import {
  "Luna-Flow/geometry3d/core",
  "Luna-Flow/geometry3d/view",
  "Luna-Flow/geometry3d/frontend",
  "Luna-Flow/linear-algebra/mutable" @la,
}
```

The [frontend design](../design/frontend.md) explains the pipeline, the shadow map and the rasterization rule; the [frontend tutorial](../tutorial/frontend.md) shows them in use.

## Scenes

### `SceneObject`

`SceneObject` is one mesh with its model transform.

```mbti
pub struct SceneObject {
  mesh : @core.Mesh
  transform : @core.Transform3
}
```

### `SceneObject::new`

`SceneObject::new(mesh, transform)` builds an object; the same mesh may be shared by several objects.

```mbti
pub fn SceneObject::new(@core.Mesh, @core.Transform3) -> Self
```

### `Light`

`Light` is a directional light: `direction` is the unit vector from the scene towards the light, in world space.

```mbti
pub struct Light {
  direction : @mutable.Vector[Double]
}
```

### `Light::directional`

`Light::directional(direction)` builds a light, normalizing `direction`.

```mbti
pub fn Light::directional(@mutable.Vector[Double]) -> Self
```

A zero vector gives a light that illuminates nothing.

### `Light::default`

`Light::default()` is `Light::directional((0.6, 0.7, -1.0))`: from the upper right, on the side of the default camera.

```mbti
pub fn Light::default() -> Self
```

It is an ordinary constructor, not an implementation of the `Default` trait.

### `Scene`

`Scene` is a list of objects lit by one directional light.

```mbti
pub struct Scene {
  objects : Array[SceneObject]
  light : Light
}
```

### `Scene::new`, `Scene::single`

`Scene::new(light)` builds an empty scene; `Scene::single(mesh, transform, light)` builds a scene with one object.

```mbti
pub fn Scene::new(Light) -> Self
pub fn Scene::single(@core.Mesh, @core.Transform3, Light) -> Self
```

### `Scene::add_object`

`scene.add_object(object)` appends an object to the scene in place.

```mbti
pub fn Scene::add_object(Self, SceneObject) -> Unit
```

```moonbit
test "scene" {
  let scene = @frontend.Scene::new(@frontend.Light::default())
  scene.add_object(
    @frontend.SceneObject::new(@core.cube_mesh(1.0), @core.Transform3::identity()),
  )
  scene.add_object(
    @frontend.SceneObject::new(
      @core.sphere_mesh(0.5, 8, 12),
      @core.Transform3::translation(2.0, 0.0, 0.0),
    ),
  )
  inspect(scene.objects.length(), content="2")
  inspect(@core.vec_length(scene.light.direction), content="1")
}
```

## Render views and draw lists

### `RenderView`

`RenderView` is the camera and the perspective projection used to render a scene.

```mbti
pub struct RenderView {
  camera : @view.Camera3
  projection : @view.PerspectiveProjection
}
```

### `RenderView::perspective`, `RenderView::scientific`

`RenderView::perspective(camera, projection)` pairs a camera with a projection; `RenderView::scientific(camera, viewport)` takes the camera of a `ScientificCamera` and derives the projection from its lens and sensor.

```mbti
pub fn RenderView::perspective(@view.Camera3, @view.PerspectiveProjection) -> Self
pub fn RenderView::scientific(@view.ScientificCamera, @view.Viewport) -> Self
```

### `DrawTriangle`

`DrawTriangle` is one projected triangle with a flat intensity, nominally in $[0, 1]$; rounding can push it a few ulps above 1, and backends clamp it.

```mbti
pub struct DrawTriangle {
  p0 : @view.ProjectedVertex
  p1 : @view.ProjectedVertex
  p2 : @view.ProjectedVertex
  intensity : Double
}
```

The vertices are in viewport units with camera-space depth, as produced by `PerspectiveProjection`. The winding on the screen is not normalized; rasterizers accept both orientations.

### `DrawTriangle::new`

`DrawTriangle::new(p0, p1, p2, intensity)` builds a triangle, for example to drive a backend without a scene.

```mbti
pub fn DrawTriangle::new(@view.ProjectedVertex, @view.ProjectedVertex, @view.ProjectedVertex, Double) -> Self
```

### `DrawList`

`DrawList` is the ordered list of triangles that every backend consumes.

```mbti
pub struct DrawList {
  triangles : Array[DrawTriangle]
}
```

### `DrawList::new`, `DrawList::push_triangle`

`DrawList::new()` builds an empty list and `list.push_triangle(t)` appends a triangle in place.

```mbti
pub fn DrawList::new() -> Self
pub fn DrawList::push_triangle(Self, DrawTriangle) -> Unit
```

### `build_draw_list`

`build_draw_list(scene, view)` runs the geometric pipeline: model transform, shadow map, view transform, projection, back-face culling, Lambert shading with shadows, and triangulation.

```mbti
pub fn build_draw_list(Scene, RenderView) -> DrawList
```

For every face that faces the camera it pushes two triangles (the second has zero area for a degenerate quad) with the intensity

$$
I = \max(0, \hat n \cdot \ell)\,\big(0.35 + 0.65\,v\big),\qquad v \in \{0, 0.2, 0.4, 0.6, 0.8, 1\},
$$

where $v$ is the fraction of the face's centre and four vertices that the light reaches according to a 128 × 128 shadow map. Faces turned away from the light get $I = 0$. Triangles appear object by object in scene order, and face by face within an object; the list is not depth-sorted. The cost is linear in the number of vertices and faces plus the rasterization of the shadow map.

```moonbit
test "draw list" {
  let scene = @frontend.Scene::single(
    @core.cube_mesh(1.0),
    @core.Transform3::rotation(0.4, 0.6, 0.0),
    @frontend.Light::default(),
  )
  let view = @frontend.RenderView::perspective(
    @view.Camera3::default(4.5),
    @view.PerspectiveProjection::new(@view.Viewport::new(80, 40), 30.0),
  )
  let list = @frontend.build_draw_list(scene, view)
  // three faces of a turned cube face the camera, two triangles each
  inspect(list.triangles.length(), content="6")
  inspect(list.triangles.all(fn(t) { t.intensity >= 0.0 && t.intensity <= 1.0 }), content="true")
}
```

## Luma buffers

### `LUMA_FAR_DEPTH`

`LUMA_FAR_DEPTH` is the depth of an empty pixel, $10^{30}$.

```mbti
pub const LUMA_FAR_DEPTH : Double = 1.0e30
```

A pixel whose depth is at least `LUMA_FAR_DEPTH * 0.5` is treated as background by the backends.

### `LumaBuffer`

`LumaBuffer` is a row-major image of scalar luma values with a depth per pixel.

```mbti
pub struct LumaBuffer {
  width : Int
  height : Int
  values : Array[Double]
  depths : Array[Double]
}
```

### `LumaBuffer::new`

`LumaBuffer::new(width, height)` builds a buffer with every value `0.0` and every depth `LUMA_FAR_DEPTH`.

```mbti
pub fn LumaBuffer::new(Int, Int) -> Self
```

### `LumaBuffer::index`

`buffer.index(x, y)` returns the array index `y * width + x`, without bounds checks.

```mbti
pub fn LumaBuffer::index(Self, Int, Int) -> Int
```

### `LumaBuffer::get`, `LumaBuffer::depth_at`

`buffer.get(x, y)` returns the value at a pixel and `buffer.depth_at(x, y)` its depth; outside the buffer they return `0.0` and `LUMA_FAR_DEPTH`.

```mbti
pub fn LumaBuffer::get(Self, Int, Int) -> Double
pub fn LumaBuffer::depth_at(Self, Int, Int) -> Double
```

### `LumaBuffer::set_if_closer`

`buffer.set_if_closer(x, y, depth, value)` is the depth test: it writes the pixel only if `depth + DEPTH_EPSILON` is less than the stored depth.

```mbti
pub fn LumaBuffer::set_if_closer(Self, Int, Int, Double, Double) -> Unit
```

Writes outside the buffer are ignored. Equal depths keep the value written first.

### `LumaBuffer::draw_triangle`

`buffer.draw_triangle(t)` rasterizes one triangle: every pixel whose centre $(x + \tfrac12, y + \tfrac12)$ lies inside or on the edge of the triangle receives `t.intensity` if it passes the depth test with the perspective-correct depth.

```mbti
pub fn LumaBuffer::draw_triangle(Self, DrawTriangle) -> Unit
```

Triangles with an area of at most `DEPTH_EPSILON` are skipped. The loop runs over the triangle's bounding box, which is not clipped to the buffer.

### `draw_list_to_luma`

`draw_list_to_luma(list, width, height)` creates a buffer and draws every triangle of the list into it, in order.

```mbti
pub fn draw_list_to_luma(DrawList, Int, Int) -> LumaBuffer
```

### `LumaBuffer::add_weighted_sample`

`buffer.add_weighted_sample(sample, w)` adds `w * sample.values[i]` to every value in place and keeps the smaller of the two depths.

```mbti
pub fn LumaBuffer::add_weighted_sample(Self, Self, Double) -> Unit
```

Only the first $\min$ of the two lengths is processed; use buffers of the same size.

### `average_luma`

`average_luma(a, b)` returns a new buffer with the mean of the values and the minimum of the depths of two buffers of the same size.

```mbti
pub fn average_luma(LumaBuffer, LumaBuffer) -> LumaBuffer
```

```moonbit
test "luma buffer" {
  let near = @frontend.DrawTriangle::new(
    @view.ProjectedVertex::new(0.0, 0.0, 2.0),
    @view.ProjectedVertex::new(8.0, 0.0, 2.0),
    @view.ProjectedVertex::new(0.0, 8.0, 2.0),
    0.8,
  )
  let far = @frontend.DrawTriangle::new(
    @view.ProjectedVertex::new(0.0, 0.0, 5.0),
    @view.ProjectedVertex::new(8.0, 0.0, 5.0),
    @view.ProjectedVertex::new(0.0, 8.0, 5.0),
    0.3,
  )
  let list = @frontend.DrawList::new()
  list.push_triangle(far)
  list.push_triangle(near)
  let buffer = @frontend.draw_list_to_luma(list, 8, 8)
  inspect(buffer.get(1, 1), content="0.8")
  inspect(buffer.depth_at(1, 1), content="2")
  inspect(buffer.depth_at(7, 7) == @frontend.LUMA_FAR_DEPTH, content="true")
  let dark = @frontend.LumaBuffer::new(8, 8)
  inspect(@frontend.average_luma(buffer, dark).get(1, 1), content="0.4")
  dark.add_weighted_sample(buffer, 0.5)
  inspect(dark.get(1, 1), content="0.4")
}
```

## Exposure

### `ShutterSpeed`

`ShutterSpeed` is an exposure time in seconds.

```mbti
pub struct ShutterSpeed {
  seconds : Double
}
```

### `ShutterSpeed::seconds`, `ShutterSpeed::reciprocal`

`ShutterSpeed::seconds(t)` builds a shutter of `t` seconds and `ShutterSpeed::reciprocal(n)` one of `1/n` seconds; non-positive arguments give 1/60 s.

```mbti
pub fn ShutterSpeed::seconds(Double) -> Self
pub fn ShutterSpeed::reciprocal(Double) -> Self
```

### `ExposureSettings`

`ExposureSettings` is a shutter, the frame interval it belongs to, and the number of samples to average.

```mbti
pub struct ExposureSettings {
  shutter : ShutterSpeed
  frame_dt : Double
  samples : Int
}
```

### `ExposureSettings::new`

`ExposureSettings::new(shutter, frame_dt, samples)` builds settings: a non-positive `frame_dt` becomes 1/60 s, the shutter is clamped to at most `frame_dt`, and `samples` is raised to at least 1.

```mbti
pub fn ExposureSettings::new(ShutterSpeed, Double, Int) -> Self
```

### `ExposureSettings::auto`

`ExposureSettings::auto(shutter, frame_dt)` builds settings with `samples = ceil(shutter / frame_dt)`, computed after the shutter has been clamped.

```mbti
pub fn ExposureSettings::auto(ShutterSpeed, Double) -> Self
```

Because the shutter never exceeds `frame_dt` after clamping, `auto` always yields one sample. Callers that want a long exposure choose a larger count themselves, as the TUI demo does.

```moonbit
test "exposure" {
  let shutter = @frontend.ShutterSpeed::reciprocal(30.0)
  let settings = @frontend.ExposureSettings::auto(shutter, 1.0 / 60.0)
  inspect(settings.shutter.seconds == 1.0 / 60.0, content="true")
  inspect(settings.samples, content="1")
  let manual = @frontend.ExposureSettings::new(shutter, 1.0 / 24.0, 12)
  inspect(manual.samples, content="12")
}
```

## Optical flow

### `FlowVector`

`FlowVector` is an integer pixel displacement.

```mbti
pub struct FlowVector {
  dx : Int
  dy : Int
}
```

### `FlowVector::new`

`FlowVector::new(dx, dy)` builds a displacement.

```mbti
pub fn FlowVector::new(Int, Int) -> Self
```

### `FlowField`

`FlowField` is a row-major field of displacements, one per pixel.

```mbti
pub struct FlowField {
  width : Int
  height : Int
  vectors : Array[FlowVector]
}
```

### `FlowField::new`, `FlowField::index`, `FlowField::get`, `FlowField::set`

`FlowField::new(w, h)` builds a zero field; `index` is `y * width + x`; `get` returns `(0, 0)` outside the field and `set` ignores writes outside it.

```mbti
pub fn FlowField::new(Int, Int) -> Self
pub fn FlowField::index(Self, Int, Int) -> Int
pub fn FlowField::get(Self, Int, Int) -> FlowVector
pub fn FlowField::set(Self, Int, Int, FlowVector) -> Unit
```

### `estimate_optical_flow`

`estimate_optical_flow(previous, current, search_radius, patch_radius)` estimates, for every pixel of `current`, where its neighbourhood came from in `previous`.

```mbti
pub fn estimate_optical_flow(LumaBuffer, LumaBuffer, Int, Int) -> FlowField
```

For each pixel $(x, y)$ it returns the displacement $(d_x, d_y)$ with $|d_x|, |d_y| \le$ `search_radius` that minimizes the sum of squared differences between the $(2P + 1)^2$ patch around $(x + d_x, y + d_y)$ in `previous` and the patch around $(x, y)$ in `current`, with $P$ = `patch_radius`. Pixels outside a buffer read as `0.0`. Ties keep the first displacement in the scan order ($d_y$, then $d_x$, from $-R$ upwards), so in a uniform region, where every displacement fits equally well, the result is $(-R, -R)$ rather than $(0, 0)$. Negative radii are treated as 0. The cost is $O\big(W H (2R + 1)^2 (2P + 1)^2\big)$.

### `align_with_flow`

`align_with_flow(previous, current, flow)` warps `previous` onto the pixel grid of `current`: pixel $(x, y)$ of the result takes value and depth from $(x + d_x, y + d_y)$ in `previous`.

```mbti
pub fn align_with_flow(LumaBuffer, LumaBuffer, FlowField) -> LumaBuffer
```

### `accumulate_with_flow`

`accumulate_with_flow(previous, current, flow)` returns the average of the warped `previous` and `current`, with the depths of `current`.

```mbti
pub fn accumulate_with_flow(LumaBuffer, LumaBuffer, FlowField) -> LumaBuffer
```

```moonbit
test "optical flow" {
  let previous = @frontend.LumaBuffer::new(6, 6)
  let current = @frontend.LumaBuffer::new(6, 6)
  previous.set_if_closer(2, 2, 1.0, 1.0) // a bright pixel at (2, 2)
  current.set_if_closer(3, 2, 1.0, 1.0) // has moved one pixel right
  let flow = @frontend.estimate_optical_flow(previous, current, 2, 1)
  let v = flow.get(3, 2)
  debug_inspect((v.dx, v.dy), content="(-1, 0)")
  let aligned = @frontend.align_with_flow(previous, current, flow)
  inspect(aligned.get(3, 2), content="1")
  inspect(@frontend.accumulate_with_flow(previous, current, flow).get(3, 2), content="1")
  // far from the moving pixel every displacement fits: the first one wins
  let flat = flow.get(0, 5)
  debug_inspect((flat.dx, flat.dy), content="(-2, -2)")
}
```

## Timelines

### `Timeline`

`Timeline` is a fixed-rate clip: a duration in seconds and a frame rate.

```mbti
pub struct Timeline {
  duration_seconds : Double
  fps : Int
}
```

### `Timeline::new`

`Timeline::new(duration, fps)` builds a timeline; a non-positive duration becomes 1 s and an fps below 1 becomes 1.

```mbti
pub fn Timeline::new(Double, Int) -> Self
```

### `Timeline::frame_count`, `Timeline::frame_dt`

`frame_count` returns $\max(1, \lceil D \cdot \mathit{fps} \rceil)$ and `frame_dt` returns $1/\mathit{fps}$.

```mbti
pub fn Timeline::frame_count(Self) -> Int
pub fn Timeline::frame_dt(Self) -> Double
```

### `TimelineSample`

`TimelineSample` is one frame of a timeline: its index, its time $t = k/\mathit{fps}$ and its progress $\min(1, t/D)$.

```mbti
pub struct TimelineSample {
  frame_index : Int
  time_seconds : Double
  progress : Double
}
```

### `Timeline::sample`

`timeline.sample(k)` returns the sample of frame `k`; a negative index is treated as 0. Indices past the end are allowed and give a progress of 1.

```mbti
pub fn Timeline::sample(Self, Int) -> TimelineSample
```

### `ScalarKeyframe`

`ScalarKeyframe` is a value at a time.

```mbti
pub struct ScalarKeyframe {
  time_seconds : Double
  value : Double
}
```

### `ScalarKeyframe::new`

`ScalarKeyframe::new(time, value)` builds a keyframe.

```mbti
pub fn ScalarKeyframe::new(Double, Double) -> Self
```

### `ScalarTrack`

`ScalarTrack` is a piecewise-linear animation curve through keyframes sorted by time.

```mbti
pub struct ScalarTrack {
  keyframes : Array[ScalarKeyframe]
}
```

### `ScalarTrack::new`

`ScalarTrack::new(keyframes)` builds a track; the keyframes must be sorted by increasing time.

```mbti
pub fn ScalarTrack::new(Array[ScalarKeyframe]) -> Self
```

### `ScalarTrack::sample`

`track.sample(t)` returns the value at time `t`: linear interpolation between the surrounding keyframes, the first value before the first keyframe, the last value after the last one, and `0.0` for an empty track.

```mbti
pub fn ScalarTrack::sample(Self, Double) -> Double
```

When two keyframes share a time (within `DEPTH_EPSILON`), the later value wins at that time.

```moonbit
test "timeline" {
  let timeline = @frontend.Timeline::new(1.0, 4)
  inspect(timeline.frame_count(), content="4")
  let s = timeline.sample(2)
  debug_inspect((s.time_seconds, s.progress), content="(0.5, 0.5)")
  let track = @frontend.ScalarTrack::new([
    @frontend.ScalarKeyframe::new(0.0, 0.0),
    @frontend.ScalarKeyframe::new(1.0, 10.0),
  ])
  inspect(track.sample(0.25), content="2.5")
  inspect(track.sample(5.0), content="10")
}
```
