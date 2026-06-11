pub fn dotted_background(_x : Int, _y : Int, _width : Int, _height : Int) -> Char {
  '.'
}

pub fn blank_background(_x : Int, _y : Int, _width : Int, _height : Int) -> Char {
  ' '
}

pub fn checker_background(x : Int, y : Int, _width : Int, _height : Int) -> Char {
  if (x + y) % 2 == 0 { '.' } else { ' ' }
}
