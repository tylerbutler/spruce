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
