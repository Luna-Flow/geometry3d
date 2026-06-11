# View Tutorial

```moonbit
let camera = @view.Camera3::look_at(
  @core.vec3(0.0, 0.0, -4.5),
  @core.vec3(0.0, 0.0, 0.0),
  @core.vec3(0.0, 1.0, 0.0),
)
let viewport = @view.Viewport::new(80, 32)
let projection = @view.PerspectiveProjection::new(viewport, 24.0)
let camera_point = camera.world_to_camera_point(@core.vec3(0.0, 1.0, 0.0))
let projected = projection.project_point(camera_point)
```

Use `OrthographicProjection` when depth should not affect projected size.
