import gleam/int
import gleam/string
import spruce
import spruce/items
import startest/expect

pub fn render_no_color_bullets_use_ascii_fallback_test() {
  items.new()
  |> items.item("first")
  |> items.item("second")
  |> items.render(spruce.no_color(), _)
  |> expect.to_equal("- first\n- second")
}

pub fn render_color_bullets_use_unicode_marker_test() {
  items.new()
  |> items.item("first")
  |> items.item("second")
  |> items.render(spruce.with_color_level(spruce.TrueColor), _)
  |> expect.to_equal("• first\n• second")
}

pub fn render_ordered_list_numbers_top_level_items_test() {
  items.new()
  |> items.kind(items.Ordered)
  |> items.item("alpha")
  |> items.item("beta")
  |> items.render(spruce.no_color(), _)
  |> expect.to_equal("1. alpha\n2. beta")
}

pub fn render_nested_ordered_children_restart_at_one_test() {
  items.new()
  |> items.kind(items.Ordered)
  |> items.child("parent", ["child one", "child two"])
  |> items.item("sibling")
  |> items.render(spruce.no_color(), _)
  |> expect.to_equal("1. parent\n  1. child one\n  2. child two\n2. sibling")
}

pub fn render_preserves_item_insertion_order_test() {
  items.new()
  |> items.item("first")
  |> items.item("second")
  |> items.item("third")
  |> items.render(spruce.no_color(), _)
  |> expect.to_equal("- first\n- second\n- third")
}

pub fn render_multiline_labels_indent_subsequent_lines_test() {
  items.new()
  |> items.child("line one\nline two", ["child line one\nchild line two"])
  |> items.render(spruce.no_color(), _)
  |> expect.to_equal(
    "- line one\n  line two\n  - child line one\n    child line two",
  )
}

pub fn custom_enumerator_receives_one_based_index_and_depth_test() {
  items.new()
  |> items.item("first")
  |> items.child("second", ["nested"])
  |> items.enumerator(fn(index, depth) {
    string.repeat("#", depth) <> int.to_string(index) <> " "
  })
  |> items.render(spruce.no_color(), _)
  |> expect.to_equal("#1 first\n#2 second\n  ##1 nested")
}

pub fn custom_ansi_enumerator_uses_visual_width_for_continuation_test() {
  items.new()
  |> items.item("line one\nline two")
  |> items.enumerator(fn(_index, _depth) { "\u{001b}[31m# \u{001b}[0m" })
  |> items.render(spruce.no_color(), _)
  |> expect.to_equal("\u{001b}[31m# \u{001b}[0mline one\n  line two")
}

pub fn render_nested_lists_arbitrary_depth_bullets_test() {
  let great = items.new() |> items.item("great")
  let grand = items.new() |> items.nested("grandchild", great)
  let children = items.new() |> items.nested("child", grand)

  items.new()
  |> items.nested("parent", children)
  |> items.render(spruce.no_color(), _)
  |> expect.to_equal("- parent\n  - child\n    - grandchild\n      - great")
}

pub fn render_nested_lists_arbitrary_depth_ordered_test() {
  let grandchildren =
    items.new()
    |> items.item("grand one")
    |> items.item("grand two")
  let children =
    items.new()
    |> items.nested("child one", grandchildren)
    |> items.item("child two")

  items.new()
  |> items.kind(items.Ordered)
  |> items.nested("parent one", children)
  |> items.item("parent two")
  |> items.render(spruce.no_color(), _)
  |> expect.to_equal(
    "1. parent one\n"
    <> "  1. child one\n"
    <> "    1. grand one\n"
    <> "    2. grand two\n"
    <> "  2. child two\n"
    <> "2. parent two",
  )
}

pub fn render_child_default_behavior_unchanged_test() {
  items.new()
  |> items.kind(items.Ordered)
  |> items.child("parent", ["child one", "child two"])
  |> items.item("sibling")
  |> items.render(spruce.no_color(), _)
  |> expect.to_equal("1. parent\n  1. child one\n  2. child two\n2. sibling")
}
