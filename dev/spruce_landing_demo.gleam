//// Generates real spruce output for the website terminal panels.
//// This development module is not part of the public API.

import gleam/io
import spruce
import spruce/border
import spruce/box
import spruce/line
import spruce/message
import spruce/output
import spruce/severity
import spruce/style
import spruce/table

fn mark(name: String) -> Nil {
  io.println("\u{0001}" <> name)
}

fn render_hero(context: spruce.Spruce) {
  box.print(context, "spruce")
  io.println(
    style.new()
    |> style.fg(style.Hex(0x7de2c4))
    |> style.bold
    |> style.render(context, _, "adaptive accent"),
  )
  output.stream_group(context, "Build", fn(context) {
    io.println(message.start(context, "compiling 14 modules"))
    io.println(message.success(context, "compiled in 312ms"))
    io.println(message.info(context, "target: javascript"))
    io.println(message.warn(context, "2 deprecation notices"))
  })
}

pub fn main() {
  let context = spruce.with_color_level(spruce.TrueColor)

  mark("hero")
  render_hero(context)

  mark("hero_ansi256")
  render_hero(spruce.with_color_level(spruce.Ansi256))

  mark("hero_basic")
  render_hero(spruce.with_color_level(spruce.Basic))

  mark("messages")
  let badge = fn(severity_value: severity.Severity, text: String) {
    line.new(text)
    |> line.severity(severity_value)
    |> line.severity_formatter(severity.badge())
    |> line.render(context, _)
  }
  io.println(badge(severity.Info, "Deploy complete"))
  io.println(badge(severity.Err, "Connection refused"))
  io.println(badge(severity.Debug, "Cache warmed"))
  io.println(badge(severity.Notice, "Listening on :4000"))

  mark("table")
  io.println(
    table.new()
    |> table.headers(["Module", "Target", "Time"])
    |> table.rows([
      ["spruce/box", "erlang", "1.2ms"],
      ["spruce/table", "javascript", "0.8ms"],
      ["spruce/markdown", "erlang", "4.1ms"],
    ])
    |> table.border(border.Rounded)
    |> table.render(context, _),
  )

  mark("example")
  box.print(context, "spruce")
  io.println(message.success(context, "ready"))

  mark("parity")
  io.println(message.success(context, "same render path"))
  io.println(message.info(context, "pure String output"))

  mark("hero_plain")
  render_hero(spruce.no_color())

  mark("style")
  io.println(
    style.new()
    |> style.fg(style.Hex(0xec6a82))
    |> style.bold()
    |> style.render(context, _, "rose"),
  )
  io.println(
    style.new()
    |> style.fg(style.Hex(0x2f6f54))
    |> style.bold()
    |> style.render(context, _, "spruce"),
  )
  mark("end")
}
