pub struct Transform3 {
  matrix : @la.Matrix[Double]
}

pub fn identity_matrix4() -> @la.Matrix[Double] {
  @la.Matrix::from_2d_array([
    [1.0, 0.0, 0.0, 0.0],
    [0.0, 1.0, 0.0, 0.0],
    [0.0, 0.0, 1.0, 0.0],
    [0.0, 0.0, 0.0, 1.0],
  ])
}

pub fn translation_matrix(x : Double, y : Double, z : Double) -> @la.Matrix[Double] {
  @la.Matrix::from_2d_array([
    [1.0, 0.0, 0.0, x],
    [0.0, 1.0, 0.0, y],
    [0.0, 0.0, 1.0, z],
    [0.0, 0.0, 0.0, 1.0],
  ])
}

pub fn scale_matrix(x : Double, y : Double, z : Double) -> @la.Matrix[Double] {
  @la.Matrix::from_2d_array([
    [x, 0.0, 0.0, 0.0],
    [0.0, y, 0.0, 0.0],
    [0.0, 0.0, z, 0.0],
    [0.0, 0.0, 0.0, 1.0],
  ])
}

pub fn rotation_x(angle : Double) -> @la.Matrix[Double] {
  let s = @math.sin(angle)
  let c = @math.cos(angle)
  @la.Matrix::from_2d_array([
    [1.0, 0.0, 0.0, 0.0],
    [0.0, c, -s, 0.0],
    [0.0, s, c, 0.0],
    [0.0, 0.0, 0.0, 1.0],
  ])
}

pub fn rotation_y(angle : Double) -> @la.Matrix[Double] {
  let s = @math.sin(angle)
  let c = @math.cos(angle)
  @la.Matrix::from_2d_array([
    [c, 0.0, s, 0.0],
    [0.0, 1.0, 0.0, 0.0],
    [-s, 0.0, c, 0.0],
    [0.0, 0.0, 0.0, 1.0],
  ])
}

pub fn rotation_z(angle : Double) -> @la.Matrix[Double] {
  let s = @math.sin(angle)
  let c = @math.cos(angle)
  @la.Matrix::from_2d_array([
    [c, -s, 0.0, 0.0],
    [s, c, 0.0, 0.0],
    [0.0, 0.0, 1.0, 0.0],
    [0.0, 0.0, 0.0, 1.0],
  ])
}

pub fn rotation_matrix(
  angle_x : Double,
  angle_y : Double,
  angle_z : Double,
) -> @la.Matrix[Double] {
  rotation_z(angle_z) * rotation_y(angle_y) * rotation_x(angle_x)
}

pub fn Transform3::identity() -> Transform3 {
  { matrix: identity_matrix4() }
}

pub fn Transform3::from_matrix(matrix : @la.Matrix[Double]) -> Transform3 {
  { matrix: matrix }
}

pub fn Transform3::translation(x : Double, y : Double, z : Double) -> Transform3 {
  { matrix: translation_matrix(x, y, z) }
}

pub fn Transform3::scale(x : Double, y : Double, z : Double) -> Transform3 {
  { matrix: scale_matrix(x, y, z) }
}

pub fn Transform3::rotation(
  angle_x : Double,
  angle_y : Double,
  angle_z : Double,
) -> Transform3 {
  { matrix: rotation_matrix(angle_x, angle_y, angle_z) }
}

pub fn Transform3::rotation_euler(
  angle_x : Double,
  angle_y : Double,
  angle_z : Double,
) -> Transform3 {
  Transform3::rotation(angle_x, angle_y, angle_z)
}

pub fn Transform3::compose(self : Transform3, next : Transform3) -> Transform3 {
  { matrix: next.matrix * self.matrix }
}

pub fn Transform3::apply_point(self : Transform3, point : @la.Vector[Double]) -> @la.Vector[Double] {
  let out = self.matrix.mul_vec(vec4(point[0], point[1], point[2], 1.0))
  if out[3].abs() <= DEPTH_EPSILON {
    vec3(out[0], out[1], out[2])
  } else {
    vec3(out[0] / out[3], out[1] / out[3], out[2] / out[3])
  }
}

pub fn Transform3::apply_direction(
  self : Transform3,
  direction : @la.Vector[Double],
) -> @la.Vector[Double] {
  let out = self.matrix.mul_vec(vec4(direction[0], direction[1], direction[2], 0.0))
  vec3(out[0], out[1], out[2])
}

pub fn Transform3::apply_vertex(self : Transform3, vertex : @la.Vector[Double]) -> @la.Vector[Double] {
  self.apply_point(vertex)
}

pub fn Transform3::apply_mesh(self : Transform3, mesh : Mesh) -> Mesh {
  {
    vertices: mesh.vertices.map(fn(vertex) { self.apply_point(vertex) }),
    faces: mesh.faces,
  }
}
