<p align="center">
  <img src="https://spruce.tylerbutler.com/spruce.png" alt="spruce logo" width="200" height="200">
</p>

<h1 align="center">spruce</h1>

<p align="center">
  <a href="https://hex.pm/packages/spruce"><img src="https://img.shields.io/hexpm/v/spruce" alt="Package Version"></a>
  <a href="https://hexdocs.pm/spruce/"><img src="https://img.shields.io/badge/hex-docs-ffaff3" alt="Hex Docs"></a>
</p>

A terminal-UI kit for Gleam. spruce renders styled terminal output — colors,
boxes, semantic message lines, icons, deterministic hash-colors, ANSI-aware
alignment, and grouped/indented output — that **automatically respects the
terminal's color support**. It is logging-agnostic and runs on both Erlang and
JavaScript.

spruce builds on [`gleam_community_ansi`](https://hex.pm/packages/gleam_community_ansi)
for styling and [`tty`](https://hex.pm/packages/tty) for color-support detection.

```sh
gleam add spruce
```

```gleam
import spruce

pub fn main() {
  // Detect the terminal's color support once, then thread the context
  // through render functions. Use `spruce.no_color()` for deterministic
  // output (e.g. in tests or when piping).
  let context = spruce.detect()
  echo spruce.supports_color(context)
}
```

## The `Spruce` context

Every render function takes an explicit `Spruce` value, which carries:

- the detected **color level** (`NoColor`, `Basic`, `Ansi256`, `TrueColor`), so
  output is plain text when color is unsupported; and
- the current **indent depth**, so grouped output nests without any global
  state.

This keeps rendering pure and testable: `spruce.no_color()` produces
escape-free, deterministic strings.

## Modules

- `spruce` — the `Spruce` context (color level + terminal background + indent depth)
- `spruce/style` — composable text styling (named, RGB/hex/256, complete, and adaptive light/dark colors) and deterministic hash colors
- `spruce/symbol` — named glyphs (with ASCII fallbacks)
- `spruce/align` — ANSI-aware length, padding, wrapping, and multi-line block composition
- `spruce/border` — border styles and glyphs shared by boxes and tables
- `spruce/box` — boxed and styled blocks: title, padding, margin, sizing, alignment, per-side borders and colors
- `spruce/table` — tables with widths, borders, separators, and cell wrapping
- `spruce/item` — bulleted/ordered lists with arbitrary nesting
- `spruce/tree` — tree-structured output
- `spruce/severity` — RFC 5424 severity labels, badges, and the status `Formatter`
- `spruce/detail` — key-value detail rendering
- `spruce/line` — compact terminal line composition (timestamp, severity, scope, details)
- `spruce/message` — semantic one-liners (success/fail/start/ready/info/warn/error)
- `spruce/output` — pipeable, buffered output composition and grouping
- `spruce/highlight` — smalto-backed syntax highlighting with adaptive light/dark themes
- `spruce/markdown` — Markdown-to-ANSI rendering (Glamour-style), built on `mork`

## Example

```gleam
import gleam/io
import spruce
import spruce/box
import spruce/message
import spruce/output

pub fn main() {
  let context = spruce.detect()
  box.print(context, "spruce")
  output.stream_group(context, "Building", fn(context) {
    io.println(message.start(context, "compiling"))
    io.println(message.success(context, "done"))
  })
}
```

```gleam
import spruce
import spruce/detail
import spruce/line
import spruce/severity

pub fn compact_line_example() {
  let context = spruce.detect()
  let meta =
    detail.new()
    |> detail.add("duration", "42ms")
    |> detail.add("target", "javascript")

  line.new("Build complete")
  |> line.severity(severity.Info)
  |> line.scope("build")
  |> line.details(meta)
  |> line.render(context, _)
  |> echo

  // Badge-style prefixes come from the severity formatter.
  line.new("Build complete")
  |> line.severity(severity.Notice)
  |> line.severity_formatter(severity.badge())
  |> line.render(context, _)
  |> echo
}
```

## Composability

Every spruce primitive is a plain value or a `String`-returning function, so
they combine freely.

**Styles are reusable values.** Build one with `style.new`, extend it with more
combinators, and apply it with `style.render`. Hash colors and adaptive
light/dark colors compose the same way.

```gleam
import spruce
import spruce/style

pub fn styles() {
  let context = spruce.detect()

  // Build a style once, then derive variants from it.
  let heading = style.new() |> style.bold |> style.underline
  let accent = heading |> style.fg(style.Cyan)
  echo style.render(context, accent, "spruce")

  // `style.hashed` returns a `Style`, so it pipes into more combinators.
  let service = style.hashed(context, "api") |> style.bold
  echo style.render(context, service, "api")

  // Adaptive colors resolve against the detected background at render time.
  let brand =
    style.new()
    |> style.fg(style.adaptive(
      light: style.Hex(0x0369a1),
      dark: style.Hex(0x7dd3fc),
    ))
  echo style.render(context, brand, "brand")
}
```

**Renderers nest, because they all return `String`.** Render a table, then drop
it straight into a box:

```gleam
import spruce
import spruce/box
import spruce/table

pub fn renderers_nest() {
  let context = spruce.detect()

  let grid =
    table.new()
    |> table.headers(["package", "target"])
    |> table.rows([["spruce", "erlang"], ["spruce", "javascript"]])
    |> table.render(context, _)

  box.render(context, grid, box.new() |> box.title("build"))
  |> echo
}
```

**Containers nest their own structure.** Lists and trees compose to any depth,
and the parent's kind and enumerator drive rendering throughout:

```gleam
import spruce
import spruce/item

pub fn lists_nest() {
  let context = spruce.detect()

  item.new()
  |> item.kind(item.Ordered)
  |> item.item("setup")
  |> item.nested(
    "build",
    item.new() |> item.item("erlang") |> item.item("javascript"),
  )
  |> item.render(context, _)
  |> echo
}
```

**Multi-line blocks compose side by side.** `spruce/align` joins blocks
horizontally or vertically while staying ANSI-aware:

```gleam
import gleam/string
import spruce/align

pub fn columns() {
  let names = ["package", "spruce", "tty"] |> string.join("\n")
  let versions = ["version", "2.0.0", "1.1.0"] |> string.join("\n")

  // Each block is padded to its own width, so the columns line up.
  align.join_horizontal(align.Start, [names, "   ", versions])
  |> echo
}
```

**Thread the context through a pipeline.** `spruce/output` accumulates rendered
blocks so several renderers — and nested groups — compose with `|>` and emit
together. `append` works with any `Spruce -> String` renderer via a `_` capture,
and nothing prints until `print`:

```gleam
import spruce
import spruce/message
import spruce/output

pub fn report() {
  let context = spruce.detect()

  output.new(context)
  |> output.append(message.start(_, "compiling"))
  |> output.group("Tests", fn(buffer) {
    buffer
    |> output.append(message.success(_, "erlang"))
    |> output.append(message.success(_, "javascript"))
  })
  |> output.append(message.ready(_, "release ready"))
  |> output.print
}
```

For eager, streaming grouping that prints as work happens and can return a value
from the body, reach for `output.stream_group` instead.

## Development

```sh
just build   # compile
just test    # run tests on both targets
just lint    # format check + glinter
just ci      # full validation
```

Further documentation will be available at <https://hexdocs.pm/spruce>.
