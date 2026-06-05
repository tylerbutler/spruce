import gleam/string
import spruce
import spruce/details
import spruce/line
import spruce/severity
import startest/expect
import tty

pub fn simple_line_test() {
  line.new("Build complete")
  |> line.render(spruce.no_color(), _)
  |> expect.to_equal("Build complete")
}

pub fn line_with_severity_test() {
  line.new("Cache warmed")
  |> line.severity(severity.Info)
  |> line.render(spruce.no_color(), _)
  |> expect.to_equal("ℹ info     Cache warmed")
}

pub fn line_with_timestamp_and_scope_test() {
  line.new("Request complete")
  |> line.timestamp("2026-06-05T20:00:00Z")
  |> line.scope("api.http")
  |> line.render(spruce.no_color(), _)
  |> expect.to_equal("2026-06-05T20:00:00Z [api.http] Request complete")
}

pub fn line_with_details_test() {
  let details =
    details.new()
    |> details.add("status", "200")
    |> details.add("duration", "10ms")

  line.new("Request complete")
  |> line.details(details)
  |> line.render(spruce.no_color(), _)
  |> expect.to_equal("Request complete status=200 duration=10ms")
}

pub fn line_uses_context_indent_test() {
  spruce.no_color()
  |> spruce.indented
  |> line.render(line.new("nested"))
  |> expect.to_equal("  nested")
}

pub fn colored_line_dims_timestamp_scope_and_details_test() {
  let out =
    line.new("Request complete")
    |> line.timestamp("now")
    |> line.scope("api")
    |> line.details(details.new() |> details.add("status", "200"))
    |> line.render(spruce.with_color_level(tty.TrueColor), _)

  expect.to_be_true(string.contains(out, "\u{001b}"))
  expect.to_be_true(string.contains(out, "[api]"))
  expect.to_be_true(string.contains(out, "status=200"))
}
