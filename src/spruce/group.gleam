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
///
/// This is the eager, streaming form of grouping: the title prints immediately
/// and `body` runs right away, so its output appears as work happens and it may
/// perform IO and return any value. For deferred, pipe-composable grouping that
/// buffers output instead, see `spruce/output.group`.
pub fn group(sp: Spruce, title: String, body: fn(Spruce) -> result) -> result {
  io.println(render_title(sp, title))
  body(spruce.indented(sp))
}

/// Render a group title line (indent prefix + styled marker + title), the same
/// line that `group` prints. Exposed so buffered output (`spruce/output`) can
/// compose group titles without duplicating the styling.
pub fn render_title(sp: Spruce, title: String) -> String {
  layout.indent_prefix(sp) <> title_line(sp, title)
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
