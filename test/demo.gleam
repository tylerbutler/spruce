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
import spruce/box
import spruce/details
import spruce/group
import spruce/layout
import spruce/line
import spruce/list as splist
import spruce/markdown
import spruce/message
import spruce/output
import spruce/palette
import spruce/severity
import spruce/style
import spruce/symbol
import spruce/table
import spruce/tree
import tty

pub fn main() {
  // Force truecolor so the demo is vivid even when stdout is not a TTY.
  let sp = spruce.with_color_level(tty.TrueColor)

  banner("spruce — a terminal-UI kit for Gleam")
  io.println("color level: " <> color_level_name(spruce.color_level(sp)))
  io.println("")

  style_section(sp)
  symbol_section(sp)
  message_section(sp)
  formatter_section(sp)
  palette_section(sp)
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
  let sp = spruce.with_color_level(tty.TrueColor)
  box.simple(sp, title)
  |> io.println
}

fn heading(label: String) -> Nil {
  let sp = spruce.with_color_level(tty.TrueColor)
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

  let icons = [
    #("info", symbol.info),
    #("warn", symbol.warn),
    #("error", symbol.error),
    #("success", symbol.success),
    #("start", symbol.start),
    #("notice", symbol.notice),
    #("alert", symbol.alert),
    #("bullet", symbol.bullet),
    #("arrow", symbol.arrow),
  ]

  icons
  |> list.map(fn(pair) {
    let #(name, glyph) = pair
    glyph <> " " <> name
  })
  |> string.join("    ")
  |> fn(line) { io.println("  " <> line) }

  io.println(
    "  ascii: "
    <> string.join(
      [
        symbol.info_ascii,
        symbol.warn_ascii,
        symbol.error_ascii,
        symbol.success_ascii,
        symbol.start_ascii,
        symbol.arrow_ascii,
        symbol.bullet_ascii,
      ],
      " ",
    ),
  )
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
    "  the *_with variants take Options — formatters and trailing details:",
  ))

  // Badge formatter: uppercase bracketed prefix, e.g. [WARN].
  let badge_options =
    message.default_options()
    |> message.with_formatter(message.badge())
  io.println(
    "  " <> message.warn_with(sp, "Deprecated option in config", badge_options),
  )
  io.println(
    "  " <> message.error_with(sp, "Could not reach registry", badge_options),
  )

  // Simple formatter: bare uppercase label, no icon.
  let simple_options =
    message.default_options()
    |> message.with_formatter(message.simple())
  io.println(
    "  " <> message.info_with(sp, "Resolving dependencies", simple_options),
  )

  // Details suffix: trailing key-value pairs after the message text.
  let warn_details =
    details.new()
    |> details.add(key: "option", value: "legacy_mode")
    |> details.add(key: "since", value: "0.4.0")
  let detail_options =
    message.default_options()
    |> message.with_details(warn_details)
  io.println(
    "  " <> message.warn_with(sp, "Deprecated option in config", detail_options),
  )

  // Badge plus details together.
  let combined_options =
    message.default_options()
    |> message.with_formatter(message.badge())
    |> message.with_details(
      details.new()
      |> details.add(key: "status", value: "500")
      |> details.add(key: "retries", value: "3"),
    )
  io.println(
    "  " <> message.fail_with(sp, "Upstream request failed", combined_options),
  )
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

fn palette_section(sp: spruce.Spruce) -> Nil {
  heading("palette — deterministic hash colors")

  ["alice", "bob", "carol", "dave", "spruce", "gleam"]
  |> list.map(fn(name) { style.render(sp, palette.hash(sp, name), name) })
  |> string.join("  ")
  |> fn(line) { io.println("  " <> line) }
}

fn box_section(sp: spruce.Spruce) -> Nil {
  heading("box — bordered output")

  box.simple(sp, "A simple default box")
  |> io.println

  io.println("")

  let opts =
    box.options(title: "Release", color: style.Green)
    |> box.border(box.Rounded)
    |> box.padding(top: 1, right: 2, bottom: 1, left: 2)

  box.render(sp, "spruce 0.1.0\nready to ship", opts)
  |> io.println

  io.println("")

  let double =
    box.options(title: "Double", color: style.Magenta)
    |> box.border(box.Double)
    |> box.padding(top: 0, right: 1, bottom: 0, left: 1)

  box.render(sp, "thick borders\nfor emphasis", double)
  |> io.println
}

fn list_section(sp: spruce.Spruce) -> Nil {
  heading("list — bullet and ordered lists")

  splist.new()
  |> splist.item("Fetch dependencies")
  |> splist.child("Compile sources", [
    "spruce.gleam",
    "style.gleam",
    "box.gleam",
  ])
  |> splist.item("Run tests")
  |> splist.render(sp, _)
  |> io.println

  io.println("")

  splist.new()
  |> splist.kind(splist.Ordered)
  |> splist.item("Plan the work")
  |> splist.item("Do the work")
  |> splist.item("Ship the work")
  |> splist.render(sp, _)
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
  io.println(group.indent(dark, 2))
  io.println("  light_theme()")
  io.println(group.indent(light, 2))
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
  |> group.indent(2)
  |> io.println
}

fn layout_section(sp: spruce.Spruce) -> Nil {
  heading("layout — composing blocks")

  let left =
    box.render(sp, "left\nblock", box.options(title: "A", color: style.Blue))
  let right =
    box.render(sp, "right\nblock", box.options(title: "B", color: style.Green))

  layout.join_horizontal(layout.Center, [left, "   ", right])
  |> io.println
}

fn group_section(sp: spruce.Spruce) -> Nil {
  heading("group — depth-in-context indentation")

  use sp <- group.group(sp, "build")
  io.println(group.indent(message.start(sp, "compiling"), spruce.depth(sp)))

  use sp <- group.group(sp, "test")
  io.println(group.indent(
    message.success(sp, "erlang target green"),
    spruce.depth(sp),
  ))
  io.println(group.indent(
    message.success(sp, "javascript target green"),
    spruce.depth(sp),
  ))
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
    tty.NoColor -> "NoColor"
    tty.Basic -> "Basic"
    tty.Ansi256 -> "Ansi256"
    tty.TrueColor -> "TrueColor"
  }
}
