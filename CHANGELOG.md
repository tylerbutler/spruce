# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.0.1 - 2026-06-08


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

