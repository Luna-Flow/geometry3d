# view tutorial

This tutorial shows you how to put a camera in a scene and find where points land on the screen: aiming a look-at camera, projecting with perspective or orthographic projection, deriving the projection from a real lens and sensor, animating a dolly zoom, and computing the correct depth inside a projected triangle.

## Quick start

Install the module as in the [core tutorial](core.md) and import `view` next to `core`:

```moonbit nocheck
import {
  "moonbitlang/core/math",
  "Luna-Flow/geometry3d/core",
  "Luna-Flow/geometry3d/view",
  "Luna-Flow/linear-algebra/mutable" @la,
}
```

Project two opposite corners of a cube into an 80 × 40 viewport:

```moonbit
fn main {
  let camera = @view.Camera3::default(3.0)
  let viewport = @view.Viewport::new(80, 40)
  let projection = @view.PerspectiveProjection::new(viewport, 40.0)
  let cube = @core.cube_mesh(1.0)
  for i in [0, 6] {
    let p = projection.project_point(
      camera.world_to_camera_point(cube.vertices[i]),
    )
    println("vertex \{i}: x=\{p.x} y=\{p.y} depth=\{p.depth}")
  }
}
```

Output:

```text
vertex 0: x=20 y=40 depth=2
vertex 6: x=50 y=10 depth=4
```

The camera stands at $z = -3$ looking at the origin. Vertex 0, the near lower-left corner, is two units away; vertex 6, the far upper-right corner, is four units away and therefore closer to the centre $(40, 20)$ of the screen. Screen $y$ grows downwards.

## Everyday tasks

### Aim the camera

`Camera3::look_at` takes the eye, the point to look at and an approximate up direction. The derived frame is orthonormal even if `up` is not perpendicular to the view:

```moonbit
test "aim the camera" {
  let camera = @view.Camera3::look_at(
    @core.vec3(5.0, 5.0, 0.0),
    @core.vec3(0.0, 0.0, 0.0),
    @core.vec3(0.0, 1.0, 0.0),
  )
  let f = camera.forward()
  let u = camera.true_up()
  inspect(f.dot(u).abs() < 1.0e-12, content="true")
  // the target lies straight ahead, sqrt(50) units away
  let t = camera.world_to_camera_point(@core.vec3(0.0, 0.0, 0.0))
  inspect(t[0].abs() < 1.0e-12 && t[1].abs() < 1.0e-12, content="true")
  inspect((t[2] - 50.0.sqrt()).abs() < 1.0e-12, content="true")
}
```

### Compare perspective and orthographic projection

Under perspective, equal sizes shrink with distance; under orthographic projection they do not:

```moonbit
test "perspective versus orthographic" {
  let viewport = @view.Viewport::new(100, 100)
  let persp = @view.PerspectiveProjection::new(viewport, 100.0)
  let ortho = @view.OrthographicProjection::new(viewport, 10.0)
  let width_at = fn(z : Double, project : (@la.Vector[Double]) -> @view.ProjectedVertex) {
    project(@core.vec3(1.0, 0.0, z)).x - project(@core.vec3(-1.0, 0.0, z)).x
  }
  inspect(width_at(2.0, fn(p) { persp.project_point(p) }), content="100")
  inspect(width_at(4.0, fn(p) { persp.project_point(p) }), content="50")
  inspect(width_at(2.0, fn(p) { ortho.project_point(p) }), content="20")
  inspect(width_at(4.0, fn(p) { ortho.project_point(p) }), content="20")
}
```

### Derive the projection from a lens

Rather than guessing a scale, describe the camera physically. The projection scale is $H f / h$, so the vertical angle of view fills the viewport height:

```moonbit
fn degrees(radians : Double) -> Double {
  (radians * 180.0 / @math.PI * 10.0).round() / 10.0
}

test "lens and sensor" {
  let sensor = @view.SensorSpec::full_frame()
  for mm in [24.0, 50.0, 200.0] {
    let lens = @view.LensSpec::new(mm)
    println("\{mm} mm: \{degrees(lens.horizontal_fov(sensor))} x \{degrees(lens.vertical_fov(sensor))} degrees")
  }
  let camera = @view.ScientificCamera::new(
    @view.Camera3::default(5.0),
    sensor,
    @view.LensSpec::new(24.0),
    @view.WorldUnit::unitless(),
  )
  let viewport = @view.Viewport::new(640, 480)
  let projection = camera.to_perspective_projection(viewport)
  inspect(projection.scale, content="480")
}
```

Printed:

```text
24 mm: 73.7 x 53.1 degrees
50 mm: 39.6 x 27 degrees
200 mm: 10.3 x 6.9 degrees
```

### Animate a dolly zoom

Move the camera back and lengthen the lens in proportion, $f = f_0\,d/d_0$. An object at the target keeps its size on screen; anything behind it grows:

```moonbit
fn projected_height(distance : Double, focal_mm : Double, object_z : Double) -> Double {
  let camera = @view.ScientificCamera::new(
    @view.Camera3::default(distance),
    @view.SensorSpec::full_frame(),
    @view.LensSpec::new(focal_mm),
    @view.WorldUnit::unitless(),
  )
  let viewport = @view.Viewport::new(640, 480)
  let projection = camera.to_perspective_projection(viewport)
  let top = projection.project_point(
    camera.camera.world_to_camera_point(@core.vec3(0.0, 1.0, object_z)),
  )
  let bottom = projection.project_point(
    camera.camera.world_to_camera_point(@core.vec3(0.0, -1.0, object_z)),
  )
  bottom.y - top.y
}

test "dolly zoom" {
  let (d0, f0) = (4.0, 24.0)
  for d in [4.0, 8.0] {
    let f = f0 * d / d0
    let subject = projected_height(d, f, 0.0).round()
    let background = projected_height(d, f, 6.0).round()
    println("d=\{d} f=\{f}: subject \{subject} px, background \{background} px")
  }
}
```

Printed:

```text
d=4 f=24: subject 240 px, background 96 px
d=8 f=48: subject 240 px, background 137 px
```

### Find the depth under a pixel

A rasterizer that knows a pixel's barycentric coordinates in a projected triangle gets the depth of the 3D surface there from `interpolate_perspective_depth`. It interpolates $1/z$, which is what projection preserves:

```moonbit
test "depth under a pixel" {
  let viewport = @view.Viewport::new(100, 100)
  let projection = @view.PerspectiveProjection::new(viewport, 50.0)
  // a floor triangle receding from depth 2 to depth 6
  let a = projection.project_point(@core.vec3(-1.0, -1.0, 2.0))
  let b = projection.project_point(@core.vec3(1.0, -1.0, 2.0))
  let c = projection.project_point(@core.vec3(0.0, -1.0, 6.0))
  let z = @view.interpolate_perspective_depth(a, b, c, 0.25, 0.25, 0.5)
  inspect(z, content="3")
  // linear interpolation would claim 4
  inspect(0.25 * a.depth + 0.25 * b.depth + 0.5 * c.depth, content="4")
}
```

## Going further

### Hand the camera to the frontend

The `frontend` package bundles a `Camera3` and a `PerspectiveProjection` into a `RenderView`. `RenderView::scientific(camera, viewport)` builds one from a `ScientificCamera`, which is what the demos use; see the [frontend tutorial](frontend.md).

### Mind the aspect ratio

The scale ties the sensor height to the viewport height. If the viewport's aspect ratio differs from the sensor's, the horizontal field shown differs from `horizontal_fov`. For a full-frame sensor (3:2) the horizontal field matches exactly on a 3:2 viewport such as 720 × 480. In a terminal, the TUI backend squeezes $y$ by `terminal_y_scale`, so the vertical field of view covers the middle half of the rows; see the [TUI backend design](../design/backend/tui.md).

### Work in physical units

`WorldUnit` lets you state what one scene unit means. It does not change the picture (the projection depends only on the ratio of focal length to sensor height), but `focal_length_world_units` and `sensor_height_world_units` express the optics in scene units, for example to place a near plane of your own at the focal distance.

## Common pitfalls

- **Points behind the camera.** Nothing is clipped. A vertex with $z \le 0$ in camera space projects to infinity or to a mirrored position. Keep the eye outside every object.
- **Up parallel to the view.** `look_at` with `up` parallel to `target - eye` (for example looking straight down with up $= +y$) yields a zero frame and an empty picture. Pick another up vector.
- **Handedness.** The camera follows the left-handed Direct3D convention: with the default camera, $+x$ is on the right, $+y$ up and $+z$ away from you. Scenes authored for right-handed systems appear mirrored.
- **Screen $y$ grows downwards.** A larger `y` in a `ProjectedVertex` means lower on the screen.
- **`Camera3::default` takes a distance.** It is an ordinary constructor, not the `Default` trait, and places the eye on the negative $z$ axis.
- **Repeated frame construction.** `world_to_camera_point` rebuilds the view matrix on every call. For many points, call `view_transform()` once and use `apply_point`.

## Next steps

- The [view API](../api/view.md) lists every type and function.
- The [view design](../design/view.md) derives the camera frame, the projection, the perspective-correct depth rule and the physical camera model.
- The [frontend tutorial](frontend.md) turns meshes and a camera into a draw list.
