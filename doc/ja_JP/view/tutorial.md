# View Tutorial

```moonbit
let camera = @view.Camera3::default(4.5)
let viewport = @view.Viewport::new(80, 32)
let projection = @view.PerspectiveProjection::new(viewport, 24.0)
let camera_point = camera.world_to_camera_point(@core.vec3(0.0, 1.0, 0.0))
let projected = projection.project_point(camera_point)
```

depth による size change が不要な場合は `OrthographicProjection` を使います。
