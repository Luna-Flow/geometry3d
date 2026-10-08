# frontend tutorial

This tutorial shows you how to describe a scene, render it into the backend-neutral `DrawList`, and work with the frontend's image tools: the luma buffer, shadows, long exposures and timelines. At the end you write a tiny backend of your own.

| I want to | Use |
| --- | --- |
| put meshes and a light into a scene | `@frontend.Scene::single`, `Scene::new`, `Scene::add_object` |
| turn a scene into shaded triangles | `@frontend.build_draw_list(scene, view)` |
| render through a physical camera | `@frontend.RenderView::scientific(camera, viewport)` |
| rasterize into a depth-tested scalar image | `@frontend.draw_list_to_luma` |
| average several frames into a long exposure | `LumaBuffer::add_weighted_sample` with `ExposureSettings` |
| sample an animation at fixed times | `Timeline::sample`, `ScalarTrack::sample` |

## Quick start

Import the frontend next to `core` and `view`:

```moonbit nocheck
import {
  "moonbitlang/core/math",
  "Luna-Flow/geometry3d/core",
  "Luna-Flow/geometry3d/view",
  "Luna-Flow/geometry3d/frontend",
  "Luna-Flow/linear-algebra/mutable" @la,
}
```

Render a turned cube into a 24 × 10 luma buffer and print it with three characters of your choice:

```moonbit
fn main {
  let scene = @frontend.Scene::single(
    @core.cube_mesh(1.0),
    @core.Transform3::rotation(0.5, 0.7, 0.0),
    @frontend.Light::default(),
  )
  let viewport = @view.Viewport::new(24, 10)
  let projection = @view.PerspectiveProjection::new(viewport, 9.0)
  let view = @frontend.RenderView::perspective(@view.Camera3::default(4.0), projection)
  let luma = @frontend.draw_list_to_luma(@frontend.build_draw_list(scene, view), 24, 10)
  for y in 0..<10 {
    let row = StringBuilder()
    for x in 0..<24 {
      let v = luma.get(x, y)
      row.write_char(if luma.depth_at(x, y) >= @frontend.LUMA_FAR_DEPTH { '.' } else if v > 0.5 { '#' } else { '+' })
    }
    println(row.to_string())
  }
}
```

Output:

```text
........................
............+#..........
..........+++#..........
.........++++##.........
.........+++###.........
........++++###.........
.........+++###.........
...........++##.........
........................
........................
```

The cube occupies the middle of the image. `#` marks the brightly lit face and `+` the dimmer ones. The frontend only computed triangles and a depth-tested scalar image; the characters are this program's own backend. The [TUI backend](backend/tui.md) does the same job properly, with aspect correction and a shade ramp.

## Everyday tasks

### Compose a scene

A scene is a list of objects, each a mesh with a model transform, lit by one directional light. Meshes can be shared between objects:

```moonbit
fn two_cubes() -> @frontend.Scene {
  let scene = @frontend.Scene::new(
    @frontend.Light::directional(@core.vec3(0.3, 1.0, -0.5)),
  )
  let cube = @core.cube_mesh(0.5)
  scene.add_object(
    @frontend.SceneObject::new(cube, @core.Transform3::translation(-1.0, 0.0, 0.0)),
  )
  scene.add_object(
    @frontend.SceneObject::new(
      cube,
      @core.Transform3::rotation(0.0, 0.8, 0.0).compose(
        @core.Transform3::translation(1.0, 0.0, 1.0),
      ),
    ),
  )
  scene
}

test "compose a scene" {
  let scene = two_cubes()
  inspect(scene.objects.length(), content="2")
}
```

### Render through a physical camera

`RenderView::scientific` derives the projection from a sensor and a lens, so the image keeps its framing when the viewport size changes:

```moonbit
test "physical camera" {
  let camera = @view.ScientificCamera::new(
    @view.Camera3::default(6.0),
    @view.SensorSpec::full_frame(),
    @view.LensSpec::new(35.0),
    @view.WorldUnit::unitless(),
  )
  let small = @frontend.RenderView::scientific(camera, @view.Viewport::new(80, 40))
  let large = @frontend.RenderView::scientific(camera, @view.Viewport::new(160, 80))
  inspect(large.projection.scale / small.projection.scale, content="2")
  let list = @frontend.build_draw_list(two_cubes(), small)
  inspect(list.triangles.length() > 0, content="true")
}
```

### See a shadow in the numbers

A thin slab lit from straight above is fully lit on its own; put a cube over it and the faces underneath lose up to 65% of their brightness. Compare the brightest triangle of the slab in both scenes:

```moonbit
fn slab_scene(with_cube : Bool) -> @frontend.Scene {
  let scene = @frontend.Scene::new(
    @frontend.Light::directional(@core.vec3(0.0, 1.0, 0.0)),
  )
  scene.add_object(
    @frontend.SceneObject::new(
      @core.cube_mesh(1.0),
      @core.Transform3::scale(0.6, 0.05, 0.6).compose(
        @core.Transform3::translation(0.0, -1.0, 0.0),
      ),
    ),
  )
  if with_cube {
    scene.add_object(
      @frontend.SceneObject::new(
        @core.cube_mesh(1.0),
        @core.Transform3::translation(0.0, 1.5, 0.0),
      ),
    )
  }
  scene
}

fn top_intensity(scene : @frontend.Scene) -> Double {
  let view = @frontend.RenderView::perspective(
    @view.Camera3::look_at(
      @core.vec3(0.0, 4.0, -4.0),
      @core.vec3(0.0, -1.0, 0.0),
      @core.vec3(0.0, 1.0, 0.0),
    ),
    @view.PerspectiveProjection::new(@view.Viewport::new(80, 40), 40.0),
  )
  let list = @frontend.build_draw_list(scene, view)
  // the slab is the first object, so its triangles come first
  let mut best = 0.0
  for i in 0..<4 {
    if list.triangles[i].intensity > best {
      best = list.triangles[i].intensity
    }
  }
  best
}

test "shadow" {
  let round2 = fn(x : Double) { (x * 100.0).round() / 100.0 }
  inspect(round2(top_intensity(slab_scene(false))), content="1")
  inspect(round2(top_intensity(slab_scene(true))), content="0.35")
}
```

The 0.35 is the ambient share: a face in full shadow keeps 35% of its Lambert brightness.

### Read depths from the luma buffer

`draw_list_to_luma` rasterizes a draw list into a `LumaBuffer`. Each pixel stores the intensity and the camera-space depth of the nearest surface; empty pixels have depth `LUMA_FAR_DEPTH`:

```moonbit
test "depth buffer" {
  let scene = @frontend.Scene::single(
    @core.cube_mesh(1.0),
    @core.Transform3::identity(),
    @frontend.Light::default(),
  )
  let view = @frontend.RenderView::perspective(
    @view.Camera3::default(4.0),
    @view.PerspectiveProjection::new(@view.Viewport::new(40, 40), 20.0),
  )
  let luma = @frontend.draw_list_to_luma(@frontend.build_draw_list(scene, view), 40, 40)
  // the front face of the cube is 3 units from the eye
  inspect(luma.depth_at(20, 20), content="3")
  inspect(luma.depth_at(0, 0) == @frontend.LUMA_FAR_DEPTH, content="true")
}
```

### Make a long exposure

Average several renders taken at successive times. Moving edges blur; static parts stay sharp:

```moonbit
fn spinning_cube_luma(angle : Double) -> @frontend.LumaBuffer {
  let scene = @frontend.Scene::single(
    @core.cube_mesh(1.0),
    @core.Transform3::rotation(0.3, angle, 0.0),
    @frontend.Light::default(),
  )
  let view = @frontend.RenderView::perspective(
    @view.Camera3::default(4.0),
    @view.PerspectiveProjection::new(@view.Viewport::new(40, 20), 16.0),
  )
  @frontend.draw_list_to_luma(@frontend.build_draw_list(scene, view), 40, 20)
}

test "long exposure" {
  let samples = 8
  let exposure = @frontend.LumaBuffer::new(40, 20)
  for k in 0..<samples {
    exposure.add_weighted_sample(
      spinning_cube_luma(k.to_double() * 0.05),
      1.0 / samples.to_double(),
    )
  }
  let sharp = spinning_cube_luma(0.35)
  let mut changed = 0
  for i in 0..<sharp.values.length() {
    if (sharp.values[i] - exposure.values[i]).abs() > 0.05 {
      changed += 1
    }
  }
  inspect(changed > 0, content="true")
}
```

### Animate with a timeline

`Timeline` turns a duration and a frame rate into frame times; `ScalarTrack` interpolates keyframed values at those times:

```moonbit
test "timeline" {
  let timeline = @frontend.Timeline::new(2.0, 2)
  let distance = @frontend.ScalarTrack::new([
    @frontend.ScalarKeyframe::new(0.0, 4.0),
    @frontend.ScalarKeyframe::new(2.0, 8.0),
  ])
  let lines = []
  for k in 0..<timeline.frame_count() {
    let s = timeline.sample(k)
    lines.push("frame \{k}: t=\{s.time_seconds} distance=\{distance.sample(s.time_seconds)}")
  }
  inspect(
    lines.join("\n"),
    content=(
      #|frame 0: t=0 distance=4
      #|frame 1: t=0.5 distance=5
      #|frame 2: t=1 distance=6
      #|frame 3: t=1.5 distance=7
    ),
  )
}
```

The last frame starts at $t = 1.5$; frame times are $k/\mathit{fps}$ for $k < \lceil D \cdot \mathit{fps} \rceil$, so the end time $D$ itself is not sampled.

## Going further

### Write your own backend

A backend is a function from `DrawList` to output. This one emits SVG polygons, sorted far to near so that later polygons cover earlier ones:

```moonbit
fn to_svg_polygons(list : @frontend.DrawList) -> Array[String] {
  let sorted = list.triangles.copy()
  sorted.sort_by(fn(a, b) {
    let da = a.p0.depth + a.p1.depth + a.p2.depth
    let db = b.p0.depth + b.p1.depth + b.p2.depth
    db.compare(da)
  })
  sorted.map(fn(t) {
    let grey = (t.intensity * 255.0).round().to_int()
    "<polygon points=\"\{t.p0.x},\{t.p0.y} \{t.p1.x},\{t.p1.y} \{t.p2.x},\{t.p2.y}\" fill=\"rgb(\{grey},\{grey},\{grey})\"/>"
  })
}

test "own backend" {
  let list = @frontend.DrawList::new()
  list.push_triangle(
    @frontend.DrawTriangle::new(
      @view.ProjectedVertex::new(0.0, 0.0, 1.0),
      @view.ProjectedVertex::new(4.0, 0.0, 1.0),
      @view.ProjectedVertex::new(0.0, 4.0, 1.0),
      1.0,
    ),
  )
  inspect(
    to_svg_polygons(list)[0],
    content="<polygon points=\"0,0 4,0 0,4\" fill=\"rgb(255,255,255)\"/>",
  )
}
```

This is, in essence, the [GSAP SVG backend](backend/gsap.md). Painter's ordering is only approximate when triangles intersect; a depth buffer such as `LumaBuffer` is exact.

### Align exposure samples with optical flow

`estimate_optical_flow(previous, current, R, P)` finds, for each pixel of `current`, the displacement into `previous` within $\pm R$ pixels whose $(2P+1)^2$ patch matches best. `align_with_flow` then warps `previous` onto `current`, and the warped samples can be accumulated as above to reduce ghosting. The cost grows with $(2R+1)^2 (2P+1)^2$ per pixel, so keep both radii small (the TUI demo uses $R = 4$, $P = 1$).

### Performance

`build_draw_list` is linear in the scene size, but it rasterizes the whole scene once more into the 128 × 128 shadow map on every call. Rasterization cost is proportional to the bounding-box area of each triangle and is not clipped to the buffer, so keep geometry inside the view.

## Common pitfalls

- **Geometry behind the eye.** Nothing is clipped. An object that reaches the camera position produces vertices with $z \le 0$, which project to infinity or mirror across the screen.
- **Light direction.** `Light::directional` takes the direction *towards* the light. A light "shining downwards" is `vec3(0.0, 1.0, 0.0)`.
- **Two sizes.** The projection's viewport and the size you pass to `draw_list_to_luma` (or a backend config) are independent. Use the same size, or the image is cropped or off-centre.
- **Value versus coverage.** A covered pixel can have luma `0.0` (a face turned away from the light). Test `depth_at(x, y) < LUMA_FAR_DEPTH` to know whether a surface is there.
- **`ExposureSettings::auto` returns one sample.** It clamps the shutter to the frame interval first. Choose the number of samples yourself for a visible long exposure.
- **Unsorted keyframes.** `ScalarTrack` assumes increasing times and does not sort.
- **Flow in flat regions.** Where every displacement fits equally well, `estimate_optical_flow` returns $(-R, -R)$, not $(0, 0)$.

## Next steps

- The [frontend API](../api/frontend.md) documents every type and function.
- The [frontend design](../design/frontend.md) derives the shadow test, the rasterization rule and the depth-buffer invariant.
- Pick a backend: [TUI](backend/tui.md), [Canvas](backend/canvas.md) or [GSAP SVG](backend/gsap.md).
