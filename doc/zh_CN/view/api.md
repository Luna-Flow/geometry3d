# View API

view package 负责 camera 和 projection 数学，不处理终端 y-scale。

## 类型

- `Camera3`：`eye`、`target`、`up`。
- `Viewport`：输出宽高。
- `SensorSpec`：以毫米表示的传感器宽高。
- `LensSpec`：以毫米表示的焦距，以及 FOV helper。
- `WorldUnit`：一个世界单位对应的米数。
- `ScientificCamera`：`Camera3` + sensor + lens + world unit。
- `PerspectiveProjection`：透视投影。
- `OrthographicProjection`：正交投影。
- `ProjectedVertex`：投影后的 `x`、`y`、`depth`。

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
