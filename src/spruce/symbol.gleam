//// Named terminal glyphs with ASCII fallbacks.
////
//// Resolve a `Status` to a glyph with `status`, choosing `Unicode` for rich
//// terminal output or `Ascii` when output must stay plain ASCII.
////
//// ```gleam
//// symbol.status(symbol.Unicode, symbol.Success) // "✔"
//// symbol.status(symbol.Ascii, symbol.Success) // "+"
//// ```

/// Glyph rendering mode.
pub type Mode {
  Unicode
  Ascii
}

/// Named status glyphs.
pub type Status {
  Info
  Warn
  Error
  Success
  Start
  Trace
  Debug
  Notice
  Alert
  Bullet
  Arrow
}

/// Resolve a named status glyph according to the requested mode.
pub fn status(mode: Mode, status: Status) -> String {
  case status, mode {
    Info, Unicode -> "ℹ"
    Info, Ascii -> "i"
    Warn, Unicode -> "⚠"
    Warn, Ascii -> "!"
    Error, Unicode -> "✖"
    Error, Ascii -> "x"
    Success, Unicode -> "✔"
    Success, Ascii -> "+"
    Start, Unicode -> "◐"
    Start, Ascii -> "*"
    Trace, Unicode -> "→"
    Trace, Ascii -> ">"
    Debug, Unicode -> "⚙"
    Debug, Ascii -> "*"
    Notice, Unicode -> "◉"
    Notice, Ascii -> "o"
    Alert, Unicode -> "‼"
    Alert, Ascii -> "!!"
    Bullet, Unicode -> "•"
    Bullet, Ascii -> "-"
    Arrow, Unicode -> "▸"
    Arrow, Ascii -> ">"
  }
}
