//// Block styling for multiline terminal text.

import gleam/bool
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import spruce.{type Spruce}
import spruce/align as text_align
import spruce/box
import spruce/internal/layout as internal_layout
import spruce/layout.{type Pos, Center, End, Start}
import spruce/style

/// Options for rendering a multiline block.
pub opaque type Block {
  Block(
    foreground: Option(style.Color),
    background: Option(style.Color),
    padding_top: Int,
    padding_right: Int,
    padding_bottom: Int,
    padding_left: Int,
    margin_top: Int,
    margin_right: Int,
    margin_bottom: Int,
    margin_left: Int,
    width: Option(Int),
    height: Option(Int),
    horizontal: Pos,
    vertical: Pos,
    border: Option(box.Border),
    border_top_color: style.Color,
    border_right_color: style.Color,
    border_bottom_color: style.Color,
    border_left_color: style.Color,
    border_top: Bool,
    border_right: Bool,
    border_bottom: Bool,
    border_left: Bool,
  )
}

type Sides {
  Sides(top: Bool, right: Bool, bottom: Bool, left: Bool)
}

/// Build block options with no styling, padding, margin, or border.
pub fn new() -> Block {
  Block(
    foreground: None,
    background: None,
    padding_top: 0,
    padding_right: 0,
    padding_bottom: 0,
    padding_left: 0,
    margin_top: 0,
    margin_right: 0,
    margin_bottom: 0,
    margin_left: 0,
    width: None,
    height: None,
    horizontal: Start,
    vertical: Start,
    border: None,
    border_top_color: style.Cyan,
    border_right_color: style.Cyan,
    border_bottom_color: style.Cyan,
    border_left_color: style.Cyan,
    border_top: True,
    border_right: True,
    border_bottom: True,
    border_left: True,
  )
}

/// Set the foreground color applied to content lines.
pub fn foreground(block: Block, color: style.Color) -> Block {
  Block(..block, foreground: Some(color))
}

/// Set the background color applied to content lines.
pub fn background(block: Block, color: style.Color) -> Block {
  Block(..block, background: Some(color))
}

/// Set inner padding as top, right, bottom, left cell counts.
pub fn padding(
  block: Block,
  top: Int,
  right: Int,
  bottom: Int,
  left: Int,
) -> Block {
  Block(
    ..block,
    padding_top: non_negative(top),
    padding_right: non_negative(right),
    padding_bottom: non_negative(bottom),
    padding_left: non_negative(left),
  )
}

/// Set outer margin as top, right, bottom, left cell counts.
pub fn margin(
  block: Block,
  top: Int,
  right: Int,
  bottom: Int,
  left: Int,
) -> Block {
  Block(
    ..block,
    margin_top: non_negative(top),
    margin_right: non_negative(right),
    margin_bottom: non_negative(bottom),
    margin_left: non_negative(left),
  )
}

/// Constrain content to a visual width and wrap with `spruce/align.wrap`.
pub fn width(block: Block, width: Int) -> Block {
  Block(..block, width: Some(non_negative(width)))
}

/// Constrain content to a line count.
/// Short content is padded with blank lines using vertical alignment; tall
/// content is truncated from the bottom after wrapping.
pub fn height(block: Block, height: Int) -> Block {
  Block(..block, height: Some(non_negative(height)))
}

/// Align content horizontally within width and vertically within height.
pub fn align(block: Block, horizontal: Pos, vertical: Pos) -> Block {
  Block(..block, horizontal: horizontal, vertical: vertical)
}

/// Draw a border around the padded block.
pub fn border(block: Block, border: box.Border) -> Block {
  Block(..block, border: Some(border))
}

/// Set top, right, bottom, and left border colors independently.
pub fn border_colors(
  block: Block,
  top: style.Color,
  right: style.Color,
  bottom: style.Color,
  left: style.Color,
) -> Block {
  Block(
    ..block,
    border_top_color: top,
    border_right_color: right,
    border_bottom_color: bottom,
    border_left_color: left,
  )
}

/// Set top, right, bottom, and left border visibility independently.
pub fn border_sides(
  block: Block,
  top: Bool,
  right: Bool,
  bottom: Bool,
  left: Bool,
) -> Block {
  Block(
    ..block,
    border_top: top,
    border_right: right,
    border_bottom: bottom,
    border_left: left,
  )
}

/// Render `content` as one block using the given options.
pub fn render(sp: Spruce, content: String, block: Block) -> String {
  let content_lines = content_region(sp, content, block)
  let padded = apply_padding(sp, content_lines, block)
  let bordered = apply_border(sp, padded, block)

  bordered
  |> apply_margin(
    internal_layout.indent_prefix(sp),
    block.margin_top,
    block.margin_right,
    block.margin_bottom,
    block.margin_left,
  )
  |> string.join("\n")
}

fn content_region(sp: Spruce, content: String, block: Block) -> List(String) {
  let wrapped = case block.width {
    Some(width) if width > 0 -> text_align.wrap(content, width)
    _ -> content
  }
  let raw_lines = string.split(wrapped, "\n")
  let region_width = case block.width {
    Some(width) if width > 0 -> width
    _ -> find_max_width(raw_lines, 0)
  }

  raw_lines
  |> list.map(fn(line) { pad_pos(line, region_width, block.horizontal) })
  |> apply_height(region_width, block.height, block.vertical)
  |> list.map(fn(line) { style.render(sp, foreground_style(block), line) })
}

fn foreground_style(block: Block) -> style.Style {
  case block.foreground {
    Some(color) -> style.fg(style.new(), color)
    None -> style.new()
  }
}

fn background_style(block: Block) -> style.Style {
  case block.background {
    Some(color) -> style.bg(style.new(), color)
    None -> style.new()
  }
}

fn apply_height(
  lines: List(String),
  width: Int,
  height: Option(Int),
  vertical: Pos,
) -> List(String) {
  case height {
    Some(height) -> fit_height(lines, width, height, vertical)
    None -> lines
  }
}

fn fit_height(
  lines: List(String),
  width: Int,
  height: Int,
  vertical: Pos,
) -> List(String) {
  let current = list.length(lines)

  case height <= 0 {
    True -> []
    False ->
      case current > height {
        True -> take_lines(lines, height)
        False -> pad_height(lines, width, height - current, vertical)
      }
  }
}

fn pad_height(
  lines: List(String),
  width: Int,
  extra: Int,
  vertical: Pos,
) -> List(String) {
  let blank = string.repeat(" ", width)
  let #(before, after) = padding_counts(extra, vertical)

  repeat_line(blank, before)
  |> list.append(lines)
  |> list.append(repeat_line(blank, after))
}

fn padding_counts(extra: Int, pos: Pos) -> #(Int, Int) {
  case pos {
    Start -> #(0, extra)
    Center -> {
      let before = extra / 2
      #(before, extra - before)
    }
    End -> #(extra, 0)
  }
}

fn apply_padding(
  sp: Spruce,
  lines: List(String),
  block: Block,
) -> List(String) {
  let content_width = find_max_width(lines, 0)
  let padded_width = content_width + block.padding_left + block.padding_right
  let blank = string.repeat(" ", padded_width)
  let body =
    list.map(lines, fn(line) {
      string.repeat(" ", block.padding_left)
      <> text_align.pad_right(line, content_width)
      <> string.repeat(" ", block.padding_right)
    })

  repeat_line(blank, block.padding_top)
  |> list.append(body)
  |> list.append(repeat_line(blank, block.padding_bottom))
  |> list.map(fn(line) { style.render(sp, background_style(block), line) })
}

fn apply_border(sp: Spruce, lines: List(String), block: Block) -> List(String) {
  case block.border {
    None -> lines
    Some(box.Hidden) -> lines
    Some(border) -> {
      let sides =
        Sides(
          top: block.border_top,
          right: block.border_right,
          bottom: block.border_bottom,
          left: block.border_left,
        )
      let chars = border_chars(border)
      let inner_width = find_max_width(lines, 0)
      let rows =
        list.map(lines, fn(line) { text_align.pad_right(line, inner_width) })
      let paint_top = border_painter(sp, block.border_top_color)
      let paint_right = border_painter(sp, block.border_right_color)
      let paint_bottom = border_painter(sp, block.border_bottom_color)
      let paint_left = border_painter(sp, block.border_left_color)

      rows
      |> add_vertical_sides(sides, chars, paint_left, paint_right)
      |> add_top(sides, inner_width, chars, paint_top)
      |> add_bottom(sides, inner_width, chars, paint_bottom)
    }
  }
}

fn add_vertical_sides(
  lines: List(String),
  sides: Sides,
  chars: box.BorderChars,
  paint_left: fn(String) -> String,
  paint_right: fn(String) -> String,
) -> List(String) {
  list.map(lines, fn(line) {
    side_left(sides, chars, paint_left)
    <> line
    <> side_right(sides, chars, paint_right)
  })
}

fn add_top(
  lines: List(String),
  sides: Sides,
  inner_width: Int,
  chars: box.BorderChars,
  paint_top: fn(String) -> String,
) -> List(String) {
  use <- bool.guard(when: sides.top == False, return: lines)

  [render_top(inner_width, sides, chars, paint_top), ..lines]
}

fn add_bottom(
  lines: List(String),
  sides: Sides,
  inner_width: Int,
  chars: box.BorderChars,
  paint_bottom: fn(String) -> String,
) -> List(String) {
  use <- bool.guard(when: sides.bottom == False, return: lines)

  list.append(lines, [render_bottom(inner_width, sides, chars, paint_bottom)])
}

fn render_top(
  inner_width: Int,
  sides: Sides,
  chars: box.BorderChars,
  paint_top: fn(String) -> String,
) -> String {
  paint_top(corner(sides.top, sides.left, chars.top_left))
  <> paint_top(string.repeat(chars.top, inner_width))
  <> paint_top(corner(sides.top, sides.right, chars.top_right))
}

fn render_bottom(
  inner_width: Int,
  sides: Sides,
  chars: box.BorderChars,
  paint_bottom: fn(String) -> String,
) -> String {
  paint_bottom(corner(sides.bottom, sides.left, chars.bottom_left))
  <> paint_bottom(string.repeat(chars.bottom, inner_width))
  <> paint_bottom(corner(sides.bottom, sides.right, chars.bottom_right))
}

fn side_left(
  sides: Sides,
  chars: box.BorderChars,
  paint_left: fn(String) -> String,
) -> String {
  use <- bool.guard(when: sides.left == False, return: "")

  paint_left(chars.left)
}

fn side_right(
  sides: Sides,
  chars: box.BorderChars,
  paint_right: fn(String) -> String,
) -> String {
  use <- bool.guard(when: sides.right == False, return: "")

  paint_right(chars.right)
}

fn corner(horizontal: Bool, vertical: Bool, char: String) -> String {
  use <- bool.guard(when: horizontal && vertical == False, return: "")

  char
}

fn border_painter(sp: Spruce, color: style.Color) -> fn(String) -> String {
  let border_style = style.new() |> style.fg(color)

  fn(text: String) -> String { style.render(sp, border_style, text) }
}

fn border_chars(border: box.Border) -> box.BorderChars {
  case border {
    box.Normal ->
      box.BorderChars(
        top_left: "┌",
        top: "─",
        top_right: "┐",
        right: "│",
        bottom_right: "┘",
        bottom: "─",
        bottom_left: "└",
        left: "│",
      )
    box.Rounded ->
      box.BorderChars(
        top_left: "╭",
        top: "─",
        top_right: "╮",
        right: "│",
        bottom_right: "╯",
        bottom: "─",
        bottom_left: "╰",
        left: "│",
      )
    box.Thick ->
      box.BorderChars(
        top_left: "┏",
        top: "━",
        top_right: "┓",
        right: "┃",
        bottom_right: "┛",
        bottom: "━",
        bottom_left: "┗",
        left: "┃",
      )
    box.Double ->
      box.BorderChars(
        top_left: "╔",
        top: "═",
        top_right: "╗",
        right: "║",
        bottom_right: "╝",
        bottom: "═",
        bottom_left: "╚",
        left: "║",
      )
    box.Block ->
      box.BorderChars(
        top_left: "█",
        top: "█",
        top_right: "█",
        right: "█",
        bottom_right: "█",
        bottom: "█",
        bottom_left: "█",
        left: "█",
      )
    box.Hidden ->
      box.BorderChars(
        top_left: "",
        top: "",
        top_right: "",
        right: "",
        bottom_right: "",
        bottom: "",
        bottom_left: "",
        left: "",
      )
    box.Custom(chars) -> chars
  }
}

fn apply_margin(
  lines: List(String),
  prefix: String,
  top: Int,
  right: Int,
  bottom: Int,
  left: Int,
) -> List(String) {
  let line_width = find_max_width(lines, 0)
  let blank = string.repeat(" ", left + line_width + right)
  let top_rows = repeat_line(prefix <> blank, top)
  let body =
    list.map(lines, fn(line) {
      prefix
      <> string.repeat(" ", left)
      <> text_align.pad_right(line, line_width)
      <> string.repeat(" ", right)
    })

  top_rows
  |> list.append(body)
  |> list.append(repeat_line(prefix <> blank, bottom))
}

fn pad_pos(text: String, width: Int, pos: Pos) -> String {
  case pos {
    Start -> text_align.pad_right(text, width)
    Center -> text_align.pad_center(text, width)
    End -> text_align.pad_left(text, width)
  }
}

fn find_max_width(lines: List(String), min_width: Int) -> Int {
  lines
  |> list.map(text_align.visual_length)
  |> list.fold(min_width, int.max)
}

fn take_lines(lines: List(String), count: Int) -> List(String) {
  take_lines_loop(lines, non_negative(count), [])
  |> list.reverse
}

fn take_lines_loop(
  lines: List(String),
  count: Int,
  acc: List(String),
) -> List(String) {
  case lines, count {
    _, 0 -> acc
    [], _ -> acc
    [line, ..rest], count -> take_lines_loop(rest, count - 1, [line, ..acc])
  }
}

fn repeat_line(line: String, count: Int) -> List(String) {
  repeat_line_loop(line, non_negative(count), [])
}

fn repeat_line_loop(
  line: String,
  count: Int,
  acc: List(String),
) -> List(String) {
  case count {
    0 -> acc
    _ -> repeat_line_loop(line, count - 1, [line, ..acc])
  }
}

fn non_negative(value: Int) -> Int {
  int.max(0, value)
}
