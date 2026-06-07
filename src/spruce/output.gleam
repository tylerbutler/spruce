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
////   let sp = spruce.detect()
////
////   output.new(sp)
////   |> output.append(message.start(_, "compiling"))
////   |> output.group("Tests", fn(o) {
////     o |> output.append(message.info(_, "running"))
////   })
////   |> output.print
//// }
//// ```
////
//// `append` accepts any `Spruce -> String` renderer via a `_` capture, so it
//// works with every spruce module without per-type variants. For eager,
//// streaming grouping that prints as work happens and can return a value, use
//// `spruce/group.group` instead.

import gleam/io
import gleam/list
import gleam/string
import spruce.{type Spruce}
import spruce/group

/// An accumulator of rendered blocks plus the context they render with.
/// Build one with `new` and the combinators in this module, then finish with
/// `to_string` or `print`.
pub opaque type Output {
  Output(sp: Spruce, chunks: List(String))
}

/// Start an empty output that renders with `sp`.
pub fn new(sp: Spruce) -> Output {
  Output(sp: sp, chunks: [])
}

/// The context the output renders with. Reflects the current group depth inside
/// a `group` body.
pub fn context(output: Output) -> Spruce {
  output.sp
}

/// Append a rendered block produced by `render`, which receives the output's
/// context. Works with any `Spruce -> String` renderer via a `_` capture, e.g.
/// `output.append(message.success(_, "done"))`.
pub fn append(output: Output, render: fn(Spruce) -> String) -> Output {
  Output(..output, chunks: [render(output.sp), ..output.chunks])
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
/// title. Unlike `spruce/group.group`, this buffers output rather than printing.
pub fn group(
  output: Output,
  title: String,
  body: fn(Output) -> Output,
) -> Output {
  let titled = text(output, group.render_title(output.sp, title))
  let body_output =
    body(Output(sp: spruce.indented(output.sp), chunks: titled.chunks))
  Output(sp: output.sp, chunks: body_output.chunks)
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
