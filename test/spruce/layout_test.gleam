import gleam/list
import gleam/string
import spruce
import spruce/internal/layout as internal_layout
import spruce/layout
import startest/expect

pub fn indent_prefix_depth_zero_test() {
  internal_layout.indent_prefix(spruce.no_color())
  |> expect.to_equal("")
}

pub fn indent_prefix_depth_two_test() {
  spruce.no_color()
  |> spruce.indented
  |> spruce.indented
  |> internal_layout.indent_prefix
  |> expect.to_equal("    ")
}

pub fn join_vertical_start_pads_each_line_to_widest_block_test() {
  layout.join_vertical(layout.Start, ["a\nbb", "ccc"])
  |> expect.to_equal("a  \nbb \nccc")
}

pub fn join_vertical_center_uses_visual_width_test() {
  let red = "\u{001b}[31mR\u{001b}[0m"

  layout.join_vertical(layout.Center, [red, "abc"])
  |> expect.to_equal(" " <> red <> " \nabc")
}

pub fn join_horizontal_start_pads_lines_to_each_block_width_test() {
  layout.join_horizontal(layout.Start, ["a\nbbb", "x\ny"])
  |> expect.to_equal("a  x\nbbby")
}

pub fn join_horizontal_end_places_shorter_blocks_at_bottom_test() {
  layout.join_horizontal(layout.End, ["a\nb", "XX"])
  |> expect.to_equal("a  \nbXX")
}

pub fn join_horizontal_center_places_shorter_blocks_in_middle_test() {
  layout.join_horizontal(layout.Center, ["1\n2\n3", "XX"])
  |> expect.to_equal("1  \n2XX\n3  ")
}

pub fn place_centers_content_horizontally_and_places_at_bottom_test() {
  layout.place(
    width: 5,
    height: 3,
    horizontal: layout.Center,
    vertical: layout.End,
    content: "ab\ncde",
  )
  |> expect.to_equal("     \n ab  \n cde ")
}

pub fn place_preserves_content_larger_than_region_test() {
  layout.place(
    width: 2,
    height: 1,
    horizontal: layout.End,
    vertical: layout.End,
    content: "abcd\nef",
  )
  |> expect.to_equal("abcd\n  ef")
}

pub fn layout_handles_large_flattened_and_repeated_lines_test() {
  let count = 20_000
  let blocks = list.repeat("x", times: count)

  layout.join_vertical(layout.Start, blocks)
  |> string.split("\n")
  |> list.length
  |> expect.to_equal(count)

  let tall_block =
    list.repeat("y", times: count)
    |> string.join("\n")

  layout.join_horizontal(layout.End, ["x", tall_block])
  |> string.split("\n")
  |> list.length
  |> expect.to_equal(count)
}
