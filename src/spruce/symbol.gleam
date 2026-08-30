//// Named terminal glyphs with ASCII fallbacks.
////
//// Resolve a `Status` to a glyph with `status`, choosing `spruce.Unicode`
//// for rich terminal output or `spruce.Ascii` when output must stay plain
//// ASCII.
////
//// ```gleam
//// symbol.status(spruce.Unicode, symbol.Success) // "✔"
//// symbol.status(spruce.Ascii, symbol.Success) // "+"
//// ```

import spruce

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
pub fn status(mode: spruce.SymbolMode, status: Status) -> String {
  case status, mode {
    Info, spruce.Unicode -> "ℹ︎"
    Info, spruce.Ascii -> "i"
    Warn, spruce.Unicode -> "⚠"
    Warn, spruce.Ascii -> "!"
    Error, spruce.Unicode -> "✖"
    Error, spruce.Ascii -> "x"
    Success, spruce.Unicode -> "✔"
    Success, spruce.Ascii -> "+"
    Start, spruce.Unicode -> "◐"
    Start, spruce.Ascii -> "*"
    Trace, spruce.Unicode -> "→"
    Trace, spruce.Ascii -> ">"
    Debug, spruce.Unicode -> "⚙"
    Debug, spruce.Ascii -> "*"
    Notice, spruce.Unicode -> "◉"
    Notice, spruce.Ascii -> "o"
    Alert, spruce.Unicode -> "‼"
    Alert, spruce.Ascii -> "!!"
    Bullet, spruce.Unicode -> "•"
    Bullet, spruce.Ascii -> "-"
    Arrow, spruce.Unicode -> "▸"
    Arrow, spruce.Ascii -> ">"
  }
}
