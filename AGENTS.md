# Agent instructions for `spruce`

## Build, test, and lint commands

- Build: `just build` (or `gleam build`)
- Format: `just format` (or `gleam format src test`)
- Lint/format check: `just lint` (or `gleam format --check src test`)
- Docs: `just docs` (or `gleam docs build`)
- Full validation: `just ci` (runs lint, type check, build with warnings-as-errors, tests on both targets, and docs)

Tests run on both targets and must stay green on both:

- `gleam test --target erlang`
- `gleam test --target javascript`

Tests use [`startest`](https://hex.pm/packages/startest): the runner is
`test/spruce_test.gleam`; test functions end in `_test` and are discovered by
reflection. Linting uses [`glinter`](https://hex.pm/packages/glinter).

## What spruce is

A logging-agnostic **terminal-UI kit**: styled text, boxes, semantic message
lines, severity icons, deterministic hash-colors, ANSI-aware alignment, and
grouped/indented output. It was extracted from the "fancy console" features of
the `birch` logging library. Porting birch to consume spruce is **out of scope**
for now.

## High-level architecture

- `src/spruce.gleam` — the `Spruce` context: detection + the two pieces of
  state every render function consults (color level and indent depth). Color
  level and stream detection are delegated to the `tty` package; styling escape
  codes come from `gleam_community_ansi`. spruce itself has **no FFI**.
- Implemented public modules include:
  - `spruce/style` — composable `Style` builder, gated by color level
  - `spruce/symbol` — icon/glyph set with ASCII fallbacks
  - `spruce/palette` — deterministic hash color from a string
  - `spruce/align` — ANSI-aware `visual_length` and padding
  - `spruce/box` — boxed output
  - `spruce/group` — depth-in-context indentation/grouping
  - `spruce/message` — semantic one-liners (success/fail/start/ready/info/warn)

## Key conventions

- **Pure string builders, explicit context.** Core render functions are
  `Spruce -> … -> String`. No global state, no IO in the core path (a thin
  `print_*` convenience layer may wrap `gleam/io`).
- **Color gating is centralized in the context.** Functions emit plain text when
  `color_level(sp) == NoColor`; downgrade to the nearest representable color
  rather than emitting unsupported sequences.
- **Indentation lives in the context, not in global state.** Block-producing
  functions (`message.*`, `box.*`, group titles) prepend the context's indent;
  inline functions (`style`, `symbol`, `palette`, `align`) do not. `group` hands
  the body a `spruce.indented` context.
- **Target parity.** Behavior must match on Erlang and JavaScript; validate on
  both targets.
- For release work, add changelog fragments under `.changes/unreleased/` and
  follow the `DEV.md` workflow (release automation updates `gleam.toml` version
  via a release PR).
