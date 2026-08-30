//// Erlang/OTP Logger and RFC 5424 severity formatting.

import gleam/bool
import gleam/option.{type Option, None, Some}
import gleam/string
import spruce.{type Spruce}
import spruce/align
import spruce/style
import spruce/symbol

/// RFC 5424 / Erlang OTP Logger severity levels, in descending order of urgency.
pub type Severity {
  Emergency
  Alert
  Critical
  Error
  Warning
  Notice
  Info
  Debug
}

/// Controls how a `Severity` is rendered: its style (label, badge, simple, or
/// custom), whether icons are shown, the glyph mode, and the padding width.
/// Construct one with `label`, `badge`, `simple`, or `custom`.
pub opaque type Formatter {
  Formatter(
    kind: FormatKind,
    icons: Bool,
    mode: Option(spruce.SymbolMode),
    target_width: Int,
  )
}

type FormatKind {
  Label
  Badge
  Simple
  Custom(render: fn(Severity, Spruce) -> String)
}

/// Render an icon plus lowercase severity label, e.g. `ℹ︎ info`.
pub fn label() -> Formatter {
  Formatter(kind: Label, icons: True, mode: None, target_width: 10)
}

/// Render an uppercase bracketed severity badge, e.g. `[WARN]`.
pub fn badge() -> Formatter {
  Formatter(kind: Badge, icons: False, mode: None, target_width: 10)
}

/// Render an uppercase severity name, e.g. `DEBUG`.
pub fn simple() -> Formatter {
  Formatter(kind: Simple, icons: False, mode: None, target_width: 8)
}

/// Render severities with a caller-supplied function.
pub fn custom(
  render: fn(Severity, Spruce) -> String,
  target_width target_width: Int,
) -> Formatter {
  Formatter(kind: Custom(render), icons: False, mode: None, target_width:)
}

/// Enable or disable icons for formatters that support them.
pub fn icons(formatter: Formatter, enabled: Bool) -> Formatter {
  case formatter.kind {
    Label ->
      Formatter(..formatter, icons: enabled, target_width: bool_width(enabled))
    Badge | Simple | Custom(_) -> Formatter(..formatter, icons: enabled)
  }
}

/// Override the glyph mode used by icon-bearing formatters.
/// When not set, the rendering context's symbol mode is used.
pub fn mode(formatter: Formatter, mode: spruce.SymbolMode) -> Formatter {
  Formatter(..formatter, mode: Some(mode))
}

/// Return the visual target width used by `render_padded`.
pub fn target_width(formatter: Formatter) -> Int {
  formatter.target_width
}

/// Render a severity with the supplied formatter.
pub fn render(
  context: Spruce,
  formatter: Formatter,
  severity: Severity,
) -> String {
  case formatter.kind {
    Label -> render_label(context, formatter, severity)
    Badge -> render_badge(context, severity)
    Simple -> render_simple(context, severity)
    Custom(render) -> render(severity, context)
  }
}

/// Render a severity and pad it to the formatter's visual target width.
pub fn render_padded(
  context: Spruce,
  formatter: Formatter,
  severity: Severity,
) -> String {
  render(context, formatter, severity)
  |> align.pad_right(formatter.target_width)
}

/// Convert a severity to its RFC 5424 ordering integer.
pub fn to_int(severity: Severity) -> Int {
  case severity {
    Emergency -> 0
    Alert -> 1
    Critical -> 2
    Error -> 3
    Warning -> 4
    Notice -> 5
    Info -> 6
    Debug -> 7
  }
}

/// Convert a severity to its uppercase label.
pub fn to_string(severity: Severity) -> String {
  case severity {
    Emergency -> "EMERGENCY"
    Alert -> "ALERT"
    Critical -> "CRITICAL"
    Error -> "ERROR"
    Warning -> "WARNING"
    Notice -> "NOTICE"
    Info -> "INFO"
    Debug -> "DEBUG"
  }
}

/// Convert a severity to its lowercase label.
pub fn to_string_lowercase(severity: Severity) -> String {
  severity
  |> to_string
  |> string.lowercase
}

fn render_label(
  context: Spruce,
  formatter: Formatter,
  severity: Severity,
) -> String {
  let text = to_string_lowercase(severity)
  let color = label_color(severity)
  let label_style = style.new() |> style.bold |> style.fg(color)
  let styled_text = style.render(context, label_style, text)

  case formatter.icons {
    False -> styled_text
    True -> {
      let resolved_mode =
        option.unwrap(formatter.mode, spruce.symbol_mode(context))
      let icon = symbol.status(resolved_mode, status(severity))
      let styled_icon = style.render(context, label_style, icon)
      styled_icon <> " " <> styled_text
    }
  }
}

fn render_badge(context: Spruce, severity: Severity) -> String {
  let text = "[" <> to_string(severity) <> "]"
  style.render(
    context,
    style.new() |> style.bold |> style.fg(label_color(severity)),
    text,
  )
}

fn render_simple(context: Spruce, severity: Severity) -> String {
  style.render(
    context,
    style.new() |> style.fg(simple_color(severity)),
    to_string(severity),
  )
}

fn status(severity: Severity) -> symbol.Status {
  case severity {
    Emergency -> symbol.Alert
    Alert -> symbol.Alert
    Critical -> symbol.Error
    Error -> symbol.Error
    Warning -> symbol.Warn
    Notice -> symbol.Notice
    Info -> symbol.Info
    Debug -> symbol.Debug
  }
}

fn label_color(severity: Severity) -> style.Color {
  case severity {
    Emergency -> style.BrightRed
    Alert -> style.BrightRed
    Critical -> style.BrightRed
    Error -> style.Red
    Warning -> style.Yellow
    Notice -> style.Cyan
    Info -> style.Cyan
    Debug -> style.Gray
  }
}

fn bool_width(enabled: Bool) -> Int {
  use <- bool.guard(when: enabled, return: 10)
  8
}

fn simple_color(severity: Severity) -> style.Color {
  case severity {
    Debug -> style.Blue
    Emergency | Alert | Critical | Error | Warning | Notice | Info ->
      label_color(severity)
  }
}
