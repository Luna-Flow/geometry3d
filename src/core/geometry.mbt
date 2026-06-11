pub fn face_center(vertices : Array[@la.Vector[Double]], face : QuadFace) -> @la.Vector[Double] {
  let sum = vertices[face.a] + vertices[face.b] + vertices[face.c] + vertices[face.d]
  sum.right_scale(0.25)
}

pub fn face_normal(vertices : Array[@la.Vector[Double]], face : QuadFace) -> @la.Vector[Double] {
  let ab = sub_vec(vertices[face.b], vertices[face.a])
  let ac = sub_vec(vertices[face.c], vertices[face.a])
  normalize_vec(cross_vec(ab, ac))
}

pub fn face_is_visible(
  vertices : Array[@la.Vector[Double]],
  face : QuadFace,
  camera_position : @la.Vector[Double],
) -> Bool {
  let normal = face_normal(vertices, face)
  let to_camera = sub_vec(camera_position, face_center(vertices, face))
  normal.dot(to_camera) > 0.0
}

pub fn face_intensity(
  vertices : Array[@la.Vector[Double]],
  face : QuadFace,
  light_direction : @la.Vector[Double],
) -> Double {
  let lit = face_normal(vertices, face).dot(light_direction)
  if lit < 0.0 { 0.0 } else { lit }
}
