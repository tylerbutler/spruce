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
import spruce/details
import spruce/items
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
  let sp = spruce.with_color_level(spruce.TrueColor)

  banner("spruce — a terminal-UI kit for Gleam")
  io.println("color level: " <> color_level_name(spruce.color_level(sp)))
  io.println("")

  style_section(sp)
  symbol_section(sp)
  message_section(sp)
  formatter_section(sp)
  hashed_section(sp)
  box_section(sp)
  list_section(sp)
  tree_section(sp)
  table_section(sp)
  markdown_section(sp)
  align_section(sp)
  layout_section(sp)
  group_section(sp)
  output_section(sp)

  io.println("")
  io.println(message.success(sp, "Demo complete."))
}

fn banner(title: String) -> Nil {
  let sp = spruce.with_color_level(spruce.TrueColor)
  box.simple(sp, title)
  |> io.println
}

fn heading(label: String) -> Nil {
  let sp = spruce.with_color_level(spruce.TrueColor)
  let styled =
    style.render(
      sp,
      style.new() |> style.bold |> style.fg(style.BrightCyan),
      "▌ " <> label,
    )
  io.println("")
  io.println(styled)
  io.println("")
}

fn style_section(sp: spruce.Spruce) -> Nil {
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
    let #(label, st) = pair
    io.println("  " <> style.render(sp, st, label))
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

fn message_section(sp: spruce.Spruce) -> Nil {
  heading("message — semantic one-liners")

  io.println("  " <> message.start(sp, "Building project…"))
  io.println("  " <> message.info(sp, "Resolving 12 dependencies"))
  io.println("  " <> message.warn(sp, "Deprecated option in config"))
  io.println("  " <> message.success(sp, "Compiled in 0.42s"))
  io.println("  " <> message.fail(sp, "1 test failed"))
  io.println("  " <> message.error(sp, "Could not reach registry"))
  io.println("  " <> message.ready(sp, "Server listening on :8080"))

  io.println("")
  io.println(style.render(
    sp,
    style.new() |> style.dim,
    "  for badges, details, timestamps, and scopes, compose a spruce/line:",
  ))

  let deprecation =
    details.new()
    |> details.add(key: "option", value: "legacy_mode")
    |> details.add(key: "since", value: "0.4.0")

  line.new("Deprecated option in config")
  |> line.severity(severity.Warn)
  |> line.severity_formatter(severity.badge())
  |> line.details(deprecation)
  |> line.render(sp, _)
  |> fn(rendered) { io.println("  " <> rendered) }
}

fn formatter_section(sp: spruce.Spruce) -> Nil {
  heading("severity/details/line — compact status lines")

  let request =
    details.new()
    |> details.add(key: "method", value: "GET")
    |> details.add(key: "path", value: "/api/users")
    |> details.add(key: "duration", value: "42ms")

  line.new("Request complete")
  |> line.timestamp("2026-06-05T20:00:00Z")
  |> line.scope("api.http")
  |> line.severity(severity.Info)
  |> line.details(request)
  |> line.render(sp, _)
  |> fn(rendered) { io.println("  " <> rendered) }

  io.println(
    "  "
    <> severity.render(sp, severity.badge(), severity.Warn)
    <> " "
    <> "Configuration uses deprecated option",
  )
}

fn hashed_section(sp: spruce.Spruce) -> Nil {
  heading("style.hashed — deterministic hash colors")

  ["alice", "bob", "carol", "dave", "spruce", "gleam"]
  |> list.map(fn(name) { style.render(sp, style.hashed(sp, name), name) })
  |> string.join("  ")
  |> fn(line) { io.println("  " <> line) }
}

fn box_section(sp: spruce.Spruce) -> Nil {
  heading("box — bordered output")

  box.simple(sp, "A simple default box")
  |> io.println

  io.println("")

  let opts =
    box.new()
    |> box.title("Release")
    |> box.border_color(style.Green)
    |> box.padding(top: 1, right: 2, bottom: 1, left: 2)

  box.render(sp, "spruce 0.1.0\nready to ship", opts)
  |> io.println

  io.println("")

  let double =
    box.new()
    |> box.title("Double")
    |> box.border(border.Double)
    |> box.border_color(style.Magenta)
    |> box.padding(top: 0, right: 1, bottom: 0, left: 1)

  box.render(sp, "thick borders\nfor emphasis", double)
  |> io.println
}

fn list_section(sp: spruce.Spruce) -> Nil {
  heading("items — bullet and ordered lists")

  items.new()
  |> items.item("Fetch dependencies")
  |> items.child("Compile sources", [
    "spruce.gleam",
    "style.gleam",
    "box.gleam",
  ])
  |> items.item("Run tests")
  |> items.render(sp, _)
  |> io.println

  io.println("")

  items.new()
  |> items.kind(items.Ordered)
  |> items.item("Plan the work")
  |> items.item("Do the work")
  |> items.item("Ship the work")
  |> items.render(sp, _)
  |> io.println
}

fn tree_section(sp: spruce.Spruce) -> Nil {
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
  |> tree.render(sp, _)
  |> io.println
}

fn table_section(sp: spruce.Spruce) -> Nil {
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
  |> table.render(sp, _)
  |> io.println
}

fn markdown_section(sp: spruce.Spruce) -> Nil {
  heading("markdown — rendered Markdown with syntax highlighting")

  let doc =
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
    sp,
    doc,
    markdown.default_options() |> markdown.with_width(64),
  )
  |> io.println

  io.println("")
  io.println(style.render(
    sp,
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
    sp,
    code_doc,
    markdown.default_options() |> markdown.with_width(64),
  )
  |> io.println

  markdown_themes_section(sp)
}

fn markdown_themes_section(sp: spruce.Spruce) -> Nil {
  io.println("")
  io.println(style.render(
    sp,
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
      sp,
      snippet,
      markdown.default_options()
        |> markdown.with_width(40)
        |> markdown.with_theme(markdown.dark_theme()),
    )
  let light =
    markdown.render_with(
      sp,
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

fn align_section(sp: spruce.Spruce) -> Nil {
  heading("align — ANSI-aware padding and truncation")

  let styled = style.render(sp, style.new() |> style.fg(style.Cyan), "colored")
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

fn layout_section(sp: spruce.Spruce) -> Nil {
  heading("align — composing blocks")

  let left =
    box.render(
      sp,
      "left\nblock",
      box.new() |> box.title("A") |> box.border_color(style.Blue),
    )
  let right =
    box.render(
      sp,
      "right\nblock",
      box.new() |> box.title("B") |> box.border_color(style.Green),
    )

  align.join_horizontal(align.Center, [left, "   ", right])
  |> io.println
}

fn group_section(sp: spruce.Spruce) -> Nil {
  heading("output — eager, streaming groups")

  use sp <- output.stream_group(sp, "build")
  io.println(message.start(sp, "compiling"))

  use sp <- output.stream_group(sp, "test")
  io.println(message.success(sp, "erlang target green"))
  io.println(message.success(sp, "javascript target green"))
}

fn output_section(sp: spruce.Spruce) -> Nil {
  heading("output — pipeable, buffered composition")

  output.new(sp)
  |> output.append(message.start(_, "compiling"))
  |> output.group("test", fn(o) {
    o
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
