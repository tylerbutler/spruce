//// Depth-in-context grouped output helpers.

import gleam/io
import gleam/list
import gleam/string
import spruce.{type Spruce}
import spruce/internal/layout
import spruce/palette
import spruce/style
import spruce/symbol

/// Print a group title, then run `body` with a context indented one level deeper.
pub fn group(sp: Spruce, title: String, body: fn(Spruce) -> result) -> result {
  io.println(layout.indent_prefix(sp) <> title_line(sp, title))
  body(spruce.indented(sp))
}

fn title_line(sp: Spruce, title: String) -> String {
  case spruce.supports_color(sp) {
    False -> symbol.arrow <> " " <> title
    True ->
      style.render(sp, palette.hash(sp, title), symbol.arrow)
      <> " "
      <> style.render(sp, style.new() |> style.bold, title)
  }
}

/// Prefix every line in `text` with two spaces for each indent level.
pub fn indent(text: String, level: Int) -> String {
  let prefix = string.repeat("  ", level)

  text
  |> string.split("\n")
  |> list.map(fn(line) { prefix <> line })
  |> string.join("\n")
}
