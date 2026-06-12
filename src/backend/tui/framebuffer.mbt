///|
pub const FAR_DEPTH : Double = 1.0e30

///|
pub struct FrameBuffer {
  width : Int
  height : Int
  cells : Array[Char]
  depths : Array[Double]
}

///|
pub fn FrameBuffer::new(
  width : Int,
  height : Int,
  background_pattern : (Int, Int, Int, Int) -> Char,
) -> FrameBuffer {
  let buffer = {
    width,
    height,
    cells: Array::make(width * height, ' '),
    depths: Array::make(width * height, FAR_DEPTH),
  }
  for y in 0..<height {
    for x in 0..<width {
      let index = buffer.index(x, y)
      buffer.cells[index] = background_pattern(x, y, width, height)
    }
  }
  buffer
}

///|
pub fn FrameBuffer::index(self : FrameBuffer, x : Int, y : Int) -> Int {
  y * self.width + x
}

///|
pub fn FrameBuffer::set_pixel_if_closer(
  self : FrameBuffer,
  x : Int,
  y : Int,
  depth : Double,
  pixel : Char,
) -> Unit {
  if x < 0 || x >= self.width || y < 0 || y >= self.height {
    return
  }
  let index = self.index(x, y)
  if depth + @core.DEPTH_EPSILON < self.depths[index] {
    self.depths[index] = depth
    self.cells[index] = pixel
  }
}

///|
pub fn FrameBuffer::to_string(self : FrameBuffer) -> String {
  let builder = StringBuilder::new()
  for y in 0..<self.height {
    for x in 0..<self.width {
      builder.write_char(self.cells[self.index(x, y)])
    }
    builder.write_char('\n')
  }
  builder.to_string()
}
