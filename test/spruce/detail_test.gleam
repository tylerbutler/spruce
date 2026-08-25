import gleam/string
import spruce
import spruce/detail
import startest/expect

pub fn empty_details_render_empty_test() {
  detail.render(spruce.no_color(), detail.new())
  |> expect.to_equal("")
}

pub fn details_render_key_value_pairs_test() {
  detail.new()
  |> detail.add(key: "method", value: "GET")
  |> detail.add(key: "path", value: "/api/users")
  |> detail.render(spruce.no_color(), _)
  |> expect.to_equal("method=GET path=/api/users")
}

pub fn details_quote_spaces_equals_quotes_and_control_chars_test() {
  detail.new()
  |> detail.add(key: "name", value: "Ada Lovelace")
  |> detail.add(key: "query", value: "a=b")
  |> detail.add(key: "quote", value: "say \"hi\"")
  |> detail.add(key: "line", value: "one\ntwo")
  |> detail.render(spruce.no_color(), _)
  |> expect.to_equal(
    "name=\"Ada Lovelace\" query=\"a=b\" quote=\"say \\\"hi\\\"\" line=\"one\\ntwo\"",
  )
}

pub fn details_quote_and_escape_tabs_test() {
  detail.new()
  |> detail.add(key: "field", value: "a\tb")
  |> detail.render(spruce.no_color(), _)
  |> expect.to_equal("field=\"a\\tb\"")
}

pub fn details_can_filter_internal_keys_test() {
  detail.new()
  |> detail.add(key: "_scope_depth", value: "2")
  |> detail.add(key: "user", value: "tyler")
  |> detail.hide_internal
  |> detail.render(spruce.no_color(), _)
  |> expect.to_equal("user=tyler")
}

pub fn colored_details_emit_escapes_test() {
  let rendered =
    detail.new()
    |> detail.add(key: "host", value: "localhost")
    |> detail.render(spruce.with_color_level(spruce.Ansi256), _)

  expect.to_be_true(string.contains(rendered, "\u{001b}"))
  expect.to_be_true(string.contains(rendered, "host=localhost"))
}
