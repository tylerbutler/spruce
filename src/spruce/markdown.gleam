//// Markdown to ANSI terminal rendering.
////
//// Rendering is driven by the [`mork`](https://codeberg.org/krig/mork)
//// parser (canonical home: <https://git.liten.app/krig/mork>) and walks its
//// document AST directly rather than going through `mork`'s HTML output.
////
//// ## GFM support
////
//// The following GitHub Flavored Markdown extensions are supported:
////
//// - Tables (rendered via `spruce/table`)
//// - Task list items (`- [x]` / `- [ ]`)
//// - Strikethrough (`~~text~~`)
//// - Extended autolinks for bare URLs and `www.` links
////
//// In addition, GitHub-style alerts (`> [!NOTE]`, `[!TIP]`, `[!IMPORTANT]`,
//// `[!WARNING]`, `[!CAUTION]`) and Astro/Starlight `:::type[Title]` container
//// directives are rendered as colored callouts.
////
//// ## Known limitations
////
//// These are GitHub/Markdown features that are *not* rendered. Most stem from
//// upstream `mork` (tracked in its
//// [TODO.md](https://git.liten.app/krig/mork/src/branch/main/TODO.md)); a few
//// are deliberate choices here.
////
//// - **Emoji shortcodes** (`:rocket:`) are not expanded. `mork` only expands
////   them in its HTML output path, not in the document AST this module
////   renders, so enabling `mork.emojis` has no effect here.
//// - **Email autolinks** (bare `me@example.com`) are not linked; extended
////   email autolinking is unimplemented upstream (`mork` TODO: "autolink
////   (email)").
//// - **Footnotes**: a `[^1]` reference renders as literal `[^1]` and the
////   definition body is dropped. Footnote bodies are not yet implemented
////   upstream, and inline footnotes (`^[...]`) are unsupported.
//// - **Heading ID attributes** (`## Title {#id}`) are stripped from the
////   rendered text (via `mork.heading_ids`), since a terminal has no anchors
////   to link to. The id itself is parsed but not rendered.
//// - **Raw HTML is not sanitized.** Inline and block HTML is passed through
////   (rendered dimmed), not escaped or stripped. `mork` does not implement
////   GFM's tagfilter. This is harmless in a terminal, but do not rely on this
////   module to neutralize untrusted HTML.
////

import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import mork
import mork/document
import spruce.{type Spruce}
import spruce/align
import spruce/border
import spruce/box
import spruce/highlight
import spruce/item
import spruce/style
import spruce/symbol
import spruce/table

/// A set of styles controlling how each Markdown element is rendered.
///
/// Use a built-in theme as a base and replace selected fields:
///
/// ```gleam
/// markdown.Theme(
///   ..markdown.dark_theme(),
///   h1: style.new() |> style.bold |> style.fg(style.Hex(0xff6b6b)),
/// )
/// ```
///
/// The public constructor also supports defining every style from scratch.
pub type Theme {
  Theme(
    h1: style.Style,
    h2: style.Style,
    h3: style.Style,
    h4: style.Style,
    h5: style.Style,
    h6: style.Style,
    emphasis: style.Style,
    strong: style.Style,
    strikethrough: style.Style,
    highlight: style.Style,
    code_span: style.Style,
    link: style.Style,
    link_target: style.Style,
    html: style.Style,
    code: highlight.Theme,
    code_border: style.Color,
    quote_border: style.Color,
    rule: style.Style,
    table_header: style.Style,
  )
}

/// Markdown rendering options: the theme and an optional wrap width.
pub opaque type Options {
  Options(theme: Theme, width: Option(Int))
}

/// Build a theme tuned for dark terminal backgrounds.
pub fn dark_theme() -> Theme {
  Theme(
    h1: style.new() |> style.bold |> style.fg(style.Hex(0x7dd3fc)),
    h2: style.new() |> style.bold |> style.fg(style.Hex(0x93c5fd)),
    h3: style.new() |> style.bold |> style.fg(style.Hex(0xc4b5fd)),
    h4: style.new() |> style.bold |> style.fg(style.Hex(0xf0abfc)),
    h5: style.new() |> style.bold |> style.fg(style.Hex(0xf9a8d4)),
    h6: style.new() |> style.bold |> style.fg(style.Hex(0xfda4af)),
    emphasis: style.new() |> style.italic,
    strong: style.new() |> style.bold,
    strikethrough: style.new() |> style.strikethrough,
    highlight: style.new() |> style.reverse,
    code_span: style.new() |> style.fg(style.Hex(0xfbbf24)) |> style.dim,
    link: style.new() |> style.underline |> style.fg(style.Hex(0x60a5fa)),
    link_target: style.new() |> style.dim,
    html: style.new() |> style.dim,
    code: highlight.dark_theme(),
    code_border: style.Hex(0x64748b),
    quote_border: style.Hex(0x94a3b8),
    rule: style.new() |> style.dim,
    table_header: style.new() |> style.bold,
  )
}

/// Build a theme tuned for light terminal backgrounds.
pub fn light_theme() -> Theme {
  Theme(
    h1: style.new() |> style.bold |> style.fg(style.Hex(0x0369a1)),
    h2: style.new() |> style.bold |> style.fg(style.Hex(0x1d4ed8)),
    h3: style.new() |> style.bold |> style.fg(style.Hex(0x6d28d9)),
    h4: style.new() |> style.bold |> style.fg(style.Hex(0xa21caf)),
    h5: style.new() |> style.bold |> style.fg(style.Hex(0xbe185d)),
    h6: style.new() |> style.bold |> style.fg(style.Hex(0xbe123c)),
    emphasis: style.new() |> style.italic,
    strong: style.new() |> style.bold,
    strikethrough: style.new() |> style.strikethrough,
    highlight: style.new() |> style.reverse,
    code_span: style.new() |> style.fg(style.Hex(0x92400e)) |> style.dim,
    link: style.new() |> style.underline |> style.fg(style.Hex(0x2563eb)),
    link_target: style.new() |> style.dim,
    html: style.new() |> style.dim,
    code: highlight.light_theme(),
    code_border: style.Hex(0x475569),
    quote_border: style.Hex(0x64748b),
    rule: style.new() |> style.dim,
    table_header: style.new() |> style.bold,
  )
}

/// A theme whose colors adapt to the terminal background (light vs dark),
/// resolved per render from `spruce.background`. This is the default theme used
/// by `render` and `default_options`. On `Unknown` backgrounds it renders as
/// dark.
pub fn adaptive_theme() -> Theme {
  let adapt = fn(light: Int, dark: Int) {
    style.adaptive(light: style.Hex(light), dark: style.Hex(dark))
  }
  Theme(
    h1: style.new() |> style.bold |> style.fg(adapt(0x0369a1, 0x7dd3fc)),
    h2: style.new() |> style.bold |> style.fg(adapt(0x1d4ed8, 0x93c5fd)),
    h3: style.new() |> style.bold |> style.fg(adapt(0x6d28d9, 0xc4b5fd)),
    h4: style.new() |> style.bold |> style.fg(adapt(0xa21caf, 0xf0abfc)),
    h5: style.new() |> style.bold |> style.fg(adapt(0xbe185d, 0xf9a8d4)),
    h6: style.new() |> style.bold |> style.fg(adapt(0xbe123c, 0xfda4af)),
    emphasis: style.new() |> style.italic,
    strong: style.new() |> style.bold,
    strikethrough: style.new() |> style.strikethrough,
    highlight: style.new() |> style.reverse,
    code_span: style.new() |> style.fg(adapt(0x92400e, 0xfbbf24)) |> style.dim,
    link: style.new() |> style.underline |> style.fg(adapt(0x2563eb, 0x60a5fa)),
    link_target: style.new() |> style.dim,
    html: style.new() |> style.dim,
    code: highlight.adaptive_theme(),
    code_border: adapt(0x475569, 0x64748b),
    quote_border: adapt(0x64748b, 0x94a3b8),
    rule: style.new() |> style.dim,
    table_header: style.new() |> style.bold,
  )
}

/// Default options: the adaptive theme and no width limit.
pub fn default_options() -> Options {
  Options(theme: adaptive_theme(), width: None)
}

/// Use a specific theme when rendering.
pub fn with_theme(options: Options, theme: Theme) -> Options {
  Options(..options, theme:)
}

/// Wrap rendered output to a maximum visual width, including context
/// indentation and structural markers. Negative values clamp to 0, and 0 keeps
/// the output unconstrained. Structural markers and frames are omitted when the
/// width cannot fit them.
pub fn with_width(options: Options, width: Int) -> Options {
  Options(..options, width: Some(int.max(0, width)))
}

/// Render Markdown to styled terminal text using the default options.
pub fn render(context: Spruce, markdown: String) -> String {
  render_with(context, markdown, default_options())
}

/// Render Markdown to styled terminal text with explicit options.
pub fn render_with(
  context: Spruce,
  markdown: String,
  options: Options,
) -> String {
  let parsed =
    mork.configure()
    |> mork.tables(True)
    |> mork.tasklists(True)
    |> mork.autolinks(True)
    |> mork.heading_ids(True)
    |> mork.parse_with_options(expand_directives(markdown))
  let document.Document(_, blocks, _, _) = parsed

  // Render all blocks at depth zero so that containers (box, table, item)
  // that apply their own indentation do not double-indent nested content.
  // The context's indent prefix is applied once here at the boundary.
  let inner = spruce.flat(context)
  let prefix = spruce.indent_prefix(context)

  case width_after_prefix(options, prefix) {
    Error(Nil) -> ""
    Ok(options) ->
      render_blocks(inner, blocks, parsed, options)
      |> constrain_lines(options.width)
      |> indent_rendered(prefix)
  }
}

/// Render Markdown with the default options and print it to stdout.
pub fn print(context: Spruce, markdown: String) -> Nil {
  io.println(render(context, markdown))
}

fn render_blocks(
  context: Spruce,
  blocks: List(document.Block),
  parsed: document.Document,
  options: Options,
) -> String {
  blocks
  |> render_block_list(context, parsed, options)
  |> remove_empty
  |> string.join("\n\n")
}

fn render_block_list(
  blocks: List(document.Block),
  context: Spruce,
  parsed: document.Document,
  options: Options,
) -> List(String) {
  list.map(blocks, render_block(context, _, parsed, options))
}

fn render_block(
  context: Spruce,
  block_: document.Block,
  parsed: document.Document,
  options: Options,
) -> String {
  case block_ {
    document.BlockQuote(blocks) ->
      render_quote(context, blocks, parsed, options)
    document.BulletList(pack, entries) ->
      render_list(context, pack, entries, None, parsed, options)
    document.Code(language, text) ->
      render_code(context, language, text, options)
    document.Empty -> ""
    document.Heading(level, _, raw, inlines) ->
      render_heading(context, level, raw, inlines, parsed, options)
    document.HtmlBlock(raw) -> render_html_block(context, raw, options)
    document.Newline -> ""
    document.OrderedList(pack, entries, start) ->
      render_list(context, pack, entries, start, parsed, options)
    document.Paragraph(_, inlines) ->
      render_paragraph(context, inlines, parsed, options)
    document.Table(header, rows) ->
      render_table(context, header, rows, parsed, options)
    document.ThematicBreak -> render_rule(context, options)
  }
}

fn render_heading(
  context: Spruce,
  level: Int,
  raw: String,
  inlines: List(document.Inline),
  parsed: document.Document,
  options: Options,
) -> String {
  let text = case render_inlines(context, inlines, parsed, options) {
    "" -> raw
    text -> text
  }
  let marker = string.repeat("#", int.clamp(level, min: 1, max: 6))
  let prefix = marker <> " "
  let prefix_width = align.visual_length(prefix)
  let text = string.trim(text)
  let line = case options.width {
    Some(width) if width > prefix_width ->
      text
      |> align.wrap(width - prefix_width)
      |> prefix_lines(prefix)
    Some(width) if width > 0 -> align.wrap(text, width)
    Some(_) | None -> prefix <> text
  }

  spruce.indent_prefix(context)
  <> style.render(context, heading_style(options.theme, level), line)
}

fn render_paragraph(
  context: Spruce,
  inlines: List(document.Inline),
  parsed: document.Document,
  options: Options,
) -> String {
  render_inlines(context, inlines, parsed, options)
  |> wrap(options.width)
  |> prefix_lines(spruce.indent_prefix(context))
}

fn render_code(
  context: Spruce,
  language: Option(String),
  text: String,
  options: Options,
) -> String {
  let title = option_string(language)
  let highlighted =
    highlight.highlight_named_with(
      context,
      code: text,
      name: title,
      theme: options.theme.code,
    )

  let code_box =
    box.new()
    |> box.title(code_title(title, options.width))
    |> box.border_color(options.theme.code_border)
    |> box.padding(top: 1, right: 0, bottom: 0, left: 0)

  case options.width {
    Some(width) if width > 2 ->
      box.render(context, highlighted, box.width(code_box, width - 2))
    Some(width) if width > 0 -> align.wrap(highlighted, width)
    Some(_) | None -> box.render(context, highlighted, code_box)
  }
}

fn render_quote(
  context: Spruce,
  blocks: List(document.Block),
  parsed: document.Document,
  options: Options,
) -> String {
  case detect_alert(blocks) {
    Some(alert) -> render_admonition(context, alert, parsed, options)
    None -> render_plain_quote(context, blocks, parsed, options)
  }
}

fn render_plain_quote(
  context: Spruce,
  blocks: List(document.Block),
  parsed: document.Document,
  options: Options,
) -> String {
  use <- bool.guard(
    when: width_cannot_fit(options.width, 3),
    return: render_blocks(context, blocks, parsed, options),
  )
  let inner_options = subtract_width(options, 2)
  let content =
    style.render(
      context,
      style.new() |> style.italic,
      render_blocks(context, blocks, parsed, inner_options),
    )

  let quote_box =
    box.plain()
    |> box.border(border.Thick)
    |> box.border_sides(top: False, right: False, bottom: False, left: True)
    |> box.border_color(options.theme.quote_border)
    |> box.padding(top: 0, right: 0, bottom: 0, left: 1)

  box.render(context, content, quote_box)
}

/// A GitHub-style alert / Astro-style aside detected inside a block quote.
type Alert {
  Alert(
    kind: AlertKind,
    title: Option(List(document.Inline)),
    body: List(document.Block),
  )
}

type AlertKind {
  AlertNote
  AlertTip
  AlertImportant
  AlertWarning
  AlertCaution
}

/// Detect a `> [!TYPE] optional title` alert at the head of a block quote and
/// split rendered its (optional) custom title and remaining body blocks.
fn detect_alert(blocks: List(document.Block)) -> Option(Alert) {
  case blocks {
    [document.Paragraph(_, inlines), ..rest] ->
      case inlines {
        [document.Text("["), document.Text(tag), document.Text("]"), ..tail] ->
          case alert_kind_from_tag(tag) {
            Ok(kind) -> {
              let #(title, body_inlines) = split_alert_first_line(tail)
              let body = case body_inlines {
                [] -> rest
                _ -> [document.Paragraph("", body_inlines), ..rest]
              }
              Some(Alert(kind:, title:, body:))
            }
            // nolint: thrown_away_error -- unrecognized alert tag means no alert
            Error(_) -> None
          }
        _ -> None
      }
    _ -> None
  }
}

fn alert_kind_from_tag(tag: String) -> Result(AlertKind, Nil) {
  use <- bool.guard(when: !string.starts_with(tag, "!"), return: Error(Nil))
  alert_kind_from_name(string.drop_start(tag, 1))
}

fn alert_kind_from_name(name: String) -> Result(AlertKind, Nil) {
  case string.lowercase(string.trim(name)) {
    "note" -> Ok(AlertNote)
    "info" -> Ok(AlertNote)
    "tip" -> Ok(AlertTip)
    "important" -> Ok(AlertImportant)
    "warning" -> Ok(AlertWarning)
    "caution" -> Ok(AlertCaution)
    "danger" -> Ok(AlertCaution)
    _ -> Error(Nil)
  }
}

/// Split inlines that follow `[!TYPE]` into an optional same-line title (the
/// inlines before the first line break) and the remaining body inlines.
fn split_alert_first_line(
  inlines: List(document.Inline),
) -> #(Option(List(document.Inline)), List(document.Inline)) {
  let #(before, after) = take_until_break(inlines, [])
  let title = case before {
    [] -> None
    _ -> Some(before)
  }
  #(title, after)
}

fn take_until_break(
  inlines: List(document.Inline),
  accumulator: List(document.Inline),
) -> #(List(document.Inline), List(document.Inline)) {
  case inlines {
    [] -> #(list.reverse(accumulator), [])
    [document.SoftBreak, ..rest] -> #(list.reverse(accumulator), rest)
    [document.HardBreak, ..rest] -> #(list.reverse(accumulator), rest)
    [first, ..rest] -> take_until_break(rest, [first, ..accumulator])
  }
}

fn render_admonition(
  context: Spruce,
  alert: Alert,
  parsed: document.Document,
  options: Options,
) -> String {
  let Alert(kind:, title:, body:) = alert
  let #(color, icon, default_title) =
    alert_properties(kind, spruce.symbol_mode(context))

  let title_text = case title {
    Some(inlines) ->
      case string.trim(render_inlines(context, inlines, parsed, options)) {
        "" -> default_title
        text -> text
      }
    None -> default_title
  }

  let header = case spruce.supports_color(context) {
    True ->
      style.render(context, style.new() |> style.fg(color), icon)
      <> " "
      <> style.render(
        context,
        style.new() |> style.bold |> style.fg(color),
        title_text,
      )
    False -> icon <> " " <> title_text
  }

  use <- bool.guard(
    when: width_cannot_fit(options.width, 3),
    return: case render_blocks(context, body, parsed, options) {
      "" -> wrap(header, options.width)
      body_text -> wrap(header, options.width) <> "\n\n" <> body_text
    },
  )

  let inner_options = subtract_width(options, 2)
  let header = wrap(header, inner_options.width)
  let content = case render_blocks(context, body, parsed, inner_options) {
    "" -> header
    body_text -> header <> "\n\n" <> body_text
  }

  let admonition_box =
    box.plain()
    |> box.border(border.Thick)
    |> box.border_sides(top: False, right: False, bottom: False, left: True)
    |> box.border_color(color)
    |> box.padding(top: 0, right: 0, bottom: 0, left: 1)

  box.render(context, content, admonition_box)
}

fn alert_properties(
  kind: AlertKind,
  mode: spruce.SymbolMode,
) -> #(style.Color, String, String) {
  let adapt = fn(light: Int, dark: Int) {
    style.adaptive(light: style.Hex(light), dark: style.Hex(dark))
  }
  case kind {
    AlertNote -> #(
      adapt(0x1d4ed8, 0x60a5fa),
      symbol.status(mode, symbol.Info),
      "Note",
    )
    AlertTip -> #(
      adapt(0x15803d, 0x4ade80),
      symbol.status(mode, symbol.Success),
      "Tip",
    )
    AlertImportant -> #(
      adapt(0x7e22ce, 0xc084fc),
      symbol.status(mode, symbol.Notice),
      "Important",
    )
    AlertWarning -> #(
      adapt(0xb45309, 0xfbbf24),
      symbol.status(mode, symbol.Warn),
      "Warning",
    )
    AlertCaution -> #(
      adapt(0xb91c1c, 0xf87171),
      symbol.status(mode, symbol.Error),
      "Caution",
    )
  }
}

/// Rewrite Astro/Starlight `:::type[Title]` … `:::` container directives into
/// GitHub-style `> [!TYPE] Title` alert block quotes, so both syntaxes share
/// one rendering path. Lines that are not recognized directives pass through
/// unchanged.
fn expand_directives(markdown: String) -> String {
  markdown
  |> string.split("\n")
  |> list.fold(
    DirectiveState(in_directive: False, fence: None, lines: []),
    expand_directive_line,
  )
  |> fn(state) { list.reverse(state.lines) }
  |> string.join("\n")
}

type Fence {
  Fence(marker: String, length: Int)
}

type DirectiveState {
  DirectiveState(in_directive: Bool, fence: Option(Fence), lines: List(String))
}

fn expand_directive_line(
  state: DirectiveState,
  line: String,
) -> DirectiveState {
  let DirectiveState(in_directive:, fence:, lines:) = state
  case in_directive, fence {
    True, Some(fence) -> {
      let next_fence = case closes_fence(line, fence) {
        True -> None
        False -> Some(fence)
      }
      DirectiveState(True, next_fence, [quote_line(line), ..lines])
    }
    True, None ->
      case is_directive_close(line) {
        True -> DirectiveState(False, None, lines)
        False -> {
          let next_fence = case is_indented_code_line(line) {
            True -> None
            False ->
              case parse_fence_open(line) {
                Ok(fence) -> Some(fence)
                Error(Nil) -> None
              }
          }
          DirectiveState(True, next_fence, [quote_line(line), ..lines])
        }
      }
    False, Some(fence) -> {
      let next_fence = case closes_fence(line, fence) {
        True -> None
        False -> Some(fence)
      }
      DirectiveState(False, next_fence, [line, ..lines])
    }
    False, None ->
      case is_indented_code_line(line) {
        True -> DirectiveState(False, None, [line, ..lines])
        False ->
          case parse_fence_open(line) {
            Ok(fence) -> DirectiveState(False, Some(fence), [line, ..lines])
            Error(Nil) ->
              case parse_directive_open(line) {
                Ok(opener) -> DirectiveState(True, None, [opener, ..lines])
                // nolint: thrown_away_error -- not a directive, keep line as-is
                Error(_) -> DirectiveState(False, None, [line, ..lines])
              }
          }
      }
  }
}

fn is_indented_code_line(line: String) -> Bool {
  string.starts_with(line, "    ") || string.starts_with(line, "\t")
}

fn parse_fence_open(line: String) -> Result(Fence, Nil) {
  use candidate <- result.try(trim_fence_candidate(line, 0))
  case string.pop_grapheme(candidate) {
    Ok(#(marker, _)) ->
      case marker {
        "`" | "~" -> {
          let length = count_prefix(candidate, marker, 0)
          case length >= 3 {
            True -> Ok(Fence(marker:, length:))
            False -> Error(Nil)
          }
        }
        _ -> Error(Nil)
      }
    Error(_) -> Error(Nil)
  }
}

fn closes_fence(line: String, fence: Fence) -> Bool {
  let Fence(marker:, length:) = fence
  case trim_fence_candidate(line, 0) {
    Ok(candidate) -> {
      let marker_count = count_prefix(candidate, marker, 0)
      marker_count >= length
      && string.trim(string.drop_start(candidate, marker_count)) == ""
    }
    Error(Nil) -> False
  }
}

fn trim_fence_candidate(line: String, spaces: Int) -> Result(String, Nil) {
  case string.pop_grapheme(line) {
    Ok(#(" ", rest)) ->
      case spaces < 3 {
        True -> trim_fence_candidate(rest, spaces + 1)
        False -> Error(Nil)
      }
    Ok(#("\t", _)) -> Error(Nil)
    Ok(_) -> Ok(line)
    Error(_) -> Error(Nil)
  }
}

fn count_prefix(input: String, marker: String, count: Int) -> Int {
  case string.pop_grapheme(input) {
    Ok(#(char, rest)) ->
      case char == marker {
        True -> count_prefix(rest, marker, count + 1)
        False -> count
      }
    // nolint: thrown_away_error -- end of input ends the run
    Error(_) -> count
  }
}

fn is_directive_close(line: String) -> Bool {
  string.trim(line) == ":::"
}

fn quote_line(line: String) -> String {
  use <- bool.guard(when: line == "", return: ">")
  "> " <> line
}

/// Parse a directive opener such as `:::note` or `:::tip[Custom Title]`,
/// returning the GitHub-alert opener line it maps to.
fn parse_directive_open(line: String) -> Result(String, Nil) {
  let trimmed = string.trim(line)
  use rest <- result.try(case string.starts_with(trimmed, ":::") {
    True -> Ok(string.drop_start(trimmed, 3))
    False -> Error(Nil)
  })

  let #(name, after) = take_name(rest, "")
  use _ <- result.try(alert_kind_from_name(name))

  use title <- result.try(parse_directive_title(string.trim(after)))

  let opener = "> [!" <> string.uppercase(name) <> "]"
  case title {
    Some(title) -> Ok(opener <> " " <> title)
    None -> Ok(opener)
  }
}

fn parse_directive_title(after: String) -> Result(Option(String), Nil) {
  case after {
    "" -> Ok(None)
    _ ->
      case string.starts_with(after, "[") {
        True ->
          case string.split_once(string.drop_start(after, 1), "]") {
            Ok(#(title, tail)) ->
              case string.trim(tail) {
                "" -> Ok(Some(string.trim(title)))
                _ -> Error(Nil)
              }
            Error(_) -> Error(Nil)
          }
        False -> Error(Nil)
      }
  }
}

fn take_name(input: String, accumulator: String) -> #(String, String) {
  case string.pop_grapheme(input) {
    Ok(#(char, rest)) ->
      case is_name_char(char) {
        True -> take_name(rest, accumulator <> char)
        False -> #(accumulator, input)
      }
    // nolint: thrown_away_error -- end of input ends the name
    Error(_) -> #(accumulator, "")
  }
}

fn is_name_char(char: String) -> Bool {
  case char {
    "a"
    | "b"
    | "c"
    | "d"
    | "e"
    | "f"
    | "g"
    | "h"
    | "i"
    | "j"
    | "k"
    | "l"
    | "m" -> True
    "n"
    | "o"
    | "p"
    | "q"
    | "r"
    | "s"
    | "t"
    | "u"
    | "v"
    | "w"
    | "x"
    | "y"
    | "z" -> True
    "A"
    | "B"
    | "C"
    | "D"
    | "E"
    | "F"
    | "G"
    | "H"
    | "I"
    | "J"
    | "K"
    | "L"
    | "M" -> True
    "N"
    | "O"
    | "P"
    | "Q"
    | "R"
    | "S"
    | "T"
    | "U"
    | "V"
    | "W"
    | "X"
    | "Y"
    | "Z" -> True
    _ -> False
  }
}

fn render_list(
  context: Spruce,
  pack: document.ListPack,
  entries: List(document.ListItem),
  start: Option(Int),
  parsed: document.Document,
  options: Options,
) -> String {
  let marker_width = list_marker_width(entries, start)
  use <- bool.guard(
    when: width_cannot_fit(options.width, marker_width + 1),
    return: render_list_labels(entries, pack, context, parsed, options)
      |> string.join("\n"),
  )
  let label_options = subtract_width(options, marker_width)
  let labels = render_list_labels(entries, pack, context, parsed, label_options)
  let list_ =
    labels
    |> list.fold(item.new(), fn(list_, label) { item.item(list_, label) })

  case start {
    None -> item.render(context, list_)
    Some(start) -> {
      let list_ =
        list_
        |> item.kind(item.Ordered)
        |> item.enumerator(fn(index, _depth) {
          int.to_string(start + index - 1) <> ". "
        })

      item.render(context, list_)
    }
  }
}

fn render_list_labels(
  entries: List(document.ListItem),
  pack: document.ListPack,
  context: Spruce,
  parsed: document.Document,
  options: Options,
) -> List(String) {
  list.map(entries, fn(entry) {
    let document.ListItem(blocks, _, _) = entry
    render_list_item_blocks(blocks, pack, context, parsed, options)
  })
}

fn render_list_item_blocks(
  blocks: List(document.Block),
  pack: document.ListPack,
  context: Spruce,
  parsed: document.Document,
  options: Options,
) -> String {
  let separator = case pack {
    document.Tight -> "\n"
    document.Loose -> "\n\n"
  }

  blocks
  |> render_block_list(context, parsed, options)
  |> remove_empty
  |> string.join(separator)
}

fn render_table(
  context: Spruce,
  headers: List(document.THead),
  rows: List(List(document.Cell)),
  parsed: document.Document,
  options: Options,
) -> String {
  use <- bool.guard(
    when: width_cannot_fit(options.width, table_minimum_width(headers, rows)),
    return: render_table_without_frame(context, headers, rows, parsed, options),
  )

  let table_ =
    table.new()
    |> table.headers(render_table_headers(context, headers, parsed, options))
    |> table.rows(render_table_rows(context, rows, parsed, options))
    |> table.column_alignments(render_table_alignments(headers))
    |> table.style_fn(fn(row_context, _column) {
      case row_context {
        table.Header -> options.theme.table_header
        table.Body(_) -> style.new()
      }
    })

  case options.width {
    Some(width) if width > 0 ->
      table.render(context, table.width(table_, width))
    Some(_) | None -> table.render(context, table_)
  }
}

fn render_table_alignments(headers: List(document.THead)) -> List(table.Align) {
  list.map(headers, fn(header) {
    let document.THead(alignment, _, _) = header
    case alignment {
      document.Left -> table.Left
      document.Center -> table.Center
      document.Right -> table.Right
    }
  })
}

fn render_table_headers(
  context: Spruce,
  headers: List(document.THead),
  parsed: document.Document,
  options: Options,
) -> List(String) {
  list.map(headers, fn(header) {
    let document.THead(_, raw, inlines) = header
    fallback_inline(context, raw, inlines, parsed, options) |> string.trim
  })
}

fn render_table_rows(
  context: Spruce,
  rows: List(List(document.Cell)),
  parsed: document.Document,
  options: Options,
) -> List(List(String)) {
  list.map(rows, render_table_cells(context, _, parsed, options))
}

fn render_table_cells(
  context: Spruce,
  cells: List(document.Cell),
  parsed: document.Document,
  options: Options,
) -> List(String) {
  list.map(cells, fn(cell) {
    let document.Cell(raw, inlines) = cell
    fallback_inline(context, raw, inlines, parsed, options) |> string.trim
  })
}

fn render_rule(context: Spruce, options: Options) -> String {
  let width = case options.width {
    Some(width) if width > 0 -> width
    Some(_) | None -> 40
  }

  spruce.indent_prefix(context)
  <> style.render(context, options.theme.rule, string.repeat("─", width))
}

fn render_html_block(context: Spruce, raw: String, options: Options) -> String {
  style.render(context, options.theme.html, raw)
  |> wrap(options.width)
  |> prefix_lines(spruce.indent_prefix(context))
}

fn render_inlines(
  context: Spruce,
  inlines: List(document.Inline),
  parsed: document.Document,
  options: Options,
) -> String {
  inlines
  |> render_inline_list(context, parsed, options)
  |> string.join("")
}

fn render_inline_list(
  inlines: List(document.Inline),
  context: Spruce,
  parsed: document.Document,
  options: Options,
) -> List(String) {
  list.map(inlines, render_inline(context, _, parsed, options))
}

fn render_inline(
  context: Spruce,
  inline: document.Inline,
  parsed: document.Document,
  options: Options,
) -> String {
  case inline {
    document.Autolink(uri, text) -> {
      let label = case text {
        Some(text) -> text
        None -> uri
      }
      render_link(context, label, uri, options.theme)
    }
    document.CodeSpan(text) ->
      style.render(context, options.theme.code_span, "`" <> text <> "`")
    document.EmailAutolink(mail) ->
      render_link(context, mail, "mailto:" <> mail, options.theme)
    document.Emphasis(children) ->
      style.render(
        context,
        options.theme.emphasis,
        render_inlines(context, children, parsed, options),
      )
    document.Footnote(number, _) -> "[^" <> int.to_string(number) <> "]"
    document.FullImage(text, data) ->
      render_image(
        context,
        text,
        destination_string(data.dest),
        parsed,
        options,
      )
    document.FullLink(text, data) ->
      render_link(
        context,
        render_inlines(context, text, parsed, options),
        destination_string(data.dest),
        options.theme,
      )
    document.HardBreak -> "\n"
    document.Highlight(children) ->
      style.render(
        context,
        options.theme.highlight,
        render_inlines(context, children, parsed, options),
      )
    document.InlineFootnote(number, _) -> "[^" <> int.to_string(number) <> "]"
    document.InlineHtml(tag, _, children) -> {
      case children {
        [] -> style.render(context, options.theme.html, "<" <> tag <> ">")
        _ -> render_inlines(context, children, parsed, options)
      }
    }
    document.RawHtml(raw) -> style.render(context, options.theme.html, raw)
    document.RefImage(text, label) ->
      case document.lookup_link(parsed, label) {
        Ok(data) ->
          render_image(
            context,
            text,
            destination_string(data.dest),
            parsed,
            options,
          )
        Error(Nil) -> render_inlines(context, text, parsed, options)
      }
    document.RefLink(text, label) -> {
      let visible = render_inlines(context, text, parsed, options)
      case document.lookup_link(parsed, label) {
        Ok(data) ->
          render_link(
            context,
            visible,
            destination_string(data.dest),
            options.theme,
          )
        Error(Nil) -> visible
      }
    }
    document.SoftBreak -> " "
    document.Strikethrough(children) ->
      style.render(
        context,
        options.theme.strikethrough,
        render_inlines(context, children, parsed, options),
      )
    document.Strong(children) ->
      style.render(
        context,
        options.theme.strong,
        render_inlines(context, children, parsed, options),
      )
    document.Text(text) -> text
    document.Checkbox(True) -> "[x]"
    document.Checkbox(False) -> "[ ]"
    document.Delim(delimiter, length, _, _) -> string.repeat(delimiter, length)
  }
}

fn render_link(
  context: Spruce,
  label: String,
  target: String,
  theme: Theme,
) -> String {
  let visible = style.render(context, theme.link, label)

  case target == "" || target == label {
    True -> visible
    False ->
      visible <> style.render(context, theme.link_target, " (" <> target <> ")")
  }
}

fn render_image(
  context: Spruce,
  text: List(document.Inline),
  target: String,
  parsed: document.Document,
  options: Options,
) -> String {
  let label = render_inlines(context, text, parsed, options)

  case label {
    "" -> target
    _ -> label
  }
}

fn fallback_inline(
  context: Spruce,
  raw: String,
  inlines: List(document.Inline),
  parsed: document.Document,
  options: Options,
) -> String {
  case render_inlines(context, inlines, parsed, options) {
    "" -> raw
    text -> text
  }
}

fn heading_style(theme: Theme, level: Int) -> style.Style {
  case level {
    1 -> theme.h1
    2 -> theme.h2
    3 -> theme.h3
    4 -> theme.h4
    5 -> theme.h5
    _ -> theme.h6
  }
}

fn destination_string(destination: document.Destination) -> String {
  case destination {
    document.Absolute(uri) -> uri
    document.Relative(uri) -> uri
    document.Anchor(id) -> "#" <> id
  }
}

fn option_string(value: Option(String)) -> String {
  case value {
    Some(value) -> value
    None -> ""
  }
}

fn wrap(text: String, width: Option(Int)) -> String {
  case width {
    Some(width) if width > 0 -> align.wrap(text, width)
    Some(_) | None -> text
  }
}

fn prefix_lines(text: String, prefix: String) -> String {
  text
  |> string.split("\n")
  |> list.map(fn(line) { prefix <> line })
  |> string.join("\n")
}

fn remove_empty(lines: List(String)) -> List(String) {
  list.filter(lines, fn(line) { line != "" })
}

fn width_cannot_fit(width: Option(Int), minimum: Int) -> Bool {
  case width {
    Some(width) -> width > 0 && width < minimum
    None -> False
  }
}

fn table_minimum_width(
  headers: List(document.THead),
  rows: List(List(document.Cell)),
) -> Int {
  let column_count =
    rows
    |> list.map(list.length)
    |> list.fold(list.length(headers), int.max)

  column_count * 3 + 1
}

fn render_table_without_frame(
  context: Spruce,
  headers: List(document.THead),
  rows: List(List(document.Cell)),
  parsed: document.Document,
  options: Options,
) -> String {
  let header_cells = render_table_headers(context, headers, parsed, options)
  let body_cells =
    rows
    |> list.map(render_table_cells(context, _, parsed, options))
    |> list.flatten

  list.append(header_cells, body_cells)
  |> string.join("\n")
  |> wrap(options.width)
}

fn subtract_width(options: Options, amount: Int) -> Options {
  case options.width {
    Some(width) if width > 0 ->
      Options(..options, width: Some(int.max(1, width - amount)))
    Some(_) | None -> options
  }
}

fn width_after_prefix(
  options: Options,
  prefix: String,
) -> Result(Options, Nil) {
  case options.width {
    Some(width) if width > 0 -> {
      let available = width - align.visual_length(prefix)
      case available > 0 {
        True -> Ok(Options(..options, width: Some(available)))
        False -> Error(Nil)
      }
    }
    Some(_) | None -> Ok(options)
  }
}

fn constrain_lines(text: String, width: Option(Int)) -> String {
  case width {
    Some(width) if width > 0 ->
      text
      |> string.split("\n")
      |> list.map(fn(line) { align.truncate(line, width:, ellipsis: "") })
      |> string.join("\n")
    Some(_) | None -> text
  }
}

fn code_title(title: String, width: Option(Int)) -> String {
  case width {
    Some(width) if width > 5 ->
      align.truncate(title, width: width - 5, ellipsis: "")
    Some(width) if width > 0 -> ""
    Some(_) | None -> title
  }
}

fn list_marker_width(
  entries: List(document.ListItem),
  start: Option(Int),
) -> Int {
  case start {
    None -> 2
    Some(start) ->
      start + int.max(0, list.length(entries) - 1)
      |> int.to_string
      |> string.length
      |> fn(digits) { digits + 2 }
  }
}

/// Prepend `prefix` to every non-empty line. Empty lines (block separators)
/// stay empty so the output has no trailing whitespace on blank lines.
fn indent_rendered(text: String, prefix: String) -> String {
  case prefix {
    "" -> text
    _ ->
      text
      |> string.split("\n")
      |> list.map(fn(line) {
        case line {
          "" -> ""
          _ -> prefix <> line
        }
      })
      |> string.join("\n")
  }
}
