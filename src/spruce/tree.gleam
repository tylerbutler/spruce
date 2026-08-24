//// Pure nested tree rendering.
////
//// Trees use Unicode branches by default, independent of color support.
//// Call `ascii` for an ASCII fallback or `branches` for custom glyphs.

import gleam/bool
import gleam/int
import gleam/list
import gleam/string
import spruce.{type Spruce}
import spruce/align

/// The four tokens used to draw tree branches.
pub type BranchChars {
  BranchChars(
    branch_mid: String,
    branch_last: String,
    pipe: String,
    blank: String,
  )
}

type BranchStyle {
  Unicode
  Ascii
  Custom(BranchChars)
}

type TableRow {
  TableRow(prefix: String, follow: String, label: String, columns: List(String))
}

/// A nested labelled tree.
pub opaque type Tree {
  Tree(
    label: String,
    columns: List(String),
    children: List(Tree),
    branch_style: BranchStyle,
  )
}

/// Build a tree root with no children.
pub fn root(label: String) -> Tree {
  Tree(label: label, columns: [], children: [], branch_style: Unicode)
}

/// Add a child to `parent`, preserving insertion order.
pub fn child(parent: Tree, child child: Tree) -> Tree {
  Tree(..parent, children: list.append(parent.children, [child]))
}

/// Set cells that `render_table` places after this node's label.
pub fn columns(tree: Tree, columns: List(String)) -> Tree {
  Tree(..tree, columns:)
}

/// Force Unicode branch markers regardless of color support.
pub fn unicode(tree: Tree) -> Tree {
  Tree(..tree, branch_style: Unicode)
}

/// Force deterministic ASCII branch markers.
pub fn ascii(tree: Tree) -> Tree {
  Tree(..tree, branch_style: Ascii)
}

/// Set all four branch tokens used to render the tree.
pub fn branches(tree: Tree, chars: BranchChars) -> Tree {
  Tree(..tree, branch_style: Custom(chars))
}

/// Render a tree to a string.
pub fn render(sp: Spruce, tree: Tree) -> String {
  render_with(sp, tree, fn(label, _prefix_width, _depth, _last) { label })
}

/// Render a tree with a function that can transform each label.
///
/// The function receives the label, its prefix's visual width, its zero-based
/// depth, and whether it is the last child. The root has depth zero and is
/// always marked as last.
pub fn render_with(
  sp: Spruce,
  tree: Tree,
  render_label: fn(String, Int, Int, Bool) -> String,
) -> String {
  let base = spruce.indent_prefix(sp)
  let lines =
    render_label(tree.label, align.visual_length(base), 0, True)
    |> label_lines(base, base, _)
    |> list.append(render_children(
      tree.children,
      tree.branch_style,
      1,
      [],
      base,
      render_label,
    ))

  string.join(lines, "\n")
}

/// Render labels and their `columns` as an aligned, borderless table.
///
/// The tree label is the first column. Cell widths are ANSI-aware, and
/// multi-line labels and cells preserve the tree's continuation guides.
pub fn render_table(sp: Spruce, tree: Tree) -> String {
  let base = spruce.indent_prefix(sp)
  let rows = [
    TableRow(
      prefix: base,
      follow: base,
      label: tree.label,
      columns: tree.columns,
    ),
    ..table_child_rows(tree.children, tree.branch_style, [], base)
  ]
  let column_count =
    rows
    |> list.map(fn(row) { list.length(row.columns) })
    |> list.fold(0, int.max)

  case column_count {
    0 -> render(sp, tree)
    _ -> {
      let first_width = first_column_width(rows)
      let widths = table_column_widths(rows, column_count, 0)

      rows
      |> list.flat_map(render_table_row(_, first_width, widths))
      |> string.join("\n")
    }
  }
}

fn render_children(
  children: List(Tree),
  branch_style: BranchStyle,
  depth: Int,
  ancestors: List(Bool),
  base: String,
  render_label: fn(String, Int, Int, Bool) -> String,
) -> List(String) {
  case children {
    [] -> []
    [last_child] ->
      render_node(
        last_child,
        branch_style,
        depth,
        ancestors,
        base,
        True,
        render_label,
      )
    [first, ..rest] ->
      render_node(
        first,
        branch_style,
        depth,
        ancestors,
        base,
        False,
        render_label,
      )
      |> list.append(render_children(
        rest,
        branch_style,
        depth,
        ancestors,
        base,
        render_label,
      ))
  }
}

fn render_node(
  tree: Tree,
  branch_style: BranchStyle,
  depth: Int,
  ancestors: List(Bool),
  base: String,
  last: Bool,
  render_label: fn(String, Int, Int, Bool) -> String,
) -> List(String) {
  let ancestor = ancestor_prefix(branch_style, ancestors)
  let prefix = base <> ancestor <> branch_token(branch_style, last)
  let follow = base <> ancestor <> ancestor_token(branch_style, last)
  let label = render_label(tree.label, align.visual_length(prefix), depth, last)

  label_lines(prefix, follow, label)
  |> list.append(render_children(
    tree.children,
    branch_style,
    depth + 1,
    list.append(ancestors, [last]),
    base,
    render_label,
  ))
}

fn label_lines(prefix: String, follow: String, label: String) -> List(String) {
  case string.split(label, "\n") {
    [] -> [prefix]
    [first, ..rest] -> [
      prefix <> first,
      ..list.map(rest, fn(line) { follow <> line })
    ]
  }
}

fn table_child_rows(
  children: List(Tree),
  branch_style: BranchStyle,
  ancestors: List(Bool),
  base: String,
) -> List(TableRow) {
  case children {
    [] -> []
    [last_child] ->
      table_node_rows(last_child, branch_style, ancestors, base, True)
    [first, ..rest] ->
      table_node_rows(first, branch_style, ancestors, base, False)
      |> list.append(table_child_rows(rest, branch_style, ancestors, base))
  }
}

fn table_node_rows(
  tree: Tree,
  branch_style: BranchStyle,
  ancestors: List(Bool),
  base: String,
  last: Bool,
) -> List(TableRow) {
  let ancestor = ancestor_prefix(branch_style, ancestors)
  let row =
    TableRow(
      prefix: base <> ancestor <> branch_token(branch_style, last),
      follow: base <> ancestor <> ancestor_token(branch_style, last),
      label: tree.label,
      columns: tree.columns,
    )

  [
    row,
    ..table_child_rows(
      tree.children,
      branch_style,
      list.append(ancestors, [last]),
      base,
    )
  ]
}

fn render_table_row(
  row: TableRow,
  first_width: Int,
  widths: List(Int),
) -> List(String) {
  let label_lines = string.split(row.label, "\n")
  let column_lines =
    list.map(row.columns, fn(cell) { string.split(cell, "\n") })
  let height =
    column_lines
    |> list.map(list.length)
    |> list.fold(list.length(label_lines), int.max)

  render_table_row_lines(
    row,
    label_lines,
    column_lines,
    first_width,
    widths,
    0,
    height,
  )
}

fn render_table_row_lines(
  row: TableRow,
  label_lines: List(String),
  column_lines: List(List(String)),
  first_width: Int,
  widths: List(Int),
  index: Int,
  height: Int,
) -> List(String) {
  case index >= height {
    True -> []
    False -> {
      let prefix = case index {
        0 -> row.prefix
        _ -> row.follow
      }
      let label = line_at(label_lines, index)
      let first =
        prefix
        <> align.pad_right(label, first_width - align.visual_length(prefix))
      let rest = render_table_columns(column_lines, widths, index)

      [
        first <> rest,
        ..render_table_row_lines(
          row,
          label_lines,
          column_lines,
          first_width,
          widths,
          index + 1,
          height,
        )
      ]
    }
  }
}

fn render_table_columns(
  columns: List(List(String)),
  widths: List(Int),
  line: Int,
) -> String {
  case columns, widths {
    [], _ -> ""
    _, [] -> ""
    [cell, ..rest], [width, ..rest_widths] -> {
      let value = line_at(cell, line)
      case rest {
        [] -> "  " <> value
        _ ->
          "  "
          <> align.pad_right(value, width)
          <> render_table_columns(rest, rest_widths, line)
      }
    }
  }
}

fn first_column_width(rows: List(TableRow)) -> Int {
  list.fold(rows, 0, fn(width, row) {
    let prefix_width =
      int.max(align.visual_length(row.prefix), align.visual_length(row.follow))
    int.max(width, prefix_width + cell_width(row.label))
  })
}

fn table_column_widths(
  rows: List(TableRow),
  column_count: Int,
  index: Int,
) -> List(Int) {
  case index >= column_count {
    True -> []
    False -> {
      let width =
        rows
        |> list.map(fn(row) { cell_at(row.columns, index) |> cell_width })
        |> list.fold(0, int.max)

      [width, ..table_column_widths(rows, column_count, index + 1)]
    }
  }
}

fn cell_width(cell: String) -> Int {
  cell
  |> string.split("\n")
  |> list.map(align.visual_length)
  |> list.fold(0, int.max)
}

fn cell_at(cells: List(String), index: Int) -> String {
  case cells, index {
    [], _ -> ""
    [cell, ..], 0 -> cell
    [_, ..rest], _ -> cell_at(rest, index - 1)
  }
}

fn line_at(lines: List(String), index: Int) -> String {
  case lines, index {
    [], _ -> ""
    [line, ..], 0 -> line
    [_, ..rest], _ -> line_at(rest, index - 1)
  }
}

fn ancestor_prefix(branch_style: BranchStyle, ancestors: List(Bool)) -> String {
  case ancestors {
    [] -> ""
    [last, ..rest] ->
      ancestor_token(branch_style, last) <> ancestor_prefix(branch_style, rest)
  }
}

fn branch_token(branch_style: BranchStyle, last: Bool) -> String {
  let chars = branch_chars(branch_style)
  use <- bool.guard(when: last, return: chars.branch_last)
  chars.branch_mid
}

fn ancestor_token(branch_style: BranchStyle, last: Bool) -> String {
  let chars = branch_chars(branch_style)
  use <- bool.guard(when: last, return: chars.blank)
  chars.pipe
}

fn branch_chars(branch_style: BranchStyle) -> BranchChars {
  case branch_style {
    Unicode ->
      BranchChars(
        branch_mid: "├─ ",
        branch_last: "└─ ",
        pipe: "│  ",
        blank: "   ",
      )
    Ascii ->
      BranchChars(
        branch_mid: "|- ",
        branch_last: "`- ",
        pipe: "|  ",
        blank: "   ",
      )
    Custom(chars) -> chars
  }
}
