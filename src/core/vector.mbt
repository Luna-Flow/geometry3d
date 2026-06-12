///|
pub const DEPTH_EPSILON : Double = 1.0e-9

///|
pub fn vec3(x : Double, y : Double, z : Double) -> @la.Vector[Double] {
  @la.Vector::from_array([x, y, z])
}

///|
pub fn vec4(
  x : Double,
  y : Double,
  z : Double,
  w : Double,
) -> @la.Vector[Double] {
  @la.Vector::from_array([x, y, z, w])
}

///|
pub fn sub_vec(
  a : @la.Vector[Double],
  b : @la.Vector[Double],
) -> @la.Vector[Double] {
  vec3(a[0] - b[0], a[1] - b[1], a[2] - b[2])
}

///|
pub fn cross_vec(
  a : @la.Vector[Double],
  b : @la.Vector[Double],
) -> @la.Vector[Double] {
  vec3(
    a[1] * b[2] - a[2] * b[1],
    a[2] * b[0] - a[0] * b[2],
    a[0] * b[1] - a[1] * b[0],
  )
}

///|
pub fn vec_length(v : @la.Vector[Double]) -> Double {
  v.dot(v).sqrt()
}

///|
pub fn normalize_vec(v : @la.Vector[Double]) -> @la.Vector[Double] {
  let length = vec_length(v)
  if length <= DEPTH_EPSILON {
    vec3(0.0, 0.0, 0.0)
  } else {
    v.right_scale(1.0 / length)
  }
}

///|
pub fn min3(a : Double, b : Double, c : Double) -> Double {
  let ab = if a < b { a } else { b }
  if ab < c {
    ab
  } else {
    c
  }
}

///|
pub fn max3(a : Double, b : Double, c : Double) -> Double {
  let ab = if a > b { a } else { b }
  if ab > c {
    ab
  } else {
    c
  }
}
