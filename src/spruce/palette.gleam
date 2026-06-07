//// Deterministic hash-based colors for consistent terminal output.
////
//// The `palette` module maps strings to colors using a simple hash function,
//// ensuring that the same input always produces the same color. This is useful
//// for coloring log categories, service names, user IDs, or any other repeated
//// identifiers in a visually consistent way.
////
//// The palette automatically adapts to the terminal's color support:
//// - When color is disabled (`NoColor`), `hash` returns a plain style
//// - When 256-color or truecolor is available, it uses a broader palette
//// - When only basic ANSI is available, it falls back to a smaller set
////
//// ```gleam
//// import spruce
//// import spruce/palette
//// import spruce/style
////
//// pub fn main() {
////   let sp = spruce.detect()
////   let colored = style.render(sp, palette.hash(sp, "database"), "database")
////   // "database" will always be rendered with the same color
//// }
//// ```

import gleam/int
import gleam/list
import gleam/string
import spruce.{type Spruce}
import spruce/style.{type Style}
import tty

/// Map a string to a deterministic color style.
///
/// The same input string will always produce the same color. The color palette
/// adapts to the context's color level: a broader set of colors is used when
/// 256-color or truecolor support is detected, and a smaller set for basic ANSI.
///
/// When the context has `NoColor`, this returns a plain style with no color.
pub fn hash(sp: Spruce, text: String) -> Style {
  case spruce.supports_color(sp) {
    False -> style.new()
    True -> {
      let colors = palette_for(spruce.color_level(sp))
      let index = hash_text(text) % list.length(colors)
      let color = case list.drop(colors, index) {
        [c, ..] -> c
        [] -> style.Cyan
      }
      style.new() |> style.fg(color)
    }
  }
}

fn hash_text(text: String) -> Int {
  text
  |> string.to_utf_codepoints
  |> list.fold(5381, fn(hash, cp) {
    let next = hash * 33 + string.utf_codepoint_to_int(cp)
    bounded_modulo(next, 2_147_483_647)
  })
}

fn bounded_modulo(value: Int, modulus: Int) -> Int {
  case int.modulo(value, by: modulus) {
    Ok(value) -> value
    Error(Nil) -> 0
  }
}

fn palette_for(level: tty.ColorLevel) -> List(style.Color) {
  case tty.color_level_at_least(level, tty.Ansi256) {
    True -> [
      style.Red,
      style.Green,
      style.Yellow,
      style.Blue,
      style.Magenta,
      style.Cyan,
      style.BrightRed,
      style.BrightGreen,
      style.BrightYellow,
      style.BrightBlue,
      style.BrightMagenta,
      style.BrightCyan,
    ]
    False -> [
      style.Cyan,
      style.Green,
      style.Yellow,
      style.Magenta,
      style.Blue,
      style.Red,
    ]
  }
}
