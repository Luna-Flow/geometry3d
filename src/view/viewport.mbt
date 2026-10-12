///|
pub struct Viewport {
  width : Int32
  height : Int32
}

///|
pub fn Viewport::new(width : Int32, height : Int32) -> Viewport {
  { width, height, }
}
