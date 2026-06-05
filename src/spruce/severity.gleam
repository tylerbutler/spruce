//// Generic Birch-style severity/status formatting.

import gleam/string
import spruce.{type Spruce}
import spruce/align
import spruce/style
import spruce/symbol

/// Birch-compatible severity levels, in ascending order.
pub type Severity {
  Trace
  Debug
  Info
  Notice
  Warn
  Err
  Critical
  Alert
  Fatal
}

pub opaque type Formatter {
  Formatter(kind: FormatKind, icons: Bool, mode: symbol.Mode, target_width: Int)
}

type FormatKind {
  Label
  Badge
  Simple
  Custom(render: fn(Severity, Spruce) -> String)
}

/// Render an icon plus lowercase severity label, e.g. `ℹ info`.
pub fn label() -> Formatter {
  Formatter(kind: Label, icons: True, mode: symbol.Unicode, target_width: 10)
}

/// Render an uppercase bracketed severity badge, e.g. `[WARN]`.
pub fn badge() -> Formatter {
  Formatter(kind: Badge, icons: False, mode: symbol.Unicode, target_width: 10)
}

/// Render an uppercase severity name, e.g. `DEBUG`.
pub fn simple() -> Formatter {
  Formatter(kind: Simple, icons: False, mode: symbol.Unicode, target_width: 8)
}

/// Render severities with a caller-supplied function.
pub fn custom(
  render: fn(Severity, Spruce) -> String,
  target_width target_width: Int,
) -> Formatter {
  Formatter(
    kind: Custom(render),
    icons: False,
    mode: symbol.Unicode,
    target_width:,
  )
}

/// Enable or disable icons for formatters that support them.
pub fn icons(formatter: Formatter, enabled: Bool) -> Formatter {
  case formatter.kind {
    Label ->
      Formatter(..formatter, icons: enabled, target_width: bool_width(enabled))
    _ -> Formatter(..formatter, icons: enabled)
  }
}

/// Set the glyph mode used by icon-bearing formatters.
pub fn mode(formatter: Formatter, mode: symbol.Mode) -> Formatter {
  Formatter(..formatter, mode:)
}

/// Return the visual target width used by `render_padded`.
pub fn target_width(formatter: Formatter) -> Int {
  formatter.target_width
}

/// Render a severity with the supplied formatter.
pub fn render(sp: Spruce, formatter: Formatter, severity: Severity) -> String {
  case formatter.kind {
    Label -> render_label(sp, formatter, severity)
    Badge -> render_badge(sp, severity)
    Simple -> render_simple(sp, severity)
    Custom(render) -> render(severity, sp)
  }
}

/// Render a severity and pad it to the formatter's visual target width.
pub fn render_padded(
  sp: Spruce,
  formatter: Formatter,
  severity: Severity,
) -> String {
  render(sp, formatter, severity)
  |> align.pad_right(formatter.target_width)
}

/// Convert a severity to its Birch ordering integer.
pub fn to_int(severity: Severity) -> Int {
  case severity {
    Trace -> 0
    Debug -> 1
    Info -> 2
    Notice -> 3
    Warn -> 4
    Err -> 5
    Critical -> 6
    Alert -> 7
    Fatal -> 8
  }
}

/// Convert a severity to its uppercase label.
pub fn to_string(severity: Severity) -> String {
  case severity {
    Trace -> "TRACE"
    Debug -> "DEBUG"
    Info -> "INFO"
    Notice -> "NOTICE"
    Warn -> "WARN"
    Err -> "ERROR"
    Critical -> "CRITICAL"
    Alert -> "ALERT"
    Fatal -> "FATAL"
  }
}

/// Convert a severity to its lowercase label.
pub fn to_string_lowercase(severity: Severity) -> String {
  severity
  |> to_string
  |> string.lowercase
}

fn render_label(
  sp: Spruce,
  formatter: Formatter,
  severity: Severity,
) -> String {
  let text = to_string_lowercase(severity)
  let color = label_color(severity)
  let label_style = style.new() |> style.bold |> style.fg(color)
  let styled_text = style.render(sp, label_style, text)

  case formatter.icons {
    False -> styled_text
    True -> {
      let icon = symbol.status(formatter.mode, status(severity))
      let styled_icon = style.render(sp, label_style, icon)
      styled_icon <> " " <> styled_text
    }
  }
}

fn render_badge(sp: Spruce, severity: Severity) -> String {
  let text = "[" <> to_string(severity) <> "]"
  style.render(
    sp,
    style.new() |> style.bold |> style.fg(label_color(severity)),
    text,
  )
}

fn render_simple(sp: Spruce, severity: Severity) -> String {
  style.render(
    sp,
    style.new() |> style.fg(simple_color(severity)),
    to_string(severity),
  )
}

fn status(severity: Severity) -> symbol.Status {
  case severity {
    Trace -> symbol.Trace
    Debug -> symbol.Debug
    Info -> symbol.Info
    Notice -> symbol.Notice
    Warn -> symbol.Warn
    Err -> symbol.Error
    Critical -> symbol.Error
    Alert -> symbol.Alert
    Fatal -> symbol.Error
  }
}

fn label_color(severity: Severity) -> style.Color {
  case severity {
    Trace -> style.Gray
    Debug -> style.Gray
    Info -> style.Cyan
    Notice -> style.Cyan
    Warn -> style.Yellow
    Err -> style.Red
    Critical -> style.BrightRed
    Alert -> style.BrightRed
    Fatal -> style.BrightRed
  }
}

fn bool_width(enabled: Bool) -> Int {
  case enabled {
    True -> 10
    False -> 8
  }
}

fn simple_color(severity: Severity) -> style.Color {
  case severity {
    Debug -> style.Blue
    _ -> label_color(severity)
  }
}
