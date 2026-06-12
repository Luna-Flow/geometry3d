///|
pub struct ProjectedVertex {
  x : Double
  y : Double
  depth : Double
}

///|
pub struct PerspectiveProjection {
  viewport : Viewport
  scale : Double
}

///|
pub struct OrthographicProjection {
  viewport : Viewport
  scale : Double
}

///|
pub fn ProjectedVertex::new(
  x : Double,
  y : Double,
  depth : Double,
) -> ProjectedVertex {
  { x, y, depth }
}

///|
pub fn interpolate_perspective_depth(
  p0 : ProjectedVertex,
  p1 : ProjectedVertex,
  p2 : ProjectedVertex,
  b0 : Double,
  b1 : Double,
  b2 : Double,
) -> Double {
  if p0.depth <= @core.DEPTH_EPSILON ||
    p1.depth <= @core.DEPTH_EPSILON ||
    p2.depth <= @core.DEPTH_EPSILON {
    b0 * p0.depth + b1 * p1.depth + b2 * p2.depth
  } else {
    let inv_depth = b0 / p0.depth + b1 / p1.depth + b2 / p2.depth
    if inv_depth.abs() <= @core.DEPTH_EPSILON {
      b0 * p0.depth + b1 * p1.depth + b2 * p2.depth
    } else {
      1.0 / inv_depth
    }
  }
}

///|
pub fn PerspectiveProjection::new(
  viewport : Viewport,
  scale : Double,
) -> PerspectiveProjection {
  { viewport, scale }
}

///|
pub fn OrthographicProjection::new(
  viewport : Viewport,
  scale : Double,
) -> OrthographicProjection {
  { viewport, scale }
}

///|
pub fn PerspectiveProjection::project_point(
  self : PerspectiveProjection,
  camera_point : @la.Vector[Double],
) -> ProjectedVertex {
  let depth = camera_point[2]
  let scale = self.scale / depth
  {
    x: camera_point[0] * scale + self.viewport.width.to_double() / 2.0,
    y: -camera_point[1] * scale + self.viewport.height.to_double() / 2.0,
    depth,
  }
}

///|
pub fn OrthographicProjection::project_point(
  self : OrthographicProjection,
  camera_point : @la.Vector[Double],
) -> ProjectedVertex {
  {
    x: camera_point[0] * self.scale + self.viewport.width.to_double() / 2.0,
    y: -camera_point[1] * self.scale + self.viewport.height.to_double() / 2.0,
    depth: camera_point[2],
  }
}

///|
pub fn project_perspective_vertices(
  vertices : Array[@la.Vector[Double]],
  projection : PerspectiveProjection,
) -> Array[ProjectedVertex] {
  vertices.map(fn(vertex) { projection.project_point(vertex) })
}

///|
pub fn project_orthographic_vertices(
  vertices : Array[@la.Vector[Double]],
  projection : OrthographicProjection,
) -> Array[ProjectedVertex] {
  vertices.map(fn(vertex) { projection.project_point(vertex) })
}
