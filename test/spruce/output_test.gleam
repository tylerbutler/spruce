import gleeunit/should
import spruce
import spruce/message
import spruce/output

pub fn new_is_empty_test() {
  spruce.no_color()
  |> output.new
  |> output.to_string
  |> should.equal("")
}

pub fn append_threads_context_test() {
  spruce.no_color()
  |> output.new
  |> output.append(message.success(_, "done"))
  |> output.append(message.info(_, "next"))
  |> output.to_string
  |> should.equal("✔ success done\nℹ︎ info next")
}

pub fn text_appends_raw_test() {
  spruce.no_color()
  |> output.new
  |> output.text("plain")
  |> output.blank
  |> output.text("after blank")
  |> output.to_string
  |> should.equal("plain\n\nafter blank")
}

pub fn group_indents_body_test() {
  spruce.no_color()
  |> output.new
  |> output.group("Tests", fn(buffer) {
    buffer |> output.append(message.info(_, "running"))
  })
  |> output.to_string
  |> should.equal("▸ Tests\n  ℹ︎ info running")
}

pub fn group_restores_outer_depth_test() {
  spruce.no_color()
  |> output.new
  |> output.group("Build", fn(buffer) {
    buffer |> output.append(message.start(_, "x"))
  })
  |> output.append(message.success(_, "done"))
  |> output.to_string
  |> should.equal("▸ Build\n  ◐ start x\n✔ success done")
}

pub fn nested_groups_test() {
  spruce.no_color()
  |> output.new
  |> output.group("Outer", fn(buffer) {
    buffer
    |> output.append(message.info(_, "a"))
    |> output.group("Inner", fn(buffer) {
      buffer |> output.append(message.info(_, "b"))
    })
  })
  |> output.to_string
  |> should.equal("▸ Outer\n  ℹ︎ info a\n  ▸ Inner\n    ℹ︎ info b")
}

pub fn context_reflects_group_depth_test() {
  spruce.no_color()
  |> output.new
  |> output.group("G", fn(buffer) {
    spruce.depth(output.context(buffer))
    |> should.equal(1)
    buffer
  })
  |> output.to_string
  |> should.equal("▸ G")
}

pub fn stream_group_passes_deeper_context_test() {
  output.stream_group(spruce.no_color(), "Build", fn(inner) {
    spruce.depth(inner)
  })
  |> should.equal(1)
}

pub fn stream_group_returns_body_result_test() {
  output.stream_group(spruce.no_color(), "Build", fn(_inner) { 42 })
  |> should.equal(42)
}

pub fn stream_group_with_writes_title_and_preserves_body_error_test() {
  output.stream_group_with(
    spruce.no_color(),
    "Build",
    fn(line) { should.equal(line, "▸ Build") },
    fn(inner) {
      spruce.depth(inner)
      |> should.equal(1)
      Error("body failed")
    },
  )
  |> should.equal(Error("body failed"))
}

pub fn print_with_writes_output_and_returns_sink_result_test() {
  spruce.no_color()
  |> output.new
  |> output.text("hello")
  |> output.print_with(fn(rendered) {
    should.equal(rendered, "hello")
    Error("write failed")
  })
  |> should.equal(Error("write failed"))
}

pub fn title_is_indented_and_marked_test() {
  spruce.no_color()
  |> spruce.indented
  |> output.title("Build")
  |> should.equal("  ▸ Build")
}

pub fn title_uses_ascii_arrow_in_ascii_mode_test() {
  spruce.no_color()
  |> spruce.with_symbol_mode(spruce.Ascii)
  |> output.title("Build")
  |> should.equal("> Build")
}
