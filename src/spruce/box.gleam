//// Boxed and styled multiline terminal output.
////
//// A `Box` is a builder that describes how to frame a block of text: inner
//// padding, outer margin, width and height constraints, horizontal and
//// vertical alignment, foreground and background colors, an optional title,
//// and a border with per-side visibility and colors. Build one with `new` (a
//// rounded, cyan border with one cell of horizontal padding) or `plain` (no
//// border, no padding), configure it with the combinators, and render it with
//// `render`.
////
//// ```gleam
//// import spruce
//// import spruce/border
//// import spruce/box
//// import spruce/style
////
//// pub fn main() {
////   let context = spruce.detect()
////
////   box.new()
////   |> box.title("Release")
////   |> box.border(border.Double)
////   |> box.border_color(style.Green)
////   |> box.padding(top: 1, right: 2, bottom: 1, left: 2)
////   |> box.render(context, "spruce 2.0.0\nready to ship", _)
////   |> echo
//// }
//// ```
////
//// Rendered boxes are indented to the context's depth.

import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import spruce.{type Spruce}
import spruce/align.{type Pos, Start}
import spruce/border.{type Border, type BorderChars}
import spruce/style

/// Box rendering options. See the module documentation for the builder.
pub opaque type Box {
  Box(
    title: String,
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
    border: Border,
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

/// A box with a rounded cyan border, one cell of horizontal padding, and no
/// title, margin, size constraints, or content colors.
pub fn new() -> Box {
  Box(
    title: "",
    foreground: None,
    background: None,
    padding_top: 0,
    padding_right: 1,
    padding_bottom: 0,
    padding_left: 1,
    margin_top: 0,
    margin_right: 0,
    margin_bottom: 0,
    margin_left: 0,
    width: None,
    height: None,
    horizontal: Start,
    vertical: Start,
    border: border.Rounded,
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

/// A box with no border and no padding: a bare styled block. Add a border
/// with `border` to frame it.
pub fn plain() -> Box {
  Box(..new(), padding_right: 0, padding_left: 0, border: border.Hidden)
}

/// Set the title shown in the top border. Newlines are replaced by spaces.
/// An empty title (the default) draws an unbroken top border.
pub fn title(box: Box, title: String) -> Box {
  Box(..box, title: title)
}

/// Set the foreground color applied to content lines.
pub fn foreground(box: Box, color: style.Color) -> Box {
  Box(..box, foreground: Some(color))
}

/// Set the background color applied to content lines and padding.
pub fn background(box: Box, color: style.Color) -> Box {
  Box(..box, background: Some(color))
}

/// Set inner padding as top, right, bottom, left cell counts.
pub fn padding(
  box: Box,
  top top: Int,
  right right: Int,
  bottom bottom: Int,
  left left: Int,
) -> Box {
  Box(
    ..box,
    padding_top: non_negative(top),
    padding_right: non_negative(right),
    padding_bottom: non_negative(bottom),
    padding_left: non_negative(left),
  )
}

/// Set outer margin as top, right, bottom, left cell counts.
pub fn margin(
  box: Box,
  top top: Int,
  right right: Int,
  bottom bottom: Int,
  left left: Int,
) -> Box {
  Box(
    ..box,
    margin_top: non_negative(top),
    margin_right: non_negative(right),
    margin_bottom: non_negative(bottom),
    margin_left: non_negative(left),
  )
}

/// Constrain content to a visual width, wrapping with `spruce/align.wrap`.
pub fn width(box: Box, width: Int) -> Box {
  Box(..box, width: Some(non_negative(width)))
}

/// Constrain content to a line count.
/// Short content is padded with blank lines using vertical alignment; tall
/// content is truncated from the bottom after wrapping.
pub fn height(box: Box, height: Int) -> Box {
  Box(..box, height: Some(non_negative(height)))
}

/// Align content horizontally within width and vertically within height.
pub fn align(
  box: Box,
  horizontal horizontal: Pos,
  vertical vertical: Pos,
) -> Box {
  Box(..box, horizontal: horizontal, vertical: vertical)
}

/// Set the border style. `border.Hidden` draws no border at all.
pub fn border(box: Box, border: Border) -> Box {
  Box(..box, border: border)
}

/// Set one color for all four border sides.
pub fn border_color(box: Box, color: style.Color) -> Box {
  border_colors(box, top: color, right: color, bottom: color, left: color)
}

/// Set top, right, bottom, and left border colors independently.
pub fn border_colors(
  box: Box,
  top top: style.Color,
  right right: style.Color,
  bottom bottom: style.Color,
  left left: style.Color,
) -> Box {
  Box(
    ..box,
    border_top_color: top,
    border_right_color: right,
    border_bottom_color: bottom,
    border_left_color: left,
  )
}

/// Set top, right, bottom, and left border visibility independently.
pub fn border_sides(
  box: Box,
  top top: Bool,
  right right: Bool,
  bottom bottom: Bool,
  left left: Bool,
) -> Box {
  Box(
    ..box,
    border_top: top,
    border_right: right,
    border_bottom: bottom,
    border_left: left,
  )
}

/// Render `content` in a default box (`new`).
pub fn simple(context: Spruce, content: String) -> String {
  render(context, content, new())
}

/// Render a default box and print it to stdout.
pub fn print(context: Spruce, content: String) -> Nil {
  io.println(simple(context, content))
}

/// Render `content` with the given box.
pub fn render(context: Spruce, content: String, box: Box) -> String {
  let title = sanitize_title(box.title)

  content_region(context, content, box, title)
  |> apply_padding(context, box)
  |> apply_border(context, box, title)
  |> apply_margin(
    spruce.indent_prefix(context),
    box.margin_top,
    box.margin_right,
    box.margin_bottom,
    box.margin_left,
  )
  |> string.join("\n")
}

// Wrap, size, align, and color the content lines. The title can widen the
// region so it always fits in the top border.
fn content_region(
  context: Spruce,
  content: String,
  box: Box,
  title: String,
) -> List(String) {
  let wrapped = case box.width {
    Some(width) if width > 0 -> align.wrap(content, width)
    Some(_) | None -> content
  }
  let lines = string.split(wrapped, "\n")
  let lines = case box.height {
    Some(height) -> list.take(lines, height)
    None -> lines
  }
  let region_width =
    [
      option.unwrap(box.width, 0),
      find_max_width(lines),
      title_min_width(title) - box.padding_left - box.padding_right,
    ]
    |> list.fold(0, int.max)
  let region_height = option.unwrap(box.height, list.length(lines))
  let placed = case lines {
    [] -> []
    _ ->
      align.place(
        width: region_width,
        height: region_height,
        horizontal: box.horizontal,
        vertical: box.vertical,
        content: string.join(lines, "\n"),
      )
      |> string.split("\n")
  }

  list.map(placed, fn(line) {
    style.render(context, color_style(box.foreground), line)
  })
}

fn title_min_width(title: String) -> Int {
  case title {
    "" -> 0
    _ -> align.visual_length(title) + 3
  }
}

fn color_style(color: Option(style.Color)) -> style.Style {
  case color {
    Some(color) -> style.fg(style.new(), color)
    None -> style.new()
  }
}

fn background_style(box: Box) -> style.Style {
  case box.background {
    Some(color) -> style.bg(style.new(), color)
    None -> style.new()
  }
}

fn apply_padding(
  lines: List(String),
  context: Spruce,
  box: Box,
) -> List(String) {
  let content_width = find_max_width(lines)
  let padded_width = content_width + box.padding_left + box.padding_right
  let blank = string.repeat(" ", padded_width)
  let body =
    list.map(lines, fn(line) {
      string.repeat(" ", box.padding_left)
      <> align.pad_right(line, content_width)
      <> string.repeat(" ", box.padding_right)
    })

  list.repeat(blank, box.padding_top)
  |> list.append(body)
  |> list.append(list.repeat(blank, box.padding_bottom))
  |> list.map(fn(line) { style.render(context, background_style(box), line) })
}

fn apply_border(
  lines: List(String),
  context: Spruce,
  box: Box,
  title: String,
) -> List(String) {
  use <- bool.guard(when: box.border == border.Hidden, return: lines)

  let sides =
    Sides(
      top: box.border_top,
      right: box.border_right,
      bottom: box.border_bottom,
      left: box.border_left,
    )
  let chars = border.chars(box.border)
  let inner_width = find_max_width(lines)
  let paint_top = border_painter(context, box.border_top_color)
  let paint_right = border_painter(context, box.border_right_color)
  let paint_bottom = border_painter(context, box.border_bottom_color)
  let paint_left = border_painter(context, box.border_left_color)

  lines
  |> list.map(fn(line) {
    side_left(sides, chars, paint_left)
    <> align.pad_right(line, inner_width)
    <> side_right(sides, chars, paint_right)
  })
  |> add_top(sides, inner_width, chars, paint_top, title)
  |> add_bottom(sides, inner_width, chars, paint_bottom)
}

fn add_top(
  lines: List(String),
  sides: Sides,
  inner_width: Int,
  chars: BorderChars,
  paint_top: fn(String) -> String,
  title: String,
) -> List(String) {
  use <- bool.guard(when: !sides.top, return: lines)

  let left = corner(sides.left, chars.top_left)
  let right = corner(sides.right, chars.top_right)
  let top = case title {
    "" -> paint_top(left <> string.repeat(chars.top, inner_width) <> right)
    _ ->
      paint_top(left <> chars.top)
      <> " "
      <> title
      <> " "
      <> paint_top(
        string.repeat(
          chars.top,
          int.max(0, inner_width - align.visual_length(title) - 3),
        )
        <> right,
      )
  }

  [top, ..lines]
}

fn add_bottom(
  lines: List(String),
  sides: Sides,
  inner_width: Int,
  chars: BorderChars,
  paint_bottom: fn(String) -> String,
) -> List(String) {
  use <- bool.guard(when: !sides.bottom, return: lines)

  let bottom =
    paint_bottom(
      corner(sides.left, chars.bottom_left)
      <> string.repeat(chars.bottom, inner_width)
      <> corner(sides.right, chars.bottom_right),
    )

  list.append(lines, [bottom])
}

fn corner(adjoining_side: Bool, char: String) -> String {
  use <- bool.guard(when: !adjoining_side, return: "")
  char
}

fn side_left(
  sides: Sides,
  chars: BorderChars,
  paint_left: fn(String) -> String,
) -> String {
  use <- bool.guard(when: !sides.left, return: "")
  paint_left(chars.left)
}

fn side_right(
  sides: Sides,
  chars: BorderChars,
  paint_right: fn(String) -> String,
) -> String {
  use <- bool.guard(when: !sides.right, return: "")
  paint_right(chars.right)
}

fn border_painter(context: Spruce, color: style.Color) -> fn(String) -> String {
  let border_style = style.new() |> style.fg(color)

  fn(text: String) -> String { style.render(context, border_style, text) }
}

fn apply_margin(
  lines: List(String),
  prefix: String,
  top: Int,
  right: Int,
  bottom: Int,
  left: Int,
) -> List(String) {
  let line_width = find_max_width(lines)
  let blank = string.repeat(" ", left + line_width + right)
  let body =
    list.map(lines, fn(line) {
      prefix
      <> string.repeat(" ", left)
      <> align.pad_right(line, line_width)
      <> string.repeat(" ", right)
    })

  list.repeat(prefix <> blank, top)
  |> list.append(body)
  |> list.append(list.repeat(prefix <> blank, bottom))
}

fn sanitize_title(title: String) -> String {
  title
  |> string.replace(each: "\r\n", with: " ")
  |> string.replace(each: "\n", with: " ")
  |> string.replace(each: "\r", with: " ")
}

fn find_max_width(lines: List(String)) -> Int {
  lines
  |> list.map(align.visual_length)
  |> list.fold(0, int.max)
}

fn non_negative(value: Int) -> Int {
  int.max(0, value)
}
