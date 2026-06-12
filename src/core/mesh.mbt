///|
pub struct QuadFace {
  a : Int
  b : Int
  c : Int
  d : Int
}

///|
pub struct TriangleFace {
  a : Int
  b : Int
  c : Int
}

///|
pub struct Mesh {
  vertices : Array[@la.Vector[Double]]
  faces : Array[QuadFace]
}

///|
pub fn cube_mesh(size : Double) -> Mesh {
  let s = size
  {
    vertices: [
      vec3(-s, -s, -s),
      vec3(s, -s, -s),
      vec3(s, s, -s),
      vec3(-s, s, -s),
      vec3(-s, -s, s),
      vec3(s, -s, s),
      vec3(s, s, s),
      vec3(-s, s, s),
    ],
    faces: [
      { a: 0, b: 3, c: 2, d: 1 },
      { a: 4, b: 5, c: 6, d: 7 },
      { a: 0, b: 4, c: 7, d: 3 },
      { a: 1, b: 2, c: 6, d: 5 },
      { a: 0, b: 1, c: 5, d: 4 },
      { a: 3, b: 7, c: 6, d: 2 },
    ],
  }
}

///|
fn sphere_ring_index(ring : Int, segment : Int, segments : Int) -> Int {
  1 + (ring - 1) * segments + segment % segments
}

///|
pub fn sphere_mesh(radius : Double, rings : Int, segments : Int) -> Mesh {
  let safe_rings = if rings < 3 { 3 } else { rings }
  let safe_segments = if segments < 3 { 3 } else { segments }
  let vertices : Array[@la.Vector[Double]] = []
  let faces : Array[QuadFace] = []

  vertices.push(vec3(0.0, radius, 0.0))
  for ring in 1..<safe_rings {
    let phi = @math.PI / 2.0 -
      @math.PI * ring.to_double() / safe_rings.to_double()
    let y = radius * @math.sin(phi)
    let ring_radius = radius * @math.cos(phi)
    for segment in 0..<safe_segments {
      let theta = 2.0 *
        @math.PI *
        segment.to_double() /
        safe_segments.to_double()
      vertices.push(
        vec3(ring_radius * @math.cos(theta), y, ring_radius * @math.sin(theta)),
      )
    }
  }
  let bottom = vertices.length()
  vertices.push(vec3(0.0, -radius, 0.0))

  for segment in 0..<safe_segments {
    let next = (segment + 1) % safe_segments
    faces.push({
      a: 0,
      b: sphere_ring_index(1, next, safe_segments),
      c: sphere_ring_index(1, segment, safe_segments),
      d: 0,
    })
  }

  for ring in 1..<(safe_rings - 1) {
    for segment in 0..<safe_segments {
      let next = (segment + 1) % safe_segments
      faces.push({
        a: sphere_ring_index(ring, segment, safe_segments),
        b: sphere_ring_index(ring, next, safe_segments),
        c: sphere_ring_index(ring + 1, next, safe_segments),
        d: sphere_ring_index(ring + 1, segment, safe_segments),
      })
    }
  }

  for segment in 0..<safe_segments {
    let next = (segment + 1) % safe_segments
    faces.push({
      a: bottom,
      b: sphere_ring_index(safe_rings - 1, segment, safe_segments),
      c: sphere_ring_index(safe_rings - 1, next, safe_segments),
      d: bottom,
    })
  }

  { vertices, faces }
}

///|
pub fn cylinder_mesh(radius : Double, height : Double, segments : Int) -> Mesh {
  let safe_segments = if segments < 3 { 3 } else { segments }
  let half_h = height * 0.5
  let vertices : Array[@la.Vector[Double]] = []
  let faces : Array[QuadFace] = []

  for segment in 0..<safe_segments {
    let theta = 2.0 * @math.PI * segment.to_double() / safe_segments.to_double()
    let x = radius * @math.cos(theta)
    let z = radius * @math.sin(theta)
    vertices.push(vec3(x, -half_h, z))
    vertices.push(vec3(x, half_h, z))
  }
  let bottom_center = vertices.length()
  vertices.push(vec3(0.0, -half_h, 0.0))
  let top_center = vertices.length()
  vertices.push(vec3(0.0, half_h, 0.0))

  for segment in 0..<safe_segments {
    let next = (segment + 1) % safe_segments
    let b0 = segment * 2
    let t0 = b0 + 1
    let b1 = next * 2
    let t1 = b1 + 1
    faces.push({ a: b0, b: b1, c: t1, d: t0 })
    faces.push({ a: bottom_center, b: b1, c: b0, d: bottom_center })
    faces.push({ a: top_center, b: t0, c: t1, d: top_center })
  }

  { vertices, faces }
}

///|
pub fn cone_mesh(radius : Double, height : Double, segments : Int) -> Mesh {
  let safe_segments = if segments < 3 { 3 } else { segments }
  let half_h = height * 0.5
  let vertices : Array[@la.Vector[Double]] = []
  let faces : Array[QuadFace] = []

  for segment in 0..<safe_segments {
    let theta = 2.0 * @math.PI * segment.to_double() / safe_segments.to_double()
    vertices.push(
      vec3(radius * @math.cos(theta), -half_h, radius * @math.sin(theta)),
    )
  }
  let apex = vertices.length()
  vertices.push(vec3(0.0, half_h, 0.0))
  let center = vertices.length()
  vertices.push(vec3(0.0, -half_h, 0.0))

  for segment in 0..<safe_segments {
    let next = (segment + 1) % safe_segments
    faces.push({ a: apex, b: segment, c: next, d: apex })
    faces.push({ a: center, b: next, c: segment, d: center })
  }

  { vertices, faces }
}

///|
pub fn triangular_pyramid_mesh(radius : Double, height : Double) -> Mesh {
  let half_h = height * 0.5
  let vertices : Array[@la.Vector[Double]] = []
  for i in 0..<3 {
    let theta = 2.0 * @math.PI * i.to_double() / 3.0 + @math.PI / 6.0
    vertices.push(
      vec3(radius * @math.cos(theta), -half_h, radius * @math.sin(theta)),
    )
  }
  vertices.push(vec3(0.0, half_h, 0.0))
  {
    vertices,
    faces: [
      { a: 3, b: 0, c: 1, d: 3 },
      { a: 3, b: 1, c: 2, d: 3 },
      { a: 3, b: 2, c: 0, d: 3 },
      { a: 0, b: 2, c: 1, d: 0 },
    ],
  }
}

///|
fn torus_vertex_index(
  major_segment : Int,
  minor_segment : Int,
  minor_segments : Int,
) -> Int {
  major_segment * minor_segments + minor_segment
}

///|
pub fn torus_mesh(
  major_radius : Double,
  minor_radius : Double,
  major_segments : Int,
  minor_segments : Int,
) -> Mesh {
  let safe_major_radius = if major_radius <= 0.0 { 1.0 } else { major_radius }
  let safe_minor_radius = if minor_radius <= 0.0 { 0.25 } else { minor_radius }
  let safe_major_segments = if major_segments < 3 { 3 } else { major_segments }
  let safe_minor_segments = if minor_segments < 3 { 3 } else { minor_segments }
  let vertices : Array[@la.Vector[Double]] = []
  let faces : Array[QuadFace] = []

  for major in 0..<safe_major_segments {
    let u = 2.0 * @math.PI * major.to_double() / safe_major_segments.to_double()
    let cos_u = @math.cos(u)
    let sin_u = @math.sin(u)
    for minor in 0..<safe_minor_segments {
      let v = 2.0 *
        @math.PI *
        minor.to_double() /
        safe_minor_segments.to_double()
      let ring = safe_major_radius + safe_minor_radius * @math.cos(v)
      let y = safe_minor_radius * @math.sin(v)
      vertices.push(vec3(ring * cos_u, y, ring * sin_u))
    }
  }

  for major in 0..<safe_major_segments {
    let next_major = (major + 1) % safe_major_segments
    for minor in 0..<safe_minor_segments {
      let next_minor = (minor + 1) % safe_minor_segments
      faces.push({
        a: torus_vertex_index(major, minor, safe_minor_segments),
        b: torus_vertex_index(major, next_minor, safe_minor_segments),
        c: torus_vertex_index(next_major, next_minor, safe_minor_segments),
        d: torus_vertex_index(next_major, minor, safe_minor_segments),
      })
    }
  }

  { vertices, faces }
}

///|
pub fn face_vertices(mesh : Mesh, face : QuadFace) -> Array[@la.Vector[Double]] {
  [
    mesh.vertices[face.a],
    mesh.vertices[face.b],
    mesh.vertices[face.c],
    mesh.vertices[face.d],
  ]
}

///|
pub fn triangulate_quad(face : QuadFace) -> Array[TriangleFace] {
  [{ a: face.a, b: face.b, c: face.c }, { a: face.a, b: face.c, c: face.d }]
}
