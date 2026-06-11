# View Tutorial

```moonbit
let camera = @view.Camera3::default(4.5)
let viewport = @view.Viewport::new(80, 32)
let projection = @view.PerspectiveProjection::new(viewport, 24.0)
let camera_point = camera.world_to_camera_point(@core.vec3(0.0, 1.0, 0.0))
let projected = projection.project_point(camera_point)
```

需要不随 depth 缩放时，使用 `OrthographicProjection`。
rasterizer 应将 triangle 的重心权重传给 `interpolate_perspective_depth`，而不是线性插值透视深度。
