import spruce
import spruce/palette
import spruce/style
import startest/expect
import tty

pub fn hash_is_deterministic_test() {
  let sp = spruce.with_color_level(tty.Ansi256)
  let a = style.render(sp, palette.hash(sp, "database"), "database")
  let b = style.render(sp, palette.hash(sp, "database"), "database")
  a
  |> expect.to_equal(b)
}

pub fn hash_foo_is_deterministic_test() {
  let sp = spruce.with_color_level(tty.Ansi256)
  let a = style.render(sp, palette.hash(sp, "foo"), "foo")
  let b = style.render(sp, palette.hash(sp, "foo"), "foo")
  a
  |> expect.to_equal(b)
}

pub fn hash_distinguishes_simple_anagrams_test() {
  let sp = spruce.with_color_level(tty.Ansi256)
  let ab = style.render(sp, palette.hash(sp, "ab"), "sample")
  let ba = style.render(sp, palette.hash(sp, "ba"), "sample")

  expect.to_be_true(ab != ba)
}

pub fn hash_uses_valid_palette_color_test() {
  let sp = spruce.with_color_level(tty.Ansi256)
  let text = "foo"
  let out = style.render(sp, palette.hash(sp, text), text)

  renders_like_valid_ansi256_palette_color(sp, out, text)
  |> expect.to_be_true
}

pub fn hash_no_color_is_plain_test() {
  let sp = spruce.no_color()
  style.render(sp, palette.hash(sp, "database"), "database")
  |> expect.to_equal("database")
}

pub fn hash_no_color_style_stays_plain_test() {
  let hashed_style = palette.hash(spruce.no_color(), "database")

  style.render(spruce.with_color_level(tty.Ansi256), hashed_style, "database")
  |> expect.to_equal("database")
}

pub fn hash_color_adds_escapes_test() {
  let sp = spruce.with_color_level(tty.Ansi256)
  let out = style.render(sp, palette.hash(sp, "database"), "database")
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
