//// Pipeable output accumulation.
////
//// An `Output` threads a `Spruce` context and a buffer of rendered blocks
//// through a pipeline, so several renderers compose with `|>` and emit
//// together. It stays pure: nothing is printed until `print`, and the context
//// is threaded for you so each renderer sees the right color level and indent
//// depth.
////
//// ```gleam
//// import spruce
//// import spruce/message
//// import spruce/output
////
//// pub fn main() {
////   let context = spruce.detect()
////
////   output.new(context)
////   |> output.append(message.start(_, "compiling"))
////   |> output.group("Tests", fn(output) {
////     output |> output.append(message.info(_, "running"))
////   })
////   |> output.print
//// }
//// ```
////
//// `append` accepts any `Spruce -> String` renderer via a `_` capture, so it
//// works with every spruce module without per-type variants. For eager,
//// streaming grouping that prints as work happens and can return a value, use
//// `stream_group` instead.

import gleam/io
import gleam/list
import gleam/string
import spruce.{type Spruce}
import spruce/style
import spruce/symbol

/// An accumulator of rendered blocks plus the context they render with.
/// Build one with `new` and the combinators in this module, then finish with
/// `to_string` or `print`.
pub opaque type Output {
  Output(context: Spruce, chunks: List(String))
}

/// Start an empty output that renders with `context`.
pub fn new(context: Spruce) -> Output {
  Output(context:, chunks: [])
}

/// The context the output renders with. Reflects the current group depth inside
/// a `group` body.
pub fn context(output: Output) -> Spruce {
  output.context
}

/// Append a rendered block produced by `render`, which receives the output's
/// context. Works with any `Spruce -> String` renderer via a `_` capture, e.g.
/// `output.append(message.success(_, "done"))`.
pub fn append(output: Output, render: fn(Spruce) -> String) -> Output {
  Output(..output, chunks: [render(output.context), ..output.chunks])
}

/// Append a raw string as-is, without rendering.
pub fn text(output: Output, text: String) -> Output {
  Output(..output, chunks: [text, ..output.chunks])
}

/// Append a blank line.
pub fn blank(output: Output) -> Output {
  Output(..output, chunks: ["", ..output.chunks])
}

/// Append a styled group title, then run `body` with the output's context
/// indented one level deeper. Blocks appended inside `body` nest under the
/// title. Unlike `stream_group`, this buffers output rather than printing.
pub fn group(
  output: Output,
  heading: String,
  body: fn(Output) -> Output,
) -> Output {
  let titled = text(output, title(output.context, heading))
  let body_output =
    body(Output(context: spruce.indented(output.context), chunks: titled.chunks))
  Output(context: output.context, chunks: body_output.chunks)
}

/// Print a group title, then run `body` with a context indented one level
/// deeper, returning its result.
///
/// This is the eager, streaming form of grouping: the title prints
/// immediately and `body` runs right away, so its output appears as work
/// happens and it may perform IO and return any value. For deferred,
/// pipe-composable grouping that buffers output instead, see `group`.
pub fn stream_group(
  context: Spruce,
  heading: String,
  body: fn(Spruce) -> result,
) -> result {
  io.println(title(context, heading))
  body(spruce.indented(context))
}

/// Render a group title line (indent prefix + styled marker + title), the same
/// line that `group` and `stream_group` emit.
pub fn title(context: Spruce, heading: String) -> String {
  let marker = symbol.status(spruce.symbol_mode(context), symbol.Arrow)
  let line = case spruce.supports_color(context) {
    False -> marker <> " " <> heading
    True ->
      style.render(context, style.hashed(heading), marker)
      <> " "
      <> style.render(context, style.new() |> style.bold, heading)
  }

  spruce.indent_prefix(context) <> line
}

/// Render the accumulated output to a single string, blocks joined by newlines.
pub fn to_string(output: Output) -> String {
  output.chunks
  |> list.reverse
  |> string.join("\n")
}

/// Print the accumulated output to stdout.
pub fn print(output: Output) -> Nil {
  io.println(to_string(output))
}
