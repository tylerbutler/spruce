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
