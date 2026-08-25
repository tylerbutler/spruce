//// Compact single-line message composition.
////
//// A `Line` wraps a main message with an optional timestamp, severity, scope,
//// and key-value details, rendered to one styled line via `render`. Build one
//// with `new` and the combinators in this module.

import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import spruce.{type Spruce}
import spruce/detail.{type Details}
import spruce/severity as severity_module
import spruce/style

/// A composable single-line message with optional prefixes and details.
pub opaque type Line {
  Line(
    text: String,
    timestamp: Option(String),
    scope: Option(String),
    severity: Option(severity_module.Severity),
    severity_formatter: severity_module.Formatter,
    details: Option(Details),
  )
}

/// Start a compact line with the main message text.
pub fn new(text: String) -> Line {
  Line(
    text: text,
    timestamp: None,
    scope: None,
    severity: None,
    severity_formatter: severity_module.label(),
    details: None,
  )
}

/// Add a timestamp prefix.
pub fn timestamp(line: Line, timestamp: String) -> Line {
  Line(..line, timestamp: Some(timestamp))
}

/// Add a dim `[scope]` prefix.
pub fn scope(line: Line, scope: String) -> Line {
  Line(..line, scope: Some(scope))
}

/// Add a generic severity/status prefix.
pub fn severity(line: Line, severity: severity_module.Severity) -> Line {
  Line(..line, severity: Some(severity))
}

/// Override the severity formatter.
pub fn severity_formatter(
  line: Line,
  formatter: severity_module.Formatter,
) -> Line {
  Line(..line, severity_formatter: formatter)
}

/// Add key-value details after the main text.
pub fn details(line: Line, details: Details) -> Line {
  Line(..line, details: Some(details))
}

/// Render the compact line.
pub fn render(context: Spruce, line: Line) -> String {
  let prefix = spruce.indent_prefix(context)
  let prefix_parts =
    []
    |> maybe_append(render_timestamp(context, line.timestamp))
    |> maybe_append(render_severity(
      context,
      line.severity,
      line.severity_formatter,
    ))
    |> maybe_append(render_scope(context, line.scope))
    |> list.reverse

  let head = case prefix_parts {
    [] -> line.text
    _ -> string.join(prefix_parts, " ") <> " " <> line.text
  }

  prefix <> head <> render_details_part(context, line.details)
}

fn maybe_append(items: List(String), item: Option(String)) -> List(String) {
  case item {
    None -> items
    Some("") -> items
    Some(item) -> [item, ..items]
  }
}

fn render_timestamp(
  context: Spruce,
  timestamp: Option(String),
) -> Option(String) {
  case timestamp {
    None -> None
    Some(timestamp) ->
      Some(style.render(context, style.new() |> style.dim, timestamp))
  }
}

fn render_scope(context: Spruce, scope: Option(String)) -> Option(String) {
  case scope {
    None -> None
    Some(scope) ->
      Some(style.render(context, style.new() |> style.dim, "[" <> scope <> "]"))
  }
}

fn render_severity(
  context: Spruce,
  severity_value: Option(severity_module.Severity),
  formatter: severity_module.Formatter,
) -> Option(String) {
  case severity_value {
    None -> None
    Some(severity_value) ->
      Some(severity_module.render_padded(context, formatter, severity_value))
  }
}

fn render_details_part(
  context: Spruce,
  details_option: Option(Details),
) -> String {
  case details_option {
    None -> ""
    Some(details) -> {
      case detail.render(context, details) {
        "" -> ""
        rendered ->
          " " <> style.render(context, style.new() |> style.dim, rendered)
      }
    }
  }
}
