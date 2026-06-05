//// Named terminal glyphs and ASCII fallbacks.
////
//// Use the Unicode constants for rich terminal output, and the `_ascii`
//// constants when output must stay plain ASCII.

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

/// Informational message glyph.
pub const info = "ℹ"

/// Warning message glyph.
pub const warn = "⚠"

/// Error message glyph.
pub const error = "✖"

/// Success message glyph.
pub const success = "✔"

/// In-progress/start glyph.
pub const start = "◐"

/// Trace/detail glyph.
pub const trace = "→"

/// Debug message glyph.
pub const debug = "⚙"

/// Notice message glyph.
pub const notice = "◉"

/// Alert message glyph.
pub const alert = "‼"

/// Bullet list glyph.
pub const bullet = "•"

/// Disclosure arrow glyph.
pub const arrow = "▸"

/// ASCII informational glyph.
pub const info_ascii = "i"

/// ASCII warning glyph.
pub const warn_ascii = "!"

/// ASCII error glyph.
pub const error_ascii = "x"

/// ASCII success glyph.
pub const success_ascii = "+"

/// ASCII in-progress/start glyph.
pub const start_ascii = "*"

/// ASCII disclosure arrow glyph.
pub const arrow_ascii = ">"

/// ASCII bullet list glyph.
pub const bullet_ascii = "-"

/// Resolve a glyph pair according to the requested mode.
pub fn resolve(
  mode: Mode,
  unicode unicode: String,
  ascii ascii: String,
) -> String {
  case mode {
    Unicode -> unicode
    Ascii -> ascii
  }
}

/// Resolve a named status glyph according to the requested mode.
pub fn status(mode: Mode, status: Status) -> String {
  case status, mode {
    Info, Unicode -> info
    Info, Ascii -> info_ascii
    Warn, Unicode -> warn
    Warn, Ascii -> warn_ascii
    Error, Unicode -> error
    Error, Ascii -> error_ascii
    Success, Unicode -> success
    Success, Ascii -> success_ascii
    Start, Unicode -> start
    Start, Ascii -> start_ascii
    Trace, Unicode -> trace
    Trace, Ascii -> ">"
    Debug, Unicode -> debug
    Debug, Ascii -> "*"
    Notice, Unicode -> notice
    Notice, Ascii -> "o"
    Alert, Unicode -> alert
    Alert, Ascii -> "!!"
    Bullet, Unicode -> bullet
    Bullet, Ascii -> bullet_ascii
    Arrow, Unicode -> arrow
    Arrow, Ascii -> arrow_ascii
  }
}
