import spruce
import spruce/group
import startest/expect

pub fn group_passes_deeper_context_test() {
  let observed_depth =
    group.group(spruce.no_color(), "Build", fn(inner) { spruce.depth(inner) })
  observed_depth
  |> expect.to_equal(1)
}

pub fn group_returns_body_result_test() {
  group.group(spruce.no_color(), "Build", fn(_inner) { 42 })
  |> expect.to_equal(42)
}

pub fn indent_multiline_test() {
  group.indent("a\nb", 1)
  |> expect.to_equal("  a\n  b")
}

pub fn indent_level_zero_test() {
  group.indent("a\nb", 0)
  |> expect.to_equal("a\nb")
}
