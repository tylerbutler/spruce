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
  let sp = spruce.detect()
  echo spruce.supports_color(sp)
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
- `spruce/style` — composable text styling (named, RGB/hex/256, complete, and adaptive light/dark colors)
- `spruce/block` — styled blocks: padding, margin, sizing, alignment, per-side borders
- `spruce/symbol` — named glyphs (with ASCII fallbacks)
- `spruce/palette` — deterministic hash colors
- `spruce/align` — ANSI-aware length and padding
- `spruce/layout` — compose multi-line text blocks
- `spruce/box` — boxed output (per-side borders and colors)
- `spruce/table` — tables with widths, borders, separators, and cell wrapping
- `spruce/list` — bulleted/ordered lists with arbitrary nesting
- `spruce/tree` — tree-structured output
- `spruce/group` — depth-in-context grouping (eager/streaming)
- `spruce/output` — pipeable, buffered output composition
- `spruce/message` — semantic one-liners (success/fail/start/ready/info/warn/error), with configurable label/badge/simple prefixes
- `spruce/severity` — generic severity/status labels and badges
- `spruce/details` — key-value detail rendering
- `spruce/line` — compact terminal line composition
- `spruce/highlight` — smalto-backed syntax highlighting with adaptive light/dark themes
- `spruce/markdown` — Markdown-to-ANSI rendering (Glamour-style), built on `mork`

## Example

```gleam
import spruce
import spruce/box
import spruce/group
import spruce/message

pub fn main() {
  let sp = spruce.detect()
  box.print(sp, "spruce")
  group.group(sp, "Building", fn(sp) {
    message.print_start(sp, "compiling")
    message.print_success(sp, "done")
  })
}
```

```gleam
import spruce
import spruce/details
import spruce/line
import spruce/message
import spruce/severity

pub fn compact_line_example() {
  let sp = spruce.detect()
  let meta =
    details.new()
    |> details.add("duration", "42ms")
    |> details.add("target", "javascript")

  line.new("Build complete")
  |> line.severity(severity.Info)
  |> line.scope("build")
  |> line.details(meta)
  |> line.render(sp, _)
  |> echo

  message.success_with(
    sp,
    "Build complete",
    message.default_options() |> message.with_formatter(message.badge()),
  )
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
import spruce/palette
import spruce/style

pub fn styles() {
  let sp = spruce.detect()

  // Build a style once, then derive variants from it.
  let heading = style.new() |> style.bold |> style.underline
  let accent = heading |> style.fg(style.Cyan)
  echo style.render(sp, accent, "spruce")

  // `palette.hash` returns a `Style`, so it pipes into more combinators.
  let service = palette.hash(sp, "api") |> style.bold
  echo style.render(sp, service, "api")

  // Adaptive colors resolve against the detected background at render time.
  let brand =
    style.new()
    |> style.fg(style.adaptive(
      light: style.Hex(0x0369a1),
      dark: style.Hex(0x7dd3fc),
    ))
  echo style.render(sp, brand, "brand")
}
```

**Renderers nest, because they all return `String`.** Render a table, then drop
it straight into a box:

```gleam
import spruce
import spruce/box
import spruce/style
import spruce/table

pub fn renderers_nest() {
  let sp = spruce.detect()

  let grid =
    table.new()
    |> table.headers(["package", "target"])
    |> table.rows([["spruce", "erlang"], ["spruce", "javascript"]])
    |> table.render(sp, _)

  box.render(sp, grid, box.options(title: "build", color: style.Cyan))
  |> echo
}
```

**Containers nest their own structure.** Lists and trees compose to any depth,
and the parent's kind and enumerator drive rendering throughout:

```gleam
import spruce
import spruce/list

pub fn lists_nest() {
  let sp = spruce.detect()

  list.new()
  |> list.kind(list.Ordered)
  |> list.item("setup")
  |> list.nested(
    "build",
    list.new() |> list.item("erlang") |> list.item("javascript"),
  )
  |> list.render(sp, _)
  |> echo
}
```

**Multi-line blocks compose side by side.** `spruce/layout` joins blocks
horizontally or vertically while staying ANSI-aware:

```gleam
import gleam/string
import spruce/layout

pub fn columns() {
  let names = ["package", "spruce", "tty"] |> string.join("\n")
  let versions = ["version", "1.0.0", "1.1.0"] |> string.join("\n")

  // Each block is padded to its own width, so the columns line up.
  layout.join_horizontal(layout.Start, [names, "   ", versions])
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
  let sp = spruce.detect()

  output.new(sp)
  |> output.append(message.start(_, "compiling"))
  |> output.group("Tests", fn(o) {
    o
    |> output.append(message.success(_, "erlang"))
    |> output.append(message.success(_, "javascript"))
  })
  |> output.append(message.ready(_, "release ready"))
  |> output.print
}
```

For eager, streaming grouping that prints as work happens and can return a value
from the body, reach for `spruce/group.group` instead.

## Development

```sh
just build   # compile
just test    # run tests on both targets
just lint    # format check + glinter
just ci      # full validation
```

Further documentation will be available at <https://hexdocs.pm/spruce>.
