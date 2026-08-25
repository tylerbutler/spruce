import gleam/option.{type Option, None, Some}
import spruce.{type Spruce}
import spruce/border
import spruce/box
import spruce/message as messages
import spruce/style
import spruce/table

/// Browser-facing color capability choices for pre-rendering ANSI strings.
pub type Capability {
  NoColor
  Basic
  Ansi256
  TrueColor
}

/// The supported semantic message variants.
pub type Message {
  Success
  Fail
  Start
  Ready
  Info
  Warn
  Error
}

/// A bounded workbench color description.
pub type Color {
  Black
  Red
  Green
  Yellow
  Blue
  Magenta
  Cyan
  White
  Gray
  BrightRed
  BrightGreen
  BrightYellow
  BrightBlue
  BrightMagenta
  BrightCyan
  BrightWhite
  Hex(Int)
  Color256(Int)
  Complete(ansi: Color, ansi256: Color, truecolor: Color)
}

/// The supported visible border styles for workbench-owned configs.
pub type BorderStyle {
  Normal
  Rounded
  Thick
  Double
  Hidden
  Block
}

type BoxBase {
  Framed
  Plain
}

/// Bounded style controls owned by the workbench facade.
pub opaque type StyleConfig {
  StyleConfig(
    foreground: Option(Color),
    background: Option(Color),
    bold: Bool,
    italic: Bool,
    underline: Bool,
  )
}

/// Bounded box controls owned by the workbench facade.
pub opaque type BoxConfig {
  BoxConfig(
    base: BoxBase,
    title: String,
    padding_top: Int,
    padding_right: Int,
    padding_bottom: Int,
    padding_left: Int,
    width: Option(Int),
    height: Option(Int),
    border: BorderStyle,
    border_color: Option(Color),
  )
}

/// Bounded table controls owned by the workbench facade.
pub opaque type TableConfig {
  TableConfig(
    headers: List(String),
    rows: List(List(String)),
    width: Option(Int),
    column_widths: Option(List(Int)),
    border: BorderStyle,
    row_separators: Bool,
  )
}

/// Render a semantic message line for the chosen browser capability.
pub fn render_message(
  capability: Capability,
  message: Message,
  text: String,
) -> String {
  let context = context(capability)

  case message {
    Success -> messages.success(context, text)
    Fail -> messages.fail(context, text)
    Start -> messages.start(context, text)
    Ready -> messages.ready(context, text)
    Info -> messages.info(context, text)
    Warn -> messages.warn(context, text)
    Error -> messages.error(context, text)
  }
}

/// Create an empty bounded style config.
pub fn new_style() -> StyleConfig {
  StyleConfig(None, None, False, False, False)
}

/// Set the bounded foreground color.
pub fn style_fg(config: StyleConfig, color: Color) -> StyleConfig {
  StyleConfig(..config, foreground: Some(color))
}

/// Set the bounded background color.
pub fn style_bg(config: StyleConfig, color: Color) -> StyleConfig {
  StyleConfig(..config, background: Some(color))
}

/// Enable bold text.
pub fn style_bold(config: StyleConfig) -> StyleConfig {
  StyleConfig(..config, bold: True)
}

/// Enable italic text.
pub fn style_italic(config: StyleConfig) -> StyleConfig {
  StyleConfig(..config, italic: True)
}

/// Enable underlined text.
pub fn style_underline(config: StyleConfig) -> StyleConfig {
  StyleConfig(..config, underline: True)
}

/// Build a color with explicit variants per color level.
pub fn complete_color(
  ansi ansi: Color,
  ansi256 ansi256: Color,
  truecolor truecolor: Color,
) -> Color {
  Complete(ansi:, ansi256:, truecolor:)
}

/// Render styled text for the chosen browser capability.
pub fn render_style(
  capability: Capability,
  text_style: StyleConfig,
  text: String,
) -> String {
  style.render(context(capability), to_spruce_style(text_style), text)
}

/// Create a framed box config.
pub fn new_box() -> BoxConfig {
  BoxConfig(Framed, "", 0, 1, 0, 1, None, None, Rounded, None)
}

/// Create a plain box config with no border and no padding.
pub fn plain_box() -> BoxConfig {
  BoxConfig(Plain, "", 0, 0, 0, 0, None, None, Hidden, None)
}

/// Set the box title.
pub fn box_title(config: BoxConfig, title: String) -> BoxConfig {
  BoxConfig(..config, title: title)
}

/// Set box padding.
pub fn box_padding(
  config: BoxConfig,
  top top: Int,
  right right: Int,
  bottom bottom: Int,
  left left: Int,
) -> BoxConfig {
  BoxConfig(
    ..config,
    padding_top: top,
    padding_right: right,
    padding_bottom: bottom,
    padding_left: left,
  )
}

/// Set the box width.
pub fn box_width(config: BoxConfig, width: Int) -> BoxConfig {
  BoxConfig(..config, width: Some(width))
}

/// Set the box height.
pub fn box_height(config: BoxConfig, height: Int) -> BoxConfig {
  BoxConfig(..config, height: Some(height))
}

/// Set the box border style.
pub fn box_border(config: BoxConfig, border: BorderStyle) -> BoxConfig {
  BoxConfig(..config, border: border)
}

/// Set one color for all four box border sides.
pub fn box_border_color(config: BoxConfig, color: Color) -> BoxConfig {
  BoxConfig(..config, border_color: Some(color))
}

/// Render a box for the chosen browser capability.
pub fn render_box(
  capability: Capability,
  content: String,
  options: BoxConfig,
) -> String {
  box.render(context(capability), content, to_spruce_box(options))
}

/// Create an empty table config.
pub fn new_table() -> TableConfig {
  TableConfig([], [], None, None, Normal, False)
}

/// Set the header row.
pub fn table_headers(
  config: TableConfig,
  headers: List(String),
) -> TableConfig {
  TableConfig(..config, headers: headers)
}

/// Set the body rows.
pub fn table_rows(
  config: TableConfig,
  rows: List(List(String)),
) -> TableConfig {
  TableConfig(..config, rows: rows)
}

/// Constrain the overall table width.
pub fn table_width(config: TableConfig, width: Int) -> TableConfig {
  TableConfig(..config, width: Some(width), column_widths: None)
}

/// Constrain table columns to maximum widths.
pub fn table_column_widths(
  config: TableConfig,
  widths: List(Int),
) -> TableConfig {
  TableConfig(..config, column_widths: Some(widths), width: None)
}

/// Set the table border style.
pub fn table_border(config: TableConfig, border: BorderStyle) -> TableConfig {
  TableConfig(..config, border: border)
}

/// Toggle body row separators.
pub fn table_row_separators(config: TableConfig, enabled: Bool) -> TableConfig {
  TableConfig(..config, row_separators: enabled)
}

/// Render a table for the chosen browser capability.
pub fn render_table(capability: Capability, data: TableConfig) -> String {
  table.render(context(capability), to_spruce_table(data))
}

fn context(capability: Capability) -> Spruce {
  case capability {
    NoColor -> spruce.no_color()
    Basic -> spruce.with_color_level(spruce.Basic)
    Ansi256 -> spruce.with_color_level(spruce.Ansi256)
    TrueColor -> spruce.with_color_level(spruce.TrueColor)
  }
}

fn to_spruce_style(config: StyleConfig) -> style.Style {
  style.new()
  |> with_foreground(config.foreground)
  |> with_background(config.background)
  |> apply_if(config.bold, style.bold)
  |> apply_if(config.italic, style.italic)
  |> apply_if(config.underline, style.underline)
}

fn with_foreground(base: style.Style, color: Option(Color)) -> style.Style {
  case color {
    Some(color) -> style.fg(base, to_spruce_color(color))
    None -> base
  }
}

fn with_background(base: style.Style, color: Option(Color)) -> style.Style {
  case color {
    Some(color) -> style.bg(base, to_spruce_color(color))
    None -> base
  }
}

fn apply_if(
  base: style.Style,
  enabled: Bool,
  step: fn(style.Style) -> style.Style,
) -> style.Style {
  case enabled {
    True -> step(base)
    False -> base
  }
}

fn to_spruce_box(config: BoxConfig) -> box.Box {
  let base = case config.base {
    Framed -> box.new()
    Plain -> box.plain()
  }

  let rendered =
    base
    |> box.title(config.title)
    |> box.padding(
      top: config.padding_top,
      right: config.padding_right,
      bottom: config.padding_bottom,
      left: config.padding_left,
    )
    |> box.border(to_spruce_border(config.border))

  let rendered = case config.width {
    Some(width) -> box.width(rendered, width)
    None -> rendered
  }

  let rendered = case config.height {
    Some(height) -> box.height(rendered, height)
    None -> rendered
  }

  case config.border_color {
    Some(color) -> box.border_color(rendered, to_spruce_color(color))
    None -> rendered
  }
}

fn to_spruce_table(config: TableConfig) -> table.Table {
  let rendered =
    table.new()
    |> table.headers(config.headers)
    |> table.rows(config.rows)
    |> table.border(to_spruce_border(config.border))
    |> table.row_separators(config.row_separators)

  case config.column_widths {
    Some(widths) -> table.column_widths(rendered, widths)
    None ->
      case config.width {
        Some(width) -> table.width(rendered, width)
        None -> rendered
      }
  }
}

fn to_spruce_border(border: BorderStyle) -> border.Border {
  case border {
    Normal -> border.Normal
    Rounded -> border.Rounded
    Thick -> border.Thick
    Double -> border.Double
    Hidden -> border.Hidden
    Block -> border.Block
  }
}

fn to_spruce_color(color: Color) -> style.Color {
  case color {
    Black -> style.Black
    Red -> style.Red
    Green -> style.Green
    Yellow -> style.Yellow
    Blue -> style.Blue
    Magenta -> style.Magenta
    Cyan -> style.Cyan
    White -> style.White
    Gray -> style.Gray
    BrightRed -> style.BrightRed
    BrightGreen -> style.BrightGreen
    BrightYellow -> style.BrightYellow
    BrightBlue -> style.BrightBlue
    BrightMagenta -> style.BrightMagenta
    BrightCyan -> style.BrightCyan
    BrightWhite -> style.BrightWhite
    Hex(value) -> style.Hex(value)
    Color256(index) -> style.Ansi256(index)
    Complete(ansi, ansi256, truecolor) ->
      style.complete(
        to_spruce_color(ansi),
        to_spruce_color(ansi256),
        to_spruce_color(truecolor),
      )
  }
}
