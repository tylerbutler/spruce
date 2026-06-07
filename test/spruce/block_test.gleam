import gleam/string
import spruce
import spruce/block
import spruce/box
import spruce/layout
import spruce/style
import startest/expect
import tty

pub fn block_no_color_plain_output_test() {
  block.render(spruce.no_color(), "hi", block.new())
  |> expect.to_equal("hi")
}

pub fn block_padding_adds_inner_space_test() {
  let options = block.new() |> block.padding(1, 2, 1, 2)

  block.render(spruce.no_color(), "hi", options)
  |> expect.to_equal("      \n  hi  \n      ")
}

pub fn block_width_wraps_content_test() {
  let options = block.new() |> block.width(5)

  block.render(spruce.no_color(), "hello world", options)
  |> expect.to_equal("hello\nworld")
}

pub fn block_alignment_places_content_within_width_and_height_test() {
  let options =
    block.new()
    |> block.width(6)
    |> block.height(3)
    |> block.align(layout.Center, layout.Center)

  block.render(spruce.no_color(), "hi", options)
  |> expect.to_equal("      \n  hi  \n      ")
}

pub fn block_border_on_and_off_test() {
  let bordered = block.new() |> block.border(box.Rounded)

  block.render(spruce.no_color(), "hi", block.new())
  |> expect.to_equal("hi")
  block.render(spruce.no_color(), "hi", bordered)
  |> expect.to_equal("╭──╮\n│hi│\n╰──╯")
}

pub fn block_per_side_border_behavior_test() {
  let options =
    block.new()
    |> block.border(box.Rounded)
    |> block.border_sides(True, False, True, True)

  block.render(spruce.no_color(), "hi", options)
  |> expect.to_equal("╭──\n│hi\n╰──")
}

pub fn block_hidden_top_omits_top_row_and_corners_test() {
  let options =
    block.new()
    |> block.border(box.Rounded)
    |> block.border_sides(False, True, True, False)

  block.render(spruce.no_color(), "hi", options)
  |> expect.to_equal("hi│\n──╯")
}

pub fn block_content_style_is_color_gated_test() {
  let options =
    block.new() |> block.foreground(style.Red) |> block.background(style.Blue)

  block.render(spruce.no_color(), "hi", options)
  |> expect.to_equal("hi")

  block.render(spruce.with_color_level(tty.TrueColor), "hi", options)
  |> string.contains("\u{001b}")
  |> expect.to_be_true
}

pub fn block_background_fills_padding_ring_test() {
  let options =
    block.new() |> block.background(style.Blue) |> block.padding(1, 1, 1, 1)

  block.render(spruce.with_color_level(tty.TrueColor), "hi", options)
  |> expect.to_equal(
    "\u{001b}[44m    \u{001b}[49m\n\u{001b}[44m hi \u{001b}[49m\n\u{001b}[44m    \u{001b}[49m",
  )
}

pub fn block_per_side_border_colors_are_applied_test() {
  let sp = spruce.with_color_level(tty.TrueColor)
  let options =
    block.new()
    |> block.border(box.Rounded)
    |> block.border_colors(style.Red, style.Green, style.Blue, style.Yellow)
  let out = block.render(sp, "hi", options)

  expect.to_be_true(string.contains(out, "\u{001b}[31m"))
  expect.to_be_true(string.contains(out, "\u{001b}[32m"))
  expect.to_be_true(string.contains(out, "\u{001b}[34m"))
  expect.to_be_true(string.contains(out, "\u{001b}[33m"))
}

pub fn block_margin_adds_outer_space_after_indent_test() {
  let options = block.new() |> block.margin(1, 2, 1, 2)

  block.render(spruce.no_color(), "hi", options)
  |> expect.to_equal("      \n  hi  \n      ")
}
