import gleam/list
import gleam/string
import spruce
import spruce/align
import spruce/box
import spruce/style
import spruce/table
import startest/expect
import tty

pub fn table_renders_headers_and_rows_no_color_test() {
  table.new()
  |> table.headers(["Name", "Lang"])
  |> table.rows([["Spruce", "Gleam"], ["Box", "UI"]])
  |> table.render(spruce.no_color(), _)
  |> expect.to_equal(
    "┌────────┬───────┐\n"
    <> "│ Name   │ Lang  │\n"
    <> "├────────┼───────┤\n"
    <> "│ Spruce │ Gleam │\n"
    <> "│ Box    │ UI    │\n"
    <> "└────────┴───────┘",
  )
}

pub fn table_pads_short_rows_and_uses_ansi_aware_widths_test() {
  let red_long =
    style.render(
      spruce.with_color_level(tty.TrueColor),
      style.new() |> style.fg(style.Red),
      "long",
    )

  let lines =
    table.new()
    |> table.headers(["A", "B"])
    |> table.rows([[red_long], ["x", "yy"]])
    |> table.render(spruce.no_color(), _)
    |> string.split("\n")

  let assert [top, _, _, first, second, bottom] = lines
  expect.to_equal(align.visual_length(top), align.visual_length(first))
  expect.to_equal(align.visual_length(top), align.visual_length(second))
  expect.to_equal(align.visual_length(top), align.visual_length(bottom))
}

pub fn table_style_fn_applies_to_headers_with_negative_row_test() {
  let out =
    table.new()
    |> table.headers(["H"])
    |> table.rows([["x"]])
    |> table.style_fn(fn(row, _col) {
      case row {
        -1 -> style.new() |> style.bold
        _ -> style.new() |> style.fg(style.Green)
      }
    })
    |> table.render(spruce.with_color_level(tty.TrueColor), _)

  expect.to_be_true(string.contains(out, "\u{001b}[1mH"))
  expect.to_be_true(string.contains(out, "\u{001b}[32mx"))
}

pub fn table_style_fn_wraps_each_line_independently_test() {
  table.new()
  |> table.rows([["alpha beta", "z"]])
  |> table.column_widths([5, 1])
  |> table.style_fn(fn(_row, col) {
    case col {
      0 -> style.new() |> style.fg(style.Red)
      _ -> style.new()
    }
  })
  |> table.render(spruce.with_color_level(tty.TrueColor), _)
  |> expect.to_equal(
    "┌───────┬───┐\n"
    <> "│ \u{001b}[31malpha\u{001b}[39m │ z │\n"
    <> "│ \u{001b}[31mbeta\u{001b}[39m  │   │\n"
    <> "└───────┴───┘",
  )
}

pub fn empty_table_renders_empty_string_test() {
  table.new()
  |> table.render(spruce.no_color(), _)
  |> expect.to_equal("")
}

pub fn table_respects_context_indentation_test() {
  table.new()
  |> table.headers(["Name"])
  |> table.rows([["Spruce"]])
  |> table.render(spruce.no_color() |> spruce.indented, _)
  |> string.split("\n")
  |> list.all(fn(line) { string.starts_with(line, "  ") })
  |> expect.to_equal(True)
}

pub fn table_default_rendering_unchanged_test() {
  table.new()
  |> table.headers(["Name", "Lang"])
  |> table.rows([["Spruce", "Gleam"], ["Box", "UI"]])
  |> table.render(spruce.no_color(), _)
  |> expect.to_equal(
    "┌────────┬───────┐\n"
    <> "│ Name   │ Lang  │\n"
    <> "├────────┼───────┤\n"
    <> "│ Spruce │ Gleam │\n"
    <> "│ Box    │ UI    │\n"
    <> "└────────┴───────┘",
  )
}

pub fn table_column_widths_wrap_multiline_rows_test() {
  table.new()
  |> table.headers(["Col", "Other"])
  |> table.rows([["alpha beta gamma", "x"]])
  |> table.column_widths([5, 5])
  |> table.render(spruce.no_color(), _)
  |> expect.to_equal(
    "┌───────┬───────┐\n"
    <> "│ Col   │ Other │\n"
    <> "├───────┼───────┤\n"
    <> "│ alpha │ x     │\n"
    <> "│ beta  │       │\n"
    <> "│ gamma │       │\n"
    <> "└───────┴───────┘",
  )
}

pub fn table_width_distributes_column_caps_test() {
  table.new()
  |> table.headers(["A", "B"])
  |> table.rows([["abcdef", "wxyz"]])
  |> table.width(16)
  |> table.render(spruce.no_color(), _)
  |> expect.to_equal(
    "┌───────┬──────┐\n"
    <> "│ A     │ B    │\n"
    <> "├───────┼──────┤\n"
    <> "│ abcde │ wxyz │\n"
    <> "│ f     │      │\n"
    <> "└───────┴──────┘",
  )
}

pub fn table_rounded_border_style_test() {
  table.new()
  |> table.headers(["A", "B"])
  |> table.rows([["x", "y"]])
  |> table.border(box.Rounded)
  |> table.render(spruce.no_color(), _)
  |> expect.to_equal(
    "╭───┬───╮\n"
    <> "│ A │ B │\n"
    <> "├───┼───┤\n"
    <> "│ x │ y │\n"
    <> "╰───┴───╯",
  )
}

pub fn table_thick_border_style_test() {
  table.new()
  |> table.headers(["A", "B"])
  |> table.rows([["x", "y"]])
  |> table.border(box.Thick)
  |> table.render(spruce.no_color(), _)
  |> expect.to_equal(
    "┏━━━┳━━━┓\n"
    <> "┃ A ┃ B ┃\n"
    <> "┣━━━╋━━━┫\n"
    <> "┃ x ┃ y ┃\n"
    <> "┗━━━┻━━━┛",
  )
}

pub fn table_double_border_style_test() {
  table.new()
  |> table.headers(["A", "B"])
  |> table.rows([["x", "y"]])
  |> table.border(box.Double)
  |> table.render(spruce.no_color(), _)
  |> expect.to_equal(
    "╔═══╦═══╗\n"
    <> "║ A ║ B ║\n"
    <> "╠═══╬═══╣\n"
    <> "║ x ║ y ║\n"
    <> "╚═══╩═══╝",
  )
}

pub fn table_row_separators_between_body_rows_test() {
  table.new()
  |> table.rows([["a"], ["b"]])
  |> table.row_separators(True)
  |> table.render(spruce.no_color(), _)
  |> expect.to_equal(
    "┌───┐\n" <> "│ a │\n" <> "├───┤\n" <> "│ b │\n" <> "└───┘",
  )
}
