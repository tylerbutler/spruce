//// Semantic one-line messages: success, fail, start, ready, info, warn, error.
////
//// Each function returns a formatted line (icon + label + text), indented to
//// the context's depth and styled when the context supports color. The
//// `print_*` variants write the line to stdout.

import gleam/io
import gleam/option.{type Option, None, Some}
import spruce.{type Spruce}
import spruce/details.{type Details}
import spruce/internal/layout
import spruce/style
import spruce/symbol

/// The kind of semantic message, selecting its icon, color, and label.
pub type Kind {
  Success
  Fail
  Start
  Ready
  Info
  Warn
  Error
}

/// Rendering options for message lines.
pub opaque type Options {
  Options(
    details: Option(Details),
    symbol_mode: symbol.Mode,
    formatter: Option(Formatter),
  )
}

/// Message prefix formatter.
pub opaque type Formatter {
  Formatter(kind: FormatKind)
}

type FormatKind {
  Label
  Badge
  Simple
  Custom(fn(Kind, Spruce) -> String)
}

/// Create default message rendering options.
pub fn default_options() -> Options {
  Options(details: None, symbol_mode: symbol.Unicode, formatter: None)
}

/// Include key-value details after the message text.
pub fn with_details(options: Options, details: Details) -> Options {
  Options(..options, details: Some(details))
}

/// Select whether message status glyphs render as Unicode or ASCII.
pub fn with_symbol_mode(options: Options, mode: symbol.Mode) -> Options {
  Options(..options, symbol_mode: mode)
}

/// Render the message prefix as icon plus lowercase label, e.g. `✔ success`.
pub fn label() -> Formatter {
  Formatter(kind: Label)
}

/// Render the message prefix as an uppercase bracketed badge, e.g. `[SUCCESS]`.
pub fn badge() -> Formatter {
  Formatter(kind: Badge)
}

/// Render the message prefix as an uppercase bare label, e.g. `SUCCESS`.
pub fn simple() -> Formatter {
  Formatter(kind: Simple)
}

/// Render the message prefix with a caller-supplied function.
pub fn custom(render: fn(Kind, Spruce) -> String) -> Formatter {
  Formatter(kind: Custom(render))
}

/// Select a message prefix formatter.
pub fn with_formatter(options: Options, formatter: Formatter) -> Options {
  Options(..options, formatter: Some(formatter))
}

/// Format a success message line.
pub fn success(sp: Spruce, text: String) -> String {
  line(sp, Success, text)
}

/// Format a success message line with explicit rendering options.
pub fn success_with(sp: Spruce, text: String, options: Options) -> String {
  line_options(sp, Success, text, options)
}

/// Format a fail message line.
pub fn fail(sp: Spruce, text: String) -> String {
  line(sp, Fail, text)
}

/// Format a fail message line with explicit rendering options.
pub fn fail_with(sp: Spruce, text: String, options: Options) -> String {
  line_options(sp, Fail, text, options)
}

/// Format a start message line.
pub fn start(sp: Spruce, text: String) -> String {
  line(sp, Start, text)
}

/// Format a start message line with explicit rendering options.
pub fn start_with(sp: Spruce, text: String, options: Options) -> String {
  line_options(sp, Start, text, options)
}

/// Format a ready message line.
pub fn ready(sp: Spruce, text: String) -> String {
  line(sp, Ready, text)
}

/// Format a ready message line with explicit rendering options.
pub fn ready_with(sp: Spruce, text: String, options: Options) -> String {
  line_options(sp, Ready, text, options)
}

/// Format an info message line.
pub fn info(sp: Spruce, text: String) -> String {
  line(sp, Info, text)
}

/// Format an info message line with explicit rendering options.
pub fn info_with(sp: Spruce, text: String, options: Options) -> String {
  line_options(sp, Info, text, options)
}

/// Format a warn message line.
pub fn warn(sp: Spruce, text: String) -> String {
  line(sp, Warn, text)
}

/// Format a warn message line with explicit rendering options.
pub fn warn_with(sp: Spruce, text: String, options: Options) -> String {
  line_options(sp, Warn, text, options)
}

/// Format an error message line.
pub fn error(sp: Spruce, text: String) -> String {
  line(sp, Error, text)
}

/// Format an error message line with explicit rendering options.
pub fn error_with(sp: Spruce, text: String, options: Options) -> String {
  line_options(sp, Error, text, options)
}

/// Print a success message to stdout.
pub fn print_success(sp: Spruce, text: String) -> Nil {
  io.println(success(sp, text))
}

/// Print a fail message to stdout.
pub fn print_fail(sp: Spruce, text: String) -> Nil {
  io.println(fail(sp, text))
}

/// Print a start message to stdout.
pub fn print_start(sp: Spruce, text: String) -> Nil {
  io.println(start(sp, text))
}

/// Print a ready message to stdout.
pub fn print_ready(sp: Spruce, text: String) -> Nil {
  io.println(ready(sp, text))
}

/// Print an info message to stdout.
pub fn print_info(sp: Spruce, text: String) -> Nil {
  io.println(info(sp, text))
}

/// Print a warn message to stdout.
pub fn print_warn(sp: Spruce, text: String) -> Nil {
  io.println(warn(sp, text))
}

/// Print an error message to stdout.
pub fn print_error(sp: Spruce, text: String) -> Nil {
  io.println(error(sp, text))
}

/// Format a message line with explicit rendering options.
pub fn line_with(
  sp: Spruce,
  kind: Kind,
  text: String,
  options: Options,
) -> String {
  line_options(sp, kind, text, options)
}

fn line(sp: Spruce, kind: Kind, text: String) -> String {
  line_options(sp, kind, text, default_options())
}

fn line_options(
  sp: Spruce,
  kind: Kind,
  text: String,
  options: Options,
) -> String {
  let prefix = layout.indent_prefix(sp)
  let rendered_prefix = case options.formatter {
    None -> render_default_prefix(sp, kind, options.symbol_mode)
    Some(formatter) ->
      render_formatter(sp, formatter, kind, options.symbol_mode)
  }
  let details_text = details_suffix(sp, options.details)

  prefix <> rendered_prefix <> " " <> text <> details_text
}

fn render_default_prefix(
  sp: Spruce,
  kind: Kind,
  symbol_mode: symbol.Mode,
) -> String {
  let #(status, color, label) = properties(kind)
  let icon = symbol.status(symbol_mode, status)

  case spruce.supports_color(sp) {
    False -> icon <> " " <> label
    True -> {
      let colored = style.new() |> style.fg(color)
      style.render(sp, colored, icon)
      <> " "
      <> style.render(sp, style.bold(colored), label)
    }
  }
}

fn render_formatter(
  sp: Spruce,
  formatter: Formatter,
  kind: Kind,
  symbol_mode: symbol.Mode,
) -> String {
  case formatter.kind {
    Label -> render_default_prefix(sp, kind, symbol_mode)
    Badge -> render_badge(sp, kind)
    Simple -> render_simple(sp, kind)
    Custom(render) -> render(kind, sp)
  }
}

fn render_badge(sp: Spruce, kind: Kind) -> String {
  let #(_, color, label) = properties(kind)
  style.render(
    sp,
    style.new() |> style.bold |> style.fg(color),
    "[" <> uppercase(label) <> "]",
  )
}

fn render_simple(sp: Spruce, kind: Kind) -> String {
  let #(_, color, label) = properties(kind)
  style.render(sp, style.new() |> style.fg(color), uppercase(label))
}

fn details_suffix(sp: Spruce, maybe_details: Option(Details)) -> String {
  case maybe_details {
    None -> ""
    Some(detail_values) -> {
      case details.render(sp, detail_values) {
        "" -> ""
        rendered -> " " <> rendered
      }
    }
  }
}

fn properties(kind: Kind) -> #(symbol.Status, style.Color, String) {
  case kind {
    Success -> #(symbol.Success, style.Green, "success")
    Fail -> #(symbol.Error, style.Red, "fail")
    Start -> #(symbol.Start, style.Magenta, "start")
    Ready -> #(symbol.Success, style.Green, "ready")
    Info -> #(symbol.Info, style.Cyan, "info")
    Warn -> #(symbol.Warn, style.Yellow, "warn")
    Error -> #(symbol.Error, style.Red, "error")
  }
}

fn uppercase(label: String) -> String {
  case label {
    "success" -> "SUCCESS"
    "fail" -> "FAIL"
    "start" -> "START"
    "ready" -> "READY"
    "info" -> "INFO"
    "warn" -> "WARN"
    "error" -> "ERROR"
    _ -> label
  }
}
