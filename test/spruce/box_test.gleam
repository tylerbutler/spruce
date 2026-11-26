import gleam/list
import gleam/string
import gleeunit/should
import spruce
import spruce/align
import spruce/border
import spruce/box
import spruce/style

pub fn simple_box_no_color_test() {
  spruce.no_color()
  |> box.simple("hi")
  |> should.equal("╭────╮\n│ hi │\n╰────╯")
}

pub fn simple_box_normalizes_crlf_before_sizing_test() {
  box.simple(spruce.no_color(), "abc\r\nx")
  |> should.equal("╭─────╮\n│ abc │\n│ x   │\n╰─────╯")
}

pub fn box_normalizes_mixed_line_endings_with_all_width_paths_test() {
  list.each(
    [box.new(), box.new() |> box.width(2), box.new() |> box.width(0)],
    fn(options) {
      box.render(spruce.no_color(), "abc\r\n\r\nx\ny\r\n", options)
      |> should.equal(box.render(spruce.no_color(), "abc\n\nx\ny\n", options))
    },
  )
}

pub fn plain_box_preserves_blank_lines_and_standalone_carriage_return_test() {
  box.render(spruce.no_color(), "\r\n\n", box.plain())
  |> should.equal("\n\n")
  box.render(spruce.no_color(), "a\rb\r\nx", box.plain())
  |> should.equal("a\rb\nx ")
}

pub fn box_preserves_carriage_return_before_crlf_with_all_width_paths_test() {
  list.each(
    [
      #(box.plain(), "a\r\nb\n "),
      #(box.plain() |> box.width(2), "a\r \nb \n  "),
      #(box.plain() |> box.width(0), "a\r\nb\n "),
    ],
    fn(pair) {
      let #(options, expected) = pair
      box.render(spruce.no_color(), "a\r\r\nb\r\n", options)
      |> should.equal(expected)
    },
  )
}

pub fn box_preserves_carriage_return_before_inserted_wrap_test() {
  box.render(spruce.no_color(), "ab\rc", box.plain() |> box.width(2))
  |> should.equal("ab\r\nc ")
}

pub fn simple_box_aligns_bmp_emoji_with_plain_text_test() {
  box.simple(spruce.no_color(), "✅ done\nplain ok")
  |> should.equal("╭──────────╮\n│ ✅ done  │\n│ plain ok │\n╰──────────╯")
}

pub fn box_with_title_no_color_test() {
  box.render(spruce.no_color(), "hi", box.new() |> box.title("T"))
  |> string.starts_with("╭─ T ")
  |> should.be_true
}

pub fn box_indented_test() {
  spruce.no_color()
  |> spruce.indented
  |> box.simple("hi")
  |> string.starts_with("  ╭")
  |> should.be_true
}

pub fn box_color_styles_border_test() {
  let rendered = box.simple(spruce.with_color_level(spruce.TrueColor), "hi")
  should.be_true(string.contains(rendered, "\u{001b}"))
}

pub fn titled_box_keeps_equal_visual_widths_test() {
  let lines =
    box.render(spruce.no_color(), "hi", box.new() |> box.title("Long"))
    |> string.split("\n")

  let assert [top, body, bottom] = lines
  should.equal(align.visual_length(top), align.visual_length(body))
  should.equal(align.visual_length(top), align.visual_length(bottom))
}

pub fn box_title_newline_stays_on_single_top_border_test() {
  let lines =
    box.render(spruce.no_color(), "hi", box.new() |> box.title("A\nB"))
    |> string.split("\n")

  let assert [top, body, bottom] = lines
  should.equal("╭─ A B ╮", top)
  should.equal(align.visual_length(body), align.visual_length(top))
  should.equal(align.visual_length(bottom), align.visual_length(top))
}

pub fn box_color_leaves_title_unstyled_test() {
  let rendered =
    box.render(
      spruce.with_color_level(spruce.TrueColor),
      "hi",
      box.new() |> box.title("T"),
    )

  should.be_true(string.contains(rendered, " T \u{001b}"))
}

pub fn box_border_catalog_test() {
  let options = box.new() |> box.border(border.Double)

  box.render(spruce.no_color(), "hi", options)
  |> should.equal("╔════╗\n║ hi ║\n╚════╝")
}

pub fn box_custom_border_test() {
  let chars =
    border.BorderChars(
      top_left: "+",
      top: "-",
      top_right: "+",
      right: "|",
      bottom_right: "+",
      bottom: "-",
      bottom_left: "+",
      left: "|",
    )

  let options = box.new() |> box.border(border.Custom(chars))

  box.render(spruce.no_color(), "hi", options)
  |> should.equal("+----+\n| hi |\n+----+")
}

pub fn box_padding_adds_inner_rows_and_columns_test() {
  let options = box.new() |> box.padding(top: 1, right: 2, bottom: 1, left: 2)

  box.render(spruce.no_color(), "hi", options)
  |> should.equal("╭──────╮\n│      │\n│  hi  │\n│      │\n╰──────╯")
}

pub fn box_margin_adds_outer_space_after_indent_test() {
  let options = box.new() |> box.margin(top: 1, right: 2, bottom: 1, left: 2)

  box.render(spruce.no_color(), "hi", options)
  |> should.equal("          \n  ╭────╮  \n  │ hi │  \n  ╰────╯  \n          ")
}

pub fn box_width_wraps_content_to_stable_visual_width_test() {
  let options = box.new() |> box.width(5)
  let lines =
    box.render(spruce.no_color(), "hello world", options)
    |> string.split("\n")

  let assert [top, first, second, bottom] = lines
  should.equal("╭───────╮", top)
  should.equal("│ hello │", first)
  should.equal("│ world │", second)
  should.equal(align.visual_length(top), align.visual_length(first))
  should.equal(align.visual_length(top), align.visual_length(second))
  should.equal(align.visual_length(top), align.visual_length(bottom))
}

pub fn box_hidden_border_reserves_no_visible_border_test() {
  let options = box.new() |> box.border(border.Hidden)

  box.render(spruce.no_color(), "hi", options)
  |> should.equal(" hi ")
}

pub fn box_default_rendering_unchanged_after_per_side_options_test() {
  box.render(spruce.no_color(), "hi", box.new())
  |> should.equal("╭────╮\n│ hi │\n╰────╯")
}

pub fn box_per_side_visibility_omits_hidden_columns_and_rows_test() {
  let options =
    box.new()
    |> box.border_sides(top: True, right: False, bottom: True, left: True)

  box.render(spruce.no_color(), "hi", options)
  |> should.equal("╭────\n│ hi \n╰────")
}

pub fn box_per_side_visibility_omits_corner_without_adjoining_side_test() {
  let options =
    box.new()
    |> box.border_sides(top: True, right: True, bottom: True, left: False)

  box.render(spruce.no_color(), "hi", options)
  |> should.equal("────╮\n hi │\n────╯")
}

pub fn box_per_side_visibility_all_hidden_matches_hidden_shape_test() {
  let options =
    box.new()
    |> box.border_sides(top: False, right: False, bottom: False, left: False)

  box.render(spruce.no_color(), "hi", options)
  |> should.equal(" hi ")
}

pub fn box_per_side_border_colors_are_applied_test() {
  let context = spruce.with_color_level(spruce.TrueColor)
  let options =
    box.new()
    |> box.border_colors(
      top: style.Red,
      right: style.Green,
      bottom: style.Blue,
      left: style.Yellow,
    )
  let rendered = box.render(context, "hi", options)

  should.be_true(string.contains(rendered, "\u{001b}[31m"))
  should.be_true(string.contains(rendered, "\u{001b}[32m"))
  should.be_true(string.contains(rendered, "\u{001b}[34m"))
  should.be_true(string.contains(rendered, "\u{001b}[33m"))
}

pub fn plain_box_no_color_is_bare_content_test() {
  box.render(spruce.no_color(), "hi", box.plain())
  |> should.equal("hi")
}

pub fn plain_box_hidden_title_does_not_widen_content_test() {
  box.render(spruce.no_color(), "x", box.plain() |> box.title("Long title"))
  |> should.equal("x")
}

pub fn hidden_box_title_preserves_explicit_spacing_test() {
  let options =
    box.new()
    |> box.border(border.Hidden)
    |> box.title("Long title")
    |> box.width(3)
    |> box.padding(top: 0, right: 1, bottom: 0, left: 1)
    |> box.margin(top: 0, right: 1, bottom: 0, left: 1)

  box.render(spruce.no_color(), "x", options)
  |> should.equal("  x    ")
}

pub fn box_hidden_top_title_does_not_widen_other_sides_test() {
  let options =
    box.plain()
    |> box.border(border.Rounded)
    |> box.title("Long title")
    |> box.border_sides(top: False, right: True, bottom: True, left: True)

  box.render(spruce.no_color(), "x", options)
  |> should.equal("│x│\n╰─╯")
}

pub fn plain_box_padding_adds_inner_space_test() {
  let options = box.plain() |> box.padding(top: 1, right: 2, bottom: 1, left: 2)

  box.render(spruce.no_color(), "hi", options)
  |> should.equal("      \n  hi  \n      ")
}

pub fn plain_box_width_wraps_content_test() {
  let options = box.plain() |> box.width(5)

  box.render(spruce.no_color(), "hello world", options)
  |> should.equal("hello\nworld")
}

pub fn box_alignment_places_content_within_width_and_height_test() {
  let options =
    box.plain()
    |> box.width(6)
    |> box.height(3)
    |> box.align(horizontal: align.Center, vertical: align.Center)

  box.render(spruce.no_color(), "hi", options)
  |> should.equal("      \n  hi  \n      ")
}

pub fn box_height_truncates_tall_content_test() {
  let options = box.plain() |> box.height(2)

  box.render(spruce.no_color(), "a\nb\nc", options)
  |> should.equal("a\nb")
}

pub fn box_zero_height_preserves_title_width_test() {
  let options = box.new() |> box.title("Title") |> box.height(0)

  box.render(spruce.no_color(), "x", options)
  |> should.equal("╭─ Title ╮\n╰────────╯")
}

pub fn box_zero_height_preserves_explicit_width_test() {
  let options = box.new() |> box.width(5) |> box.height(0)

  box.render(spruce.no_color(), "x", options)
  |> should.equal("╭───────╮\n╰───────╯")
}

pub fn box_zero_height_padding_uses_region_width_test() {
  let options =
    box.new()
    |> box.title("Title")
    |> box.height(0)
    |> box.padding(top: 1, right: 2, bottom: 1, left: 1)

  box.render(spruce.no_color(), "x", options)
  |> should.equal("╭─ Title ╮\n│        │\n│        │\n╰────────╯")

  box.render(spruce.no_color(), "x", options |> box.width(7))
  |> should.equal("╭─ Title ──╮\n│          │\n│          │\n╰──────────╯")
}

pub fn box_zero_height_hidden_border_ignores_title_test() {
  let options =
    box.plain()
    |> box.title("Long title")
    |> box.width(3)
    |> box.height(0)

  box.render(spruce.no_color(), "x", options)
  |> should.equal("")

  box.render(
    spruce.no_color(),
    "x",
    options |> box.padding(top: 1, right: 1, bottom: 1, left: 1),
  )
  |> should.equal("     \n     ")
}

pub fn box_zero_height_hidden_top_ignores_title_test() {
  let options =
    box.plain()
    |> box.border(border.Rounded)
    |> box.title("Long title")
    |> box.width(3)
    |> box.height(0)
    |> box.border_sides(top: False, right: True, bottom: True, left: True)

  box.render(spruce.no_color(), "x", options)
  |> should.equal("╰───╯")
}

pub fn box_zero_height_omits_hidden_side_corners_test() {
  let options =
    box.new()
    |> box.title("Title")
    |> box.height(0)
    |> box.border_sides(top: True, right: False, bottom: True, left: True)

  box.render(spruce.no_color(), "x", options)
  |> should.equal("╭─ Title \n╰────────")

  box.render(
    spruce.no_color(),
    "x",
    options
      |> box.border_sides(top: True, right: True, bottom: True, left: False),
  )
  |> should.equal("─ Title ╮\n────────╯")
}

pub fn bordered_box_title_widens_aligned_content_test() {
  let options =
    box.new()
    |> box.title("Long title")
    |> box.align(horizontal: align.End, vertical: align.Start)

  box.render(spruce.no_color(), "hi", options)
  |> should.equal("╭─ Long title ╮\n│          hi │\n╰─────────────╯")
}

pub fn plain_box_border_on_and_off_test() {
  let bordered = box.plain() |> box.border(border.Rounded)

  box.render(spruce.no_color(), "hi", box.plain())
  |> should.equal("hi")
  box.render(spruce.no_color(), "hi", bordered)
  |> should.equal("╭──╮\n│hi│\n╰──╯")
}

pub fn plain_box_per_side_border_behavior_test() {
  let options =
    box.plain()
    |> box.border(border.Rounded)
    |> box.border_sides(top: True, right: False, bottom: True, left: True)

  box.render(spruce.no_color(), "hi", options)
  |> should.equal("╭──\n│hi\n╰──")
}

pub fn box_hidden_top_omits_top_row_and_corners_test() {
  let options =
    box.plain()
    |> box.border(border.Rounded)
    |> box.border_sides(top: False, right: True, bottom: True, left: False)

  box.render(spruce.no_color(), "hi", options)
  |> should.equal("hi│\n──╯")
}

pub fn box_content_style_is_color_gated_test() {
  let options =
    box.plain() |> box.foreground(style.Red) |> box.background(style.Blue)

  box.render(spruce.no_color(), "hi", options)
  |> should.equal("hi")

  box.render(spruce.with_color_level(spruce.TrueColor), "hi", options)
  |> string.contains("\u{001b}")
  |> should.be_true
}

pub fn box_background_fills_padding_ring_test() {
  let options =
    box.plain()
    |> box.background(style.Blue)
    |> box.padding(top: 1, right: 1, bottom: 1, left: 1)

  box.render(spruce.with_color_level(spruce.TrueColor), "hi", options)
  |> should.equal(
    "\u{001b}[44m    \u{001b}[49m\n\u{001b}[44m hi \u{001b}[49m\n\u{001b}[44m    \u{001b}[49m",
  )
}

pub fn box_background_survives_wrapped_foreground_test() {
  let context = spruce.with_color_level(spruce.Basic)
  let content =
    style.render(
      context,
      style.new() |> style.fg(style.Red),
      "hello world again ok",
    )
  let options = box.new() |> box.width(12) |> box.background(style.Blue)
  let rendered = box.render(context, content, options)
  should.be_true(string.contains(
    rendered,
    "\u{001b}[44m \u{001b}[31mhello world\u{001b}[39m  \u{001b}[49m",
  ))
  should.be_false(string.contains(rendered, "\u{001b}[0m"))
}

pub fn box_border_color_applies_to_all_sides_test() {
  let context = spruce.with_color_level(spruce.Basic)
  let options =
    box.plain() |> box.border(border.Normal) |> box.border_color(style.Red)
  let rendered = box.render(context, "hi", options)

  should.be_true(string.contains(rendered, "\u{001b}[31m"))
  should.be_false(string.contains(rendered, "\u{001b}[36m"))
}

pub fn plain_box_margin_adds_outer_space_after_indent_test() {
  let options = box.plain() |> box.margin(top: 1, right: 2, bottom: 1, left: 2)

  box.render(spruce.no_color(), "hi", options)
  |> should.equal("      \n  hi  \n      ")
}

pub fn box_multiline_styles_are_isolated_from_padding_and_borders_test() {
  let context = spruce.with_color_level(spruce.Basic)
  let options = [
    box.new(),
    box.new() |> box.width(0),
    box.new() |> box.width(3),
  ]

  list.each(["\u{001b}[1m", "\u{001b}[2m"], fn(intensity) {
    let content = intensity <> "\u{001b}[31mone\ntwo\u{001b}[39m\u{001b}[22m"
    let expected = fn(close: String) -> String {
      "\u{001b}[36m╭─────╮\u{001b}[39m\n"
      <> "\u{001b}[36m│\u{001b}[39m "
      <> intensity
      <> "\u{001b}[31mone"
      <> close
      <> " \u{001b}[36m│\u{001b}[39m\n"
      <> "\u{001b}[36m│\u{001b}[39m "
      <> intensity
      <> "\u{001b}[31mtwo\u{001b}[39m\u{001b}[22m \u{001b}[36m│\u{001b}[39m\n"
      <> "\u{001b}[36m╰─────╯\u{001b}[39m"
    }

    list.each(options, fn(options) {
      box.render(context, content, options)
      |> assert_synthetic_close("\u{001b}[22m\u{001b}[39m", expected)
    })
  })
}

pub fn box_crlf_normalization_preserves_multiline_style_isolation_test() {
  let context = spruce.with_color_level(spruce.Basic)
  let opening = "\u{001b}[1;31m"
  let reset = "\u{001b}[0m"

  list.each(
    [box.new(), box.new() |> box.width(0), box.new() |> box.width(2)],
    fn(options) {
      box.render(context, opening <> "abc\r\n\r\nx\r\n" <> reset, options)
      |> should.equal(box.render(
        context,
        opening <> "abc\n\nx\n" <> reset,
        options,
      ))
    },
  )
}

pub fn box_height_truncation_closes_multiline_styles_test() {
  box.render(
    spruce.with_color_level(spruce.Basic),
    "\u{001b}[1m\u{001b}[31mone\ntwo\u{001b}[39m\u{001b}[22m",
    box.plain() |> box.height(1),
  )
  |> assert_synthetic_close("\u{001b}[22m\u{001b}[39m", fn(close) {
    "\u{001b}[1m\u{001b}[31mone" <> close
  })
}

pub fn box_multiline_style_closes_before_alignment_spaces_test() {
  box.render(
    spruce.with_color_level(spruce.Basic),
    "\u{001b}[31ma\nlong\u{001b}[39m",
    box.plain() |> box.align(horizontal: align.Center, vertical: align.Start),
  )
  |> assert_synthetic_close("\u{001b}[39m", fn(close) {
    " \u{001b}[31ma" <> close <> "  \n\u{001b}[31mlong\u{001b}[39m"
  })
}

pub fn box_unconstrained_preserves_whitespace_and_blank_lines_test() {
  let context = spruce.no_color()
  let content =
    style.render(context, style.new() |> style.bold, "\n  a  \n\n \n")
  let expected = "     \n  a  \n     \n     \n     "

  box.render(context, content, box.plain())
  |> should.equal(expected)
  box.render(context, content, box.plain() |> box.width(0))
  |> should.equal(expected)
  box.render(context, content, box.new() |> box.border(border.Hidden))
  |> should.equal("       \n   a   \n       \n       \n       ")
}

pub fn plain_box_multiline_styles_preserve_blank_lines_and_spaces_test() {
  box.render(
    spruce.with_color_level(spruce.Basic),
    "\u{001b}[31m a  \n\n b \n\u{001b}[39m",
    box.plain(),
  )
  |> assert_synthetic_close("\u{001b}[39m", fn(close) {
    "\u{001b}[31m a  "
    <> close
    <> "\n\u{001b}[31m"
    <> close
    <> "    \n\u{001b}[31m b "
    <> close
    <> " \n\u{001b}[31m\u{001b}[39m    "
  })
}

pub fn box_zero_visual_width_still_isolates_styles_test() {
  let context = spruce.with_color_level(spruce.Basic)
  let content = "\u{001b}[31m\n\u{001b}[39m"
  let expected = fn(close: String) -> String {
    "\u{001b}[31m" <> close <> "\n\u{001b}[31m\u{001b}[39m"
  }

  box.render(context, content, box.plain())
  |> assert_synthetic_close("\u{001b}[39m", expected)
  box.render(context, content, box.plain() |> box.width(0))
  |> assert_synthetic_close("\u{001b}[39m", expected)
}

fn assert_synthetic_close(
  actual: String,
  selective_close: String,
  expected: fn(String) -> String,
) -> Nil {
  case actual == expected("\u{001b}[0m") {
    True -> Nil
    False -> should.equal(actual, expected(selective_close))
  }
}

pub fn box_expands_tabs_to_tab_stops_test() {
  box.render(spruce.no_color(), "a\tb\nlonger\tx", box.new())
  |> should.equal(
    "╭───────────╮\n"
    <> "│ a       b │\n"
    <> "│ longer  x │\n"
    <> "╰───────────╯",
  )
}
