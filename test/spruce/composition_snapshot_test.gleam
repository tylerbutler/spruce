import birdie
import gleam/string
import gleeunit/should
import spruce
import spruce/align
import spruce/box
import spruce/markdown
import spruce/message
import spruce/output
import spruce/style
import spruce/table

const document = "# Build *report*\n\nA **ready build with nested *emphasis* inside** is available.\n\n> Review **the wrapped output** before release.\n\n1. Run the tests on both targets.\n2. Review the snapshots.\n\n```gleam\nlet ready = True\n```\n\nDone."

pub fn plain_markdown_document_test() -> Nil {
  markdown.render_with(
    spruce.no_color(),
    document,
    markdown.default_options() |> markdown.with_width(32),
  )
  |> visible_output
  |> birdie.snap(title: "plain composed markdown document")
}

pub fn styled_markdown_document_test() -> Nil {
  markdown.render_with(
    spruce.with_color_level(spruce.Basic),
    document,
    markdown.default_options() |> markdown.with_width(32),
  )
  |> visible_output
  |> birdie.snap(title: "styled composed markdown document")
}

pub fn styled_wrapped_table_test() -> Nil {
  let context = spruce.with_color_level(spruce.Basic) |> spruce.indented
  let status =
    style.render(
      context,
      style.new() |> style.fg(style.Green) |> style.bold,
      "ready for review",
    )

  table.new()
  |> table.headers(["Target", "Status"])
  |> table.rows([["Erlang", status], ["JavaScript", "run\n\nagain"]])
  |> table.column_widths([7, 9])
  |> table.column_alignments([table.Left, table.Center])
  |> table.row_separators(True)
  |> table.style_fn(fn(row, _column) {
    case row {
      table.Header -> style.new() |> style.bold
      table.Body(_) -> style.new() |> style.dim
    }
  })
  |> table.render(context, _)
  |> visible_output
  |> birdie.snap(title: "styled wrapped table with multiline cells")
}

pub fn styled_wrapped_box_test() -> Nil {
  let context = spruce.with_color_level(spruce.Basic)
  let content =
    "Review "
    <> style.render(
      context,
      style.new() |> style.bold,
      "bold " <> style.render(context, style.new() |> style.dim, "and dim"),
    )
    <> " text before release.\n\nDone."

  box.render(
    context,
    content,
    box.new()
      |> box.title("Review")
      |> box.width(16)
      |> box.foreground(style.White)
      |> box.background(style.Blue)
      |> box.padding(top: 1, right: 1, bottom: 1, left: 1)
      |> box.margin(top: 0, right: 2, bottom: 1, left: 1),
  )
  |> visible_output
  |> birdie.snap(title: "styled box with nested styles and wrapping")
}

pub fn grouped_layout_test() -> Nil {
  let context = spruce.no_color()
  let summary =
    table.new()
    |> table.headers(["Target", "State"])
    |> table.rows([["Erlang", "ready"], ["JS", "ready"]])
    |> table.column_widths([6, 5])
    |> table.render(context, _)
  let note =
    box.render(
      context,
      "Review both targets.",
      box.new() |> box.title("Next") |> box.width(12),
    )
  let layout =
    align.join_horizontal(align.End, [summary, "  ", note])
    |> align.place(
      width: 40,
      height: 7,
      horizontal: align.Center,
      vertical: align.Center,
      content: _,
    )
    |> fn(body) { align.join_vertical(align.Center, ["Build report", body]) }

  context
  |> output.new
  |> output.group("Release", fn(buffer) {
    buffer
    |> output.append(box.render(_, layout, box.plain()))
    |> output.blank
    |> output.append(message.info(_, "Review complete"))
  })
  |> output.append(message.success(_, "Ready"))
  |> output.to_string
  |> visible_output
  |> birdie.snap(title: "grouped side by side layout")
}

fn visible_output(text: String) -> String {
  text
  |> string.replace(each: "\\", with: "\\\\")
  |> string.replace(each: "\u{001b}", with: "\\x1b")
  |> string.replace(each: " ", with: "·")
}

pub fn visible_output_preserves_controls_spaces_and_line_breaks_test() -> Nil {
  visible_output("\\x1b \u{001b}[1mhi\u{001b}[22m  \n\nend \n")
  |> should.equal("\\\\x1b·\\x1b[1mhi\\x1b[22m··\n\nend·\n")
}
