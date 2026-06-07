import gleam/string
import spruce
import spruce/details
import startest/expect
import tty

pub fn empty_details_render_empty_test() {
  details.render(spruce.no_color(), details.new())
  |> expect.to_equal("")
}

pub fn details_render_key_value_pairs_test() {
  details.new()
  |> details.add("method", "GET")
  |> details.add("path", "/api/users")
  |> details.render(spruce.no_color(), _)
  |> expect.to_equal("method=GET path=/api/users")
}

pub fn details_quote_spaces_equals_quotes_and_control_chars_test() {
  details.new()
  |> details.add("name", "Ada Lovelace")
  |> details.add("query", "a=b")
  |> details.add("quote", "say \"hi\"")
  |> details.add("line", "one\ntwo")
  |> details.render(spruce.no_color(), _)
  |> expect.to_equal(
    "name=\"Ada Lovelace\" query=\"a=b\" quote=\"say \\\"hi\\\"\" line=\"one\\ntwo\"",
  )
}

pub fn details_quote_and_escape_tabs_test() {
  details.new()
  |> details.add("field", "a\tb")
  |> details.render(spruce.no_color(), _)
  |> expect.to_equal("field=\"a\\tb\"")
}

pub fn details_can_filter_internal_keys_test() {
  details.new()
  |> details.add("_scope_depth", "2")
  |> details.add("user", "tyler")
  |> details.hide_internal
  |> details.render(spruce.no_color(), _)
  |> expect.to_equal("user=tyler")
}

pub fn colored_details_emit_escapes_test() {
  let out =
    details.new()
    |> details.add("host", "localhost")
    |> details.render(spruce.with_color_level(tty.Ansi256), _)

  expect.to_be_true(string.contains(out, "\u{001b}"))
  expect.to_be_true(string.contains(out, "host=localhost"))
}
