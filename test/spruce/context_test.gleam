import gleam/order
import spruce
import startest/expect
import tty

// The context's color level round-trips through with_color_level.
pub fn with_color_level_sets_level_test() {
  spruce.with_color_level(tty.Ansi256)
  |> spruce.color_level
  |> expect.to_equal(tty.Ansi256)
}

// no_color() reports no color support.
pub fn no_color_disables_color_test() {
  spruce.no_color()
  |> spruce.supports_color
  |> expect.to_be_false
}

// A non-NoColor level reports color support.
pub fn truecolor_supports_color_test() {
  spruce.with_color_level(tty.TrueColor)
  |> spruce.supports_color
  |> expect.to_be_true
}

// A fresh context starts at depth 0.
pub fn fresh_context_starts_at_depth_zero_test() {
  spruce.no_color()
  |> spruce.depth
  |> expect.to_equal(0)
}

// indented increments depth and preserves it across calls.
pub fn indented_increments_depth_test() {
  spruce.no_color()
  |> spruce.indented
  |> spruce.indented
  |> spruce.depth
  |> expect.to_equal(2)
}

// detect() returns one of the known levels without crashing on either target.
pub fn detect_returns_a_known_level_test() {
  case spruce.color_level(spruce.detect()) {
    tty.NoColor | tty.Basic | tty.Ansi256 | tty.TrueColor ->
      expect.to_be_true(True)
  }
}

// Smoke check that the re-exported Stream type is usable end to end.
pub fn detect_stream_stderr_returns_a_known_level_test() {
  case spruce.color_level(spruce.detect_stream(tty.Stderr)) {
    tty.NoColor | tty.Basic | tty.Ansi256 | tty.TrueColor ->
      expect.to_be_true(True)
  }
}

// Sanity anchor on the dependency ordering helper (keeps `order` import live).
pub fn truecolor_outranks_no_color_test() {
  tty.color_level_compare(tty.TrueColor, tty.NoColor)
  |> expect.to_equal(order.Gt)
}
