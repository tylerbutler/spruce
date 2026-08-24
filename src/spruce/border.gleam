//// Border styles and the glyphs that draw them, shared by `spruce/box` and
//// `spruce/table`.

/// The characters used to draw a visible border.
pub type BorderChars {
  BorderChars(
    top_left: String,
    top: String,
    top_right: String,
    right: String,
    bottom_right: String,
    bottom: String,
    bottom_left: String,
    left: String,
  )
}

/// A border style. `Hidden` draws nothing; `Custom` supplies its own glyphs.
pub type Border {
  Normal
  Rounded
  Thick
  Double
  Hidden
  Block
  Custom(BorderChars)
}

/// The glyph set for a border style.
pub fn chars(border: Border) -> BorderChars {
  case border {
    Normal ->
      BorderChars(
        top_left: "┌",
        top: "─",
        top_right: "┐",
        right: "│",
        bottom_right: "┘",
        bottom: "─",
        bottom_left: "└",
        left: "│",
      )
    Rounded ->
      BorderChars(
        top_left: "╭",
        top: "─",
        top_right: "╮",
        right: "│",
        bottom_right: "╯",
        bottom: "─",
        bottom_left: "╰",
        left: "│",
      )
    Thick ->
      BorderChars(
        top_left: "┏",
        top: "━",
        top_right: "┓",
        right: "┃",
        bottom_right: "┛",
        bottom: "━",
        bottom_left: "┗",
        left: "┃",
      )
    Double ->
      BorderChars(
        top_left: "╔",
        top: "═",
        top_right: "╗",
        right: "║",
        bottom_right: "╝",
        bottom: "═",
        bottom_left: "╚",
        left: "║",
      )
    Block ->
      BorderChars(
        top_left: "█",
        top: "█",
        top_right: "█",
        right: "█",
        bottom_right: "█",
        bottom: "█",
        bottom_left: "█",
        left: "█",
      )
    Hidden ->
      BorderChars(
        top_left: "",
        top: "",
        top_right: "",
        right: "",
        bottom_right: "",
        bottom: "",
        bottom_left: "",
        left: "",
      )
    Custom(chars) -> chars
  }
}
