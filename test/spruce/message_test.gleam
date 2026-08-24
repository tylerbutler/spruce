import gleam/string
import spruce
import spruce/message
import startest/expect
import tty

pub fn success_no_color_test() {
  spruce.no_color()
  |> message.success("done")
  |> expect.to_equal("✔ success done")
}

pub fn fail_no_color_test() {
  spruce.no_color()
  |> message.fail("nope")
  |> expect.to_equal("✖ fail nope")
}

pub fn start_no_color_test() {
  spruce.no_color()
  |> message.start("compiling")
  |> expect.to_equal("◐ start compiling")
}

pub fn ready_no_color_test() {
  spruce.no_color()
  |> message.ready("listening")
  |> expect.to_equal("✔ ready listening")
}

pub fn info_no_color_test() {
  spruce.no_color()
  |> message.info("noted")
  |> expect.to_equal("ℹ info noted")
}

pub fn warn_indented_test() {
  spruce.no_color()
  |> spruce.indented
  |> message.warn("careful")
  |> expect.to_equal("  ⚠ warn careful")
}

pub fn error_no_color_test() {
  spruce.no_color()
  |> message.error("broken")
  |> expect.to_equal("✖ error broken")
}

pub fn success_color_has_escapes_test() {
  let out = message.success(spruce.with_color_level(tty.TrueColor), "done")
  expect.to_be_true(string.contains(out, "\u{001b}"))
  expect.to_be_true(string.contains(out, "success"))
}

pub fn label_is_bold_and_colored_test() {
  let out = message.warn(spruce.with_color_level(tty.Basic), "careful")
  expect.to_be_true(string.contains(out, "\u{001b}[1m"))
  expect.to_be_true(string.contains(out, "\u{001b}[33m"))
}
