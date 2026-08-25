//// Semantic one-line status messages: success, fail, start, ready, info,
//// warn, and error.
////
//// Each function returns one line — a colored icon, a bold label, and the
//// text — indented to the context's depth and plain when the context does not
//// support color. They are sugar for the common cases; for timestamps,
//// scopes, key-value details, RFC 5424 severities, or badge/simple prefixes,
//// compose a `spruce/line` instead. Print with `gleam/io` (or collect lines
//// with `spruce/output`).
////
//// ```gleam
//// import gleam/io
//// import spruce
//// import spruce/message
////
//// pub fn main() {
////   let context = spruce.detect()
////   io.println(message.start(context, "compiling"))
////   io.println(message.success(context, "done"))
//// }
//// ```

import spruce.{type Spruce}
import spruce/style
import spruce/symbol

/// Format a success message line, e.g. `✔ success done`.
pub fn success(context: Spruce, text: String) -> String {
  render(context, symbol.Success, style.Green, "success", text)
}

/// Format a fail message line, e.g. `✖ fail 1 test failed`.
pub fn fail(context: Spruce, text: String) -> String {
  render(context, symbol.Error, style.Red, "fail", text)
}

/// Format a start message line, e.g. `◐ start compiling`.
pub fn start(context: Spruce, text: String) -> String {
  render(context, symbol.Start, style.Magenta, "start", text)
}

/// Format a ready message line, e.g. `✔ ready listening on :8080`.
pub fn ready(context: Spruce, text: String) -> String {
  render(context, symbol.Success, style.Green, "ready", text)
}

/// Format an info message line, e.g. `ℹ info resolving dependencies`.
pub fn info(context: Spruce, text: String) -> String {
  render(context, symbol.Info, style.Cyan, "info", text)
}

/// Format a warn message line, e.g. `⚠ warn deprecated option`.
pub fn warn(context: Spruce, text: String) -> String {
  render(context, symbol.Warn, style.Yellow, "warn", text)
}

/// Format an error message line, e.g. `✖ error could not reach registry`.
pub fn error(context: Spruce, text: String) -> String {
  render(context, symbol.Error, style.Red, "error", text)
}

fn render(
  context: Spruce,
  status: symbol.Status,
  color: style.Color,
  label: String,
  text: String,
) -> String {
  let icon = symbol.status(symbol.Unicode, status)
  let prefix = case spruce.supports_color(context) {
    False -> icon <> " " <> label
    True -> {
      let colored = style.new() |> style.fg(color)
      style.render(context, colored, icon)
      <> " "
      <> style.render(context, style.bold(colored), label)
    }
  }

  spruce.indent_prefix(context) <> prefix <> " " <> text
}
