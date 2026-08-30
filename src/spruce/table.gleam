//// Bordered, ANSI-aware data table rendering.

import gleam/bool
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import spruce.{type Spruce}
import spruce/align
import spruce/border.{type Border, type BorderChars}
import spruce/style

/// Identifies the row kind passed to a `style_fn`.
pub type RowContext {
  /// The header row.
  Header
  /// A zero-based body row.
  Body(index: Int)
}

/// A table of string cells with an optional header row. Build one with `new`
/// and the configuration functions in this module, then render it with `render`.
pub opaque type Table {
  Table(
    headers: List(String),
    rows: List(List(String)),
    style_fn: Option(fn(RowContext, Int) -> style.Style),
    width: Option(Int),
    column_widths: Option(List(Int)),
    border: Border,
    row_separators: Bool,
  )
}

type GridChars {
  GridChars(
    border: BorderChars,
    top_mid: String,
    left_mid: String,
    cross: String,
    right_mid: String,
    bottom_mid: String,
  )
}

/// Create an empty table.
pub fn new() -> Table {
  Table(
    headers: [],
    rows: [],
    style_fn: None,
    width: None,
    column_widths: None,
    border: border.Normal,
    row_separators: False,
  )
}

/// Set the optional header row.
pub fn headers(table: Table, headers: List(String)) -> Table {
  Table(..table, headers: headers)
}

/// Set the body rows. Short rows are padded with empty cells at render time.
pub fn rows(table: Table, rows: List(List(String))) -> Table {
  Table(..table, rows: rows)
}

/// Set a per-cell style function.
///
/// The `RowContext` argument is `Header` for header cells and `Body(index)` for
/// zero-based body row cells.
pub fn style_fn(
  table: Table,
  style_fn: fn(RowContext, Int) -> style.Style,
) -> Table {
  Table(..table, style_fn: Some(style_fn))
}

/// Constrain the overall table to a maximum visual width.
///
/// The available cell content width is distributed evenly across columns. Cells
/// that exceed their column width are wrapped with `spruce/align.wrap`.
pub fn width(table: Table, width: Int) -> Table {
  Table(..table, width: Some(non_negative(width)), column_widths: None)
}

/// Constrain columns to maximum visual widths.
///
/// Widths less than one are ignored. Columns without a corresponding configured
/// width use their natural content width.
pub fn column_widths(table: Table, widths: List(Int)) -> Table {
  Table(..table, column_widths: Some(widths), width: None)
}

/// Set the table border style.
///
/// Junctions are exact for Normal, Rounded, Thick, and Double. Other border
/// styles approximate junctions from their edge characters.
pub fn border(table: Table, border: Border) -> Table {
  Table(..table, border: border)
}

/// Toggle separator lines between body rows.
pub fn row_separators(table: Table, enabled: Bool) -> Table {
  Table(..table, row_separators: enabled)
}

/// Render a table as a bordered grid.
pub fn render(context: Spruce, table: Table) -> String {
  let column_count = count_columns(table.headers, table.rows)

  case column_count {
    0 -> ""
    _ -> {
      let widths =
        resolved_column_widths(
          column_count,
          table.headers,
          table.rows,
          table.width,
          table.column_widths,
        )
      let chars = grid_chars(table.border)
      let hidden = case table.border {
        border.Hidden -> True
        _ -> False
      }
      let body =
        render_body_rows(
          context,
          table.rows,
          widths,
          table.style_fn,
          chars,
          table.row_separators && !hidden,
          0,
        )

      let lines = case hidden {
        True ->
          render_header_plain(
            context,
            table.headers,
            widths,
            table.style_fn,
            chars,
          )
          |> list.append(body)
        False ->
          [render_top(widths, chars)]
          |> list.append(render_header(
            context,
            table.headers,
            widths,
            table.style_fn,
            chars,
            body,
          ))
          |> list.append(body)
          |> list.append([render_bottom(widths, chars)])
      }

      lines
      |> list.map(fn(line) { spruce.indent_prefix(context) <> line })
      |> string.join("\n")
    }
  }
}

fn count_columns(headers: List(String), rows: List(List(String))) -> Int {
  rows
  |> list.map(list.length)
  |> list.fold(list.length(headers), int.max)
}

fn natural_column_widths(
  column_count: Int,
  headers: List(String),
  rows: List(List(String)),
) -> List(Int) {
  column_widths_loop(0, column_count, headers, rows, [])
}

fn column_widths_loop(
  index: Int,
  column_count: Int,
  headers: List(String),
  rows: List(List(String)),
  acc: List(Int),
) -> List(Int) {
  case index >= column_count {
    True -> list.reverse(acc)
    False -> {
      let header_width = cell_at(headers, index) |> cell_width
      let row_width =
        rows
        |> list.map(fn(row) { cell_at(row, index) |> cell_width })
        |> list.fold(header_width, int.max)

      column_widths_loop(index + 1, column_count, headers, rows, [
        row_width,
        ..acc
      ])
    }
  }
}

fn resolved_column_widths(
  column_count: Int,
  headers: List(String),
  rows: List(List(String)),
  table_width: Option(Int),
  max_widths: Option(List(Int)),
) -> List(Int) {
  let natural = natural_column_widths(column_count, headers, rows)

  case max_widths {
    Some(widths) -> cap_widths(natural, widths)
    None ->
      case table_width {
        Some(width) ->
          cap_widths(natural, distributed_widths(column_count, width))
        None -> natural
      }
  }
}

fn cell_width(cell: String) -> Int {
  let #(width, _) = align.size(cell)
  width
}

fn cap_widths(natural: List(Int), caps: List(Int)) -> List(Int) {
  case natural, caps {
    [], _ -> []
    [width, ..rest], [] -> [width, ..cap_widths(rest, [])]
    [width, ..rest], [cap, ..cap_rest] if cap > 0 -> [
      int.min(width, cap),
      ..cap_widths(rest, cap_rest)
    ]
    [width, ..rest], [_, ..cap_rest] -> [width, ..cap_widths(rest, cap_rest)]
  }
}

fn distributed_widths(column_count: Int, table_width: Int) -> List(Int) {
  let total_cell_width = int.max(1, table_width - { column_count * 3 + 1 })
  let base = int.max(1, total_cell_width / column_count)
  let extra = total_cell_width - { base * column_count }

  distributed_widths_loop(column_count, base, extra, [])
}

fn distributed_widths_loop(
  remaining: Int,
  base: Int,
  extra: Int,
  acc: List(Int),
) -> List(Int) {
  case remaining {
    0 -> list.reverse(acc)
    _ -> {
      let add = case extra > 0 {
        True -> 1
        False -> 0
      }
      distributed_widths_loop(remaining - 1, base, extra - add, [
        base + add,
        ..acc
      ])
    }
  }
}

fn render_header(
  context: Spruce,
  headers: List(String),
  widths: List(Int),
  maybe_style: Option(fn(RowContext, Int) -> style.Style),
  chars: GridChars,
  body: List(String),
) -> List(String) {
  case headers {
    [] -> []
    _ -> {
      let header =
        render_row(context, headers, widths, maybe_style, Header, chars)

      case body {
        [] -> header
        _ -> header |> list.append([render_inner_separator(widths, chars)])
      }
    }
  }
}

fn render_header_plain(
  context: Spruce,
  headers: List(String),
  widths: List(Int),
  maybe_style: Option(fn(RowContext, Int) -> style.Style),
  chars: GridChars,
) -> List(String) {
  case headers {
    [] -> []
    _ -> render_row(context, headers, widths, maybe_style, Header, chars)
  }
}

fn render_body_rows(
  context: Spruce,
  rows: List(List(String)),
  widths: List(Int),
  maybe_style: Option(fn(RowContext, Int) -> style.Style),
  chars: GridChars,
  row_separators: Bool,
  row_index: Int,
) -> List(String) {
  case rows {
    [] -> []
    [row, ..rest] -> {
      let rendered =
        render_row(context, row, widths, maybe_style, Body(row_index), chars)
      let tail =
        render_body_rows(
          context,
          rest,
          widths,
          maybe_style,
          chars,
          row_separators,
          row_index + 1,
        )

      case row_separators, rest {
        True, [_, ..] ->
          rendered
          |> list.append([render_inner_separator(widths, chars)])
          |> list.append(tail)
        _, _ -> rendered |> list.append(tail)
      }
    }
  }
}

fn render_row(
  context: Spruce,
  row: List(String),
  widths: List(Int),
  maybe_style: Option(fn(RowContext, Int) -> style.Style),
  row_context: RowContext,
  chars: GridChars,
) -> List(String) {
  let cells =
    render_cell_lines(context, row, widths, maybe_style, row_context, 0)
  let height = max_cell_height(cells, 1)

  render_row_lines(cells, widths, chars, height, 0, [])
}

fn render_cell_lines(
  context: Spruce,
  row: List(String),
  widths: List(Int),
  maybe_style: Option(fn(RowContext, Int) -> style.Style),
  row_context: RowContext,
  col_index: Int,
) -> List(List(String)) {
  case widths {
    [] -> []
    [width, ..rest] -> {
      let lines =
        cell_at(row, col_index)
        |> wrap_cell(width)
        |> string.split("\n")
        |> list.map(apply_style(_, context, maybe_style, row_context, col_index))

      [
        lines,
        ..render_cell_lines(
          context,
          row,
          rest,
          maybe_style,
          row_context,
          col_index + 1,
        )
      ]
    }
  }
}

fn wrap_cell(cell: String, width: Int) -> String {
  use <- bool.guard(when: width <= 0, return: cell)
  align.wrap(cell, width)
}

fn max_cell_height(cells: List(List(String)), minimum: Int) -> Int {
  cells
  |> list.map(list.length)
  |> list.fold(minimum, int.max)
}

fn render_row_lines(
  cells: List(List(String)),
  widths: List(Int),
  chars: GridChars,
  height: Int,
  index: Int,
  acc: List(String),
) -> List(String) {
  case index >= height {
    True -> list.reverse(acc)
    False -> {
      let line =
        chars.border.left
        <> render_cell_line(cells, widths, chars.border.right, index, 0)
        <> chars.border.right

      render_row_lines(cells, widths, chars, height, index + 1, [line, ..acc])
    }
  }
}

fn render_cell_line(
  cells: List(List(String)),
  widths: List(Int),
  separator: String,
  line_index: Int,
  col_index: Int,
) -> String {
  case widths {
    [] -> ""
    [width, ..rest] -> {
      let content =
        cell_lines_at(cells, col_index)
        |> line_at(line_index)
        |> align.pad_right(width)

      let inner_separator = case rest {
        [] -> ""
        _ -> separator
      }

      " "
      <> content
      <> " "
      <> inner_separator
      <> render_cell_line(cells, rest, separator, line_index, col_index + 1)
    }
  }
}

fn apply_style(
  content: String,
  context: Spruce,
  maybe_style: Option(fn(RowContext, Int) -> style.Style),
  row_context: RowContext,
  col_index: Int,
) -> String {
  case maybe_style {
    None -> content
    Some(style_fn) ->
      style.render(context, style_fn(row_context, col_index), content)
  }
}

fn cell_at(row: List(String), index: Int) -> String {
  case row, index {
    [], _ -> ""
    [cell, ..], 0 -> cell
    [_, ..rest], _ -> cell_at(rest, index - 1)
  }
}

fn cell_lines_at(cells: List(List(String)), index: Int) -> List(String) {
  case cells, index {
    [], _ -> []
    [lines, ..], 0 -> lines
    [_, ..rest], _ -> cell_lines_at(rest, index - 1)
  }
}

fn line_at(lines: List(String), index: Int) -> String {
  case lines, index {
    [], _ -> ""
    [line, ..], 0 -> line
    [_, ..rest], _ -> line_at(rest, index - 1)
  }
}

fn render_top(widths: List(Int), chars: GridChars) -> String {
  render_separator(
    widths,
    chars.border.top_left,
    chars.top_mid,
    chars.border.top_right,
    chars.border.top,
  )
}

fn render_inner_separator(widths: List(Int), chars: GridChars) -> String {
  render_separator(
    widths,
    chars.left_mid,
    chars.cross,
    chars.right_mid,
    chars.border.top,
  )
}

fn render_bottom(widths: List(Int), chars: GridChars) -> String {
  render_separator(
    widths,
    chars.border.bottom_left,
    chars.bottom_mid,
    chars.border.bottom_right,
    chars.border.bottom,
  )
}

fn render_separator(
  widths: List(Int),
  left: String,
  mid: String,
  right: String,
  horizontal: String,
) -> String {
  left <> render_separator_cells(widths, mid, right, horizontal)
}

fn render_separator_cells(
  widths: List(Int),
  mid: String,
  right: String,
  horizontal: String,
) -> String {
  case widths {
    [] -> ""
    [width, ..rest] -> {
      let segment = string.repeat(horizontal, width + 2)
      let separator = case rest {
        [] -> right
        _ -> mid
      }

      segment
      <> separator
      <> render_separator_cells(rest, mid, right, horizontal)
    }
  }
}

fn grid_chars(border: Border) -> GridChars {
  let chars = border.chars(border)

  case border {
    border.Normal | border.Rounded ->
      junctions(chars, top: "┬", left: "├", cross: "┼", right: "┤", bottom: "┴")
    border.Thick ->
      junctions(chars, top: "┳", left: "┣", cross: "╋", right: "┫", bottom: "┻")
    border.Double ->
      junctions(chars, top: "╦", left: "╠", cross: "╬", right: "╣", bottom: "╩")
    border.Block | border.Hidden | border.Custom(_) ->
      junctions(
        chars,
        top: chars.top,
        left: chars.left,
        cross: chars.top,
        right: chars.right,
        bottom: chars.bottom,
      )
  }
}

fn junctions(
  chars: BorderChars,
  top top: String,
  left left: String,
  cross cross: String,
  right right: String,
  bottom bottom: String,
) -> GridChars {
  GridChars(
    border: chars,
    top_mid: top,
    left_mid: left,
    cross: cross,
    right_mid: right,
    bottom_mid: bottom,
  )
}

fn non_negative(value: Int) -> Int {
  int.max(0, value)
}
