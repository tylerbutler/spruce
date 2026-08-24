import gleam/string
import spruce
import spruce/style
import startest/expect

pub fn render_no_color_is_plain_test() {
  style.new()
  |> style.fg(style.Red)
  |> style.bold
  |> style.render(spruce.no_color(), _, "x")
  |> expect.to_equal("x")
}

pub fn render_color_wraps_text_test() {
  let out =
    style.render(
      spruce.with_color_level(spruce.TrueColor),
      style.new() |> style.fg(style.Red),
      "x",
    )
  expect.to_be_true(string.contains(out, "\u{001b}"))
  expect.to_be_true(string.contains(out, "31m"))
}

pub fn render_empty_style_is_plain_test() {
  style.render(spruce.with_color_level(spruce.TrueColor), style.new(), "x")
  |> expect.to_equal("x")
}

pub fn render_no_color_strips_style_parity_attributes_test() {
  style.new()
  |> style.strikethrough
  |> style.reverse
  |> style.faint
  |> style.render(spruce.no_color(), _, "x")
  |> expect.to_equal("x")
}

pub fn render_color_wraps_style_parity_attributes_test() {
  let out =
    style.render(
      spruce.with_color_level(spruce.TrueColor),
      style.new()
        |> style.strikethrough
        |> style.reverse
        |> style.faint,
      "x",
    )

  expect.to_be_true(string.contains(out, "\u{001b}[9m"))
  expect.to_be_true(string.contains(out, "\u{001b}[7m"))
  expect.to_be_true(string.contains(out, "\u{001b}[2m"))
}

pub fn render_inline_collapses_newlines_without_color_test() {
  style.new()
  |> style.inline
  |> style.render(spruce.no_color(), _, "a\nb\r\nc")
  |> expect.to_equal("a b c")
}

pub fn render_inline_collapses_newlines_with_color_test() {
  let out =
    style.render(
      spruce.with_color_level(spruce.TrueColor),
      style.new() |> style.inline |> style.bold,
      "a\nb",
    )

  expect.to_be_true(string.contains(out, "a b"))
}

pub fn render_complete_fg_chooses_basic_color_test() {
  let out =
    style.render(
      spruce.with_color_level(spruce.Basic),
      style.new()
        |> style.fg(style.complete(
          ansi: style.Red,
          ansi256: style.BrightBlue,
          truecolor: style.BrightGreen,
        )),
      "x",
    )

  expect.to_be_true(string.contains(out, "\u{001b}[31m"))
}

pub fn render_complete_fg_chooses_ansi256_color_test() {
  let out =
    style.render(
      spruce.with_color_level(spruce.Ansi256),
      style.new()
        |> style.fg(style.complete(
          ansi: style.Red,
          ansi256: style.BrightBlue,
          truecolor: style.BrightGreen,
        )),
      "x",
    )

  expect.to_be_true(string.contains(out, "\u{001b}[94m"))
}

pub fn render_complete_fg_chooses_truecolor_color_test() {
  let out =
    style.render(
      spruce.with_color_level(spruce.TrueColor),
      style.new()
        |> style.fg(style.complete(
          ansi: style.Red,
          ansi256: style.BrightBlue,
          truecolor: style.BrightGreen,
        )),
      "x",
    )

  expect.to_be_true(string.contains(out, "\u{001b}[92m"))
}

pub fn render_complete_bg_chooses_color_level_test() {
  let out =
    style.render(
      spruce.with_color_level(spruce.Ansi256),
      style.new()
        |> style.bg(style.complete(
          ansi: style.Red,
          ansi256: style.BrightBlue,
          truecolor: style.BrightGreen,
        )),
      "x",
    )

  expect.to_be_true(string.contains(out, "\u{001b}[104m"))
}

pub fn render_complete_no_color_is_plain_test() {
  style.new()
  |> style.fg(style.complete(
    ansi: style.Red,
    ansi256: style.BrightBlue,
    truecolor: style.BrightGreen,
  ))
  |> style.render(spruce.no_color(), _, "x")
  |> expect.to_equal("x")
}

pub fn render_no_color_strips_arbitrary_colors_test() {
  style.new()
  |> style.fg(style.Rgb(135, 75, 253))
  |> style.bg(style.Hex(0x241F31))
  |> style.render(spruce.no_color(), _, "x")
  |> expect.to_equal("x")
}

pub fn render_truecolor_rgb_uses_24_bit_sequence_test() {
  style.render(
    spruce.with_color_level(spruce.TrueColor),
    style.new() |> style.fg(style.Rgb(135, 75, 253)),
    "x",
  )
  |> expect.to_equal("\u{001b}[38;2;135;75;253mx\u{001b}[39m")
}

pub fn render_truecolor_hex_uses_24_bit_sequence_test() {
  style.render(
    spruce.with_color_level(spruce.TrueColor),
    style.new() |> style.bg(style.Hex(0x874BFD)),
    "x",
  )
  |> expect.to_equal("\u{001b}[48;2;135;75;253mx\u{001b}[49m")
}

pub fn render_basic_downgrades_rgb_to_nearest_basic_color_test() {
  let out =
    style.render(
      spruce.with_color_level(spruce.Basic),
      style.new() |> style.fg(style.Rgb(128, 0, 0)),
      "x",
    )

  expect.to_be_true(string.contains(out, "\u{001b}[31m"))
}

pub fn render_ansi256_fg_uses_256_color_sequence_test() {
  style.render(
    spruce.with_color_level(spruce.Ansi256),
    style.new() |> style.fg(style.Ansi256(200)),
    "x",
  )
  |> expect.to_equal("\u{001b}[38;5;200mx\u{001b}[39m")
}

pub fn render_ansi256_fg_clamps_low_index_test() {
  style.render(
    spruce.with_color_level(spruce.Ansi256),
    style.new() |> style.fg(style.Ansi256(-9)),
    "x",
  )
  |> expect.to_equal("\u{001b}[38;5;0mx\u{001b}[39m")
}

pub fn render_ansi256_rgb_uses_nearest_256_color_sequence_test() {
  style.render(
    spruce.with_color_level(spruce.Ansi256),
    style.new() |> style.fg(style.Rgb(135, 75, 253)),
    "x",
  )
  |> expect.to_equal("\u{001b}[38;5;135mx\u{001b}[39m")
}

pub fn render_ansi256_hex_uses_nearest_256_color_sequence_test() {
  style.render(
    spruce.with_color_level(spruce.Ansi256),
    style.new() |> style.fg(style.Hex(0x874BFD)),
    "x",
  )
  |> expect.to_equal("\u{001b}[38;5;135mx\u{001b}[39m")
}

pub fn render_ansi256_fg_and_bg_keep_separate_resets_test() {
  style.render(
    spruce.with_color_level(spruce.Ansi256),
    style.new()
      |> style.fg(style.Ansi256(200))
      |> style.bg(style.Ansi256(21)),
    "x",
  )
  |> expect.to_equal(
    "\u{001b}[48;5;21m\u{001b}[38;5;200mx\u{001b}[39m\u{001b}[49m",
  )
}

pub fn render_ansi256_bg_clamps_high_index_test() {
  style.render(
    spruce.with_color_level(spruce.Ansi256),
    style.new() |> style.bg(style.Ansi256(999)),
    "x",
  )
  |> expect.to_equal("\u{001b}[48;5;255mx\u{001b}[49m")
}

pub fn render_hex_and_rgb_match_for_same_color_test() {
  let sp = spruce.with_color_level(spruce.TrueColor)
  let rgb =
    style.render(sp, style.new() |> style.fg(style.Rgb(135, 75, 253)), "x")
  let hex = style.render(sp, style.new() |> style.fg(style.Hex(0x874BFD)), "x")

  expect.to_equal(hex, rgb)
}

pub fn adaptive_picks_dark_on_dark_background_test() {
  let sp =
    spruce.with_color_level(spruce.TrueColor)
    |> spruce.with_background(spruce.Dark)
  let adaptive =
    style.render(
      sp,
      style.new()
        |> style.fg(style.adaptive(
          light: style.Hex(0x000000),
          dark: style.Hex(0xffffff),
        )),
      "x",
    )
  let direct =
    style.render(sp, style.new() |> style.fg(style.Hex(0xffffff)), "x")

  expect.to_equal(adaptive, direct)
}

pub fn adaptive_picks_light_on_light_background_test() {
  let sp =
    spruce.with_color_level(spruce.TrueColor)
    |> spruce.with_background(spruce.Light)
  let adaptive =
    style.render(
      sp,
      style.new()
        |> style.fg(style.adaptive(
          light: style.Hex(0x000000),
          dark: style.Hex(0xffffff),
        )),
      "x",
    )
  let direct =
    style.render(sp, style.new() |> style.fg(style.Hex(0x000000)), "x")

  expect.to_equal(adaptive, direct)
}

pub fn adaptive_defaults_to_dark_on_unknown_background_test() {
  let sp = spruce.with_color_level(spruce.TrueColor)
  let adaptive =
    style.render(
      sp,
      style.new()
        |> style.fg(style.adaptive(
          light: style.Hex(0x000000),
          dark: style.Hex(0xffffff),
        )),
      "x",
    )
  let dark = style.render(sp, style.new() |> style.fg(style.Hex(0xffffff)), "x")

  expect.to_equal(adaptive, dark)
}

pub fn adaptive_is_plain_under_no_color_test() {
  style.new()
  |> style.fg(style.adaptive(light: style.Red, dark: style.Blue))
  |> style.render(spruce.no_color(), _, "x")
  |> expect.to_equal("x")
}

pub fn hashed_is_deterministic_test() {
  let sp = spruce.with_color_level(spruce.Ansi256)
  let first = style.render(sp, style.hashed(sp, "database"), "database")
  let second = style.render(sp, style.hashed(sp, "database"), "database")
  first
  |> expect.to_equal(second)
}

pub fn hashed_foo_is_deterministic_test() {
  let sp = spruce.with_color_level(spruce.Ansi256)
  let first = style.render(sp, style.hashed(sp, "foo"), "foo")
  let second = style.render(sp, style.hashed(sp, "foo"), "foo")
  first
  |> expect.to_equal(second)
}

pub fn hashed_distinguishes_simple_anagrams_test() {
  let sp = spruce.with_color_level(spruce.Ansi256)
  let ab = style.render(sp, style.hashed(sp, "ab"), "sample")
  let ba = style.render(sp, style.hashed(sp, "ba"), "sample")

  expect.to_be_true(ab != ba)
}

pub fn hashed_uses_valid_palette_color_test() {
  let sp = spruce.with_color_level(spruce.Ansi256)
  let text = "foo"
  let out = style.render(sp, style.hashed(sp, text), text)

  renders_like_valid_ansi256_palette_color(sp, out, text)
  |> expect.to_be_true
}

pub fn hashed_no_color_is_plain_test() {
  let sp = spruce.no_color()
  style.render(sp, style.hashed(sp, "database"), "database")
  |> expect.to_equal("database")
}

pub fn hashed_no_color_style_stays_plain_test() {
  let hashed_style = style.hashed(spruce.no_color(), "database")

  style.render(
    spruce.with_color_level(spruce.Ansi256),
    hashed_style,
    "database",
  )
  |> expect.to_equal("database")
}

pub fn hashed_color_adds_escapes_test() {
  let sp = spruce.with_color_level(spruce.Ansi256)
  let out = style.render(sp, style.hashed(sp, "database"), "database")
  expect.to_be_true(out != "database")
}

fn renders_like_valid_ansi256_palette_color(
  sp: spruce.Spruce,
  out: String,
  text: String,
) -> Bool {
  let render = fn(color) {
    style.render(sp, style.new() |> style.fg(color), text)
  }

  out == render(style.Red)
  || out == render(style.Green)
  || out == render(style.Yellow)
  || out == render(style.Blue)
  || out == render(style.Magenta)
  || out == render(style.Cyan)
  || out == render(style.BrightRed)
  || out == render(style.BrightGreen)
  || out == render(style.BrightYellow)
  || out == render(style.BrightBlue)
  || out == render(style.BrightMagenta)
  || out == render(style.BrightCyan)
}
