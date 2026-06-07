import spruce
import spruce/message
import spruce/output
import startest/expect

pub fn new_is_empty_test() {
  spruce.no_color()
  |> output.new
  |> output.to_string
  |> expect.to_equal("")
}

pub fn append_threads_context_test() {
  spruce.no_color()
  |> output.new
  |> output.append(message.success(_, "done"))
  |> output.append(message.info(_, "next"))
  |> output.to_string
  |> expect.to_equal("✔ success done\nℹ info next")
}

pub fn text_appends_raw_test() {
  spruce.no_color()
  |> output.new
  |> output.text("plain")
  |> output.blank
  |> output.text("after blank")
  |> output.to_string
  |> expect.to_equal("plain\n\nafter blank")
}

pub fn group_indents_body_test() {
  spruce.no_color()
  |> output.new
  |> output.group("Tests", fn(o) {
    o |> output.append(message.info(_, "running"))
  })
  |> output.to_string
  |> expect.to_equal("▸ Tests\n  ℹ info running")
}

pub fn group_restores_outer_depth_test() {
  spruce.no_color()
  |> output.new
  |> output.group("Build", fn(o) { o |> output.append(message.start(_, "x")) })
  |> output.append(message.success(_, "done"))
  |> output.to_string
  |> expect.to_equal("▸ Build\n  ◐ start x\n✔ success done")
}

pub fn nested_groups_test() {
  spruce.no_color()
  |> output.new
  |> output.group("Outer", fn(o) {
    o
    |> output.append(message.info(_, "a"))
    |> output.group("Inner", fn(o) { o |> output.append(message.info(_, "b")) })
  })
  |> output.to_string
  |> expect.to_equal("▸ Outer\n  ℹ info a\n  ▸ Inner\n    ℹ info b")
}

pub fn context_reflects_group_depth_test() {
  spruce.no_color()
  |> output.new
  |> output.group("G", fn(o) {
    spruce.depth(output.context(o))
    |> expect.to_equal(1)
    o
  })
  |> output.to_string
  |> expect.to_equal("▸ G")
}
