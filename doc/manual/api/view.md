# view API

## Purpose

The package `Luna-Flow/geometry3d/view` takes points from world space to the screen. It contains the look-at camera, the perspective and orthographic projections into a viewport, the perspective-correct depth interpolation used by every rasterizer, and a physical camera model (sensor, lens, world unit) that derives the projection scale from a focal length. It does not rasterize and knows nothing about terminals or the DOM.

Coordinates follow one convention throughout. In camera space $x$ points right, $y$ up and $z$ forward, so visible points have $z > 0$. On the screen $x$ grows to the right and $y$ grows downwards, in pixels (or terminal cells) of the viewport. The [view design](../design/view.md) derives every formula on this page.

## Importing

```moonbit nocheck
import {
  "Luna-Flow/geometry3d/core",
  "Luna-Flow/geometry3d/view",
  "Luna-Flow/linear-algebra/mutable" @la,
}
```

## Camera

### `Camera3`

`Camera3` is a look-at camera: an eye position, a target point and an approximate up direction, all in world space.

```mbti
pub struct Camera3 {
  eye : @mutable.Vector[Double]
  target : @mutable.Vector[Double]
  up : @mutable.Vector[Double]
}
```

`up` need not be perpendicular to the viewing direction; the camera derives an orthonormal frame from it. It must not be parallel to `target - eye`.

### `Camera3::look_at`

`Camera3::look_at(eye, target, up)` builds a camera from its three vectors without validating them.

```mbti
pub fn Camera3::look_at(@mutable.Vector[Double], @mutable.Vector[Double], @mutable.Vector[Double]) -> Self
```

### `Camera3::default`

`Camera3::default(distance)` places the eye at $(0, 0, -\mathit{distance})$, looking at the origin with up $= +y$.

```mbti
pub fn Camera3::default(Double) -> Self
```

It is an ordinary constructor, not an implementation of the `Default` trait.

### `Camera3::forward`, `Camera3::right`, `Camera3::true_up`

These methods return the orthonormal camera frame.

```mbti
pub fn Camera3::forward(Self) -> @mutable.Vector[Double]
pub fn Camera3::right(Self) -> @mutable.Vector[Double]
pub fn Camera3::true_up(Self) -> @mutable.Vector[Double]
```

They are

$$
f = \operatorname{normalize}(\mathit{target} - \mathit{eye}),\qquad
r = \operatorname{normalize}(\mathit{up} \times f),\qquad
u = \operatorname{normalize}(f \times r).
$$

$r$, $u$, $f$ are pairwise perpendicular unit vectors with $r \times u = f$. If `up` is parallel to $f$, $r$ and $u$ are zero vectors and the camera is unusable.

### `Camera3::view_transform`

`camera.view_transform()` returns the world-to-camera transform, the rigid motion that moves the eye to the origin and the frame $(r, u, f)$ onto the axes $(x, y, z)$.

```mbti
pub fn Camera3::view_transform(Self) -> @core.Transform3
```

Its matrix has the rows $(r^\mathsf{T}, -r \cdot e)$, $(u^\mathsf{T}, -u \cdot e)$, $(f^\mathsf{T}, -f \cdot e)$ and $(0, 0, 0, 1)$, where $e$ is the eye.

### `Camera3::world_to_camera_point`, `Camera3::world_to_camera_direction`

These methods apply the view transform to a point or to a direction.

```mbti
pub fn Camera3::world_to_camera_point(Self, @mutable.Vector[Double]) -> @mutable.Vector[Double]
pub fn Camera3::world_to_camera_direction(Self, @mutable.Vector[Double]) -> @mutable.Vector[Double]
```

A point becomes $(r \cdot (p - e),\ u \cdot (p - e),\ f \cdot (p - e))$; a direction becomes $(r \cdot d,\ u \cdot d,\ f \cdot d)$. Each call rebuilds the view matrix, so keep the transform from `view_transform` when you map many points.

```moonbit
test "camera" {
  let camera = @view.Camera3::default(4.5)
  inspect(camera.forward()[2], content="1")
  inspect(camera.right()[0], content="1")
  inspect(camera.true_up()[1], content="1")
  let p = camera.world_to_camera_point(@core.vec3(1.0, 2.0, 0.0))
  inspect(p[0], content="1")
  inspect(p[1], content="2")
  inspect(p[2], content="4.5")
  let d = camera.world_to_camera_direction(@core.vec3(0.0, 0.0, 1.0))
  inspect(d[2], content="1")
}
```

## Viewport and projected vertices

### `Viewport`

`Viewport` is the size of the output in pixels or terminal cells.

```mbti
pub struct Viewport {
  width : Int
  height : Int
}
```

### `Viewport::new`

`Viewport::new(width, height)` builds a viewport without validation.

```mbti
pub fn Viewport::new(Int, Int) -> Self
```

### `ProjectedVertex`

`ProjectedVertex` is a vertex after projection: screen coordinates `x`, `y` in viewport units, and `depth`, the camera-space $z$ of the original point.

```mbti
pub struct ProjectedVertex {
  x : Double
  y : Double
  depth : Double
}
```

`depth` is a distance along the viewing direction, not a normalized device depth. Smaller is closer.

### `ProjectedVertex::new`

`ProjectedVertex::new(x, y, depth)` builds a projected vertex, for example to feed a rasterizer directly.

```mbti
pub fn ProjectedVertex::new(Double, Double, Double) -> Self
```

## Projections

### `PerspectiveProjection`

`PerspectiveProjection` is a pinhole projection into a viewport with scale $s$ in pixels per unit of $x/z$.

```mbti
pub struct PerspectiveProjection {
  viewport : Viewport
  scale : Double
}
```

### `PerspectiveProjection::new`

`PerspectiveProjection::new(viewport, scale)` builds the projection. Use `ScientificCamera::to_perspective_projection` to derive `scale` from a lens.

```mbti
pub fn PerspectiveProjection::new(Viewport, Double) -> Self
```

### `PerspectiveProjection::project_point`

`projection.project_point(p)` maps a camera-space point to the screen:

```mbti
pub fn PerspectiveProjection::project_point(Self, @mutable.Vector[Double]) -> ProjectedVertex
```

$$
x_s = \frac{W}{2} + s\,\frac{x}{z},\qquad
y_s = \frac{H}{2} - s\,\frac{y}{z},\qquad
\mathit{depth} = z ,
$$

where $W \times H$ is the viewport. The point must lie in front of the camera ($z > 0$). There is no near plane and no clipping: $z = 0$ produces infinities (or NaN for a coordinate that is also $0$) and $z < 0$ a point reflected through the centre of the viewport.

### `OrthographicProjection`

`OrthographicProjection` is a parallel projection into a viewport with scale $s$ in pixels per world unit.

```mbti
pub struct OrthographicProjection {
  viewport : Viewport
  scale : Double
}
```

### `OrthographicProjection::new`

`OrthographicProjection::new(viewport, scale)` builds the projection.

```mbti
pub fn OrthographicProjection::new(Viewport, Double) -> Self
```

### `OrthographicProjection::project_point`

`projection.project_point(p)` maps a camera-space point with $x_s = W/2 + s x$, $y_s = H/2 - s y$ and $\mathit{depth} = z$.

```mbti
pub fn OrthographicProjection::project_point(Self, @mutable.Vector[Double]) -> ProjectedVertex
```

### `project_perspective_vertices`, `project_orthographic_vertices`

These functions project every point of an array with the given projection.

```mbti
pub fn project_perspective_vertices(Array[@mutable.Vector[Double]], PerspectiveProjection) -> Array[ProjectedVertex]
pub fn project_orthographic_vertices(Array[@mutable.Vector[Double]], OrthographicProjection) -> Array[ProjectedVertex]
```

The output has the same length and order as the input, so face indices of a mesh remain valid.

```moonbit
test "projections" {
  let viewport = @view.Viewport::new(80, 40)
  let persp = @view.PerspectiveProjection::new(viewport, 20.0)
  let near = persp.project_point(@core.vec3(1.0, 1.0, 2.0))
  let far = persp.project_point(@core.vec3(1.0, 1.0, 4.0))
  inspect(near.x, content="50")
  inspect(near.y, content="10")
  inspect(far.x, content="45")
  inspect(far.depth, content="4")
  let ortho = @view.OrthographicProjection::new(viewport, 20.0)
  inspect(ortho.project_point(@core.vec3(1.0, 1.0, 4.0)).x, content="60")
  let all = @view.project_perspective_vertices(
    [@core.vec3(0.0, 0.0, 1.0), @core.vec3(0.0, 0.0, 2.0)],
    persp,
  )
  inspect(all.length(), content="2")
}
```

## Depth interpolation

### `interpolate_perspective_depth`

`interpolate_perspective_depth(p0, p1, p2, b0, b1, b2)` returns the depth at the screen point with barycentric coordinates $(b_0, b_1, b_2)$ in the projected triangle $p_0 p_1 p_2$.

```mbti
pub fn interpolate_perspective_depth(ProjectedVertex, ProjectedVertex, ProjectedVertex, Double, Double, Double) -> Double
```

The result is

$$
z = \left( \frac{b_0}{z_0} + \frac{b_1}{z_1} + \frac{b_2}{z_2} \right)^{-1},
$$

which is the exact camera-space depth of the corresponding point on the 3D triangle when the triangle was projected with `PerspectiveProjection`. If any $z_i \le$ `DEPTH_EPSILON`, or the sum is within `DEPTH_EPSILON` of zero, it falls back to the linear $b_0 z_0 + b_1 z_1 + b_2 z_2$. The barycentric coordinates should sum to 1.

```moonbit
test "perspective-correct depth" {
  let a = @view.ProjectedVertex::new(0.0, 0.0, 1.0)
  let b = @view.ProjectedVertex::new(10.0, 0.0, 3.0)
  let c = @view.ProjectedVertex::new(0.0, 10.0, 1.0)
  // halfway along the edge from a to b on the screen
  let z = @view.interpolate_perspective_depth(a, b, c, 0.5, 0.5, 0.0)
  inspect(z, content="1.5")
  // the linear average would have been 2.0
}
```

## Physical camera

### `SensorSpec`

`SensorSpec` is the size of a camera sensor in millimetres.

```mbti
pub struct SensorSpec {
  width_mm : Double
  height_mm : Double
}
```

### `SensorSpec::custom`

`SensorSpec::custom(width_mm, height_mm)` builds a sensor; a non-positive dimension is replaced by `1.0`.

```mbti
pub fn SensorSpec::custom(Double, Double) -> Self
```

### `SensorSpec::full_frame`, `SensorSpec::apsc`, `SensorSpec::medium_format`

These presets are 36 × 24 mm, 23.5 × 15.6 mm and 44 × 33 mm.

```mbti
pub fn SensorSpec::full_frame() -> Self
pub fn SensorSpec::apsc() -> Self
pub fn SensorSpec::medium_format() -> Self
```

### `SensorSpec::diagonal_mm`

`sensor.diagonal_mm()` returns $\sqrt{w^2 + h^2}$.

```mbti
pub fn SensorSpec::diagonal_mm(Self) -> Double
```

### `LensSpec`

`LensSpec` is a lens given by its focal length in millimetres.

```mbti
pub struct LensSpec {
  focal_length_mm : Double
}
```

### `LensSpec::new`, `LensSpec::normal_full_frame`

`LensSpec::new(f)` builds a lens, replacing a non-positive focal length by `1.0`; `LensSpec::normal_full_frame()` is the 50 mm lens.

```mbti
pub fn LensSpec::new(Double) -> Self
pub fn LensSpec::normal_full_frame() -> Self
```

### `LensSpec::horizontal_fov`, `LensSpec::vertical_fov`, `LensSpec::diagonal_fov`

These methods return the angle of view, in radians, across the sensor's width, height or diagonal.

```mbti
pub fn LensSpec::horizontal_fov(Self, SensorSpec) -> Double
pub fn LensSpec::vertical_fov(Self, SensorSpec) -> Double
pub fn LensSpec::diagonal_fov(Self, SensorSpec) -> Double
```

Each is $2 \arctan\!\big(d / (2 f)\big)$ for the sensor dimension $d$ and the focal length $f$.

### `WorldUnit`

`WorldUnit` states how many metres one world-space unit represents.

```mbti
pub struct WorldUnit {
  meters_per_unit : Double
}
```

### `WorldUnit::new`, `WorldUnit::unitless`

`WorldUnit::new(m)` builds the unit, replacing a non-positive value by `1.0`; `WorldUnit::unitless()` is one metre per unit.

```mbti
pub fn WorldUnit::new(Double) -> Self
pub fn WorldUnit::unitless() -> Self
```

### `WorldUnit::millimeters_per_unit`

`unit.millimeters_per_unit()` returns `meters_per_unit * 1000`.

```mbti
pub fn WorldUnit::millimeters_per_unit(Self) -> Double
```

### `ScientificCamera`

`ScientificCamera` bundles a `Camera3` with a sensor, a lens and a world unit.

```mbti
pub struct ScientificCamera {
  camera : Camera3
  sensor : SensorSpec
  lens : LensSpec
  world_unit : WorldUnit
}
```

### `ScientificCamera::new`

`ScientificCamera::new(camera, sensor, lens, world_unit)` builds the camera from its parts.

```mbti
pub fn ScientificCamera::new(Camera3, SensorSpec, LensSpec, WorldUnit) -> Self
```

### `ScientificCamera::auto`

`ScientificCamera::auto(viewport)` returns `Camera3::default(4.5)` with a full-frame sensor, a 50 mm lens and unitless world units.

```mbti
pub fn ScientificCamera::auto(Viewport) -> Self
```

The viewport argument is currently ignored.

### `ScientificCamera::with_camera`, `ScientificCamera::with_lens`

These methods return a copy with the camera or the lens replaced; they are the way to animate a dolly or a zoom.

```mbti
pub fn ScientificCamera::with_camera(Self, Camera3) -> Self
pub fn ScientificCamera::with_lens(Self, LensSpec) -> Self
```

### `ScientificCamera::projection_scale`

`camera.projection_scale(viewport)` returns the perspective scale $s = H f / h$, where $H$ is the viewport height, $f$ the focal length and $h$ the sensor height.

```mbti
pub fn ScientificCamera::projection_scale(Self, Viewport) -> Double
```

With this scale the vertical angle of view spans exactly the viewport height.

### `ScientificCamera::to_perspective_projection`

`camera.to_perspective_projection(viewport)` returns `PerspectiveProjection::new(viewport, camera.projection_scale(viewport))`.

```mbti
pub fn ScientificCamera::to_perspective_projection(Self, Viewport) -> PerspectiveProjection
```

### `ScientificCamera::focal_length_world_units`, `ScientificCamera::sensor_height_world_units`

These methods convert the focal length and the sensor height from millimetres into world units.

```mbti
pub fn ScientificCamera::focal_length_world_units(Self) -> Double
pub fn ScientificCamera::sensor_height_world_units(Self) -> Double
```

They are informational: the projection scale depends only on the ratio $f / h$, in which the unit cancels.

```moonbit
test "scientific camera" {
  let sensor = @view.SensorSpec::full_frame()
  let lens = @view.LensSpec::normal_full_frame()
  let degrees = lens.vertical_fov(sensor) * 180.0 / @math.PI
  inspect((degrees * 10.0).round() / 10.0, content="27")
  let camera = @view.ScientificCamera::auto(@view.Viewport::new(640, 480))
  inspect(camera.projection_scale(@view.Viewport::new(640, 480)), content="1000")
  let mm = @view.ScientificCamera::new(
    @view.Camera3::default(4500.0),
    sensor,
    lens,
    @view.WorldUnit::new(0.001),
  )
  inspect(mm.focal_length_world_units(), content="50")
  let tele = camera.with_lens(@view.LensSpec::new(100.0))
  inspect(tele.projection_scale(@view.Viewport::new(640, 480)), content="2000")
}
```
