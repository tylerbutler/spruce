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
//// - **GFM table column alignment** (`:--`, `:-:`, `--:`) is parsed by `mork`
////   but ignored here: every cell is left-aligned, because `spruce/table`
////   does not expose per-column alignment.
//// - **Heading ID attributes** (`## Title {#id}`) are stripped from the
////   rendered text (via `mork.heading_ids`), since a terminal has no anchors
////   to link to. The id itself is parsed but not rendered.
//// - **Raw HTML is not sanitized.** Inline and block HTML is passed through
////   (rendered dimmed), not escaped or stripped. `mork` does not implement
////   GFM's tagfilter. This is harmless in a terminal, but do not rely on this
////   module to neutralize untrusted HTML.
////

import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import mork
import mork/document as md
import spruce.{type Spruce}
import spruce/align
import spruce/block
import spruce/box
import spruce/highlight
import spruce/internal/layout
import spruce/list as ui_list
import spruce/style
import spruce/symbol
import spruce/table

pub opaque type Theme {
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

pub opaque type Options {
  Options(theme: Theme, width: Option(Int))
}

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

pub fn default_options() -> Options {
  Options(theme: adaptive_theme(), width: None)
}

pub fn with_theme(options: Options, theme: Theme) -> Options {
  Options(..options, theme:)
}

pub fn with_width(options: Options, width: Int) -> Options {
  Options(..options, width: Some(int.max(0, width)))
}

pub fn render(sp: Spruce, markdown: String) -> String {
  render_with(sp, markdown, default_options())
}

pub fn render_with(sp: Spruce, markdown: String, options: Options) -> String {
  let md.Document(_, blocks, _, _) =
    mork.configure()
    |> mork.tables(True)
    |> mork.tasklists(True)
    |> mork.autolinks(True)
    |> mork.heading_ids(True)
    |> mork.parse_with_options(expand_directives(markdown))

  render_blocks(sp, blocks, options)
}

pub fn print(sp: Spruce, markdown: String) -> Nil {
  io.println(render(sp, markdown))
}

fn render_blocks(
  sp: Spruce,
  blocks: List(md.Block),
  options: Options,
) -> String {
  blocks
  |> render_block_list(sp, options)
  |> remove_empty
  |> string.join("\n\n")
}

fn render_block_list(
  blocks: List(md.Block),
  sp: Spruce,
  options: Options,
) -> List(String) {
  case blocks {
    [] -> []
    [first, ..rest] -> [
      render_block(sp, first, options),
      ..render_block_list(rest, sp, options)
    ]
  }
}

fn render_block(sp: Spruce, block_: md.Block, options: Options) -> String {
  case block_ {
    md.BlockQuote(blocks) -> render_quote(sp, blocks, options)
    md.BulletList(pack, items) -> render_list(sp, pack, items, None, options)
    md.Code(lang, text) -> render_code(sp, lang, text, options)
    md.Empty -> ""
    md.Heading(level, _, raw, inlines) ->
      render_heading(sp, level, raw, inlines, options)
    md.HtmlBlock(raw) -> render_html_block(sp, raw, options.theme)
    md.Newline -> ""
    md.OrderedList(pack, items, start) ->
      render_list(sp, pack, items, start, options)
    md.Paragraph(_, inlines) -> render_paragraph(sp, inlines, options)
    md.Table(header, rows) -> render_table(sp, header, rows, options)
    md.ThematicBreak -> render_rule(sp, options)
  }
}

fn render_heading(
  sp: Spruce,
  level: Int,
  raw: String,
  inlines: List(md.Inline),
  options: Options,
) -> String {
  let text = case render_inlines(sp, inlines, options) {
    "" -> raw
    text -> text
  }
  let marker = string.repeat("#", int.clamp(level, min: 1, max: 6))
  let line = marker <> " " <> string.trim(text)

  layout.indent_prefix(sp)
  <> style.render(sp, heading_style(options.theme, level), line)
}

fn render_paragraph(
  sp: Spruce,
  inlines: List(md.Inline),
  options: Options,
) -> String {
  render_inlines(sp, inlines, options)
  |> wrap(options.width)
  |> prefix_lines(layout.indent_prefix(sp))
}

fn render_code(
  sp: Spruce,
  lang: Option(String),
  text: String,
  options: Options,
) -> String {
  let title = option_string(lang)
  let highlighted =
    highlight.highlight_named_with(sp, text, title, options.theme.code)

  let options_ =
    box.options(title: title, color: options.theme.code_border)
    |> box.padding(1, 0, 0, 0)
  box.render(sp, highlighted, options_)
}

fn render_quote(
  sp: Spruce,
  blocks: List(md.Block),
  options: Options,
) -> String {
  case detect_alert(blocks) {
    Some(alert) -> render_admonition(sp, alert, options)
    None -> render_plain_quote(sp, blocks, options)
  }
}

fn render_plain_quote(
  sp: Spruce,
  blocks: List(md.Block),
  options: Options,
) -> String {
  let content =
    style.render(
      sp,
      style.new() |> style.italic,
      render_blocks(sp, blocks, options),
    )

  let quote_block =
    block.new()
    |> block.border(box.Thick)
    |> block.border_sides(False, False, False, True)
    |> block.border_colors(
      options.theme.quote_border,
      options.theme.quote_border,
      options.theme.quote_border,
      options.theme.quote_border,
    )
    |> block.padding(0, 0, 0, 1)

  block.render(sp, content, quote_block)
}

/// A GitHub-style alert / Astro-style aside detected inside a block quote.
type Alert {
  Alert(kind: AlertKind, title: Option(List(md.Inline)), body: List(md.Block))
}

type AlertKind {
  AlertNote
  AlertTip
  AlertImportant
  AlertWarning
  AlertCaution
}

/// Detect a `> [!TYPE] optional title` alert at the head of a block quote and
/// split out its (optional) custom title and remaining body blocks.
fn detect_alert(blocks: List(md.Block)) -> Option(Alert) {
  case blocks {
    [md.Paragraph(_, inlines), ..rest] ->
      case inlines {
        [md.Text("["), md.Text(tag), md.Text("]"), ..tail] ->
          case alert_kind_from_tag(tag) {
            Ok(kind) -> {
              let #(title, body_inlines) = split_alert_first_line(tail)
              let body = case body_inlines {
                [] -> rest
                _ -> [md.Paragraph("", body_inlines), ..rest]
              }
              Some(Alert(kind:, title:, body:))
            }
            Error(_) -> None
          }
        _ -> None
      }
    _ -> None
  }
}

fn alert_kind_from_tag(tag: String) -> Result(AlertKind, Nil) {
  case string.starts_with(tag, "!") {
    True -> alert_kind_from_name(string.drop_start(tag, 1))
    False -> Error(Nil)
  }
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
  inlines: List(md.Inline),
) -> #(Option(List(md.Inline)), List(md.Inline)) {
  let #(before, after) = take_until_break(inlines, [])
  let title = case before {
    [] -> None
    _ -> Some(before)
  }
  #(title, after)
}

fn take_until_break(
  inlines: List(md.Inline),
  acc: List(md.Inline),
) -> #(List(md.Inline), List(md.Inline)) {
  case inlines {
    [] -> #(list.reverse(acc), [])
    [md.SoftBreak, ..rest] -> #(list.reverse(acc), rest)
    [md.HardBreak, ..rest] -> #(list.reverse(acc), rest)
    [first, ..rest] -> take_until_break(rest, [first, ..acc])
  }
}

fn render_admonition(sp: Spruce, alert: Alert, options: Options) -> String {
  let Alert(kind:, title:, body:) = alert
  let #(color, icon, default_title) = alert_properties(kind)

  let title_text = case title {
    Some(inlines) ->
      case string.trim(render_inlines(sp, inlines, options)) {
        "" -> default_title
        text -> text
      }
    None -> default_title
  }

  let header = case spruce.supports_color(sp) {
    True ->
      style.render(sp, style.new() |> style.fg(color), icon)
      <> " "
      <> style.render(
        sp,
        style.new() |> style.bold |> style.fg(color),
        title_text,
      )
    False -> icon <> " " <> title_text
  }

  let content = case render_blocks(sp, body, options) {
    "" -> header
    body_text -> header <> "\n\n" <> body_text
  }

  let admonition_block =
    block.new()
    |> block.border(box.Thick)
    |> block.border_sides(False, False, False, True)
    |> block.border_colors(color, color, color, color)
    |> block.padding(0, 0, 0, 1)

  block.render(sp, content, admonition_block)
}

fn alert_properties(kind: AlertKind) -> #(style.Color, String, String) {
  let adapt = fn(light: Int, dark: Int) {
    style.adaptive(light: style.Hex(light), dark: style.Hex(dark))
  }
  case kind {
    AlertNote -> #(adapt(0x1d4ed8, 0x60a5fa), symbol.info, "Note")
    AlertTip -> #(adapt(0x15803d, 0x4ade80), symbol.success, "Tip")
    AlertImportant -> #(adapt(0x7e22ce, 0xc084fc), symbol.notice, "Important")
    AlertWarning -> #(adapt(0xb45309, 0xfbbf24), symbol.warn, "Warning")
    AlertCaution -> #(adapt(0xb91c1c, 0xf87171), symbol.error, "Caution")
  }
}

/// Rewrite Astro/Starlight `:::type[Title]` … `:::` container directives into
/// GitHub-style `> [!TYPE] Title` alert block quotes, so both syntaxes share
/// one rendering path. Lines that are not recognized directives pass through
/// unchanged.
fn expand_directives(markdown: String) -> String {
  markdown
  |> string.split("\n")
  |> expand_lines(False)
  |> string.join("\n")
}

fn expand_lines(lines: List(String), in_directive: Bool) -> List(String) {
  case lines {
    [] -> []
    [line, ..rest] ->
      case in_directive {
        True ->
          case is_directive_close(line) {
            True -> expand_lines(rest, False)
            False -> [quote_line(line), ..expand_lines(rest, True)]
          }
        False ->
          case parse_directive_open(line) {
            Ok(opener) -> [opener, ..expand_lines(rest, True)]
            Error(_) -> [line, ..expand_lines(rest, False)]
          }
      }
  }
}

fn is_directive_close(line: String) -> Bool {
  string.trim(line) == ":::"
}

fn quote_line(line: String) -> String {
  case line == "" {
    True -> ">"
    False -> "> " <> line
  }
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

fn take_name(input: String, acc: String) -> #(String, String) {
  case string.pop_grapheme(input) {
    Ok(#(char, rest)) ->
      case is_name_char(char) {
        True -> take_name(rest, acc <> char)
        False -> #(acc, input)
      }
    Error(_) -> #(acc, "")
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
  sp: Spruce,
  pack: md.ListPack,
  items: List(md.ListItem),
  start: Option(Int),
  options: Options,
) -> String {
  let labels = render_list_labels(items, pack, sp, options)
  let list_ =
    labels
    |> list.fold(ui_list.new(), fn(list_, label) { ui_list.item(list_, label) })

  case start {
    None -> ui_list.render(sp, list_)
    Some(start) -> {
      let list_ =
        list_
        |> ui_list.kind(ui_list.Ordered)
        |> ui_list.enumerator(fn(index, _depth) {
          int.to_string(start + index - 1) <> ". "
        })

      ui_list.render(sp, list_)
    }
  }
}

fn render_list_labels(
  items: List(md.ListItem),
  pack: md.ListPack,
  sp: Spruce,
  options: Options,
) -> List(String) {
  case items {
    [] -> []
    [md.ListItem(blocks, _, _), ..rest] -> [
      render_list_item_blocks(blocks, pack, sp, options),
      ..render_list_labels(rest, pack, sp, options)
    ]
  }
}

fn render_list_item_blocks(
  blocks: List(md.Block),
  pack: md.ListPack,
  sp: Spruce,
  options: Options,
) -> String {
  let separator = case pack {
    md.Tight -> "\n"
    md.Loose -> "\n\n"
  }

  blocks
  |> render_block_list(sp, options)
  |> remove_empty
  |> string.join(separator)
}

fn render_table(
  sp: Spruce,
  headers: List(md.THead),
  rows: List(List(md.Cell)),
  options: Options,
) -> String {
  let table_ =
    table.new()
    |> table.headers(render_table_headers(sp, headers, options))
    |> table.rows(render_table_rows(sp, rows, options))
    |> table.style_fn(fn(row, _column) {
      case row {
        -1 -> options.theme.table_header
        _ -> style.new()
      }
    })

  case options.width {
    Some(width) if width > 0 -> table.render(sp, table.width(table_, width))
    _ -> table.render(sp, table_)
  }
}

fn render_table_headers(
  sp: Spruce,
  headers: List(md.THead),
  options: Options,
) -> List(String) {
  case headers {
    [] -> []
    [md.THead(_, raw, inlines), ..rest] -> [
      fallback_inline(sp, raw, inlines, options) |> string.trim,
      ..render_table_headers(sp, rest, options)
    ]
  }
}

fn render_table_rows(
  sp: Spruce,
  rows: List(List(md.Cell)),
  options: Options,
) -> List(List(String)) {
  case rows {
    [] -> []
    [row, ..rest] -> [
      render_table_cells(sp, row, options),
      ..render_table_rows(sp, rest, options)
    ]
  }
}

fn render_table_cells(
  sp: Spruce,
  cells: List(md.Cell),
  options: Options,
) -> List(String) {
  case cells {
    [] -> []
    [md.Cell(raw, inlines), ..rest] -> [
      fallback_inline(sp, raw, inlines, options) |> string.trim,
      ..render_table_cells(sp, rest, options)
    ]
  }
}

fn render_rule(sp: Spruce, options: Options) -> String {
  let width = case options.width {
    Some(width) if width > 0 -> width
    _ -> 40
  }

  layout.indent_prefix(sp)
  <> style.render(sp, options.theme.rule, string.repeat("─", width))
}

fn render_html_block(sp: Spruce, raw: String, theme: Theme) -> String {
  style.render(sp, theme.html, raw)
  |> prefix_lines(layout.indent_prefix(sp))
}

fn render_inlines(
  sp: Spruce,
  inlines: List(md.Inline),
  options: Options,
) -> String {
  inlines
  |> render_inline_list(sp, options)
  |> string.join("")
}

fn render_inline_list(
  inlines: List(md.Inline),
  sp: Spruce,
  options: Options,
) -> List(String) {
  case inlines {
    [] -> []
    [first, ..rest] -> [
      render_inline(sp, first, options),
      ..render_inline_list(rest, sp, options)
    ]
  }
}

fn render_inline(sp: Spruce, inline: md.Inline, options: Options) -> String {
  case inline {
    md.Autolink(uri, text) -> {
      let label = case text {
        Some(text) -> text
        None -> uri
      }
      render_link(sp, label, uri, options.theme)
    }
    md.CodeSpan(text) ->
      style.render(sp, options.theme.code_span, "`" <> text <> "`")
    md.EmailAutolink(mail) ->
      render_link(sp, mail, "mailto:" <> mail, options.theme)
    md.Emphasis(children) ->
      style.render(
        sp,
        options.theme.emphasis,
        render_inlines(sp, children, options),
      )
    md.Footnote(num, _) -> "[^" <> int.to_string(num) <> "]"
    md.FullImage(text, data) ->
      render_image(sp, text, destination_string(data.dest), options)
    md.FullLink(text, data) ->
      render_link(
        sp,
        render_inlines(sp, text, options),
        destination_string(data.dest),
        options.theme,
      )
    md.HardBreak -> "\n"
    md.Highlight(children) ->
      style.render(
        sp,
        options.theme.highlight,
        render_inlines(sp, children, options),
      )
    md.InlineFootnote(num, _) -> "[^" <> int.to_string(num) <> "]"
    md.InlineHtml(tag, _, children) -> {
      case children {
        [] -> style.render(sp, options.theme.html, "<" <> tag <> ">")
        _ -> render_inlines(sp, children, options)
      }
    }
    md.RawHtml(raw) -> style.render(sp, options.theme.html, raw)
    md.RefImage(text, label) -> render_image(sp, text, label, options)
    md.RefLink(text, _) -> render_inlines(sp, text, options)
    md.SoftBreak -> " "
    md.Strikethrough(children) ->
      style.render(
        sp,
        options.theme.strikethrough,
        render_inlines(sp, children, options),
      )
    md.Strong(children) ->
      style.render(
        sp,
        options.theme.strong,
        render_inlines(sp, children, options),
      )
    md.Text(text) -> text
    md.Checkbox(True) -> "[x]"
    md.Checkbox(False) -> "[ ]"
    md.Delim(delimiter, len, _, _) -> string.repeat(delimiter, len)
  }
}

fn render_link(
  sp: Spruce,
  label: String,
  target: String,
  theme: Theme,
) -> String {
  let visible = style.render(sp, theme.link, label)

  case target == "" || target == label {
    True -> visible
    False ->
      visible <> style.render(sp, theme.link_target, " (" <> target <> ")")
  }
}

fn render_image(
  sp: Spruce,
  text: List(md.Inline),
  target: String,
  options: Options,
) -> String {
  let label = render_inlines(sp, text, options)

  case label {
    "" -> target
    _ -> label
  }
}

fn fallback_inline(
  sp: Spruce,
  raw: String,
  inlines: List(md.Inline),
  options: Options,
) -> String {
  case render_inlines(sp, inlines, options) {
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

fn destination_string(destination: md.Destination) -> String {
  case destination {
    md.Absolute(uri) -> uri
    md.Relative(uri) -> uri
    md.Anchor(id) -> "#" <> id
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
    _ -> text
  }
}

fn prefix_lines(text: String, prefix: String) -> String {
  text
  |> string.split("\n")
  |> list.map(fn(line) { prefix <> line })
  |> string.join("\n")
}

fn remove_empty(lines: List(String)) -> List(String) {
  case lines {
    [] -> []
    ["", ..rest] -> remove_empty(rest)
    [line, ..rest] -> [line, ..remove_empty(rest)]
  }
}
