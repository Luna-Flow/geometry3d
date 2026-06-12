///|
pub struct DrawTriangle {
  p0 : @view.ProjectedVertex
  p1 : @view.ProjectedVertex
  p2 : @view.ProjectedVertex
  intensity : Double
}

///|
pub struct DrawList {
  triangles : Array[DrawTriangle]
}

///|
pub fn DrawTriangle::new(
  p0 : @view.ProjectedVertex,
  p1 : @view.ProjectedVertex,
  p2 : @view.ProjectedVertex,
  intensity : Double,
) -> DrawTriangle {
  { p0, p1, p2, intensity }
}

///|
pub fn DrawList::new() -> DrawList {
  { triangles: [] }
}

///|
pub fn DrawList::push_triangle(
  self : DrawList,
  triangle : DrawTriangle,
) -> Unit {
  self.triangles.push(triangle)
}
