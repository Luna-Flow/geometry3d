struct Transform3 {
  matrix : @la.Matrix[Double]
}

fn rotation_x(angle : Double) -> @la.Matrix[Double] {
  let s = @math.sin(angle)
  let c = @math.cos(angle)
  @la.Matrix::from_2d_array([
    [1.0, 0.0, 0.0],
    [0.0, c, -s],
    [0.0, s, c],
  ])
}

fn rotation_y(angle : Double) -> @la.Matrix[Double] {
  let s = @math.sin(angle)
  let c = @math.cos(angle)
  @la.Matrix::from_2d_array([
    [c, 0.0, s],
    [0.0, 1.0, 0.0],
    [-s, 0.0, c],
  ])
}

fn rotation_z(angle : Double) -> @la.Matrix[Double] {
  let s = @math.sin(angle)
  let c = @math.cos(angle)
  @la.Matrix::from_2d_array([
    [c, -s, 0.0],
    [s, c, 0.0],
    [0.0, 0.0, 1.0],
  ])
}

fn rotation_matrix(
  angle_x : Double,
  angle_y : Double,
  angle_z : Double,
) -> @la.Matrix[Double] {
  rotation_z(angle_z) * rotation_y(angle_y) * rotation_x(angle_x)
}

fn Transform3::rotation(
  angle_x : Double,
  angle_y : Double,
  angle_z : Double,
) -> Transform3 {
  { matrix: rotation_matrix(angle_x, angle_y, angle_z) }
}

fn Transform3::apply_vertex(self : Transform3, vertex : @la.Vector[Double]) -> @la.Vector[Double] {
  self.matrix.mul_vec(vertex)
}

fn Transform3::apply_mesh(self : Transform3, mesh : Mesh) -> Mesh {
  {
    vertices: mesh.vertices.map(fn(vertex) { self.apply_vertex(vertex) }),
    faces: mesh.faces,
  }
}
