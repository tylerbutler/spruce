//// spruce — a terminal-UI kit for Gleam.
////
//// spruce renders styled terminal output — colors, boxes, semantic message
//// lines, icons, deterministic hash-colors, ANSI-aware alignment, and
//// grouped/indented output — that automatically respects the terminal's color
//// support. It is logging-agnostic and targets both Erlang and JavaScript.
////
//// ## The `Spruce` context
////
//// Every render function takes an explicit `Spruce` value. The context carries
//// two things: the detected color level (so output is plain when color is
//// unsupported) and the current indent depth (so grouped output nests without
//// any global state).
////
//// ```gleam
//// import spruce
////
//// pub fn main() {
////   let sp = spruce.detect()
////   // pass `sp` to render functions in spruce/style, spruce/box, etc.
////   echo spruce.supports_color(sp)
//// }
//// ```
////
//// Use `spruce.no_color()` in tests to get deterministic, escape-free output.

import tty

/// The terminal color support level, re-exported from the `tty` package.
/// One of `NoColor`, `Basic`, `Ansi256`, or `TrueColor`.
pub type ColorLevel =
  tty.ColorLevel

/// An output stream, re-exported from the `tty` package.
/// One of `Stdin`, `Stdout`, or `Stderr`.
pub type Stream =
  tty.Stream

/// The rendering context. Carries the detected color level and the current
/// indent depth. Construct it with `detect`, `with_color_level`, or `no_color`,
/// and deepen it with `indented`.
pub opaque type Spruce {
  Spruce(color: tty.ColorLevel, depth: Int)
}

/// Build a context by auto-detecting the color support of standard output.
///
/// Detection honors `NO_COLOR`, `FORCE_COLOR`, `TERM`, CI environment hints,
/// and TTY status (via the `tty` package), falling back to `NoColor` when
/// uncertain.
pub fn detect() -> Spruce {
  Spruce(color: tty.detect_color_level(tty.Stdout), depth: 0)
}

/// Build a context by auto-detecting the color support of a specific stream.
pub fn detect_stream(stream: Stream) -> Spruce {
  Spruce(color: tty.detect_color_level(stream), depth: 0)
}

/// Build a context with an explicit color level, bypassing detection.
/// Useful for forcing a level in tests or honoring a user `--color` flag.
pub fn with_color_level(level: ColorLevel) -> Spruce {
  Spruce(color: level, depth: 0)
}

/// Build a context that never emits color. All output is plain text.
/// This is the recommended context for deterministic tests.
pub fn no_color() -> Spruce {
  Spruce(color: tty.NoColor, depth: 0)
}

/// Get the color level of a context.
pub fn color_level(sp: Spruce) -> ColorLevel {
  sp.color
}

/// Whether the context will emit any color (i.e. its level is not `NoColor`).
pub fn supports_color(sp: Spruce) -> Bool {
  sp.color != tty.NoColor
}

/// Get the current indent depth of a context (0 at the top level).
pub fn depth(sp: Spruce) -> Int {
  sp.depth
}

/// Return a copy of the context with its indent depth increased by one.
/// `spruce/group` uses this to hand a deeper context to grouped bodies.
pub fn indented(sp: Spruce) -> Spruce {
  Spruce(..sp, depth: sp.depth + 1)
}
