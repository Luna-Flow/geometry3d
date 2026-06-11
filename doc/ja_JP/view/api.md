# View API

view package は camera と projection math を扱います。terminal y-scale は含みません。

## Types

- `Camera3`: `eye`、`target`、`up`。
- `Viewport`: output width / height。
- `SensorSpec`: millimeter 単位の sensor width / height。
- `LensSpec`: millimeter 単位の focal length と FOV helpers。
- `WorldUnit`: world-space 1 unit が表す meters。
- `ScientificCamera`: `Camera3` + sensor + lens + world unit。
- `PerspectiveProjection`: perspective projection。
- `OrthographicProjection`: orthographic projection。
- `ProjectedVertex`: projected `x`、`y`、`depth`。

## API

- `Camera3::look_at(eye, target, up)`
- `Camera3::default(distance)`
- `Camera3::view_transform()`
- `world_to_camera_point` / `world_to_camera_direction`
- `SensorSpec::apsc` / `SensorSpec::full_frame` / `SensorSpec::medium_format`
- `SensorSpec::custom`
- `LensSpec::new`
- `horizontal_fov` / `vertical_fov` / `diagonal_fov`
- `WorldUnit::new`
- `ScientificCamera::auto`
- `ScientificCamera::to_perspective_projection`
- `PerspectiveProjection::project_point`
- `OrthographicProjection::project_point`
- `interpolate_perspective_depth`: barycentric weights から reciprocal-depth interpolation を行い、無効 depth では linear fallback を使います。
