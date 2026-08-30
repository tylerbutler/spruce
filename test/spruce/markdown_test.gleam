import gleam/string
import gleeunit/should
import spruce
import spruce/markdown
import spruce/symbol

pub fn heading_no_color_test() {
  markdown.render(spruce.no_color(), "# Hello")
  |> should.equal("# Hello")
}

pub fn heading_id_attribute_stripped_test() {
  markdown.render(spruce.no_color(), "## Title {#custom}")
  |> should.equal("## Title")
}

pub fn paragraph_inline_no_color_test() {
  let rendered =
    markdown.render(
      spruce.no_color(),
      "A *soft* **loud** ~~gone~~ and `code` span.",
    )

  should.equal(rendered, "A soft loud gone and `code` span.")
  should.be_false(string.contains(rendered, "\u{001b}"))
}

pub fn bullet_ordered_nested_tasklist_test() {
  let markdown_text = "- parent\n  - child\n- [x] done\n\n3. third\n4. fourth"
  let rendered = markdown.render(spruce.no_color(), markdown_text)

  should.be_true(string.contains(rendered, "• parent\n  • child"))
  should.be_true(string.contains(rendered, "• [x] done"))
  should.be_true(string.contains(rendered, "3. third\n4. fourth"))
}

pub fn fenced_code_block_box_test() {
  let rendered = markdown.render(spruce.no_color(), "```gleam\nlet x = 1\n```")

  should.be_true(string.contains(rendered, "gleam"))
  should.be_true(string.contains(rendered, "let x = 1"))
  should.be_true(string.contains(rendered, "╭"))
}

pub fn fenced_code_block_has_top_padding_test() {
  let rendered = markdown.render(spruce.no_color(), "```gleam\nlet x = 1\n```")

  should.be_true(string.contains(rendered, "│         │\n│let x = 1│"))
}

pub fn fenced_code_block_highlight_no_color_stays_plain_test() {
  let rendered = markdown.render(spruce.no_color(), "```gleam\nlet x = 1\n```")

  should.be_true(string.contains(rendered, "let x = 1"))
  should.be_true(string.contains(rendered, "╭"))
  should.be_false(string.contains(rendered, "\u{001b}"))
}

pub fn fenced_code_block_highlight_color_applies_test() {
  let rendered =
    markdown.render(
      spruce.with_color_level(spruce.TrueColor),
      "```gleam\nlet x = 1\n```",
    )

  should.be_true(string.contains(rendered, "\u{001b}"))
  should.be_true(string.contains(
    rendered,
    "\u{001b}[1m\u{001b}[38;2;196;181;253mlet",
  ))
  should.be_true(string.contains(rendered, "x"))
}

pub fn fenced_code_block_unknown_language_stays_plain_test() {
  let rendered =
    markdown.render(spruce.no_color(), "```nonsense\nlet x = 1\n```")

  should.be_true(string.contains(rendered, "nonsense"))
  should.be_true(string.contains(rendered, "let x = 1"))
  should.be_false(string.contains(rendered, "\u{001b}"))
}

pub fn blockquote_indented_test() {
  markdown.render(spruce.no_color(), "> quoted")
  |> should.equal("┃ quoted")
}

pub fn blockquote_text_is_italic_when_colored_test() {
  let rendered =
    markdown.render(spruce.with_color_level(spruce.TrueColor), "> quoted")

  should.be_true(string.contains(rendered, "\u{001b}[3mquoted\u{001b}[23m"))
}

pub fn github_alert_note_test() {
  let rendered =
    markdown.render(spruce.no_color(), "> [!NOTE]\n> Pay attention.")

  should.be_true(string.contains(rendered, "┃ "))
  should.be_true(string.contains(rendered, "Note"))
  should.be_true(string.contains(
    rendered,
    symbol.status(spruce.Unicode, symbol.Info),
  ))
  should.be_true(string.contains(rendered, "Pay attention."))
  should.be_false(string.contains(rendered, "[!NOTE]"))
}

pub fn github_alert_custom_title_test() {
  let rendered =
    markdown.render(spruce.no_color(), "> [!WARNING] Heads up\n> Be careful.")

  should.be_true(string.contains(
    rendered,
    symbol.status(spruce.Unicode, symbol.Warn),
  ))
  should.be_true(string.contains(rendered, "Heads up"))
  should.be_true(string.contains(rendered, "Be careful."))
  should.be_false(string.contains(rendered, "Warning\n"))
}

pub fn github_alert_aliases_test() {
  let tip = markdown.render(spruce.no_color(), "> [!TIP]\n> A tip.")
  should.be_true(string.contains(tip, "Tip"))
  should.be_true(string.contains(
    tip,
    symbol.status(spruce.Unicode, symbol.Success),
  ))

  let important =
    markdown.render(spruce.no_color(), "> [!IMPORTANT]\n> Read this.")
  should.be_true(string.contains(important, "Important"))
  should.be_true(string.contains(
    important,
    symbol.status(spruce.Unicode, symbol.Notice),
  ))

  let caution = markdown.render(spruce.no_color(), "> [!CAUTION]\n> Danger.")
  should.be_true(string.contains(caution, "Caution"))
  should.be_true(string.contains(
    caution,
    symbol.status(spruce.Unicode, symbol.Error),
  ))
}

pub fn github_alert_unknown_stays_quote_test() {
  let rendered = markdown.render(spruce.no_color(), "> [!BOGUS]\n> body")

  should.be_true(string.contains(rendered, "[!BOGUS]"))
  should.be_false(string.contains(
    rendered,
    symbol.status(spruce.Unicode, symbol.Info),
  ))
}

pub fn astro_directive_note_test() {
  let rendered =
    markdown.render(spruce.no_color(), ":::note\nAstro aside body.\n:::")

  should.be_true(string.contains(rendered, "Note"))
  should.be_true(string.contains(
    rendered,
    symbol.status(spruce.Unicode, symbol.Info),
  ))
  should.be_true(string.contains(rendered, "Astro aside body."))
  should.be_false(string.contains(rendered, ":::"))
}

pub fn astro_directive_custom_title_test() {
  let rendered =
    markdown.render(
      spruce.no_color(),
      ":::danger[Watch Out]\nSomething risky.\n:::",
    )

  should.be_true(string.contains(
    rendered,
    symbol.status(spruce.Unicode, symbol.Error),
  ))
  should.be_true(string.contains(rendered, "Watch Out"))
  should.be_true(string.contains(rendered, "Something risky."))
  should.be_false(string.contains(rendered, ":::"))
}

pub fn astro_directive_multi_paragraph_test() {
  let rendered =
    markdown.render(
      spruce.no_color(),
      ":::tip\nFirst paragraph.\n\nSecond paragraph.\n:::",
    )

  should.be_true(string.contains(rendered, "First paragraph."))
  should.be_true(string.contains(rendered, "Second paragraph."))
}

pub fn astro_directive_inside_fenced_code_stays_literal_test() {
  let rendered =
    markdown.render(
      spruce.no_color(),
      "```md\n:::note\nLiteral directive body.\n:::\n```",
    )

  should.be_true(string.contains(rendered, ":::note"))
  should.be_true(string.contains(rendered, "Literal directive body."))
  should.be_false(string.contains(rendered, "[!NOTE]"))
}

pub fn astro_directive_inside_fenced_code_with_indented_fence_marker_stays_literal_test() {
  let rendered =
    markdown.render(
      spruce.no_color(),
      "```md\n    ```\n:::note\nLiteral directive body.\n:::\n```",
    )

  should.be_true(string.contains(rendered, ":::note"))
  should.be_true(string.contains(rendered, "Literal directive body."))
  should.be_false(string.contains(rendered, "[!NOTE]"))
}

pub fn astro_directive_inside_indented_code_stays_literal_test() {
  let rendered =
    markdown.render(
      spruce.no_color(),
      "    :::note\n    Literal directive body.\n    :::",
    )

  should.be_true(string.contains(rendered, ":::note"))
  should.be_true(string.contains(rendered, "Literal directive body."))
  should.be_false(string.contains(rendered, "[!NOTE]"))
}

pub fn non_directive_colon_fence_untouched_test() {
  let rendered =
    markdown.render(spruce.no_color(), ":::unknownthing\nbody\n:::")

  should.be_true(string.contains(rendered, ":::unknownthing"))
}

pub fn gfm_table_grid_test() {
  let rendered =
    markdown.render(spruce.no_color(), "| A | B |\n| - | - |\n| 1 | 2 |")

  should.be_true(string.contains(rendered, "┌"))
  should.be_true(string.contains(rendered, "│ A │ B │"))
  should.be_true(string.contains(rendered, "│ 1 │ 2 │"))
}

pub fn thematic_break_rule_test() {
  markdown.render(spruce.no_color(), "---")
  |> should.equal("────────────────────────────────────────")
}

pub fn multi_element_smoke_test() {
  let markdown_text =
    "# Title\n\nText with [a link](https://example.com).\n\n> quote\n\n| A |\n| - |\n| B |\n\n- item\n\n```txt\ncode\n```"
  let rendered = markdown.render(spruce.no_color(), markdown_text)

  should.be_true(string.contains(rendered, "# Title"))
  should.be_true(string.contains(rendered, "https://example.com"))
  should.be_true(string.contains(rendered, "┃ quote"))
  should.be_true(string.contains(rendered, "code"))
}

pub fn heading_truecolor_is_styled_test() {
  let rendered =
    markdown.render(spruce.with_color_level(spruce.TrueColor), "# Hello")

  should.be_true(string.contains(rendered, "\u{001b}"))
}

pub fn render_with_options_wraps_and_themes_test() {
  let options =
    markdown.default_options()
    |> markdown.with_theme(markdown.dark_theme())
    |> markdown.with_theme(markdown.light_theme())
    |> markdown.with_width(8)
  let rendered =
    markdown.render_with(spruce.no_color(), "alpha beta gamma", options)

  should.equal(rendered, "alpha\nbeta\ngamma")
}

pub fn heading_theme_adapts_to_background_test() {
  let dark =
    markdown.render(
      spruce.with_color_level(spruce.TrueColor)
        |> spruce.with_background(spruce.Dark),
      "# Hello",
    )
  let light =
    markdown.render(
      spruce.with_color_level(spruce.TrueColor)
        |> spruce.with_background(spruce.Light),
      "# Hello",
    )

  should.be_true(string.contains(dark, "\u{001b}"))
  should.be_true(string.contains(light, "\u{001b}"))
  should.not_equal(dark, light)
}
