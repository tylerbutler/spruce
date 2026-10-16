import gleam/string
import gleeunit/should
import spruce
import spruce/detail
import spruce/line
import spruce/severity

pub fn simple_line_test() {
  line.new("Build complete")
  |> line.render(spruce.no_color(), _)
  |> should.equal("Build complete")
}

pub fn line_with_severity_test() {
  line.new("Cache warmed")
  |> line.severity(severity.Info)
  |> line.render(spruce.no_color(), _)
  |> should.equal("ℹ︎ info       Cache warmed")
}

pub fn line_with_timestamp_and_scope_test() {
  line.new("Request complete")
  |> line.timestamp("2026-06-05T20:00:00Z")
  |> line.scope("api.http")
  |> line.render(spruce.no_color(), _)
  |> should.equal("2026-06-05T20:00:00Z [api.http] Request complete")
}

pub fn line_with_details_test() {
  let details =
    detail.new()
    |> detail.add(key: "status", value: "200")
    |> detail.add(key: "duration", value: "10ms")

  line.new("Request complete")
  |> line.details(details)
  |> line.render(spruce.no_color(), _)
  |> should.equal("Request complete status=200 duration=10ms")
}

pub fn line_uses_context_indent_test() {
  spruce.no_color()
  |> spruce.indented
  |> line.render(line.new("nested"))
  |> should.equal("  nested")
}

pub fn multiline_line_uses_context_indent_test() {
  spruce.no_color()
  |> spruce.indented
  |> line.render(line.new("a\nb"))
  |> should.equal("  a\n  b")
}

pub fn multiline_line_preserves_blank_and_trailing_lines_test() {
  spruce.no_color()
  |> spruce.indented
  |> line.render(line.new("a\n\nb\n"))
  |> should.equal("  a\n\n  b\n")
}

pub fn empty_timestamp_is_absent_at_all_color_levels_test() {
  assert_empty_timestamp(spruce.no_color())
  assert_empty_timestamp(spruce.with_color_level(spruce.Basic))
  assert_empty_timestamp(spruce.with_color_level(spruce.Ansi256))
  assert_empty_timestamp(spruce.with_color_level(spruce.TrueColor))
}

pub fn real_timestamp_is_preserved_with_color_test() {
  line.new("x")
  |> line.timestamp("now")
  |> line.render(spruce.with_color_level(spruce.Basic), _)
  |> should.equal("\u{001b}[2mnow\u{001b}[22m x")
}

pub fn colored_line_dims_timestamp_scope_and_details_test() {
  let rendered =
    line.new("Request complete")
    |> line.timestamp("now")
    |> line.scope("api")
    |> line.details(detail.new() |> detail.add(key: "status", value: "200"))
    |> line.render(spruce.with_color_level(spruce.TrueColor), _)

  should.be_true(string.contains(rendered, "\u{001b}"))
  should.be_true(string.contains(rendered, "[api]"))
  should.be_true(string.contains(rendered, "status=200"))
}

fn assert_empty_timestamp(context: spruce.Spruce) -> Nil {
  let absent = line.new("x") |> line.render(context, _)
  let empty = line.new("x") |> line.timestamp("") |> line.render(context, _)

  should.equal(empty, absent)
}
