struct Camera {
  distance : Double
}

struct Projection {
  width : Int
  height : Int
  scale : Double
}

struct ProjectedVertex {
  x : Double
  y : Double
  depth : Double
}

fn Camera::position(self : Camera) -> @la.Vector[Double] {
  vec3(0.0, 0.0, -self.distance)
}

fn project_vertex(
  vertex : @la.Vector[Double],
  camera : Camera,
  projection : Projection,
) -> ProjectedVertex {
  let depth = vertex[2] + camera.distance
  let scale = projection.scale / depth
  {
    x: vertex[0] * scale + projection.width.to_double() / 2.0,
    y: (-vertex[1]) * scale + projection.height.to_double() / 2.0,
    depth,
  }
}

fn project_vertices(
  vertices : Array[@la.Vector[Double]],
  camera : Camera,
  projection : Projection,
) -> Array[ProjectedVertex] {
  vertices.map(fn(vertex) { project_vertex(vertex, camera, projection) })
}

fn apply_terminal_y_scale(
  point : ProjectedVertex,
  height : Int,
  terminal_y_scale : Double,
) -> ProjectedVertex {
  let center_y = height.to_double() / 2.0
  { x: point.x, y: center_y + (point.y - center_y) * terminal_y_scale, depth: point.depth }
}
