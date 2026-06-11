const TUI_SEQUENCE_MAGIC : String = "GEOMETRY3D_TUI_SEQUENCE v1"
const TUI_FRAME_MARKER : String = "---frame---"

pub struct TuiFrame {
  content : String
}

pub struct TuiSequence {
  width : Int
  height : Int
  fps : Int
  frames : Array[TuiFrame]
}

pub fn TuiFrame::new(content : String) -> TuiFrame {
  { content: content }
}

pub fn TuiSequence::new(width : Int, height : Int, fps : Int) -> TuiSequence {
  {
    width: if width < 1 { 1 } else { width },
    height: if height < 1 { 1 } else { height },
    fps: if fps < 1 { 1 } else { fps },
    frames: [],
  }
}

pub fn TuiSequence::push_frame(self : TuiSequence, content : String) -> Unit {
  self.frames.push(TuiFrame::new(content))
}

fn write_line(builder : StringBuilder, line : String) -> Unit {
  builder.write_string(line)
  builder.write_char('\n')
}

pub fn encode_tui_sequence(sequence : TuiSequence) -> String {
  let builder = StringBuilder::new()
  write_line(builder, TUI_SEQUENCE_MAGIC)
  write_line(builder, "width=\{sequence.width}")
  write_line(builder, "height=\{sequence.height}")
  write_line(builder, "fps=\{sequence.fps}")
  write_line(builder, "frames=\{sequence.frames.length()}")
  for frame in sequence.frames {
    write_line(builder, TUI_FRAME_MARKER)
    builder.write_string(frame.content)
    if frame.content.length() == 0 || frame.content[frame.content.length() - 1].unsafe_to_char() != '\n' {
      builder.write_char('\n')
    }
  }
  builder.to_string()
}

fn split_lines(text : String) -> Array[String] {
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

fn digit_value(ch : Char) -> Int {
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

fn parse_int_after_equals(line : String, fallback : Int) -> Int {
  let mut seen_equals = false
  let mut value = 0
  let mut seen_digit = false
  for ch in line {
    if seen_equals {
      let digit = digit_value(ch)
      if digit >= 0 {
        value = value * 10 + digit
        seen_digit = true
      }
    } else if ch == '=' {
      seen_equals = true
    }
  }
  if seen_digit { value } else { fallback }
}

pub fn decode_tui_sequence(text : String) -> TuiSequence {
  let lines = split_lines(text)
  if lines.length() < 5 || lines[0] != TUI_SEQUENCE_MAGIC {
    return TuiSequence::new(DEFAULT_WIDTH, DEFAULT_HEIGHT, 30)
  }
  let sequence = TuiSequence::new(
    parse_int_after_equals(lines[1], DEFAULT_WIDTH),
    parse_int_after_equals(lines[2], DEFAULT_HEIGHT),
    parse_int_after_equals(lines[3], 30),
  )
  let mut index = 5
  while index < lines.length() {
    if lines[index - 1] == TUI_FRAME_MARKER {
      let builder = StringBuilder::new()
      let mut rows = 0
      while index < lines.length() && rows < sequence.height {
        write_line(builder, lines[index])
        index += 1
        rows += 1
      }
      sequence.push_frame(builder.to_string())
    } else {
      index += 1
    }
  }
  sequence
}
