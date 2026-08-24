//// Temporary demo used to generate real spruce output for the landing page.
//// Not part of the public API — safe to delete.

import gleam/io
import spruce
import spruce/border
import spruce/box
import spruce/details
import spruce/items
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
  let sp = spruce.with_color_level(spruce.TrueColor)

  mark("hero")
  box.print(sp, "spruce")
  output.stream_group(sp, "Build", fn(sp) {
    io.println(message.start(sp, "compiling 14 modules"))
    io.println(message.success(sp, "compiled in 312ms"))
    io.println(message.info(sp, "target: javascript"))
    io.println(message.warn(sp, "2 deprecation notices"))
  })

  mark("messages")
  let badge = fn(sev: severity.Severity, text: String) {
    line.new(text)
    |> line.severity(sev)
    |> line.severity_formatter(severity.badge())
    |> line.render(sp, _)
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
    |> table.render(sp, _),
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
    |> tree.render(sp, _),
  )

  mark("list")
  io.println(
    items.new()
    |> items.item("Auto-detects color support")
    |> items.nested(
      "Renders on both runtimes",
      items.new()
        |> items.item("Erlang / BEAM")
        |> items.item("JavaScript / Node"),
    )
    |> items.item("Pure, testable string builders")
    |> items.render(sp, _),
  )

  mark("line")
  let meta =
    details.new()
    |> details.add(key: "duration", value: "42ms")
    |> details.add(key: "target", value: "javascript")
  io.println(
    line.new("Request handled")
    |> line.severity(severity.Info)
    |> line.scope("http")
    |> line.details(meta)
    |> line.render(sp, _),
  )

  mark("example")
  box.print(sp, "spruce")
  io.println(message.success(sp, "ready"))

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
    |> style.render(sp, _, "rose"),
  )
  io.println(
    style.new()
    |> style.fg(style.Hex(0x2f6f54))
    |> style.bold()
    |> style.render(sp, _, "spruce"),
  )
  mark("end")
}
