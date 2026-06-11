pub struct RenderView {
  camera : @view.Camera3
  projection : @view.PerspectiveProjection
}

pub fn RenderView::perspective(
  camera : @view.Camera3,
  projection : @view.PerspectiveProjection,
) -> RenderView {
  { camera, projection }
}

pub fn RenderView::scientific(
  camera : @view.ScientificCamera,
  viewport : @view.Viewport,
) -> RenderView {
  {
    camera: camera.camera,
    projection: camera.to_perspective_projection(viewport),
  }
}

pub fn build_draw_list(scene : Scene, render_view : RenderView) -> DrawList {
  let draw_list = DrawList::new()
  let camera_position = @core.vec3(0.0, 0.0, 0.0)
  let camera_light = render_view.camera.world_to_camera_direction(scene.light.direction)
  let light_direction = @core.normalize_vec(camera_light)

  for object in scene.objects {
    let world_mesh = object.transform.apply_mesh(object.mesh)
    let camera_vertices = world_mesh.vertices.map(fn(vertex) {
      render_view.camera.world_to_camera_point(vertex)
    })
    let projected = @view.project_perspective_vertices(camera_vertices, render_view.projection)

    for face in world_mesh.faces {
      if @core.face_is_visible(camera_vertices, face, camera_position) {
        let intensity = @core.face_intensity(camera_vertices, face, light_direction)
        for triangle in @core.triangulate_quad(face) {
          draw_list.push_triangle(DrawTriangle::new(
            projected[triangle.a],
            projected[triangle.b],
            projected[triangle.c],
            intensity,
          ))
        }
      }
    }
  }

  draw_list
}
