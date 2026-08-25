//// Temporary demo used to generate real spruce output for the landing page.
//// Not part of the public API — safe to delete.

import gleam/io
import spruce
import spruce/border
import spruce/box
import spruce/detail
import spruce/item
import spruce/line
import spruce/message
import spruce/output
import spruce/severity
import spruce/style
import spruce/table
import spruce/tree

fn mark(name: String) -> Nil {
  io.println("\u{0001}" <> name)
}

pub fn main() {
  let context = spruce.with_color_level(spruce.TrueColor)

  mark("hero")
  box.print(context, "spruce")
  output.stream_group(context, "Build", fn(context) {
    io.println(message.start(context, "compiling 14 modules"))
    io.println(message.success(context, "compiled in 312ms"))
    io.println(message.info(context, "target: javascript"))
    io.println(message.warn(context, "2 deprecation notices"))
  })

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

  mark("tree")
  io.println(
    tree.root("spruce")
    |> tree.child(
      child: tree.root("style")
      |> tree.child(child: tree.root("named"))
      |> tree.child(child: tree.root("rgb / hex / 256"))
      |> tree.child(child: tree.root("adaptive")),
    )
    |> tree.child(
      child: tree.root("layout")
      |> tree.child(child: tree.root("box"))
      |> tree.child(child: tree.root("table"))
      |> tree.child(child: tree.root("tree")),
    )
    |> tree.render(context, _),
  )

  mark("list")
  io.println(
    item.new()
    |> item.item("Auto-detects color support")
    |> item.nested(
      "Renders on both runtimes",
      item.new()
        |> item.item("Erlang / BEAM")
        |> item.item("JavaScript / Node"),
    )
    |> item.item("Pure, testable string builders")
    |> item.render(context, _),
  )

  mark("line")
  let meta =
    detail.new()
    |> detail.add(key: "duration", value: "42ms")
    |> detail.add(key: "target", value: "javascript")
  io.println(
    line.new("Request handled")
    |> line.severity(severity.Info)
    |> line.scope("http")
    |> line.details(meta)
    |> line.render(context, _),
  )

  mark("example")
  box.print(context, "spruce")
  io.println(message.success(context, "ready"))

  mark("hero_plain")
  let np = spruce.no_color()
  box.print(np, "spruce")
  output.stream_group(np, "Build", fn(np) {
    io.println(message.start(np, "compiling 14 modules"))
    io.println(message.success(np, "compiled in 312ms"))
    io.println(message.info(np, "target: javascript"))
    io.println(message.warn(np, "2 deprecation notices"))
  })

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
