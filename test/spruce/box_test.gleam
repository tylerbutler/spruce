import gleam/string
import spruce
import spruce/align
import spruce/box
import spruce/style
import startest/expect
import tty

pub fn simple_box_no_color_test() {
  spruce.no_color()
  |> box.simple("hi")
  |> expect.to_equal("╭────╮\n│ hi │\n╰────╯")
}

pub fn box_with_title_no_color_test() {
  box.render(
    spruce.no_color(),
    "hi",
    box.options(title: "T", color: style.Cyan),
  )
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
  let out = box.simple(spruce.with_color_level(tty.TrueColor), "hi")
  expect.to_be_true(string.contains(out, "\u{001b}"))
}

pub fn titled_box_keeps_equal_visual_widths_test() {
  let lines =
    box.render(
      spruce.no_color(),
      "hi",
      box.options(title: "Long", color: style.Cyan),
    )
    |> string.split("\n")

  let assert [top, body, bottom] = lines
  expect.to_equal(align.visual_length(top), align.visual_length(body))
  expect.to_equal(align.visual_length(top), align.visual_length(bottom))
}

pub fn box_title_newline_stays_on_single_top_border_test() {
  let lines =
    box.render(
      spruce.no_color(),
      "hi",
      box.options(title: "A\nB", color: style.Cyan),
    )
    |> string.split("\n")

  let assert [top, body, bottom] = lines
  expect.to_equal("╭─ A B ╮", top)
  expect.to_equal(align.visual_length(body), align.visual_length(top))
  expect.to_equal(align.visual_length(bottom), align.visual_length(top))
}

pub fn box_color_leaves_title_unstyled_test() {
  let out =
    box.render(
      spruce.with_color_level(tty.TrueColor),
      "hi",
      box.options(title: "T", color: style.Cyan),
    )

  expect.to_be_true(string.contains(out, " T \u{001b}"))
}

pub fn box_border_catalog_test() {
  let opts = box.default_options() |> box.border(box.Double)

  box.render(spruce.no_color(), "hi", opts)
  |> expect.to_equal("╔════╗\n║ hi ║\n╚════╝")
}

pub fn box_custom_border_test() {
  let chars =
    box.BorderChars(
      top_left: "+",
      top: "-",
      top_right: "+",
      right: "|",
      bottom_right: "+",
      bottom: "-",
      bottom_left: "+",
      left: "|",
    )

  let opts = box.default_options() |> box.border(box.Custom(chars))

  box.render(spruce.no_color(), "hi", opts)
  |> expect.to_equal("+----+\n| hi |\n+----+")
}

pub fn box_padding_adds_inner_rows_and_columns_test() {
  let opts =
    box.default_options() |> box.padding(top: 1, right: 2, bottom: 1, left: 2)

  box.render(spruce.no_color(), "hi", opts)
  |> expect.to_equal("╭──────╮\n│      │\n│  hi  │\n│      │\n╰──────╯")
}

pub fn box_margin_adds_outer_space_after_indent_test() {
  let opts =
    box.default_options() |> box.margin(top: 1, right: 2, bottom: 1, left: 2)

  box.render(spruce.no_color(), "hi", opts)
  |> expect.to_equal(
    "          \n  ╭────╮  \n  │ hi │  \n  ╰────╯  \n          ",
  )
}

pub fn box_width_wraps_content_to_stable_visual_width_test() {
  let opts = box.default_options() |> box.width(5)
  let lines =
    box.render(spruce.no_color(), "hello world", opts)
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
  let opts = box.default_options() |> box.border(box.Hidden)

  box.render(spruce.no_color(), "hi", opts)
  |> expect.to_equal(" hi ")
}

pub fn box_default_rendering_unchanged_after_per_side_options_test() {
  box.render(spruce.no_color(), "hi", box.default_options())
  |> expect.to_equal("╭────╮\n│ hi │\n╰────╯")
}

pub fn box_per_side_visibility_omits_hidden_columns_and_rows_test() {
  let opts =
    box.default_options()
    |> box.border_sides(top: True, right: False, bottom: True, left: True)

  box.render(spruce.no_color(), "hi", opts)
  |> expect.to_equal("╭────\n│ hi \n╰────")
}

pub fn box_per_side_visibility_omits_corner_without_adjoining_side_test() {
  let opts =
    box.default_options()
    |> box.border_sides(top: True, right: True, bottom: True, left: False)

  box.render(spruce.no_color(), "hi", opts)
  |> expect.to_equal("────╮\n hi │\n────╯")
}

pub fn box_per_side_visibility_all_hidden_matches_hidden_shape_test() {
  let opts =
    box.default_options()
    |> box.border_sides(top: False, right: False, bottom: False, left: False)

  box.render(spruce.no_color(), "hi", opts)
  |> expect.to_equal(" hi ")
}

pub fn box_per_side_border_colors_are_applied_test() {
  let sp = spruce.with_color_level(tty.TrueColor)
  let opts =
    box.default_options()
    |> box.border_colors(
      top: style.Red,
      right: style.Green,
      bottom: style.Blue,
      left: style.Yellow,
    )
  let out = box.render(sp, "hi", opts)

  expect.to_be_true(string.contains(out, "\u{001b}[31m"))
  expect.to_be_true(string.contains(out, "\u{001b}[32m"))
  expect.to_be_true(string.contains(out, "\u{001b}[34m"))
  expect.to_be_true(string.contains(out, "\u{001b}[33m"))
}
