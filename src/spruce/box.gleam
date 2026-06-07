//// Boxed terminal output with rounded borders and an optional title.

import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import spruce.{type Spruce}
import spruce/align
import spruce/internal/layout
import spruce/style

/// The characters used to draw a visible border.
pub type BorderChars {
  BorderChars(
    top_left: String,
    top: String,
    top_right: String,
    right: String,
    bottom_right: String,
    bottom: String,
    bottom_left: String,
    left: String,
  )
}

/// The border style used by a box.
pub type Border {
  Normal
  Rounded
  Thick
  Double
  Hidden
  Block
  Custom(BorderChars)
}

/// Box rendering options.
pub opaque type BoxOptions {
  BoxOptions(
    /// Title shown in the top border (empty string for no title).
    title: String,
    /// Border color.
    color: style.Color,
  )
  ConfiguredBoxOptions(
    /// Title shown in the top border (empty string for no title).
    title: String,
    /// Border color.
    color: style.Color,
    padding_top: Int,
    padding_right: Int,
    padding_bottom: Int,
    padding_left: Int,
    margin_top: Int,
    margin_right: Int,
    margin_bottom: Int,
    margin_left: Int,
    border: Border,
    width: Option(Int),
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

type BoxConfig {
  BoxConfig(
    title: String,
    color: style.Color,
    padding_top: Int,
    padding_right: Int,
    padding_bottom: Int,
    padding_left: Int,
    margin_top: Int,
    margin_right: Int,
    margin_bottom: Int,
    margin_left: Int,
    border: Border,
    width: Option(Int),
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

/// Default options: no title, cyan border.
pub fn default_options() -> BoxOptions {
  BoxOptions(title: "", color: style.Cyan)
}

/// Build options with an explicit title and border color.
pub fn options(title title: String, color color: style.Color) -> BoxOptions {
  BoxOptions(title: title, color: color)
}

/// Set inner padding as top, right, bottom, left cell counts.
pub fn padding(
  options: BoxOptions,
  top: Int,
  right: Int,
  bottom: Int,
  left: Int,
) -> BoxOptions {
  let config = box_config(options)

  configured(
    BoxConfig(
      ..config,
      padding_top: non_negative(top),
      padding_right: non_negative(right),
      padding_bottom: non_negative(bottom),
      padding_left: non_negative(left),
    ),
  )
}

/// Set outer margin as top, right, bottom, left cell counts.
pub fn margin(
  options: BoxOptions,
  top: Int,
  right: Int,
  bottom: Int,
  left: Int,
) -> BoxOptions {
  let config = box_config(options)

  configured(
    BoxConfig(
      ..config,
      margin_top: non_negative(top),
      margin_right: non_negative(right),
      margin_bottom: non_negative(bottom),
      margin_left: non_negative(left),
    ),
  )
}

/// Set the border style.
pub fn border(options: BoxOptions, border: Border) -> BoxOptions {
  let config = box_config(options)
  configured(BoxConfig(..config, border: border))
}

/// Set top, right, bottom, and left border colors independently.
pub fn border_colors(
  options: BoxOptions,
  top: style.Color,
  right: style.Color,
  bottom: style.Color,
  left: style.Color,
) -> BoxOptions {
  let config = box_config(options)

  configured(
    BoxConfig(
      ..config,
      border_top_color: top,
      border_right_color: right,
      border_bottom_color: bottom,
      border_left_color: left,
    ),
  )
}

/// Set top, right, bottom, and left border visibility independently.
pub fn border_sides(
  options: BoxOptions,
  top: Bool,
  right: Bool,
  bottom: Bool,
  left: Bool,
) -> BoxOptions {
  let config = box_config(options)

  configured(
    BoxConfig(
      ..config,
      border_top: top,
      border_right: right,
      border_bottom: bottom,
      border_left: left,
    ),
  )
}

/// Constrain content to a visual width, wrapping with `spruce/align.wrap`.
pub fn width(options: BoxOptions, width: Int) -> BoxOptions {
  let config = box_config(options)
  configured(BoxConfig(..config, width: Some(non_negative(width))))
}

/// Render `content` in a box using the default options.
pub fn simple(sp: Spruce, content: String) -> String {
  render(sp, content, default_options())
}

/// Render `content` in a box with the given options.
pub fn render(sp: Spruce, content: String, options: BoxOptions) -> String {
  let config = box_config(options)
  let prefix = layout.indent_prefix(sp)
  let sides = effective_sides(config)
  let lines =
    content
    |> wrap_content(config.width)
    |> string.split("\n")
  let title = sanitize_title(config.title)
  let title_width = align.visual_length(title)
  let title_min_width = case title {
    "" -> 0
    _ -> title_width + 3
  }
  let content_width = find_max_width(lines, 0)
  let padded_content_width =
    content_width + config.padding_left + config.padding_right
  let inner_width = int.max(padded_content_width, title_min_width)
  let text_width = inner_width - config.padding_left - config.padding_right
  let chars = border_chars(config.border)
  let paint_top = border_painter(sp, config.border_top_color)
  let paint_right = border_painter(sp, config.border_right_color)
  let paint_bottom = border_painter(sp, config.border_bottom_color)
  let paint_left = border_painter(sp, config.border_left_color)

  let body =
    list.append(
      blank_rows(
        config.padding_top,
        inner_width,
        sides,
        chars,
        paint_left,
        paint_right,
      ),
      {
        let content_rows =
          list.map(lines, fn(line) {
            render_body_line(
              line,
              text_width,
              config.padding_left,
              config.padding_right,
              sides,
              chars,
              paint_left,
              paint_right,
            )
          })

        list.append(
          content_rows,
          blank_rows(
            config.padding_bottom,
            inner_width,
            sides,
            chars,
            paint_left,
            paint_right,
          ),
        )
      },
    )

  let boxed =
    case sides.top {
      True -> [
        render_top(title, title_width, inner_width, sides, chars, paint_top),
        ..body
      ]
      False -> body
    }
    |> append_bottom(sides, inner_width, chars, paint_bottom)

  boxed
  |> apply_margin(
    prefix,
    config.margin_top,
    config.margin_right,
    config.margin_bottom,
    config.margin_left,
  )
  |> string.join("\n")
}

fn box_config(options: BoxOptions) -> BoxConfig {
  case options {
    BoxOptions(title, color) -> default_config(title, color)
    ConfiguredBoxOptions(
      title,
      color,
      padding_top,
      padding_right,
      padding_bottom,
      padding_left,
      margin_top,
      margin_right,
      margin_bottom,
      margin_left,
      border,
      width,
      border_top_color,
      border_right_color,
      border_bottom_color,
      border_left_color,
      border_top,
      border_right,
      border_bottom,
      border_left,
    ) ->
      BoxConfig(
        title: title,
        color: color,
        padding_top: padding_top,
        padding_right: padding_right,
        padding_bottom: padding_bottom,
        padding_left: padding_left,
        margin_top: margin_top,
        margin_right: margin_right,
        margin_bottom: margin_bottom,
        margin_left: margin_left,
        border: border,
        width: width,
        border_top_color: border_top_color,
        border_right_color: border_right_color,
        border_bottom_color: border_bottom_color,
        border_left_color: border_left_color,
        border_top: border_top,
        border_right: border_right,
        border_bottom: border_bottom,
        border_left: border_left,
      )
  }
}

fn default_config(title: String, color: style.Color) -> BoxConfig {
  BoxConfig(
    title: title,
    color: color,
    padding_top: 0,
    padding_right: 1,
    padding_bottom: 0,
    padding_left: 1,
    margin_top: 0,
    margin_right: 0,
    margin_bottom: 0,
    margin_left: 0,
    border: Rounded,
    width: None,
    border_top_color: color,
    border_right_color: color,
    border_bottom_color: color,
    border_left_color: color,
    border_top: True,
    border_right: True,
    border_bottom: True,
    border_left: True,
  )
}

fn configured(config: BoxConfig) -> BoxOptions {
  ConfiguredBoxOptions(
    title: config.title,
    color: config.color,
    padding_top: config.padding_top,
    padding_right: config.padding_right,
    padding_bottom: config.padding_bottom,
    padding_left: config.padding_left,
    margin_top: config.margin_top,
    margin_right: config.margin_right,
    margin_bottom: config.margin_bottom,
    margin_left: config.margin_left,
    border: config.border,
    width: config.width,
    border_top_color: config.border_top_color,
    border_right_color: config.border_right_color,
    border_bottom_color: config.border_bottom_color,
    border_left_color: config.border_left_color,
    border_top: config.border_top,
    border_right: config.border_right,
    border_bottom: config.border_bottom,
    border_left: config.border_left,
  )
}

fn effective_sides(config: BoxConfig) -> Sides {
  case config.border {
    Hidden -> Sides(top: False, right: False, bottom: False, left: False)
    _ ->
      Sides(
        top: config.border_top,
        right: config.border_right,
        bottom: config.border_bottom,
        left: config.border_left,
      )
  }
}

fn border_chars(border: Border) -> BorderChars {
  case border {
    Normal ->
      BorderChars(
        top_left: "┌",
        top: "─",
        top_right: "┐",
        right: "│",
        bottom_right: "┘",
        bottom: "─",
        bottom_left: "└",
        left: "│",
      )
    Rounded ->
      BorderChars(
        top_left: "╭",
        top: "─",
        top_right: "╮",
        right: "│",
        bottom_right: "╯",
        bottom: "─",
        bottom_left: "╰",
        left: "│",
      )
    Thick ->
      BorderChars(
        top_left: "┏",
        top: "━",
        top_right: "┓",
        right: "┃",
        bottom_right: "┛",
        bottom: "━",
        bottom_left: "┗",
        left: "┃",
      )
    Double ->
      BorderChars(
        top_left: "╔",
        top: "═",
        top_right: "╗",
        right: "║",
        bottom_right: "╝",
        bottom: "═",
        bottom_left: "╚",
        left: "║",
      )
    Block ->
      BorderChars(
        top_left: "█",
        top: "█",
        top_right: "█",
        right: "█",
        bottom_right: "█",
        bottom: "█",
        bottom_left: "█",
        left: "█",
      )
    Hidden ->
      BorderChars(
        top_left: "",
        top: "",
        top_right: "",
        right: "",
        bottom_right: "",
        bottom: "",
        bottom_left: "",
        left: "",
      )
    Custom(chars) -> chars
  }
}

fn wrap_content(content: String, width: Option(Int)) -> String {
  case width {
    Some(width) if width > 0 -> align.wrap(content, width)
    _ -> content
  }
}

fn sanitize_title(title: String) -> String {
  title
  |> string.replace(each: "\r\n", with: " ")
  |> string.replace(each: "\n", with: " ")
  |> string.replace(each: "\r", with: " ")
}

fn border_painter(sp: Spruce, color: style.Color) -> fn(String) -> String {
  let border_style = style.new() |> style.fg(color)

  fn(text: String) -> String { style.render(sp, border_style, text) }
}

fn append_bottom(
  lines: List(String),
  sides: Sides,
  inner_width: Int,
  chars: BorderChars,
  paint_bottom: fn(String) -> String,
) -> List(String) {
  use <- bool.guard(when: sides.bottom == False, return: lines)

  list.append(lines, [render_bottom(inner_width, sides, chars, paint_bottom)])
}

fn render_top(
  title: String,
  title_width: Int,
  inner_width: Int,
  sides: Sides,
  chars: BorderChars,
  paint_top: fn(String) -> String,
) -> String {
  let left = case sides.left {
    True -> chars.top_left
    False -> ""
  }
  let right = case sides.right {
    True -> chars.top_right
    False -> ""
  }

  case title {
    "" -> paint_top(left <> string.repeat(chars.top, inner_width) <> right)
    title ->
      paint_top(left <> chars.top)
      <> " "
      <> title
      <> " "
      <> paint_top(
        string.repeat(chars.top, int.max(0, inner_width - title_width - 3))
        <> right,
      )
  }
}

fn render_bottom(
  inner_width: Int,
  sides: Sides,
  chars: BorderChars,
  paint_bottom: fn(String) -> String,
) -> String {
  let left = case sides.left {
    True -> chars.bottom_left
    False -> ""
  }
  let right = case sides.right {
    True -> chars.bottom_right
    False -> ""
  }

  paint_bottom(left <> string.repeat(chars.bottom, inner_width) <> right)
}

fn render_body_line(
  line: String,
  text_width: Int,
  padding_left: Int,
  padding_right: Int,
  sides: Sides,
  chars: BorderChars,
  paint_left: fn(String) -> String,
  paint_right: fn(String) -> String,
) -> String {
  let inner =
    string.repeat(" ", padding_left)
    <> align.pad_right(line, text_width)
    <> string.repeat(" ", padding_right)

  side_left(sides, chars, paint_left)
  <> inner
  <> side_right(sides, chars, paint_right)
}

fn blank_rows(
  count: Int,
  inner_width: Int,
  sides: Sides,
  chars: BorderChars,
  paint_left: fn(String) -> String,
  paint_right: fn(String) -> String,
) -> List(String) {
  repeat_line(
    render_blank_row(inner_width, sides, chars, paint_left, paint_right),
    count,
  )
}

fn render_blank_row(
  inner_width: Int,
  sides: Sides,
  chars: BorderChars,
  paint_left: fn(String) -> String,
  paint_right: fn(String) -> String,
) -> String {
  let inner = string.repeat(" ", inner_width)

  side_left(sides, chars, paint_left)
  <> inner
  <> side_right(sides, chars, paint_right)
}

fn side_left(
  sides: Sides,
  chars: BorderChars,
  paint_left: fn(String) -> String,
) -> String {
  use <- bool.guard(when: sides.left == False, return: "")

  paint_left(chars.left)
}

fn side_right(
  sides: Sides,
  chars: BorderChars,
  paint_right: fn(String) -> String,
) -> String {
  use <- bool.guard(when: sides.right == False, return: "")

  paint_right(chars.right)
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
      <> align.pad_right(line, line_width)
      <> string.repeat(" ", right)
    })

  top_rows
  |> list.append(body)
  |> list.append(repeat_line(prefix <> blank, bottom))
}

fn find_max_width(lines: List(String), min_width: Int) -> Int {
  lines
  |> list.map(align.visual_length)
  |> list.fold(min_width, int.max)
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

/// Render a default box and print it to stdout.
pub fn print(sp: Spruce, content: String) -> Nil {
  io.println(simple(sp, content))
}
