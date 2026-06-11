pub struct LumaBuffer {
  width : Int
  height : Int
  values : Array[Double]
  depths : Array[Double]
}

pub const LUMA_FAR_DEPTH : Double = 1.0e30

pub fn LumaBuffer::new(width : Int, height : Int) -> LumaBuffer {
  {
    width,
    height,
    values: Array::make(width * height, 0.0),
    depths: Array::make(width * height, LUMA_FAR_DEPTH),
  }
}

pub fn LumaBuffer::index(self : LumaBuffer, x : Int, y : Int) -> Int {
  y * self.width + x
}

pub fn LumaBuffer::get(self : LumaBuffer, x : Int, y : Int) -> Double {
  if x < 0 || x >= self.width || y < 0 || y >= self.height {
    0.0
  } else {
    self.values[self.index(x, y)]
  }
}

pub fn LumaBuffer::set_if_closer(
  self : LumaBuffer,
  x : Int,
  y : Int,
  depth : Double,
  value : Double,
) -> Unit {
  if x < 0 || x >= self.width || y < 0 || y >= self.height {
    return
  }
  let index = self.index(x, y)
  if depth + @core.DEPTH_EPSILON < self.depths[index] {
    self.depths[index] = depth
    self.values[index] = value
  }
}

pub fn LumaBuffer::depth_at(self : LumaBuffer, x : Int, y : Int) -> Double {
  if x < 0 || x >= self.width || y < 0 || y >= self.height {
    LUMA_FAR_DEPTH
  } else {
    self.depths[self.index(x, y)]
  }
}

pub fn LumaBuffer::add_weighted_sample(
  self : LumaBuffer,
  sample : LumaBuffer,
  weight : Double,
) -> Unit {
  let count = if self.values.length() < sample.values.length() {
    self.values.length()
  } else {
    sample.values.length()
  }
  for i in 0..<count {
    self.values[i] += sample.values[i] * weight
    if sample.depths[i] < self.depths[i] {
      self.depths[i] = sample.depths[i]
    }
  }
}

fn luma_edge_function(
  ax : Double,
  ay : Double,
  bx : Double,
  by : Double,
  px : Double,
  py : Double,
) -> Double {
  (px - ax) * (by - ay) - (py - ay) * (bx - ax)
}

pub fn LumaBuffer::draw_triangle(self : LumaBuffer, triangle : DrawTriangle) -> Unit {
  let p0 = triangle.p0
  let p1 = triangle.p1
  let p2 = triangle.p2
  let area = luma_edge_function(p0.x, p0.y, p1.x, p1.y, p2.x, p2.y)
  if area.abs() <= @core.DEPTH_EPSILON {
    return
  }
  let min_x = @core.min3(p0.x, p1.x, p2.x).floor().to_int()
  let max_x = @core.max3(p0.x, p1.x, p2.x).ceil().to_int()
  let min_y = @core.min3(p0.y, p1.y, p2.y).floor().to_int()
  let max_y = @core.max3(p0.y, p1.y, p2.y).ceil().to_int()
  for y in min_y..<(max_y + 1) {
    for x in min_x..<(max_x + 1) {
      let sample_x = x.to_double() + 0.5
      let sample_y = y.to_double() + 0.5
      let w0 = luma_edge_function(p1.x, p1.y, p2.x, p2.y, sample_x, sample_y)
      let w1 = luma_edge_function(p2.x, p2.y, p0.x, p0.y, sample_x, sample_y)
      let w2 = luma_edge_function(p0.x, p0.y, p1.x, p1.y, sample_x, sample_y)
      let inside = if area > 0.0 {
        w0 >= 0.0 && w1 >= 0.0 && w2 >= 0.0
      } else {
        w0 <= 0.0 && w1 <= 0.0 && w2 <= 0.0
      }
      if inside {
        let inv_area = 1.0 / area
        let depth =
          (w0 * inv_area) * p0.depth +
          (w1 * inv_area) * p1.depth +
          (w2 * inv_area) * p2.depth
        self.set_if_closer(x, y, depth, triangle.intensity)
      }
    }
  }
}

pub fn draw_list_to_luma(draw_list : DrawList, width : Int, height : Int) -> LumaBuffer {
  let buffer = LumaBuffer::new(width, height)
  for triangle in draw_list.triangles {
    buffer.draw_triangle(triangle)
  }
  buffer
}
