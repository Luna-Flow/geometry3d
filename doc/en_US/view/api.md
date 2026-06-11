# View API

The view package owns camera and projection math. It is backend neutral and does
not apply terminal y-scale correction.

## Types

- `Camera3`: `eye`, `target`, and `up` vectors.
- `Viewport`: output width and height.
- `SensorSpec`: physical sensor width and height in millimeters.
- `LensSpec`: focal length in millimeters plus FOV helpers.
- `WorldUnit`: meters represented by one world-space unit.
- `ScientificCamera`: `Camera3` plus sensor, lens, and world-unit metadata.
- `PerspectiveProjection`: viewport plus perspective scale.
- `OrthographicProjection`: viewport plus orthographic scale.
- `ProjectedVertex`: projected `x`, `y`, and `depth`.

## Camera

- `Camera3::look_at(eye, target, up)`: builds a camera description.
- `Camera3::default(distance)`: camera at `(0, 0, -distance)` looking at origin.
- `Camera3::view_transform()`: world-to-camera 4x4 transform.
- `world_to_camera_point` / `world_to_camera_direction`: apply the view transform.

## Scientific Camera

- `SensorSpec::apsc()` / `full_frame()` / `medium_format()`: common sensor presets.
- `SensorSpec::custom(width_mm, height_mm)`: custom positive sensor size.
- `LensSpec::new(focal_length_mm)`: focal length in millimeters.
- `horizontal_fov` / `vertical_fov` / `diagonal_fov`: FOV helpers using
  `2 * atan(sensor_dimension / (2 * focal_length))`.
- `WorldUnit::new(meters_per_unit)`: explicit world-unit scale.
- `ScientificCamera::auto(viewport)`: full-frame, 50mm default camera.
- `ScientificCamera::to_perspective_projection(viewport)`: derives the current
  single-axis `PerspectiveProjection.scale` from vertical sensor scale.

## Projection

- `PerspectiveProjection::project_point(point)`: perspective screen projection.
- `OrthographicProjection::project_point(point)`: orthographic screen projection.
- `project_perspective_vertices` / `project_orthographic_vertices`: batch helpers.
