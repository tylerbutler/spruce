//// Key-value detail rendering for compact terminal lines.

import gleam/list
import gleam/string
import spruce.{type Spruce}
import spruce/palette
import spruce/style

pub opaque type Details {
  Details(items: List(#(String, String)), show_internal: Bool)
}

/// Create an empty details collection.
pub fn new() -> Details {
  Details(items: [], show_internal: True)
}

/// Add a key-value pair, preserving insertion order.
pub fn add(details: Details, key key: String, value value: String) -> Details {
  Details(..details, items: [#(key, value), ..details.items])
}

/// Omit keys beginning with `_` when rendering.
pub fn hide_internal(details: Details) -> Details {
  Details(..details, show_internal: False)
}

/// Render details as space-separated `key=value` pairs.
pub fn render(sp: Spruce, details: Details) -> String {
  details.items
  |> list.reverse
  |> list.filter(fn(pair) {
    let #(key, _) = pair
    details.show_internal || !string.starts_with(key, "_")
  })
  |> list.map(render_pair(sp, _))
  |> string.join(" ")
}

fn render_pair(sp: Spruce, pair: #(String, String)) -> String {
  let #(key, value) = pair
  let text = key <> "=" <> escape_value(value)
  style.render(sp, palette.hash(sp, key), text)
}

fn escape_value(value: String) -> String {
  let needs_quoting =
    string.contains(value, " ")
    || string.contains(value, "=")
    || string.contains(value, "\"")
    || contains_ascii_control(value)

  case needs_quoting {
    False -> value
    True -> {
      let escaped =
        value
        |> string.replace(each: "\\", with: "\\\\")
        |> string.replace(each: "\"", with: "\\\"")
        |> string.replace(each: "\t", with: "\\t")
        |> string.replace(each: "\n", with: "\\n")
        |> string.replace(each: "\r", with: "\\r")

      "\"" <> escaped <> "\""
    }
  }
}

fn contains_ascii_control(value: String) -> Bool {
  value
  |> string.to_utf_codepoints
  |> list.any(fn(cp) { string.utf_codepoint_to_int(cp) < 32 })
}
