# spruce

[![Package Version](https://img.shields.io/hexpm/v/spruce)](https://hex.pm/packages/spruce)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/spruce/)

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

## Status

Early development. The `Spruce` context is in place; the styling, box, message,
symbol, palette, alignment, and grouping modules are being implemented. See
the design spec for the full plan.

## Development

```sh
just build   # compile
just test    # run tests on both targets
just lint    # format check + glinter
just ci      # full validation
```

Further documentation will be available at <https://hexdocs.pm/spruce>.
