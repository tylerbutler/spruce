//// Temporary demo used to generate real spruce output for the landing page.
//// Not part of the public API — safe to delete.

import gleam/io
import spruce
import spruce/box
import spruce/details
import spruce/group
import spruce/line
import spruce/list
import spruce/message
import spruce/severity
import spruce/style
import spruce/table
import spruce/tree
import tty

fn mark(name: String) -> Nil {
  io.println("\u{0001}" <> name)
}

pub fn main() {
  let sp = spruce.with_color_level(tty.TrueColor)

  mark("hero")
  box.print(sp, "spruce")
  group.group(sp, "Build", fn(sp) {
    message.print_start(sp, "compiling 14 modules")
    message.print_success(sp, "compiled in 312ms")
    message.print_info(sp, "target: javascript")
    message.print_warn(sp, "2 deprecation notices")
  })

  mark("messages")
  let badge =
    message.default_options() |> message.with_formatter(message.badge())
  io.println(message.success_with(sp, "Deploy complete", badge))
  io.println(message.error_with(sp, "Connection refused", badge))
  io.println(message.info_with(sp, "Cache warmed", badge))
  io.println(message.ready_with(sp, "Listening on :4000", badge))

  mark("table")
  io.println(
    table.new()
    |> table.headers(["Module", "Target", "Time"])
    |> table.rows([
      ["spruce/box", "erlang", "1.2ms"],
      ["spruce/table", "javascript", "0.8ms"],
      ["spruce/markdown", "erlang", "4.1ms"],
    ])
    |> table.border(box.Rounded)
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
    list.new()
    |> list.item("Auto-detects color support")
    |> list.nested(
      "Renders on both runtimes",
      list.new()
        |> list.item("Erlang / BEAM")
        |> list.item("JavaScript / Node"),
    )
    |> list.item("Pure, testable string builders")
    |> list.render(sp, _),
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
  group.group(np, "Build", fn(np) {
    message.print_start(np, "compiling 14 modules")
    message.print_success(np, "compiled in 312ms")
    message.print_info(np, "target: javascript")
    message.print_warn(np, "2 deprecation notices")
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
