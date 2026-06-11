const DEPTH_EPSILON : Double = 1.0e-9

fn vec3(x : Double, y : Double, z : Double) -> @la.Vector[Double] {
  @la.Vector::from_array([x, y, z])
}

fn sub_vec(a : @la.Vector[Double], b : @la.Vector[Double]) -> @la.Vector[Double] {
  vec3(a[0] - b[0], a[1] - b[1], a[2] - b[2])
}

fn cross_vec(a : @la.Vector[Double], b : @la.Vector[Double]) -> @la.Vector[Double] {
  vec3(
    a[1] * b[2] - a[2] * b[1],
    a[2] * b[0] - a[0] * b[2],
    a[0] * b[1] - a[1] * b[0],
  )
}

fn vec_length(v : @la.Vector[Double]) -> Double {
  v.dot(v).sqrt()
}

fn normalize_vec(v : @la.Vector[Double]) -> @la.Vector[Double] {
  let length = vec_length(v)
  if length <= DEPTH_EPSILON {
    vec3(0.0, 0.0, 0.0)
  } else {
    v.right_scale(1.0 / length)
  }
}

fn min3(a : Double, b : Double, c : Double) -> Double {
  let ab = if a < b { a } else { b }
  if ab < c { ab } else { c }
}

fn max3(a : Double, b : Double, c : Double) -> Double {
  let ab = if a > b { a } else { b }
  if ab > c { ab } else { c }
}

fn face_center(vertices : Array[@la.Vector[Double]], face : QuadFace) -> @la.Vector[Double] {
  let sum = vertices[face.a] + vertices[face.b] + vertices[face.c] + vertices[face.d]
  sum.right_scale(0.25)
}

fn face_normal(vertices : Array[@la.Vector[Double]], face : QuadFace) -> @la.Vector[Double] {
  let ab = sub_vec(vertices[face.b], vertices[face.a])
  let ac = sub_vec(vertices[face.c], vertices[face.a])
  normalize_vec(cross_vec(ab, ac))
}

fn face_is_visible(
  vertices : Array[@la.Vector[Double]],
  face : QuadFace,
  camera_position : @la.Vector[Double],
) -> Bool {
  let normal = face_normal(vertices, face)
  let to_camera = sub_vec(camera_position, face_center(vertices, face))
  normal.dot(to_camera) > 0.0
}

fn face_intensity(
  vertices : Array[@la.Vector[Double]],
  face : QuadFace,
  light_direction : @la.Vector[Double],
) -> Double {
  let lit = face_normal(vertices, face).dot(light_direction)
  if lit < 0.0 { 0.0 } else { lit }
}
