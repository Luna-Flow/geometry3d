///|
pub fn dotted_background(
  _x : Int32,
  _y : Int32,
  _width : Int32,
  _height : Int32,
) -> Char {
  '.'
}

///|
pub fn blank_background(
  _x : Int32,
  _y : Int32,
  _width : Int32,
  _height : Int32,
) -> Char {
  ' '
}

///|
pub fn checker_background(
  x : Int32,
  y : Int32,
  _width : Int32,
  _height : Int32,
) -> Char {
  if (x + y) % 2 == 0 {
    '.'
  } else {
    ' '
  }
}
