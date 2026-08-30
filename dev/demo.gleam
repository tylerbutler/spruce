//// A runnable showcase of spruce's terminal-UI features.
////
//// Run it with `just demo` (or `gleam run -m demo`). The demo forces a color
//// level so output is colorful even when stdout is piped; pass `--target
//// javascript` to confirm parity on the JavaScript target.

import gleam/int
import gleam/io
import gleam/list
import gleam/string
import spruce
import spruce/align
import spruce/border
import spruce/box
import spruce/detail
import spruce/item
import spruce/line
import spruce/markdown
import spruce/message
import spruce/output
import spruce/severity
import spruce/style
import spruce/symbol
import spruce/table
import spruce/tree

pub fn main() {
  // Force truecolor so the demo is vivid even when stdout is not a TTY.
  let context = spruce.with_color_level(spruce.TrueColor)

  banner("spruce — a terminal-UI kit for Gleam")
  io.println("color level: " <> color_level_name(spruce.color_level(context)))
  io.println("")

  style_section(context)
  symbol_section(context)
  message_section(context)
  formatter_section(context)
  hashed_section(context)
  box_section(context)
  list_section(context)
  tree_section(context)
  table_section(context)
  markdown_section(context)
  align_section(context)
  layout_section(context)
  group_section(context)
  output_section(context)

  io.println("")
  io.println(message.success(context, "Demo complete."))
}

fn banner(title: String) -> Nil {
  let context = spruce.with_color_level(spruce.TrueColor)
  box.simple(context, title)
  |> io.println
}

fn heading(label: String) -> Nil {
  let context = spruce.with_color_level(spruce.TrueColor)
  let styled =
    style.render(
      context,
      style.new() |> style.bold |> style.fg(style.BrightCyan),
      "▌ " <> label,
    )
  io.println("")
  io.println(styled)
  io.println("")
}

fn style_section(context: spruce.Spruce) -> Nil {
  heading("style — composable ANSI styling")

  let samples = [
    #("bold", style.new() |> style.bold),
    #("dim", style.new() |> style.dim),
    #("italic", style.new() |> style.italic),
    #("underline", style.new() |> style.underline),
    #("strikethrough", style.new() |> style.strikethrough),
    #("reverse", style.new() |> style.reverse),
    #(
      "red on white",
      style.new() |> style.fg(style.Red) |> style.bg(style.White),
    ),
    #("bright green", style.new() |> style.fg(style.BrightGreen)),
    #("magenta bold", style.new() |> style.fg(style.Magenta) |> style.bold),
  ]

  list.each(samples, fn(pair) {
    let #(label, text_style) = pair
    io.println("  " <> style.render(context, text_style, label))
  })
}

fn symbol_section(_sp: spruce.Spruce) -> Nil {
  heading("symbol — icons with ASCII fallbacks")

  let statuses = [
    #("info", symbol.Info),
    #("warn", symbol.Warn),
    #("error", symbol.Error),
    #("success", symbol.Success),
    #("start", symbol.Start),
    #("notice", symbol.Notice),
    #("alert", symbol.Alert),
    #("bullet", symbol.Bullet),
    #("arrow", symbol.Arrow),
  ]

  let row = fn(mode: symbol.Mode) {
    statuses
    |> list.map(fn(pair) {
      let #(name, status) = pair
      symbol.status(mode, status) <> " " <> name
    })
    |> string.join("    ")
  }

  io.println("  unicode: " <> row(symbol.Unicode))
  io.println("  ascii:   " <> row(symbol.Ascii))
}

fn message_section(context: spruce.Spruce) -> Nil {
  heading("message — semantic one-liners")

  io.println("  " <> message.start(context, "Building project…"))
  io.println("  " <> message.info(context, "Resolving 12 dependencies"))
  io.println("  " <> message.warn(context, "Deprecated option in config"))
  io.println("  " <> message.success(context, "Compiled in 0.42s"))
  io.println("  " <> message.fail(context, "1 test failed"))
  io.println("  " <> message.error(context, "Could not reach registry"))
  io.println("  " <> message.ready(context, "Server listening on :8080"))

  io.println("")
  io.println(style.render(
    context,
    style.new() |> style.dim,
    "  for badges, details, timestamps, and scopes, compose a spruce/line:",
  ))

  let deprecation =
    detail.new()
    |> detail.add(key: "option", value: "legacy_mode")
    |> detail.add(key: "since", value: "0.4.0")

  line.new("Deprecated option in config")
  |> line.severity(severity.Warning)
  |> line.severity_formatter(severity.badge())
  |> line.details(deprecation)
  |> line.render(context, _)
  |> fn(rendered) { io.println("  " <> rendered) }
}

fn formatter_section(context: spruce.Spruce) -> Nil {
  heading("severity/details/line — compact status lines")

  let request =
    detail.new()
    |> detail.add(key: "method", value: "GET")
    |> detail.add(key: "path", value: "/api/users")
    |> detail.add(key: "duration", value: "42ms")

  line.new("Request complete")
  |> line.timestamp("2026-06-05T20:00:00Z")
  |> line.scope("api.http")
  |> line.severity(severity.Info)
  |> line.details(request)
  |> line.render(context, _)
  |> fn(rendered) { io.println("  " <> rendered) }

  io.println(
    "  "
    <> severity.render(context, severity.badge(), severity.Warning)
    <> " "
    <> "Configuration uses deprecated option",
  )
}

fn hashed_section(context: spruce.Spruce) -> Nil {
  heading("style.hashed — deterministic hash colors")

  ["alice", "bob", "carol", "dave", "spruce", "gleam"]
  |> list.map(fn(name) {
    style.render(context, style.hashed(context, name), name)
  })
  |> string.join("  ")
  |> fn(line) { io.println("  " <> line) }
}

fn box_section(context: spruce.Spruce) -> Nil {
  heading("box — bordered output")

  box.simple(context, "A simple default box")
  |> io.println

  io.println("")

  let options =
    box.new()
    |> box.title("Release")
    |> box.border_color(style.Green)
    |> box.padding(top: 1, right: 2, bottom: 1, left: 2)

  box.render(context, "spruce 0.1.0\nready to ship", options)
  |> io.println

  io.println("")

  let double =
    box.new()
    |> box.title("Double")
    |> box.border(border.Double)
    |> box.border_color(style.Magenta)
    |> box.padding(top: 0, right: 1, bottom: 0, left: 1)

  box.render(context, "thick borders\nfor emphasis", double)
  |> io.println
}

fn list_section(context: spruce.Spruce) -> Nil {
  heading("items — bullet and ordered lists")

  item.new()
  |> item.item("Fetch dependencies")
  |> item.child("Compile sources", [
    "spruce.gleam",
    "style.gleam",
    "box.gleam",
  ])
  |> item.item("Run tests")
  |> item.render(context, _)
  |> io.println

  io.println("")

  item.new()
  |> item.kind(item.Ordered)
  |> item.item("Plan the work")
  |> item.item("Do the work")
  |> item.item("Ship the work")
  |> item.render(context, _)
  |> io.println
}

fn tree_section(context: spruce.Spruce) -> Nil {
  heading("tree — nested structure")

  tree.root("spruce")
  |> tree.child(
    child: tree.root("src")
    |> tree.child(child: tree.root("spruce.gleam"))
    |> tree.child(
      child: tree.root("spruce")
      |> tree.child(child: tree.root("style.gleam"))
      |> tree.child(child: tree.root("box.gleam"))
      |> tree.child(child: tree.root("table.gleam")),
    ),
  )
  |> tree.child(
    child: tree.root("test")
    |> tree.child(child: tree.root("spruce_test.gleam")),
  )
  |> tree.render(context, _)
  |> io.println
}

fn table_section(context: spruce.Spruce) -> Nil {
  heading("table — bordered data grid")

  table.new()
  |> table.headers(["Module", "Lines", "Target"])
  |> table.rows([
    ["style", "112", "both"],
    ["box", "506", "both"],
    ["table", "180", "both"],
    ["tree", "90", "both"],
  ])
  |> table.style_fn(fn(row, _col) {
    case row {
      -1 -> style.new() |> style.bold |> style.fg(style.BrightYellow)
      _ -> style.new()
    }
  })
  |> table.render(context, _)
  |> io.println
}

fn markdown_section(context: spruce.Spruce) -> Nil {
  heading("markdown — rendered Markdown with syntax highlighting")

  let markdown_document =
    "# Spruce Markdown

Spruce can render **Markdown** straight to the terminal, with *emphasis*,
~~strikethrough~~, `inline code`, and [links](https://hexdocs.pm/spruce).

> Block quotes get a colored left border.

> [!NOTE]
> GitHub-style alerts render as colored callouts.

:::tip[Astro asides too]
Both `> [!TYPE]` alerts and Astro `:::` directives are supported.
:::

- Bullet lists
- With **styled** items
- And `code spans`

1. Ordered lists too
2. Numbered automatically"

  markdown.render_with(
    context,
    markdown_document,
    markdown.default_options() |> markdown.with_width(64),
  )
  |> io.println

  io.println("")
  io.println(style.render(
    context,
    style.new() |> style.bold,
    "Fenced code blocks are highlighted for many languages:",
  ))
  io.println("")

  let code_doc =
    "```gleam
import gleam/io

pub fn main() -> Nil {
  let greeting = \"Hello, spruce!\"
  io.println(greeting)
}
```

```python
def greet(name: str) -> None:
    # f-strings, keywords, and builtins all get colors
    print(f\"Hello, {name}!\")
```

```sql
SELECT name, color_level
FROM terminals
WHERE supports_truecolor = TRUE
ORDER BY name;
```

```json
{
  \"name\": \"spruce\",
  \"highlight\": true,
  \"languages\": 30
}
```

```bash
# Run the demo on both targets
gleam run -m demo --target erlang
gleam run -m demo --target javascript
```"

  markdown.render_with(
    context,
    code_doc,
    markdown.default_options() |> markdown.with_width(64),
  )
  |> io.println

  markdown_themes_section(context)
}

fn markdown_themes_section(context: spruce.Spruce) -> Nil {
  io.println("")
  io.println(style.render(
    context,
    style.new() |> style.bold,
    "The same snippet rendered with the dark and light themes:",
  ))
  io.println("")

  let snippet =
    "```rust
fn main() {
    let count = 42; // colored comment
    println!(\"spruce: {}\", count);
}
```"

  let dark =
    markdown.render_with(
      context,
      snippet,
      markdown.default_options()
        |> markdown.with_width(40)
        |> markdown.with_theme(markdown.dark_theme()),
    )
  let light =
    markdown.render_with(
      context,
      snippet,
      markdown.default_options()
        |> markdown.with_width(40)
        |> markdown.with_theme(markdown.light_theme()),
    )

  io.println("  dark_theme()")
  io.println(indent(dark, 2))
  io.println("  light_theme()")
  io.println(indent(light, 2))
}

fn align_section(context: spruce.Spruce) -> Nil {
  heading("align — ANSI-aware padding and truncation")

  let styled =
    style.render(context, style.new() |> style.fg(style.Cyan), "colored")
  io.println(
    "  visual_length(\"colored\") = "
    <> int.to_string(align.visual_length(styled)),
  )
  io.println("  pad_right : [" <> align.pad_right("left", 12) <> "]")
  io.println("  pad_left  : [" <> align.pad_left("right", 12) <> "]")
  io.println("  pad_center: [" <> align.pad_center("mid", 12) <> "]")
  io.println(
    "  truncate  : "
    <> align.truncate("a rather long sentence", width: 14, ellipsis: "…"),
  )
  io.println("  wrap:")
  align.wrap(
    "Spruce keeps width-aware wrapping deterministic across targets.",
    24,
  )
  |> indent(2)
  |> io.println
}

fn layout_section(context: spruce.Spruce) -> Nil {
  heading("align — composing blocks")

  let left =
    box.render(
      context,
      "left\nblock",
      box.new() |> box.title("A") |> box.border_color(style.Blue),
    )
  let right =
    box.render(
      context,
      "right\nblock",
      box.new() |> box.title("B") |> box.border_color(style.Green),
    )

  align.join_horizontal(align.Center, [left, "   ", right])
  |> io.println
}

fn group_section(context: spruce.Spruce) -> Nil {
  heading("output — eager, streaming groups")

  use context <- output.stream_group(context, "build")
  io.println(message.start(context, "compiling"))

  use context <- output.stream_group(context, "test")
  io.println(message.success(context, "erlang target green"))
  io.println(message.success(context, "javascript target green"))
}

fn output_section(context: spruce.Spruce) -> Nil {
  heading("output — pipeable, buffered composition")

  output.new(context)
  |> output.append(message.start(_, "compiling"))
  |> output.group("test", fn(buffer) {
    buffer
    |> output.append(message.success(_, "erlang target green"))
    |> output.append(message.success(_, "javascript target green"))
  })
  |> output.append(message.ready(_, "release ready"))
  |> output.print
}

fn color_level_name(level: spruce.ColorLevel) -> String {
  case level {
    spruce.NoColor -> "NoColor"
    spruce.Basic -> "Basic"
    spruce.Ansi256 -> "Ansi256"
    spruce.TrueColor -> "TrueColor"
  }
}

// Prefix every line of `text` with `level` levels of two-space indentation.
fn indent(text: String, level: Int) -> String {
  let prefix = string.repeat("  ", level)

  text
  |> string.split("\n")
  |> list.map(fn(line) { prefix <> line })
  |> string.join("\n")
}
