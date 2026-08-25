import gleam/string
import spruce
import spruce/align
import spruce/border
import spruce/box
import spruce/style
import startest/expect

pub fn simple_box_no_color_test() {
  spruce.no_color()
  |> box.simple("hi")
  |> expect.to_equal("╭────╮\n│ hi │\n╰────╯")
}

pub fn box_with_title_no_color_test() {
  box.render(spruce.no_color(), "hi", box.new() |> box.title("T"))
  |> string.starts_with("╭─ T ")
  |> expect.to_be_true
}

pub fn box_indented_test() {
  spruce.no_color()
  |> spruce.indented
  |> box.simple("hi")
  |> string.starts_with("  ╭")
  |> expect.to_be_true
}

pub fn box_color_styles_border_test() {
  let rendered = box.simple(spruce.with_color_level(spruce.TrueColor), "hi")
  expect.to_be_true(string.contains(rendered, "\u{001b}"))
}

pub fn titled_box_keeps_equal_visual_widths_test() {
  let lines =
    box.render(spruce.no_color(), "hi", box.new() |> box.title("Long"))
    |> string.split("\n")

  let assert [top, body, bottom] = lines
  expect.to_equal(align.visual_length(top), align.visual_length(body))
  expect.to_equal(align.visual_length(top), align.visual_length(bottom))
}

pub fn box_title_newline_stays_on_single_top_border_test() {
  let lines =
    box.render(spruce.no_color(), "hi", box.new() |> box.title("A\nB"))
    |> string.split("\n")

  let assert [top, body, bottom] = lines
  expect.to_equal("╭─ A B ╮", top)
  expect.to_equal(align.visual_length(body), align.visual_length(top))
  expect.to_equal(align.visual_length(bottom), align.visual_length(top))
}

pub fn box_color_leaves_title_unstyled_test() {
  let rendered =
    box.render(
      spruce.with_color_level(spruce.TrueColor),
      "hi",
      box.new() |> box.title("T"),
    )

  expect.to_be_true(string.contains(rendered, " T \u{001b}"))
}

pub fn box_border_catalog_test() {
  let options = box.new() |> box.border(border.Double)

  box.render(spruce.no_color(), "hi", options)
  |> expect.to_equal("╔════╗\n║ hi ║\n╚════╝")
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
  |> expect.to_equal("+----+\n| hi |\n+----+")
}

pub fn box_padding_adds_inner_rows_and_columns_test() {
  let options = box.new() |> box.padding(top: 1, right: 2, bottom: 1, left: 2)

  box.render(spruce.no_color(), "hi", options)
  |> expect.to_equal("╭──────╮\n│      │\n│  hi  │\n│      │\n╰──────╯")
}

pub fn box_margin_adds_outer_space_after_indent_test() {
  let options = box.new() |> box.margin(top: 1, right: 2, bottom: 1, left: 2)

  box.render(spruce.no_color(), "hi", options)
  |> expect.to_equal(
    "          \n  ╭────╮  \n  │ hi │  \n  ╰────╯  \n          ",
  )
}

pub fn box_width_wraps_content_to_stable_visual_width_test() {
  let options = box.new() |> box.width(5)
  let lines =
    box.render(spruce.no_color(), "hello world", options)
    |> string.split("\n")

  let assert [top, first, second, bottom] = lines
  expect.to_equal("╭───────╮", top)
  expect.to_equal("│ hello │", first)
  expect.to_equal("│ world │", second)
  expect.to_equal(align.visual_length(top), align.visual_length(first))
  expect.to_equal(align.visual_length(top), align.visual_length(second))
  expect.to_equal(align.visual_length(top), align.visual_length(bottom))
}

pub fn box_hidden_border_reserves_no_visible_border_test() {
  let options = box.new() |> box.border(border.Hidden)

  box.render(spruce.no_color(), "hi", options)
  |> expect.to_equal(" hi ")
}

pub fn box_default_rendering_unchanged_after_per_side_options_test() {
  box.render(spruce.no_color(), "hi", box.new())
  |> expect.to_equal("╭────╮\n│ hi │\n╰────╯")
}

pub fn box_per_side_visibility_omits_hidden_columns_and_rows_test() {
  let options =
    box.new()
    |> box.border_sides(top: True, right: False, bottom: True, left: True)

  box.render(spruce.no_color(), "hi", options)
  |> expect.to_equal("╭────\n│ hi \n╰────")
}

pub fn box_per_side_visibility_omits_corner_without_adjoining_side_test() {
  let options =
    box.new()
    |> box.border_sides(top: True, right: True, bottom: True, left: False)

  box.render(spruce.no_color(), "hi", options)
  |> expect.to_equal("────╮\n hi │\n────╯")
}

pub fn box_per_side_visibility_all_hidden_matches_hidden_shape_test() {
  let options =
    box.new()
    |> box.border_sides(top: False, right: False, bottom: False, left: False)

  box.render(spruce.no_color(), "hi", options)
  |> expect.to_equal(" hi ")
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

  expect.to_be_true(string.contains(rendered, "\u{001b}[31m"))
  expect.to_be_true(string.contains(rendered, "\u{001b}[32m"))
  expect.to_be_true(string.contains(rendered, "\u{001b}[34m"))
  expect.to_be_true(string.contains(rendered, "\u{001b}[33m"))
}

pub fn plain_box_no_color_is_bare_content_test() {
  box.render(spruce.no_color(), "hi", box.plain())
  |> expect.to_equal("hi")
}

pub fn plain_box_padding_adds_inner_space_test() {
  let options = box.plain() |> box.padding(top: 1, right: 2, bottom: 1, left: 2)

  box.render(spruce.no_color(), "hi", options)
  |> expect.to_equal("      \n  hi  \n      ")
}

pub fn plain_box_width_wraps_content_test() {
  let options = box.plain() |> box.width(5)

  box.render(spruce.no_color(), "hello world", options)
  |> expect.to_equal("hello\nworld")
}

pub fn box_alignment_places_content_within_width_and_height_test() {
  let options =
    box.plain()
    |> box.width(6)
    |> box.height(3)
    |> box.align(horizontal: align.Center, vertical: align.Center)

  box.render(spruce.no_color(), "hi", options)
  |> expect.to_equal("      \n  hi  \n      ")
}

pub fn box_height_truncates_tall_content_test() {
  let options = box.plain() |> box.height(2)

  box.render(spruce.no_color(), "a\nb\nc", options)
  |> expect.to_equal("a\nb")
}

pub fn bordered_box_title_widens_aligned_content_test() {
  let options =
    box.new()
    |> box.title("Long title")
    |> box.align(horizontal: align.End, vertical: align.Start)

  box.render(spruce.no_color(), "hi", options)
  |> expect.to_equal("╭─ Long title ╮\n│          hi │\n╰─────────────╯")
}

pub fn plain_box_border_on_and_off_test() {
  let bordered = box.plain() |> box.border(border.Rounded)

  box.render(spruce.no_color(), "hi", box.plain())
  |> expect.to_equal("hi")
  box.render(spruce.no_color(), "hi", bordered)
  |> expect.to_equal("╭──╮\n│hi│\n╰──╯")
}

pub fn plain_box_per_side_border_behavior_test() {
  let options =
    box.plain()
    |> box.border(border.Rounded)
    |> box.border_sides(top: True, right: False, bottom: True, left: True)

  box.render(spruce.no_color(), "hi", options)
  |> expect.to_equal("╭──\n│hi\n╰──")
}

pub fn box_hidden_top_omits_top_row_and_corners_test() {
  let options =
    box.plain()
    |> box.border(border.Rounded)
    |> box.border_sides(top: False, right: True, bottom: True, left: False)

  box.render(spruce.no_color(), "hi", options)
  |> expect.to_equal("hi│\n──╯")
}

pub fn box_content_style_is_color_gated_test() {
  let options =
    box.plain() |> box.foreground(style.Red) |> box.background(style.Blue)

  box.render(spruce.no_color(), "hi", options)
  |> expect.to_equal("hi")

  box.render(spruce.with_color_level(spruce.TrueColor), "hi", options)
  |> string.contains("\u{001b}")
  |> expect.to_be_true
}

pub fn box_background_fills_padding_ring_test() {
  let options =
    box.plain()
    |> box.background(style.Blue)
    |> box.padding(top: 1, right: 1, bottom: 1, left: 1)

  box.render(spruce.with_color_level(spruce.TrueColor), "hi", options)
  |> expect.to_equal(
    "\u{001b}[44m    \u{001b}[49m\n\u{001b}[44m hi \u{001b}[49m\n\u{001b}[44m    \u{001b}[49m",
  )
}

pub fn box_border_color_applies_to_all_sides_test() {
  let context = spruce.with_color_level(spruce.Basic)
  let options =
    box.plain() |> box.border(border.Normal) |> box.border_color(style.Red)
  let rendered = box.render(context, "hi", options)

  expect.to_be_true(string.contains(rendered, "\u{001b}[31m"))
  expect.to_be_false(string.contains(rendered, "\u{001b}[36m"))
}

pub fn plain_box_margin_adds_outer_space_after_indent_test() {
  let options = box.plain() |> box.margin(top: 1, right: 2, bottom: 1, left: 2)

  box.render(spruce.no_color(), "hi", options)
  |> expect.to_equal("      \n  hi  \n      ")
}
