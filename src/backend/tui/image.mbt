///|
const TUI_IMAGE_MAGIC : String = "GEOMETRY3D_TUI_IMAGE v1"

///|
const TUI_IMAGE_MARKER : String = "---image---"

///|
pub struct TuiImage {
  width : Int
  height : Int
  content : String
}

///|
pub fn TuiImage::new(width : Int, height : Int, content : String) -> TuiImage {
  {
    width: if width < 1 {
      1
    } else {
      width
    },
    height: if height < 1 {
      1
    } else {
      height
    },
    content,
  }
}

///|
fn image_write_line(builder : StringBuilder, line : String) -> Unit {
  builder.write_string(line)
  builder.write_char('\n')
}

///|
pub fn encode_tui_image(image : TuiImage) -> String {
  let builder = StringBuilder::new()
  image_write_line(builder, TUI_IMAGE_MAGIC)
  image_write_line(builder, "width=\{image.width}")
  image_write_line(builder, "height=\{image.height}")
  image_write_line(builder, TUI_IMAGE_MARKER)
  builder.write_string(image.content)
  if image.content.length() == 0 ||
    image.content[image.content.length() - 1].unsafe_to_char() != '\n' {
    builder.write_char('\n')
  }
  builder.to_string()
}

///|
fn image_split_lines(text : String) -> Array[String] {
  let lines : Array[String] = []
  let mut current = StringBuilder::new()
  for ch in text {
    if ch == '\n' {
      lines.push(current.to_string())
      current = StringBuilder::new()
    } else if ch != '\r' {
      current.write_char(ch)
    }
  }
  if current.to_string().length() > 0 {
    lines.push(current.to_string())
  }
  lines
}

///|
fn image_digit_value(ch : Char) -> Int {
  if ch == '0' {
    0
  } else if ch == '1' {
    1
  } else if ch == '2' {
    2
  } else if ch == '3' {
    3
  } else if ch == '4' {
    4
  } else if ch == '5' {
    5
  } else if ch == '6' {
    6
  } else if ch == '7' {
    7
  } else if ch == '8' {
    8
  } else if ch == '9' {
    9
  } else {
    -1
  }
}

///|
fn image_parse_int_after_equals(line : String, fallback : Int) -> Int {
  let mut seen_equals = false
  let mut value = 0
  let mut seen_digit = false
  for ch in line {
    if seen_equals {
      let digit = image_digit_value(ch)
      if digit >= 0 {
        value = value * 10 + digit
        seen_digit = true
      }
    } else if ch == '=' {
      seen_equals = true
    }
  }
  if seen_digit {
    value
  } else {
    fallback
  }
}

///|
pub fn decode_tui_image(text : String) -> TuiImage {
  let lines = image_split_lines(text)
  if lines.length() < 4 || lines[0] != TUI_IMAGE_MAGIC {
    return TuiImage::new(DEFAULT_WIDTH, DEFAULT_HEIGHT, "")
  }
  let width = image_parse_int_after_equals(lines[1], DEFAULT_WIDTH)
  let height = image_parse_int_after_equals(lines[2], DEFAULT_HEIGHT)
  let builder = StringBuilder::new()
  let mut index = 4
  let mut rows = 0
  while index < lines.length() && rows < height {
    image_write_line(builder, lines[index])
    index += 1
    rows += 1
  }
  TuiImage::new(width, height, builder.to_string())
}
