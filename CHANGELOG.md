# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v2.0.0 - 2026-10-16

### Major Release

- severity.Severity now matches the eight Erlang/OTP Logger and RFC 5424 levels exactly: Emergency (0), Alert (1), Critical (2), Error (3), Warning (4), Notice (5), Info (6), Debug (7). The previous variants Trace, Warn, Err, and Fatal are removed. Rename Warn to Warning, Err to Error, and remove any uses of Trace or Fatal. to_string now returns "EMERGENCY", "WARNING", and "ERROR" for the affected variants.
- spruce 2.0 consolidates overlapping modules into one box builder, one set of border glyphs, one status formatter, one indentation helper, and one output-composition module. The breaking-change entries describe the migration from the 1.x API.
- spruce/block is merged into spruce/box, and boxes are configured with a single builder. Start from box.new() (a rounded cyan border with one cell of horizontal padding) or box.plain() (no border and no padding), then apply title, foreground, background, padding, margin, width, height, align, border, border_color, border_colors, and border_sides before calling render. BoxOptions, box.options, and box.default_options are removed. Replace box.options(title: t, color: c) with box.new() |> box.title(t) |> box.border_color(c), and replace block.new() with box.plain().
- Move the Border and BorderChars types from spruce/box to spruce/border, which boxes and tables share. Replace box.Rounded, box.Custom(...), and the other box border constructors with their spruce/border equivalents, including in calls to table.border. Use border.chars to look up the glyphs for a border style.
- spruce/group is merged into spruce/output. group.render_title is renamed to output.title, and group.group, which prints its heading and runs its body immediately, is renamed to output.stream_group. The buffered output.group is unchanged.
- spruce.indent_prefix(context) returns the indentation for the context's depth (two spaces per level), and every block renderer uses it. group.indent is removed; prefix lines with spruce.indent_prefix or string.repeat instead.
- spruce/layout is merged into spruce/align. Pos (Start, Center, and End), join_vertical, join_horizontal, and place are unchanged apart from the module name.
- Rename the 1.x spruce/list module to spruce/item and its opaque List type to Items. Replace imports of spruce/list with spruce/item and references to its List type with item.Items. The builder and rendering functions keep their names.
- spruce/message now provides only the seven one-line functions success, fail, start, ready, info, warn, and error, each of which renders an icon, a label, and the message text. The Options and Formatter types, default_options, with_details, with_symbol_mode, with_formatter, label, badge, simple, custom, line_with, the *_with functions, and the print_* functions are removed. For badges, key-value details, ASCII glyphs, or custom prefixes, build a spruce/line with line.severity and line.severity_formatter. Print lines with io.println, or collect them with spruce/output.
- Remove spruce/palette. Replace palette.hash(context, text) with style.hashed(text) from spruce/style; the new function no longer takes a Spruce context. The new style.Hashed(key) Color constructor resolves hash colors at render time, so callers can reuse the same style or color across color levels without reconstruction.
- Rename spruce/details to spruce/detail. Import spruce/detail instead; the Details type and functions are unchanged.
- spruce/symbol no longer exports the glyph constants (symbol.info, symbol.info_ascii, symbol.arrow, and the rest) or resolve. Use symbol.status(spruce.Unicode, symbol.Info) for a Unicode glyph and symbol.status(spruce.Ascii, symbol.Info) for its ASCII fallback.
- The ColorLevel, Background, and Stream types are now defined in spruce rather than re-exported from tty, so their constructors can be used without importing tty, for example spruce.with_color_level(spruce.TrueColor), spruce.with_background(spruce.Dark), and spruce.detect_stream(spruce.Stderr). Replace tty.TrueColor, tty.Light, tty.Stderr, and the other tty constructors with their spruce equivalents.
- Remove symbol.Mode; use spruce.SymbolMode (spruce.Unicode / spruce.Ascii) instead. The Spruce context defaults to Unicode. Messages, severity labels, item bullets, output titles, tree branches, and Markdown alerts use the context symbol mode instead of color support to choose glyphs. Set the mode with spruce.with_symbol_mode(context, spruce.Ascii) and read it with spruce.symbol_mode(context). Explicit tree.unicode, tree.ascii, or custom branches still override the context.
- table.style_fn now receives a RowContext (Header | Body(index: Int)) instead of the -1 sentinel integer for header rows. Update callers to pattern-match on table.Header and table.Body(_).
- tree.enumerator is replaced by tree.branches and BranchChars, which customize branch, last-branch, pipe, and blank tokens without losing ancestor guides.

### Added

- output.print_with and output.stream_group_with allow buffered output and streaming groups to write to stderr or any other string sink while the existing stdout helpers remain unchanged.
- The public `highlight.Theme` and `markdown.Theme` constructors now support custom themes and field updates based on the built-in dark, light, and adaptive themes.
- Add an interactive website workbench for messages, styles, boxes, and tables, with color-capability controls and runnable Gleam examples.
- Expose syntax language discovery and canonical names.
- spruce.flat(context) returns a copy of a context with its indent depth reset to zero. Composing renderers that own indentation at their boundary — such as spruce/markdown — use it so inner blocks are not indented twice.
- Add per-column left, center, and right alignment to spruce/table, and honor GFM table alignment markers in spruce/markdown.
- spruce/tree adds tree.columns and tree.render_table for aligned tree rows, plus tree.render_with for label rendering based on prefix width, depth, and sibling position.

### Fixed

- Preserve whitespace, ANSI styles, and hyperlinks across wrapping and truncation, including existing line breaks; improve terminal escape parsing and emoji widths.
- RGB colors now use the actual ANSI 256-color cube values, and nested foreground and background resets restore the outer color.
- Hidden table borders now use all available width for cell padding and content, and box titles no longer widen content when the top border is not visible.
- Markdown rendering is now stack-safe for large flat documents, resolves reference links and images, preserves directive-like text inside fenced code, and applies width limits without clipping user text across headings, quotes, alerts, lists, code blocks, tables, HTML, and context indentation.
- Syntax highlighting now returns source text immediately when color is disabled, without resolving a grammar or tokenizing the input.
- Multiline messages, compact lines, and output titles now apply the context indentation to every non-empty line without changing blank or trailing lines. Empty timestamps are treated as absent before styling.
- style.faint is now a true alias for style.dim. Applying both attributes emits one dim escape sequence instead of nesting duplicate sequences.
- Markdown blocks (paragraphs, headings, lists, blockquotes, alerts, code blocks, tables, rules, HTML blocks) now receive the context indentation exactly once when rendered at nonzero depth. Previously, content inside containers was double-indented.
- The Unicode Info symbol includes a text-presentation selector, so terminals do not substitute an emoji. Informational messages and severity labels use the same glyph.
- table.border(border.Hidden) now renders a borderless table with no leading or trailing blank lines. Cell padding and two-space column separation are preserved.

### Performance

- Wrap long unbroken text in one pass instead of repeatedly rescanning the remaining input.
- Build item and tree siblings in linear time while preserving insertion and render order.

### Changed

- The website Gleam example now shows an explicit Nil return annotation on main.
- The built-in severity formatter target widths increase to fit Emergency in label, badge, and simple formats. render_padded now produces equal-width output for every OTP Logger severity in both Unicode and ASCII symbol modes.
- Website terminal examples use matching spruce output from Erlang and JavaScript, including plain, basic, 256-color, and truecolor variants.

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.0.1 - 2026-08-05


### Changed

- Documentation for spruce/severity now refers to the RFC 5424 logging levels it follows, rather than the birch library it was extracted from.

## v1.0.0 - 2026-06-08


### Major Release

- First stable release of spruce — a logging-agnostic terminal-UI kit for Gleam. It renders styled terminal output (colors, boxes, tables, lists, trees, semantic message lines, icons, deterministic hash-colors, ANSI-aware alignment, and grouped/indented output) that automatically respects the terminal's color support. Render functions are pure, IO-free string builders that take an explicit Spruce context and behave identically on Erlang and JavaScript. ColorLevel (NoColor, Basic, Ansi256, TrueColor) is a stable 1.x API contract.

### Added

- Initial render modules: style, symbol, palette, align, box (with per-side borders and border colors via box.border_sides/box.border_colors), group, and message — a terminal-UI kit built on gleam_community_ansi and tty.
- Semantic line modules: spruce/severity (generic severity/status labels and badges), spruce/message (success/fail/start/ready/info/warn/error one-liners with configurable label, badge, and simple prefixes), spruce/details (key-value detail rendering), and spruce/line (compact terminal line composition).
- Arbitrary colors: style.Rgb, style.Hex, and style.Ansi256, with automatic downgrade to the nearest representable color for lower color levels.
- Adaptive light/dark colors via style.adaptive, resolved against the terminal background; the spruce context carries the detected background (spruce.background, spruce.with_background) using tty 1.1's detect_background.
- New spruce/block module for styled blocks: padding, margin, width, height, alignment, and per-side borders/border-colors in a single render call.
- New spruce/markdown module: a Glamour-style Markdown-to-ANSI renderer (headings, lists, task lists, code blocks, blockquotes, GFM tables, thematic breaks, and inline styling) built on mork, with a background-adaptive default theme.
- Structural layout modules: spruce/table (width constraints, per-column widths, configurable border style, optional row separators, and multi-line cell wrapping), spruce/list (bulleted and ordered lists with arbitrary-depth nesting), spruce/tree (tree-structured output), and spruce/layout (composing multi-line text blocks).
- New spruce/highlight module: syntax highlighting for 36 languages (via smalto) with dark/light/adaptive themes, a name/alias language resolver, and automatic color gating. Fenced code blocks in spruce/markdown are highlighted by default, with a plain fallback for unknown languages.
- spruce/markdown renders admonitions/callouts: GitHub-style alerts (> [!NOTE|TIP|IMPORTANT|WARNING|CAUTION]) and Astro/Starlight :::type[Title] container directives, each with a colored left border, icon, and title (custom titles supported).
- New spruce/output module: pipeable, buffered output composition. Thread the Spruce context through a pipeline with output.new/append/group/text/blank, then emit with to_string/print; append works with any Spruce -> String renderer via a _ capture.
- Release pipeline now generates a CycloneDX SBOM with licence_audit and signs it (along with a source archive) via build attestations, uploading both to the GitHub Release. Adds a `just sbom` recipe for local generation.
- Release pipeline now adds SLSA build-provenance attestations alongside the existing SBOM attestation, and publishes a SHA-256 checksums file (spruce-<version>.sha256sum) that is itself attested and uploaded to the GitHub Release. A `just dist` recipe builds the same artifact set (source archive, SBOM, checksums) locally.

### Dependencies

- Built on gleam_community_ansi (text styling) and tty >= 1.1 (color-support and terminal background detection); mork (MIT) powers Markdown parsing and smalto (MIT) powers syntax highlighting.
- Pin local Erlang/OTP to 28 and add licence_audit (via mise github backend) as a development dependency for SBOM generation.
