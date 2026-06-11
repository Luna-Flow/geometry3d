# Frontend Tutorial

```moonbit
let scene = @frontend.Scene::single(
  @core.cube_mesh(1.0),
  @core.Transform3::rotation(0.2, 0.3, 0.0),
  @frontend.Light::default(),
)
let viewport = @view.Viewport::new(80, 32)
let camera = @view.Camera3::default(4.5)
let projection = @view.PerspectiveProjection::new(viewport, 24.0)
let render_view = @frontend.RenderView::perspective(camera, projection)
let draw_list = @frontend.build_draw_list(scene, render_view)
```

Backends consume `draw_list` and decide how to rasterize or serialize it.
`build_draw_list` also applies the scene's directional-light shadow map before
writing each triangle intensity.
