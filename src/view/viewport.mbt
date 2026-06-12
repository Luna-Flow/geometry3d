///|
pub struct Viewport {
  width : Int
  height : Int
}

///|
pub fn Viewport::new(width : Int, height : Int) -> Viewport {
  { width, height }
}
