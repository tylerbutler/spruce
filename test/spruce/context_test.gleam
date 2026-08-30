import gleeunit/should
import spruce

// The context's color level round-trips through with_color_level.
pub fn with_color_level_sets_level_test() {
  spruce.with_color_level(spruce.Ansi256)
  |> spruce.color_level
  |> should.equal(spruce.Ansi256)
}

// no_color() reports no color support.
pub fn no_color_disables_color_test() {
  spruce.no_color()
  |> spruce.supports_color
  |> should.be_false
}

// A non-NoColor level reports color support.
pub fn truecolor_supports_color_test() {
  spruce.with_color_level(spruce.TrueColor)
  |> spruce.supports_color
  |> should.be_true
}

// A fresh context starts at depth 0.
pub fn fresh_context_starts_at_depth_zero_test() {
  spruce.no_color()
  |> spruce.depth
  |> should.equal(0)
}

// indented increments depth and preserves it across calls.
pub fn indented_increments_depth_test() {
  spruce.no_color()
  |> spruce.indented
  |> spruce.indented
  |> spruce.depth
  |> should.equal(2)
}

// detect() returns one of the known levels without crashing on either target.
pub fn detect_returns_a_known_level_test() {
  case spruce.color_level(spruce.detect()) {
    spruce.NoColor | spruce.Basic | spruce.Ansi256 | spruce.TrueColor ->
      should.be_true(True)
  }
}

// Smoke check that the re-exported Stream type is usable end to end.
pub fn detect_stream_stderr_returns_a_known_level_test() {
  case spruce.color_level(spruce.detect_stream(spruce.Stderr)) {
    spruce.NoColor | spruce.Basic | spruce.Ansi256 | spruce.TrueColor ->
      should.be_true(True)
  }
}

// indented preserves the context's background.
pub fn indented_preserves_background_test() {
  spruce.no_color()
  |> spruce.with_background(spruce.Light)
  |> spruce.indented
  |> spruce.background
  |> should.equal(spruce.Light)
}

// with_background overrides the context background.
pub fn with_background_sets_background_test() {
  spruce.with_color_level(spruce.TrueColor)
  |> spruce.with_background(spruce.Dark)
  |> spruce.background
  |> should.equal(spruce.Dark)
}

// A context built without detection defaults to an Unknown background.
pub fn default_background_is_unknown_test() {
  spruce.no_color()
  |> spruce.background
  |> should.equal(spruce.Unknown)
}

// detect() returns one of the known backgrounds without crashing on either
// target.
pub fn detect_returns_a_known_background_test() {
  case spruce.background(spruce.detect()) {
    spruce.Light | spruce.Dark | spruce.Unknown -> should.be_true(True)
  }
}
