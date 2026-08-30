import gleam/string
import gleeunit/should
import spruce
import spruce/message

pub fn success_no_color_test() {
  spruce.no_color()
  |> message.success("done")
  |> should.equal("✔ success done")
}

pub fn fail_no_color_test() {
  spruce.no_color()
  |> message.fail("nope")
  |> should.equal("✖ fail nope")
}

pub fn start_no_color_test() {
  spruce.no_color()
  |> message.start("compiling")
  |> should.equal("◐ start compiling")
}

pub fn ready_no_color_test() {
  spruce.no_color()
  |> message.ready("listening")
  |> should.equal("✔ ready listening")
}

pub fn info_no_color_test() {
  spruce.no_color()
  |> message.info("noted")
  |> should.equal("ℹ︎ info noted")
}

pub fn warn_indented_test() {
  spruce.no_color()
  |> spruce.indented
  |> message.warn("careful")
  |> should.equal("  ⚠ warn careful")
}

pub fn error_no_color_test() {
  spruce.no_color()
  |> message.error("broken")
  |> should.equal("✖ error broken")
}

pub fn success_color_has_escapes_test() {
  let rendered =
    message.success(spruce.with_color_level(spruce.TrueColor), "done")
  should.be_true(string.contains(rendered, "\u{001b}"))
  should.be_true(string.contains(rendered, "success"))
}

pub fn label_is_bold_and_colored_test() {
  let rendered = message.warn(spruce.with_color_level(spruce.Basic), "careful")
  should.be_true(string.contains(rendered, "\u{001b}[1m"))
  should.be_true(string.contains(rendered, "\u{001b}[33m"))
}

pub fn ascii_mode_uses_ascii_icons_test() {
  spruce.no_color()
  |> spruce.with_symbol_mode(spruce.Ascii)
  |> message.success("done")
  |> should.equal("+ success done")
}
