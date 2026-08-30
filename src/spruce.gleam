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
//// four things: the detected color level (so output is plain when color is
//// unsupported), the terminal background hint (light or dark, used for adaptive
//// colors), the symbol mode (Unicode or ASCII glyphs), and the current indent
//// depth (so grouped output nests without any global state).
////
//// ```gleam
//// import spruce
////
//// pub fn main() {
////   let context = spruce.detect()
////   // pass `context` to render functions in spruce/style, spruce/box, etc.
////   echo spruce.supports_color(context)
//// }
//// ```
////
//// Use `spruce.no_color()` in tests to get deterministic, escape-free output,
//// or `spruce.with_color_level(spruce.TrueColor)` to force a level.

import gleam/string
import tty

/// The terminal's color support level, in ascending order of capability.
pub type ColorLevel {
  NoColor
  Basic
  Ansi256
  TrueColor
}

/// An output stream to detect against.
pub type Stream {
  Stdin
  Stdout
  Stderr
}

/// The terminal background. Adaptive colors (see `spruce/style.adaptive`)
/// resolve against this, treating `Unknown` as `Dark`.
pub type Background {
  Light
  Dark
  Unknown
}

/// Glyph rendering mode: Unicode for rich glyphs, Ascii for plain fallbacks.
/// Every renderer that emits icons or bullets consults the context's mode.
pub type SymbolMode {
  Unicode
  Ascii
}

/// The rendering context. Carries the detected color level, the detected
/// terminal background, the symbol mode, and the current indent depth.
/// Construct it with `detect`, `with_color_level`, or `no_color`, and deepen
/// it with `indented`.
pub opaque type Spruce {
  Spruce(
    color: ColorLevel,
    background: Background,
    symbol_mode: SymbolMode,
    depth: Int,
  )
}

/// Build a context by auto-detecting the color support of standard output.
///
/// Detection honors `NO_COLOR`, `FORCE_COLOR`, `TERM`, CI environment hints,
/// and TTY status (via the `tty` package), falling back to `NoColor` when
/// uncertain.
pub fn detect() -> Spruce {
  detect_stream(Stdout)
}

/// Build a context by auto-detecting the color support of a specific stream.
pub fn detect_stream(stream: Stream) -> Spruce {
  let stream = to_tty_stream(stream)

  Spruce(
    color: tty_color_level_to_color_level(tty.detect_color_level(stream)),
    background: tty_background_to_background(tty.detect_background(stream)),
    symbol_mode: Unicode,
    depth: 0,
  )
}

/// Build a context with an explicit color level, bypassing detection.
/// Useful for forcing a level in tests or honoring a user `--color` flag.
/// The background defaults to `Unknown` (treated as `Dark` by adaptive colors);
/// override it with `with_background`.
pub fn with_color_level(level: ColorLevel) -> Spruce {
  Spruce(color: level, background: Unknown, symbol_mode: Unicode, depth: 0)
}

/// Build a context that never emits color. All output is plain text.
/// This is the recommended context for deterministic tests.
pub fn no_color() -> Spruce {
  Spruce(color: NoColor, background: Unknown, symbol_mode: Unicode, depth: 0)
}

/// Get the color level of a context.
pub fn color_level(context: Spruce) -> ColorLevel {
  context.color
}

/// Whether the context will emit any color (i.e. its level is not `NoColor`).
pub fn supports_color(context: Spruce) -> Bool {
  context.color != NoColor
}

/// Get the detected terminal background of a context.
pub fn background(context: Spruce) -> Background {
  context.background
}

/// Return a copy of the context with an explicit terminal background, bypassing
/// detection. Useful for forcing light/dark adaptive colors in tests or honoring
/// a user `--background` flag.
pub fn with_background(context: Spruce, background: Background) -> Spruce {
  Spruce(..context, background:)
}

/// Get the glyph rendering mode of a context.
pub fn symbol_mode(context: Spruce) -> SymbolMode {
  context.symbol_mode
}

/// Return a copy of the context with an explicit symbol mode.
/// Use `Ascii` for environments that cannot display Unicode glyphs.
pub fn with_symbol_mode(context: Spruce, mode: SymbolMode) -> Spruce {
  Spruce(..context, symbol_mode: mode)
}

/// Get the current indent depth of a context (0 at the top level).
pub fn depth(context: Spruce) -> Int {
  context.depth
}

/// Return a copy of the context with its indent depth increased by one.
/// `spruce/output.group` uses this to hand a deeper context to grouped bodies.
pub fn indented(context: Spruce) -> Spruce {
  Spruce(..context, depth: context.depth + 1)
}

/// Return a copy of the context with its indent depth reset to zero.
/// Composing modules that own indentation at their boundary use this so that
/// inner renderers do not double-indent content that the outer module will
/// indent itself.
pub fn flat(context: Spruce) -> Spruce {
  Spruce(..context, depth: 0)
}

/// The indentation prefix for the context's depth: two spaces per level.
/// Block-producing renderers prepend this to every line they emit.
pub fn indent_prefix(context: Spruce) -> String {
  string.repeat("  ", context.depth)
}

fn to_tty_stream(stream: Stream) -> tty.Stream {
  case stream {
    Stdin -> tty.Stdin
    Stdout -> tty.Stdout
    Stderr -> tty.Stderr
  }
}

fn tty_color_level_to_color_level(level: tty.ColorLevel) -> ColorLevel {
  case level {
    tty.NoColor -> NoColor
    tty.Basic -> Basic
    tty.Ansi256 -> Ansi256
    tty.TrueColor -> TrueColor
  }
}

fn tty_background_to_background(background: tty.Background) -> Background {
  case background {
    tty.Light -> Light
    tty.Dark -> Dark
    tty.Unknown -> Unknown
  }
}
