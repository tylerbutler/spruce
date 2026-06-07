//// Composable ANSI styling helpers.
////
//// A `Style` is an immutable value built with `new` and refined through piped
//// combinators such as `fg`, `bold`, and `underline`. Apply it to text with
//// `render`, which downgrades or drops colors to match the context's color
//// level and resolves adaptive colors against its background.
////
//// ```gleam
//// import spruce
//// import spruce/style
////
//// pub fn main() {
////   let sp = spruce.detect()
////   let heading = style.new() |> style.fg(style.Cyan) |> style.bold
////   echo style.render(sp, heading, "Hello")
//// }
//// ```

import gleam/bool
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import gleam_community/ansi
import spruce.{type Spruce}
import tty

/// A color usable as a foreground or background.
///
/// The named constructors map to the 16 standard ANSI colors. `Rgb`, `Hex`,
/// and `Ansi256` give finer control and are downgraded to the nearest
/// representable color when the terminal lacks support. `Complete` and
/// `Adaptive` select a color based on the color level and terminal background
/// respectively (see `complete` and `adaptive`).
pub type Color {
  Black
  Red
  Green
  Yellow
  Blue
  Magenta
  Cyan
  White
  Gray
  BrightRed
  BrightGreen
  BrightYellow
  BrightBlue
  BrightMagenta
  BrightCyan
  BrightWhite
  Rgb(r: Int, g: Int, b: Int)
  Hex(value: Int)
  Ansi256(index: Int)
  Complete(ansi: Color, ansi256: Color, truecolor: Color)
  Adaptive(light: Color, dark: Color)
}

type BasicCandidate {
  BasicCandidate(color: Color, rgb: RgbValue)
}

type RgbValue {
  RgbValue(r: Int, g: Int, b: Int)
}

/// An immutable set of text attributes (colors and SGR flags). Build one with
/// `new` and the combinators in this module, then apply it with `render`.
pub opaque type Style {
  Style(
    fg: Option(Color),
    bg: Option(Color),
    bold: Bool,
    dim: Bool,
    italic: Bool,
    underline: Bool,
    strikethrough: Bool,
    reverse: Bool,
    faint: Bool,
    inline: Bool,
  )
}

/// Create an empty style with no color and no attributes set.
pub fn new() -> Style {
  Style(
    fg: None,
    bg: None,
    bold: False,
    dim: False,
    italic: False,
    underline: False,
    strikethrough: False,
    reverse: False,
    faint: False,
    inline: False,
  )
}

/// Set the foreground (text) color.
pub fn fg(style: Style, color: Color) -> Style {
  Style(..style, fg: Some(color))
}

/// Set the background color.
pub fn bg(style: Style, color: Color) -> Style {
  Style(..style, bg: Some(color))
}

/// Build a color with an explicit variant per color level: `ansi` for basic
/// terminals, `ansi256` for 256-color, and `truecolor` for truecolor. The
/// level detected in the context selects which variant is used at render time.
pub fn complete(
  ansi ansi: Color,
  ansi256 ansi256: Color,
  truecolor truecolor: Color,
) -> Color {
  Complete(ansi:, ansi256:, truecolor:)
}

/// Build a color that adapts to the terminal background: `light` is used on a
/// light background, `dark` on a dark (or `Unknown`) background. Each side may
/// be any `Color`, including `complete`, so this also covers
/// "complete-adaptive" colors. Resolved against `spruce.background` at render.
pub fn adaptive(light light: Color, dark dark: Color) -> Color {
  Adaptive(light:, dark:)
}

/// Enable bold text.
pub fn bold(style: Style) -> Style {
  Style(..style, bold: True)
}

/// Enable dim (faint) text.
pub fn dim(style: Style) -> Style {
  Style(..style, dim: True)
}

/// Enable italic text.
pub fn italic(style: Style) -> Style {
  Style(..style, italic: True)
}

/// Enable underlined text.
pub fn underline(style: Style) -> Style {
  Style(..style, underline: True)
}

/// Enable strikethrough text.
pub fn strikethrough(style: Style) -> Style {
  Style(..style, strikethrough: True)
}

/// Enable reverse video, swapping the foreground and background colors.
pub fn reverse(style: Style) -> Style {
  Style(..style, reverse: True)
}

/// Enable faint text. This is an alias for `dim`.
pub fn faint(style: Style) -> Style {
  Style(..style, faint: True)
}

/// Collapse newlines in the text to single spaces when rendering, keeping a
/// styled value on one line.
pub fn inline(style: Style) -> Style {
  Style(..style, inline: True)
}

/// Apply a style to `text`, returning the styled string.
///
/// When the context does not support color, all color and attribute styling is
/// dropped (only the `inline` transform is applied). Colors the terminal cannot
/// represent are downgraded to the nearest available color, and `Adaptive`
/// colors are resolved against the context's background.
pub fn render(sp: Spruce, style: Style, text: String) -> String {
  let text = render_inline(text, style.inline)

  case spruce.supports_color(sp) {
    False -> text
    True -> {
      let background = spruce.background(sp)
      let fg = resolve_adaptive_option(style.fg, background)
      let bg = resolve_adaptive_option(style.bg, background)
      text
      |> render_fg(fg, spruce.color_level(sp))
      |> render_bg(bg, spruce.color_level(sp))
      |> render_bold(style.bold)
      |> render_dim(style.dim)
      |> render_italic(style.italic)
      |> render_underline(style.underline)
      |> render_strikethrough(style.strikethrough)
      |> render_reverse(style.reverse)
      |> render_faint(style.faint)
    }
  }
}

fn resolve_adaptive_option(
  color: Option(Color),
  background: tty.Background,
) -> Option(Color) {
  case color {
    None -> None
    Some(color) -> Some(resolve_adaptive(color, background))
  }
}

/// Resolve `Adaptive` colors against the terminal background, treating
/// `Unknown` as `Dark`. Recurses through `Complete` so adaptive colors may nest
/// inside complete colors (and vice versa).
fn resolve_adaptive(color: Color, background: tty.Background) -> Color {
  case color {
    Adaptive(light, dark) ->
      case background {
        tty.Light -> resolve_adaptive(light, background)
        tty.Dark | tty.Unknown -> resolve_adaptive(dark, background)
      }
    Complete(ansi, ansi256, truecolor) ->
      Complete(
        resolve_adaptive(ansi, background),
        resolve_adaptive(ansi256, background),
        resolve_adaptive(truecolor, background),
      )
    other -> other
  }
}

fn render_inline(text: String, enabled: Bool) -> String {
  use <- bool.guard(when: !enabled, return: text)
  text
  |> string.replace(each: "\r\n", with: " ")
  |> string.replace(each: "\n", with: " ")
  |> string.replace(each: "\r", with: " ")
}

fn render_fg(
  text: String,
  color: Option(Color),
  color_level: spruce.ColorLevel,
) -> String {
  case color {
    None -> text
    Some(color) -> render_fg_color(text, color, color_level)
  }
}

fn render_bg(
  text: String,
  color: Option(Color),
  color_level: spruce.ColorLevel,
) -> String {
  case color {
    None -> text
    Some(color) -> render_bg_color(text, color, color_level)
  }
}

fn render_fg_color(
  text: String,
  color: Color,
  color_level: spruce.ColorLevel,
) -> String {
  case color {
    Black -> ansi.black(text)
    Red -> ansi.red(text)
    Green -> ansi.green(text)
    Yellow -> ansi.yellow(text)
    Blue -> ansi.blue(text)
    Magenta -> ansi.magenta(text)
    Cyan -> ansi.cyan(text)
    White -> ansi.white(text)
    Gray -> ansi.gray(text)
    BrightRed -> ansi.bright_red(text)
    BrightGreen -> ansi.bright_green(text)
    BrightYellow -> ansi.bright_yellow(text)
    BrightBlue -> ansi.bright_blue(text)
    BrightMagenta -> ansi.bright_magenta(text)
    BrightCyan -> ansi.bright_cyan(text)
    BrightWhite -> ansi.bright_white(text)
    Rgb(r, g, b) -> render_fg_rgb(text, RgbValue(r, g, b), color_level)
    Hex(value) -> render_fg_rgb(text, hex_to_rgb(value), color_level)
    Ansi256(index) -> render_fg_ansi256(text, index, color_level)
    Complete(ansi, ansi256, truecolor) ->
      render_fg_color(
        text,
        choose_complete_color(ansi, ansi256, truecolor, color_level),
        color_level,
      )
    Adaptive(_, dark) -> render_fg_color(text, dark, color_level)
  }
}

fn render_bg_color(
  text: String,
  color: Color,
  color_level: spruce.ColorLevel,
) -> String {
  case color {
    Black -> ansi.bg_black(text)
    Red -> ansi.bg_red(text)
    Green -> ansi.bg_green(text)
    Yellow -> ansi.bg_yellow(text)
    Blue -> ansi.bg_blue(text)
    Magenta -> ansi.bg_magenta(text)
    Cyan -> ansi.bg_cyan(text)
    White -> ansi.bg_white(text)
    Gray -> ansi.bg_bright_black(text)
    BrightRed -> ansi.bg_bright_red(text)
    BrightGreen -> ansi.bg_bright_green(text)
    BrightYellow -> ansi.bg_bright_yellow(text)
    BrightBlue -> ansi.bg_bright_blue(text)
    BrightMagenta -> ansi.bg_bright_magenta(text)
    BrightCyan -> ansi.bg_bright_cyan(text)
    BrightWhite -> ansi.bg_bright_white(text)
    Rgb(r, g, b) -> render_bg_rgb(text, RgbValue(r, g, b), color_level)
    Hex(value) -> render_bg_rgb(text, hex_to_rgb(value), color_level)
    Ansi256(index) -> render_bg_ansi256(text, index, color_level)
    Complete(ansi, ansi256, truecolor) ->
      render_bg_color(
        text,
        choose_complete_color(ansi, ansi256, truecolor, color_level),
        color_level,
      )
    Adaptive(_, dark) -> render_bg_color(text, dark, color_level)
  }
}

fn render_fg_rgb(
  text: String,
  rgb: RgbValue,
  color_level: spruce.ColorLevel,
) -> String {
  case color_level {
    tty.TrueColor -> ansi.hex(text, rgb_to_hex(rgb))
    tty.Ansi256 -> render_fg_ansi256_sequence(text, rgb_to_ansi256_index(rgb))
    tty.Basic | tty.NoColor ->
      render_fg_color(text, nearest_basic_color(rgb), color_level)
  }
}

fn render_bg_rgb(
  text: String,
  rgb: RgbValue,
  color_level: spruce.ColorLevel,
) -> String {
  case color_level {
    tty.TrueColor -> ansi.bg_hex(text, rgb_to_hex(rgb))
    tty.Ansi256 -> render_bg_ansi256_sequence(text, rgb_to_ansi256_index(rgb))
    tty.Basic | tty.NoColor ->
      render_bg_color(text, nearest_basic_color(rgb), color_level)
  }
}

fn render_fg_ansi256(
  text: String,
  index: Int,
  color_level: spruce.ColorLevel,
) -> String {
  let rgb = ansi256_to_rgb(index)
  case color_level {
    tty.TrueColor -> ansi.hex(text, rgb_to_hex(rgb))
    tty.Ansi256 -> render_fg_ansi256_sequence(text, index)
    tty.Basic | tty.NoColor ->
      render_fg_color(text, nearest_basic_color(rgb), color_level)
  }
}

fn render_bg_ansi256(
  text: String,
  index: Int,
  color_level: spruce.ColorLevel,
) -> String {
  let rgb = ansi256_to_rgb(index)
  case color_level {
    tty.TrueColor -> ansi.bg_hex(text, rgb_to_hex(rgb))
    tty.Ansi256 -> render_bg_ansi256_sequence(text, index)
    tty.Basic | tty.NoColor ->
      render_bg_color(text, nearest_basic_color(rgb), color_level)
  }
}

fn render_fg_ansi256_sequence(text: String, index: Int) -> String {
  "\u{001b}[38;5;" <> int.to_string(index) <> "m" <> text <> "\u{001b}[39m"
}

fn render_bg_ansi256_sequence(text: String, index: Int) -> String {
  "\u{001b}[48;5;" <> int.to_string(index) <> "m" <> text <> "\u{001b}[49m"
}

fn choose_complete_color(
  ansi: Color,
  ansi256: Color,
  truecolor: Color,
  color_level: spruce.ColorLevel,
) -> Color {
  case color_level {
    tty.Basic -> ansi
    tty.Ansi256 -> ansi256
    tty.TrueColor -> truecolor
    tty.NoColor -> ansi
  }
}

fn hex_to_rgb(value: Int) -> RgbValue {
  let value = int.clamp(value, max: 0xffffff, min: 0)
  RgbValue(
    int.bitwise_shift_right(value, 16) |> int.bitwise_and(0xff),
    int.bitwise_shift_right(value, 8) |> int.bitwise_and(0xff),
    int.bitwise_and(value, 0xff),
  )
}

fn rgb_to_hex(rgb: RgbValue) -> Int {
  let RgbValue(r, g, b) = clamp_rgb(rgb)
  r * 0x10000 + g * 0x100 + b
}

fn clamp_rgb(rgb: RgbValue) -> RgbValue {
  let RgbValue(r, g, b) = rgb
  RgbValue(clamp_component(r), clamp_component(g), clamp_component(b))
}

fn clamp_component(value: Int) -> Int {
  int.clamp(value, max: 255, min: 0)
}

fn nearest_basic_color(rgb: RgbValue) -> Color {
  case basic_candidates() {
    [] -> Black
    [first, ..rest] -> {
      let best =
        list.fold(rest, first, fn(best, candidate) {
          case
            candidate_distance(candidate, rgb) < candidate_distance(best, rgb)
          {
            True -> candidate
            False -> best
          }
        })
      let BasicCandidate(color, _) = best
      color
    }
  }
}

fn candidate_distance(candidate: BasicCandidate, rgb: RgbValue) -> Int {
  let BasicCandidate(_, candidate_rgb) = candidate
  distance_squared(candidate_rgb, rgb)
}

fn distance_squared(left: RgbValue, right: RgbValue) -> Int {
  let RgbValue(left_r, left_g, left_b) = clamp_rgb(left)
  let RgbValue(right_r, right_g, right_b) = clamp_rgb(right)
  let red_distance = left_r - right_r
  let green_distance = left_g - right_g
  let blue_distance = left_b - right_b
  red_distance
  * red_distance
  + green_distance
  * green_distance
  + blue_distance
  * blue_distance
}

fn basic_candidates() -> List(BasicCandidate) {
  [
    BasicCandidate(Black, RgbValue(0, 0, 0)),
    BasicCandidate(Red, RgbValue(128, 0, 0)),
    BasicCandidate(Green, RgbValue(0, 128, 0)),
    BasicCandidate(Yellow, RgbValue(128, 128, 0)),
    BasicCandidate(Blue, RgbValue(0, 0, 128)),
    BasicCandidate(Magenta, RgbValue(128, 0, 128)),
    BasicCandidate(Cyan, RgbValue(0, 128, 128)),
    BasicCandidate(White, RgbValue(192, 192, 192)),
    BasicCandidate(Gray, RgbValue(128, 128, 128)),
    BasicCandidate(BrightRed, RgbValue(255, 0, 0)),
    BasicCandidate(BrightGreen, RgbValue(0, 255, 0)),
    BasicCandidate(BrightYellow, RgbValue(255, 255, 0)),
    BasicCandidate(BrightBlue, RgbValue(0, 0, 255)),
    BasicCandidate(BrightMagenta, RgbValue(255, 0, 255)),
    BasicCandidate(BrightCyan, RgbValue(0, 255, 255)),
    BasicCandidate(BrightWhite, RgbValue(255, 255, 255)),
  ]
}

fn ansi256_to_rgb(index: Int) -> RgbValue {
  let index = int.clamp(index, max: 255, min: 0)
  case index < 16 {
    True -> basic_color_rgb(ansi256_basic_color(index))
    False ->
      case index < 232 {
        True -> {
          let offset = index - 16
          RgbValue(
            ansi256_cube_component(offset / 36),
            ansi256_cube_component(offset % 36 / 6),
            ansi256_cube_component(offset % 6),
          )
        }
        False -> {
          let gray = 8 + { index - 232 } * 10
          RgbValue(gray, gray, gray)
        }
      }
  }
}

fn ansi256_cube_component(value: Int) -> Int {
  case value {
    0 -> 0
    _ -> 55 + value * 40
  }
}

fn ansi256_basic_color(index: Int) -> Color {
  case index {
    0 -> Black
    1 -> Red
    2 -> Green
    3 -> Yellow
    4 -> Blue
    5 -> Magenta
    6 -> Cyan
    7 -> White
    8 -> Gray
    9 -> BrightRed
    10 -> BrightGreen
    11 -> BrightYellow
    12 -> BrightBlue
    13 -> BrightMagenta
    14 -> BrightCyan
    _ -> BrightWhite
  }
}

fn basic_color_rgb(color: Color) -> RgbValue {
  case color {
    Black -> RgbValue(0, 0, 0)
    Red -> RgbValue(128, 0, 0)
    Green -> RgbValue(0, 128, 0)
    Yellow -> RgbValue(128, 128, 0)
    Blue -> RgbValue(0, 0, 128)
    Magenta -> RgbValue(128, 0, 128)
    Cyan -> RgbValue(0, 128, 128)
    White -> RgbValue(192, 192, 192)
    Gray -> RgbValue(128, 128, 128)
    BrightRed -> RgbValue(255, 0, 0)
    BrightGreen -> RgbValue(0, 255, 0)
    BrightYellow -> RgbValue(255, 255, 0)
    BrightBlue -> RgbValue(0, 0, 255)
    BrightMagenta -> RgbValue(255, 0, 255)
    BrightCyan -> RgbValue(0, 255, 255)
    BrightWhite -> RgbValue(255, 255, 255)
    Rgb(r, g, b) -> RgbValue(r, g, b)
    Hex(value) -> hex_to_rgb(value)
    Ansi256(index) -> ansi256_to_rgb(index)
    Complete(ansi, _, _) -> basic_color_rgb(ansi)
    Adaptive(_, dark) -> basic_color_rgb(dark)
  }
}

fn rgb_to_ansi256_index(rgb: RgbValue) -> Int {
  let rgb = clamp_rgb(rgb)
  let cube_index = rgb_to_ansi256_cube_index(rgb)
  let grayscale_index = rgb_to_ansi256_grayscale_index(rgb)
  let cube_rgb = ansi256_to_rgb(cube_index)
  let grayscale_rgb = ansi256_to_rgb(grayscale_index)

  case distance_squared(grayscale_rgb, rgb) < distance_squared(cube_rgb, rgb) {
    True -> grayscale_index
    False -> cube_index
  }
}

fn rgb_to_ansi256_cube_index(rgb: RgbValue) -> Int {
  let RgbValue(r, g, b) = clamp_rgb(rgb)
  16
  + 36
  * quantize_ansi256_cube_channel(r)
  + 6
  * quantize_ansi256_cube_channel(g)
  + quantize_ansi256_cube_channel(b)
}

fn rgb_to_ansi256_grayscale_index(rgb: RgbValue) -> Int {
  let RgbValue(r, g, b) = clamp_rgb(rgb)
  let average = { r + g + b } / 3
  232 + int.clamp({ average - 8 + 5 } / 10, max: 23, min: 0)
}

fn quantize_ansi256_cube_channel(value: Int) -> Int {
  { clamp_component(value) * 5 + 127 } / 255
}

fn render_bold(text: String, enabled: Bool) -> String {
  use <- bool.guard(when: !enabled, return: text)
  ansi.bold(text)
}

fn render_dim(text: String, enabled: Bool) -> String {
  use <- bool.guard(when: !enabled, return: text)
  ansi.dim(text)
}

fn render_italic(text: String, enabled: Bool) -> String {
  use <- bool.guard(when: !enabled, return: text)
  ansi.italic(text)
}

fn render_underline(text: String, enabled: Bool) -> String {
  use <- bool.guard(when: !enabled, return: text)
  ansi.underline(text)
}

fn render_strikethrough(text: String, enabled: Bool) -> String {
  use <- bool.guard(when: !enabled, return: text)
  ansi.strikethrough(text)
}

fn render_reverse(text: String, enabled: Bool) -> String {
  use <- bool.guard(when: !enabled, return: text)
  ansi.inverse(text)
}

fn render_faint(text: String, enabled: Bool) -> String {
  use <- bool.guard(when: !enabled, return: text)
  ansi.dim(text)
}
