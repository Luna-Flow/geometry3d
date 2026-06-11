struct QuadFace {
  a : Int
  b : Int
  c : Int
  d : Int
}

struct TriangleFace {
  a : Int
  b : Int
  c : Int
}

struct Mesh {
  vertices : Array[@la.Vector[Double]]
  faces : Array[QuadFace]
}

fn cube_mesh(size : Double) -> Mesh {
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

fn sphere_ring_index(ring : Int, segment : Int, segments : Int) -> Int {
  1 + (ring - 1) * segments + segment % segments
}

fn sphere_mesh(radius : Double, rings : Int, segments : Int) -> Mesh {
  let safe_rings = if rings < 3 { 3 } else { rings }
  let safe_segments = if segments < 3 { 3 } else { segments }
  let vertices : Array[@la.Vector[Double]] = []
  let faces : Array[QuadFace] = []

  vertices.push(vec3(0.0, radius, 0.0))
  for ring in 1..<safe_rings {
    let phi = @math.PI / 2.0 - @math.PI * ring.to_double() / safe_rings.to_double()
    let y = radius * @math.sin(phi)
    let ring_radius = radius * @math.cos(phi)
    for segment in 0..<safe_segments {
      let theta = 2.0 * @math.PI * segment.to_double() / safe_segments.to_double()
      vertices.push(vec3(ring_radius * @math.cos(theta), y, ring_radius * @math.sin(theta)))
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

pub fn face_vertices(mesh : Mesh, face : QuadFace) -> Array[@la.Vector[Double]] {
  [
    mesh.vertices[face.a],
    mesh.vertices[face.b],
    mesh.vertices[face.c],
    mesh.vertices[face.d],
  ]
}

fn triangulate_quad(face : QuadFace) -> Array[TriangleFace] {
  [{ a: face.a, b: face.b, c: face.c }, { a: face.a, b: face.c, c: face.d }]
}
