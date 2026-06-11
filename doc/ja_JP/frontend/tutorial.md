# Frontend Tutorial

```moonbit
let scene = @frontend.Scene::single(
  @core.cube_mesh(1.0),
  @core.Transform3::rotation(0.2, 0.3, 0.0),
  @frontend.Light::default(),
)
let render_view = @frontend.RenderView::perspective(
  @view.Camera3::default(4.5),
  @view.PerspectiveProjection::new(@view.Viewport::new(80, 32), 24.0),
)
let draw_list = @frontend.build_draw_list(scene, render_view)
```

backend は `draw_list` を消費し、rasterize または serialize の方法を決めます。
