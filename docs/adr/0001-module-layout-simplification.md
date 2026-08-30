# ADR 0001: Simplify the module layout for 2.0

- **Status:** Accepted (implemented for 2.0)
- **Date:** 2026-08-24
- **Scope:** `src/spruce.gleam` and `src/spruce/*`
- **Breaking:** Yes — targets a 2.0 release

## Context

spruce 1.0 ships 20 modules (`spruce`, 18 public `spruce/*` modules, and
`spruce/internal/layout`) totalling roughly 6.5k lines of source. The
dependency graph is a clean DAG — `spruce` is the root, `style` and `align` are
leaves, `markdown` sits at the top — and the core conventions (explicit
`Spruce` context, pure `Spruce -> … -> String` renderers, indentation carried in
the context) are consistently applied.

The modules were added incrementally, though, and several of them overlap:
two box renderers, three "status prefix" systems, two indentation helpers, two
grouping APIs, and private helpers (`repeat_line`, `find_max_width`,
`non_negative`, `padding_counts`, `border_chars`) copied between modules.
`DEV.md` commits 1.x to additive changes, so these can only be cleaned up in a
major release.

## Findings

Ordered by expected payoff.

### 1. `box` and `block` are two implementations of the same thing

`src/spruce/block.gleam` (570 lines) is a superset of `src/spruce/box.gleam`
(685 lines) minus the title: both implement padding, margin, width, and
per-side border visibility and colors. Each has a private copy of
`border_chars`, `border_painter`, `Sides`, `apply_margin`, `repeat_line`,
`find_max_width`, and `non_negative` (compare `box.gleam:412` with
`block.gleam:426`).

`box.BoxOptions` (`box.gleam:40`) also has a two-constructor shape
(`BoxOptions` / `ConfiguredBoxOptions`) that is normalized to a private
`BoxConfig` on every setter call. `block` uses a straightforward builder.

`table` imports `box` only for the `Border` / `BorderChars` types
(`table.gleam:23,30,524`) and carries its own hand-written glyph tables for
each border style.

### 2. `spruce/internal/layout` collides with `spruce/layout`

`internal/layout.gleam` is a six-line module exposing `indent_prefix`. Seven
modules import it, and `block` has to alias it as `internal_layout` because
the public `layout` module is also in scope. Meanwhile `list` and `tree`
inline `string.repeat("  ", spruce.depth(context))` instead of using it, and
`group.indent` reimplements the same thing for arbitrary levels.

### 3. `message`, `severity`, `line`, and `symbol` are three overlapping status systems

- `message.Kind` (7 kinds) with `message.Formatter` (`Label` / `Badge` /
  `Simple` / `Custom`)
- `severity.Severity` (8 RFC 5424 / OTP Logger levels) with `severity.Formatter` — the same
  four constructors plus icons, glyph mode, and target width
- `symbol.Status` — a third enum of 11 statuses
- `line` is `message` plus timestamp and scope, but keyed on `Severity` rather
  than `Kind`

`message.gleam` is 305 lines with 30 exports because every kind has an `x`,
`x_with`, and `print_x` variant. `line_with` is a public re-export of the
private `line_options`, and `uppercase` (`message.gleam:294`) is a hand-rolled
`string.uppercase`.

### 4. `layout` duplicates `block`'s positioning logic

`layout.padding_counts`, `pad`, `repeat_line`, and `place`
(`layout.gleam:99-170`) are private twins of `block.padding_counts`,
`pad_pos`, `repeat_line`, and `fit_height` (`block.gleam:259-290`). `layout`
is otherwise "more ANSI-aware geometry" of the kind `align` already owns
(`size`, `height`, `pad_*`, `wrap`, `truncate`).

### 5. `group` exists mostly to serve `output`

`group.render_title` is public only so `output.group` can reuse it
(`group.gleam:26`). `group.group` is the eager/IO twin of the buffered
`output.group`, and `group.indent` is an unrelated string helper (see #2).

### 6. Smaller items

- **`palette`** is a one-function module. `hash` belongs next to `Color` in
  `style`.
- **`symbol`** exposes 18 `pub const` glyphs *and* `status(mode, status)`,
  which returns the same glyphs. `resolve` is a trivial `case` on `Mode`.
- **`spruce/list`** shadows both `gleam/list` and the prelude `List` type.
  Every importer aliases it (`splist`, `ui_list`, `gleam_list`), and it needs a
  glinter `missing_type_annotation` ignore because `child`'s `children`
  parameter cannot be typed (`list.gleam:53`).
- **`tty` re-exports do not achieve independence.** `spruce.ColorLevel`,
  `Stream`, and `Background` (`spruce.gleam:31-43`) are type aliases, and
  aliases do not re-export constructors — `dev/demo.gleam:28` still has to
  `import tty` to write `tty.TrueColor`.
- **`highlight` and `markdown`** make `smalto` (40 grammar modules) and `mork`
  hard dependencies for every consumer, including those who only want `style`
  or `box`.

## Decision

Reshape the package to 16 modules for 2.0:

| Module | Change |
|---|---|
| `spruce` | Gains `indent_prefix(context)`. Replaces `tty` type aliases with spruce-owned enums (or drops the aliases and documents `tty` as the API). |
| `spruce/style` | Absorbs `palette`: `palette.hash(context, text)` becomes `style.hashed(context, text)`. |
| `spruce/symbol` | Drops the `pub const` glyphs and `resolve`; `Mode`, `Status`, and `status` remain. |
| `spruce/align` | Absorbs `layout`: `Pos`, `join_vertical`, `join_horizontal`, `place`. |
| `spruce/border` | **New leaf.** `Border`, `BorderChars`, and `chars(Border) -> BorderChars`, shared by `box` and `table`. |
| `spruce/box` | Absorbs `block`: one builder (`new |> padding |> margin |> width |> height |> align |> border |> title |> render`). Uses `align.place` and `border.chars` instead of private copies. |
| `spruce/table` | Uses `spruce/border`; derives grid glyphs from `border.chars` where possible. |
| `spruce/item` | Renamed from `spruce/list`; opaque type renamed `List` → `Items`. |
| `spruce/tree` | Unchanged. |
| `spruce/severity` | Owns the single `Formatter` type used by both `line` and `message`. |
| `spruce/detail` | Unchanged. |
| `spruce/line` | Unchanged API; uses `severity.Formatter`. |
| `spruce/message` | Thin sugar over `line`: seven one-liners (`success`, `fail`, `start`, `ready`, `info`, `warn`, `error`). The `_with` and `print_*` variants are removed — use `line` for options and `io.println` for IO. |
| `spruce/output` | Absorbs `group`: `render_title` → `output.title`; eager grouping becomes `output.stream_group` (or is dropped — it is two lines at the call site). |
| `spruce/highlight` | Unchanged. |
| `spruce/markdown` | Unchanged. |

Removed: `block`, `layout`, `internal/layout`, `group`, `palette`. The
`internal_modules` entry in `gleam.toml` and the `list.gleam`
`missing_type_annotation` glinter ignore go with them.

Deferred: splitting `highlight` and `markdown` into a `spruce_markdown`
package. It is the only layout choice with a cost for downstream users, but it
is independent of everything above and can be decided separately.

## Consequences

- Roughly 500 duplicated lines removed from `box`/`block`, plus the duplicated
  positioning and indentation helpers.
- One builder for boxes, one `Formatter` for status prefixes, one place for
  indentation, one "compose and emit" module.
- All public import paths except `spruce/tree`, `spruce/detail`,
  `spruce/highlight`, and `spruce/markdown` change in some way; every consumer
  needs a migration pass. README, `AGENTS.md`, the hexdocs, the website module
  groups (`website/src/App.tsx`), and `dev/demo.gleam` must be updated.
- `align` grows to roughly 900 lines. Acceptable given it is one cohesive
  concern (ANSI-aware text geometry), but worth re-checking after the merge.

## Sequencing

Each step is independently shippable on the 2.0 branch.

1. `spruce/border` + `box`/`block` merge (largest dedupe, mostly mechanical).
2. `spruce.indent_prefix`; delete `internal/layout`; fold `group.indent`.
3. Shared `severity.Formatter`; slim `message` to sugar over `line`.
4. Fold `layout` into `align`; point `box` at `align.place`.
5. Fold `group` into `output`.
6. `palette` → `style.hashed`; drop `symbol` consts; rename `list` → `items`;
   resolve the `tty` alias question.
7. Update docs, demo, website module groups; add `.changes/unreleased/`
   fragments per step.

## Resolution of open choices

Decisions taken while implementing:

- `spruce` owns `ColorLevel`, `Background`, and `Stream` enums and converts
  at the `tty` detection boundary, rather than documenting `tty` as the API.
- `box.new()` keeps the 1.x default box (rounded cyan border, one cell of
  horizontal padding); `box.plain()` is the borderless, unpadded starting
  point that `block.new()` used to be. `box.simple` and `box.print` stay.
- The eager grouping form is kept as `output.stream_group`.
- `group.indent` is dropped without replacement; `spruce.indent_prefix`
  covers the context case and callers can prefix lines themselves.
- `message` renders its seven lines directly (there is no RFC 5424 severity
  for success/fail/start/ready) and no longer takes options; `line` with
  `severity.Formatter` is the configurable path.
