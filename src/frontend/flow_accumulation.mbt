pub struct FlowVector {
  dx : Int
  dy : Int
}

pub struct FlowField {
  width : Int
  height : Int
  vectors : Array[FlowVector]
}

pub fn FlowVector::new(dx : Int, dy : Int) -> FlowVector {
  { dx, dy }
}

pub fn FlowField::new(width : Int, height : Int) -> FlowField {
  { width, height, vectors: Array::make(width * height, FlowVector::new(0, 0)) }
}

pub fn FlowField::index(self : FlowField, x : Int, y : Int) -> Int {
  y * self.width + x
}

pub fn FlowField::get(self : FlowField, x : Int, y : Int) -> FlowVector {
  if x < 0 || x >= self.width || y < 0 || y >= self.height {
    FlowVector::new(0, 0)
  } else {
    self.vectors[self.index(x, y)]
  }
}

pub fn FlowField::set(self : FlowField, x : Int, y : Int, flow : FlowVector) -> Unit {
  if x < 0 || x >= self.width || y < 0 || y >= self.height {
    return
  }
  self.vectors[self.index(x, y)] = flow
}

fn patch_error(
  previous : LumaBuffer,
  current : LumaBuffer,
  x : Int,
  y : Int,
  dx : Int,
  dy : Int,
  radius : Int,
) -> Double {
  let mut error = 0.0
  for oy in -radius..<(radius + 1) {
    for ox in -radius..<(radius + 1) {
      let a = previous.get(x + ox + dx, y + oy + dy)
      let b = current.get(x + ox, y + oy)
      let diff = a - b
      error += diff * diff
    }
  }
  error
}

pub fn estimate_optical_flow(
  previous : LumaBuffer,
  current : LumaBuffer,
  search_radius : Int,
  patch_radius : Int,
) -> FlowField {
  let flow = FlowField::new(current.width, current.height)
  let safe_search = if search_radius < 0 { 0 } else { search_radius }
  let safe_patch = if patch_radius < 0 { 0 } else { patch_radius }
  for y in 0..<current.height {
    for x in 0..<current.width {
      let mut best_error = 1.0e30
      let mut best_dx = 0
      let mut best_dy = 0
      for dy in -safe_search..<(safe_search + 1) {
        for dx in -safe_search..<(safe_search + 1) {
          let error = patch_error(previous, current, x, y, dx, dy, safe_patch)
          if error < best_error {
            best_error = error
            best_dx = dx
            best_dy = dy
          }
        }
      }
      flow.set(x, y, FlowVector::new(best_dx, best_dy))
    }
  }
  flow
}

pub fn accumulate_with_flow(
  previous : LumaBuffer,
  current : LumaBuffer,
  flow : FlowField,
) -> LumaBuffer {
  let out = LumaBuffer::new(current.width, current.height)
  for y in 0..<current.height {
    for x in 0..<current.width {
      let vector = flow.get(x, y)
      let prev = previous.get(x + vector.dx, y + vector.dy)
      let curr = current.get(x, y)
      let index = out.index(x, y)
      out.values[index] = (prev + curr) * 0.5
      out.depths[index] = current.depths[index]
    }
  }
  out
}

pub fn align_with_flow(
  previous : LumaBuffer,
  current : LumaBuffer,
  flow : FlowField,
) -> LumaBuffer {
  let out = LumaBuffer::new(current.width, current.height)
  for y in 0..<current.height {
    for x in 0..<current.width {
      let vector = flow.get(x, y)
      let prev_x = x + vector.dx
      let prev_y = y + vector.dy
      let index = out.index(x, y)
      out.values[index] = previous.get(prev_x, prev_y)
      out.depths[index] = previous.depth_at(prev_x, prev_y)
    }
  }
  out
}

pub fn average_luma(a : LumaBuffer, b : LumaBuffer) -> LumaBuffer {
  let out = LumaBuffer::new(a.width, a.height)
  for i in 0..<out.values.length() {
    out.values[i] = (a.values[i] + b.values[i]) * 0.5
    out.depths[i] = if a.depths[i] < b.depths[i] { a.depths[i] } else { b.depths[i] }
  }
  out
}
