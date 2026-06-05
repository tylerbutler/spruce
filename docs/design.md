# spruce — design

> **Status:** approved design (brainstorming output), pre-implementation.
> **Date:** 2026-06-05
> **Location note:** This spec currently lives in the birch repo because spruce is
> being spun out of birch. It should be copied into the `spruce/` repo once that
> repo is scaffolded.

## Summary

`spruce` is a standalone, **logging-agnostic terminal-UI kit** for Gleam, extracted
from the "fancy console" features currently living inside birch. It provides styled
terminal output — colors, boxes, semantic message lines, severity icons, deterministic
hash-colors, ANSI-aware alignment, and grouped/indented output — that **automatically
respects the terminal's color support**.

It is a new Gleam package, a sibling repo to birch in the workspace, and targets both
**Erlang (BEAM)** and **JavaScript** (Node / Deno / Bun / browser).

### Non-goals (this iteration)

- **Porting birch to consume spruce.** spruce is designed cleanly on its own; birch is
  left untouched for now. Migrating birch's console handler onto spruce is a separate,
  later effort.
- Spinners, progress bars, interactive prompts (possible future work).
- Global/ambient scope-based auto-indent (deliberately replaced — see Grouping).
- Any custom FFI (the dependencies cover everything spruce needs).

## Decisions (locked during brainstorming)

| Decision | Choice |
|---|---|
| Library scope | General terminal-UI kit, logging-agnostic, reusable by any CLI |
| API approach | Redesigned ergonomic API (not a lift-and-shift of birch's functions) |
| Birch migration | Out of scope for now |
| Coloring | Use `gleam_community_ansi` (don't hand-roll ANSI constants) |
| TTY / color detection | Use the `tty` hex package (don't hand-roll FFI) |
| Color gating | Explicit `Spruce` context value passed to render functions |
| Grouping / indentation | Indent **depth carried in the `Spruce` context** (no global state) |
| Name | `spruce` (tree, pairs with birch; "spruce up" = make it look nicer). Confirmed available on hex.pm |

## Architecture

```
spruce  (depends on gleam_stdlib)
 ├── gleam_community_ansi   → emits the actual color / style escape codes
 └── tty                    → is_tty / detect_color_level (NO_COLOR, FORCE_COLOR, TERM, CI aware)
```

**Core principle: pure string builders, gated by an explicit context.**

- No global mutable state, no FFI, no IO in the core rendering path.
- A `Spruce` value carries the detected `ColorLevel` **and** the current indent depth.
- Every render function takes `sp` and consults it: it emits plain text when color is
  unsupported, and prepends indentation based on depth.
- `spruce.no_color()` (or `with_color_level(NoColor)`) makes all output escape-free and
  fully deterministic — the key testability win of the explicit-context design.

### The `Spruce` context

```gleam
pub opaque type Spruce
// internally: Spruce(color: ColorLevel, depth: Int)

pub fn detect() -> Spruce                  // tty.detect_color_level(tty.Stdout)
pub fn detect_stream(stream: tty.Stream) -> Spruce
pub fn with_color_level(level: ColorLevel) -> Spruce   // explicit, e.g. for tests
pub fn no_color() -> Spruce                // ColorLevel = NoColor, depth = 0

pub fn color_level(sp: Spruce) -> ColorLevel
pub fn supports_color(sp: Spruce) -> Bool
pub fn depth(sp: Spruce) -> Int
pub fn indented(sp: Spruce) -> Spruce      // depth + 1
```

`ColorLevel` (`NoColor | Basic | Ansi256 | TrueColor`) is re-exported from `tty` so
consumers don't import `tty` directly.

## Modules

| Module | Purpose | Indents? | Key API |
|---|---|---|---|
| `spruce` | Context + detection | n/a | `detect`, `with_color_level`, `no_color`, `supports_color`, `indented` |
| `spruce/style` | Composable text styling | no (inline) | `Style` opaque builder: `new() \|> fg(Cyan) \|> bold`; `render(sp, style, text) -> String` |
| `spruce/symbol` | Icon / glyph set | no (inline) | named glyphs (`info`, `warn`, `error`, `success`, `start`, …) + ASCII fallbacks |
| `spruce/palette` | Deterministic hash colors | no (inline) | `hash(sp, text) -> Style` — 256-palette when `Ansi256`+, else 6 basic |
| `spruce/align` | ANSI-aware alignment | no (inline) | `visual_length(text) -> Int`, `pad_right/pad_left(text, width) -> String` |
| `spruce/box` | Boxed output | yes | `render(sp, content, BoxOptions) -> String`, `simple(sp, content) -> String` |
| `spruce/group` | Grouped indentation | yes | `group(sp, title, body: fn(Spruce) -> a) -> a`, `indent(text, level) -> String` |
| `spruce/message` | Semantic one-liners | yes | `success/fail/start/ready/info/warn(sp, text) -> String` + `print_*` convenience |

**Indentation rule:** *block-producing* functions (`message.*`, `box.*`, and the title
line emitted by `group`) prepend `string.repeat("  ", depth(sp))`. *Inline* functions
(`style`, `symbol`, `palette`, `align`) never indent — they produce fragments meant to
be embedded in a line.

### Styling (`spruce/style`)

Wraps `gleam_community_ansi`, but gated by the context's color level:

```gleam
pub opaque type Style
pub fn new() -> Style
pub fn fg(Style, Color) -> Style
pub fn bg(Style, Color) -> Style
pub fn bold(Style) -> Style
pub fn dim(Style) -> Style
pub fn italic(Style) -> Style
pub fn underline(Style) -> Style
pub fn render(sp: Spruce, style: Style, text: String) -> String
```

`render` returns the plain `text` unchanged when `color_level(sp) == NoColor`. Where the
requested color exceeds the terminal's level (e.g. a truecolor hex on a `Basic`
terminal), spruce downgrades to the nearest representable color rather than emitting
unsupported sequences. MVP gate is color/no-color; depth-aware downgrade is a goal and
is exercised mainly via `palette`.

### Grouping (`spruce/group`)

Indent depth lives in the context — no global/ambient state, so it works identically on
all five runtimes.

```gleam
pub fn group(sp: Spruce, title: String, body: fn(Spruce) -> a) -> a {
  io.println(title_line(sp, title))   // title indented at sp's current depth
  body(spruce.indented(sp))           // body receives depth + 1
}

pub fn indent(text: String, level: Int) -> String   // indent every line, manual control
```

Trade-off accepted: a function that does **not** receive `sp` won't auto-indent — but in
spruce you must pass `sp` to render anything, so the threading is already present. This
deliberately replaces birch's ambient process-dict / AsyncLocalStorage depth, which
silently no-ops on Deno/Bun/browser.

## Data flow

1. Caller builds a context once: `let sp = spruce.detect()` (or `no_color()` in tests).
2. Render functions are pure `Spruce -> … -> String`.
3. `box` and `group` use `align.visual_length` internally so colored/styled content
   never corrupts width math.
4. Caller prints the returned strings, or uses the thin `message.print_*` helpers
   (which wrap `gleam/io`).

## Error handling

- Nothing throws. `detect()` falls back to `NoColor` when uncertain (tty's own behavior).
- Pure builders cannot fail.
- `print_*` helpers are best-effort, identical to `gleam/io`.

## Testing

- **gleeunit**, run on **both targets** (`gleam test` and `gleam test --target javascript`).
- Deterministic assertions via `with_color_level(NoColor)` (escape-free output); colored
  assertions via `with_color_level(TrueColor)`.
- **qcheck** properties:
  - `align.visual_length(plain_text) == string.length(plain_text)`
  - `align.visual_length` ignores ANSI escape codes (styled vs plain have equal visual length)
  - `align.pad_right(text, w)` yields visual length `max(w, visual_length(text))`
  - `box.render` border width matches the widest content line (ANSI-aware)
  - `group`/`indent` indent every line of a multi-line block

## Repo & tooling

- New sibling repo `spruce/` in the workspace.
- `gleam.toml`: `name = "spruce"`, targets Erlang + JavaScript; deps `gleam_community_ansi`,
  `tty`, `gleam_stdlib`; dev deps `gleeunit`, `qcheck`.
- Mirror birch's developer tooling where it adds value: `just` task runner, `changie`
  changelog fragments, CI running both targets + `gleam format --check`.
- Register the new repo in the workspace `mani` config and add a workspace CLAUDE.md
  pointer (follow-up once scaffolded).

## Open items to verify during implementation

- **JS-target support of `tty`.** birch is dual-target; confirm `tty` resolves color
  level on the JS target. If it's Erlang-only, spruce should degrade to `NoColor` on JS
  (or add a tiny JS-only detection shim) rather than break the build.
- Confirm `gleam_community_ansi`'s JS-target support (expected: pure Gleam, both targets).

## Feature mapping (birch → spruce)

| birch today | spruce |
|---|---|
| `internal/ansi` constants | dropped; `gleam_community_ansi` + `spruce/style` |
| `platform.is_stdout_tty` / `get_color_depth` (FFI) | dropped; `tty` package via `spruce` context |
| `formatter.hash_color` | `spruce/palette.hash` |
| `level_formatter` icons/colors | `spruce/symbol` + `spruce/style` (severity-agnostic; birch keeps its level coupling) |
| `console.box` / `box_with_title` / `box_colored` | `spruce/box` |
| `console.success/start/ready/fail` | `spruce/message` |
| `console.with_group` + scope auto-indent | `spruce/group` (depth-in-context) |
| `level_formatter.pad_to_width` / `calculate_visual_length` | `spruce/align` |
