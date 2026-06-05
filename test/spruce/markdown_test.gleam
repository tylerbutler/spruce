import gleam/string
import spruce
import spruce/markdown
import spruce/symbol
import startest/expect
import tty

pub fn heading_no_color_test() {
  markdown.render(spruce.no_color(), "# Hello")
  |> expect.to_equal("# Hello")
}

pub fn heading_id_attribute_stripped_test() {
  markdown.render(spruce.no_color(), "## Title {#custom}")
  |> expect.to_equal("## Title")
}

pub fn paragraph_inline_no_color_test() {
  let out =
    markdown.render(
      spruce.no_color(),
      "A *soft* **loud** ~~gone~~ and `code` span.",
    )

  expect.to_equal(out, "A soft loud gone and `code` span.")
  expect.to_be_false(string.contains(out, "\u{001b}"))
}

pub fn bullet_ordered_nested_tasklist_test() {
  let md = "- parent\n  - child\n- [x] done\n\n3. third\n4. fourth"
  let out = markdown.render(spruce.no_color(), md)

  expect.to_be_true(string.contains(out, "- parent\n  - child"))
  expect.to_be_true(string.contains(out, "- [x] done"))
  expect.to_be_true(string.contains(out, "3. third\n4. fourth"))
}

pub fn fenced_code_block_box_test() {
  let out = markdown.render(spruce.no_color(), "```gleam\nlet x = 1\n```")

  expect.to_be_true(string.contains(out, "gleam"))
  expect.to_be_true(string.contains(out, "let x = 1"))
  expect.to_be_true(string.contains(out, "╭"))
}

pub fn fenced_code_block_has_top_padding_test() {
  let out = markdown.render(spruce.no_color(), "```gleam\nlet x = 1\n```")

  expect.to_be_true(string.contains(out, "│         │\n│let x = 1│"))
}

pub fn fenced_code_block_highlight_no_color_stays_plain_test() {
  let out = markdown.render(spruce.no_color(), "```gleam\nlet x = 1\n```")

  expect.to_be_true(string.contains(out, "let x = 1"))
  expect.to_be_true(string.contains(out, "╭"))
  expect.to_be_false(string.contains(out, "\u{001b}"))
}

pub fn fenced_code_block_highlight_color_applies_test() {
  let out =
    markdown.render(
      spruce.with_color_level(tty.TrueColor),
      "```gleam\nlet x = 1\n```",
    )

  expect.to_be_true(string.contains(out, "\u{001b}"))
  expect.to_be_true(string.contains(
    out,
    "\u{001b}[1m\u{001b}[38;2;196;181;253mlet",
  ))
  expect.to_be_true(string.contains(out, "x"))
}

pub fn fenced_code_block_unknown_language_stays_plain_test() {
  let out = markdown.render(spruce.no_color(), "```nonsense\nlet x = 1\n```")

  expect.to_be_true(string.contains(out, "nonsense"))
  expect.to_be_true(string.contains(out, "let x = 1"))
  expect.to_be_false(string.contains(out, "\u{001b}"))
}

pub fn blockquote_indented_test() {
  markdown.render(spruce.no_color(), "> quoted")
  |> expect.to_equal("┃ quoted")
}

pub fn blockquote_text_is_italic_when_colored_test() {
  let out = markdown.render(spruce.with_color_level(tty.TrueColor), "> quoted")

  expect.to_be_true(string.contains(out, "\u{001b}[3mquoted\u{001b}[23m"))
}

pub fn github_alert_note_test() {
  let out = markdown.render(spruce.no_color(), "> [!NOTE]\n> Pay attention.")

  expect.to_be_true(string.contains(out, "┃ "))
  expect.to_be_true(string.contains(out, "Note"))
  expect.to_be_true(string.contains(out, symbol.info))
  expect.to_be_true(string.contains(out, "Pay attention."))
  expect.to_be_false(string.contains(out, "[!NOTE]"))
}

pub fn github_alert_custom_title_test() {
  let out =
    markdown.render(spruce.no_color(), "> [!WARNING] Heads up\n> Be careful.")

  expect.to_be_true(string.contains(out, symbol.warn))
  expect.to_be_true(string.contains(out, "Heads up"))
  expect.to_be_true(string.contains(out, "Be careful."))
  expect.to_be_false(string.contains(out, "Warning\n"))
}

pub fn github_alert_aliases_test() {
  let tip = markdown.render(spruce.no_color(), "> [!TIP]\n> A tip.")
  expect.to_be_true(string.contains(tip, "Tip"))
  expect.to_be_true(string.contains(tip, symbol.success))

  let important =
    markdown.render(spruce.no_color(), "> [!IMPORTANT]\n> Read this.")
  expect.to_be_true(string.contains(important, "Important"))
  expect.to_be_true(string.contains(important, symbol.notice))

  let caution = markdown.render(spruce.no_color(), "> [!CAUTION]\n> Danger.")
  expect.to_be_true(string.contains(caution, "Caution"))
  expect.to_be_true(string.contains(caution, symbol.error))
}

pub fn github_alert_unknown_stays_quote_test() {
  let out = markdown.render(spruce.no_color(), "> [!BOGUS]\n> body")

  expect.to_be_true(string.contains(out, "[!BOGUS]"))
  expect.to_be_false(string.contains(out, symbol.info))
}

pub fn astro_directive_note_test() {
  let out =
    markdown.render(spruce.no_color(), ":::note\nAstro aside body.\n:::")

  expect.to_be_true(string.contains(out, "Note"))
  expect.to_be_true(string.contains(out, symbol.info))
  expect.to_be_true(string.contains(out, "Astro aside body."))
  expect.to_be_false(string.contains(out, ":::"))
}

pub fn astro_directive_custom_title_test() {
  let out =
    markdown.render(
      spruce.no_color(),
      ":::danger[Watch Out]\nSomething risky.\n:::",
    )

  expect.to_be_true(string.contains(out, symbol.error))
  expect.to_be_true(string.contains(out, "Watch Out"))
  expect.to_be_true(string.contains(out, "Something risky."))
  expect.to_be_false(string.contains(out, ":::"))
}

pub fn astro_directive_multi_paragraph_test() {
  let out =
    markdown.render(
      spruce.no_color(),
      ":::tip\nFirst paragraph.\n\nSecond paragraph.\n:::",
    )

  expect.to_be_true(string.contains(out, "First paragraph."))
  expect.to_be_true(string.contains(out, "Second paragraph."))
}

pub fn non_directive_colon_fence_untouched_test() {
  let out = markdown.render(spruce.no_color(), ":::unknownthing\nbody\n:::")

  expect.to_be_true(string.contains(out, ":::unknownthing"))
}

pub fn gfm_table_grid_test() {
  let out =
    markdown.render(spruce.no_color(), "| A | B |\n| - | - |\n| 1 | 2 |")

  expect.to_be_true(string.contains(out, "┌"))
  expect.to_be_true(string.contains(out, "│ A │ B │"))
  expect.to_be_true(string.contains(out, "│ 1 │ 2 │"))
}

pub fn thematic_break_rule_test() {
  markdown.render(spruce.no_color(), "---")
  |> expect.to_equal("────────────────────────────────────────")
}

pub fn multi_element_smoke_test() {
  let md =
    "# Title\n\nText with [a link](https://example.com).\n\n> quote\n\n| A |\n| - |\n| B |\n\n- item\n\n```txt\ncode\n```"
  let out = markdown.render(spruce.no_color(), md)

  expect.to_be_true(string.contains(out, "# Title"))
  expect.to_be_true(string.contains(out, "https://example.com"))
  expect.to_be_true(string.contains(out, "┃ quote"))
  expect.to_be_true(string.contains(out, "code"))
}

pub fn heading_truecolor_is_styled_test() {
  let out = markdown.render(spruce.with_color_level(tty.TrueColor), "# Hello")

  expect.to_be_true(string.contains(out, "\u{001b}"))
}

pub fn render_with_options_wraps_and_themes_test() {
  let options =
    markdown.default_options()
    |> markdown.with_theme(markdown.dark_theme())
    |> markdown.with_theme(markdown.light_theme())
    |> markdown.with_width(8)
  let out = markdown.render_with(spruce.no_color(), "alpha beta gamma", options)

  expect.to_equal(out, "alpha\nbeta\ngamma")
}

pub fn heading_theme_adapts_to_background_test() {
  let dark =
    markdown.render(
      spruce.with_color_level(tty.TrueColor) |> spruce.with_background(tty.Dark),
      "# Hello",
    )
  let light =
    markdown.render(
      spruce.with_color_level(tty.TrueColor)
        |> spruce.with_background(tty.Light),
      "# Hello",
    )

  expect.to_be_true(string.contains(dark, "\u{001b}"))
  expect.to_be_true(string.contains(light, "\u{001b}"))
  expect.to_not_equal(dark, light)
}
