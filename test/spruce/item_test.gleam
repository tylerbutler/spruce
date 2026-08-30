import gleam/int
import gleam/string
import gleeunit/should
import spruce
import spruce/item

pub fn render_no_color_bullets_use_ascii_fallback_test() {
  item.new()
  |> item.item("first")
  |> item.item("second")
  |> item.render(spruce.no_color(), _)
  |> should.equal("- first\n- second")
}

pub fn render_color_bullets_use_unicode_marker_test() {
  item.new()
  |> item.item("first")
  |> item.item("second")
  |> item.render(spruce.with_color_level(spruce.TrueColor), _)
  |> should.equal("• first\n• second")
}

pub fn render_ordered_list_numbers_top_level_items_test() {
  item.new()
  |> item.kind(item.Ordered)
  |> item.item("alpha")
  |> item.item("beta")
  |> item.render(spruce.no_color(), _)
  |> should.equal("1. alpha\n2. beta")
}

pub fn render_nested_ordered_children_restart_at_one_test() {
  item.new()
  |> item.kind(item.Ordered)
  |> item.child("parent", ["child one", "child two"])
  |> item.item("sibling")
  |> item.render(spruce.no_color(), _)
  |> should.equal("1. parent\n  1. child one\n  2. child two\n2. sibling")
}

pub fn render_preserves_item_insertion_order_test() {
  item.new()
  |> item.item("first")
  |> item.item("second")
  |> item.item("third")
  |> item.render(spruce.no_color(), _)
  |> should.equal("- first\n- second\n- third")
}

pub fn render_multiline_labels_indent_subsequent_lines_test() {
  item.new()
  |> item.child("line one\nline two", ["child line one\nchild line two"])
  |> item.render(spruce.no_color(), _)
  |> should.equal(
    "- line one\n  line two\n  - child line one\n    child line two",
  )
}

pub fn custom_enumerator_receives_one_based_index_and_depth_test() {
  item.new()
  |> item.item("first")
  |> item.child("second", ["nested"])
  |> item.enumerator(fn(index, depth) {
    string.repeat("#", depth) <> int.to_string(index) <> " "
  })
  |> item.render(spruce.no_color(), _)
  |> should.equal("#1 first\n#2 second\n  ##1 nested")
}

pub fn custom_ansi_enumerator_uses_visual_width_for_continuation_test() {
  item.new()
  |> item.item("line one\nline two")
  |> item.enumerator(fn(_index, _depth) { "\u{001b}[31m# \u{001b}[0m" })
  |> item.render(spruce.no_color(), _)
  |> should.equal("\u{001b}[31m# \u{001b}[0mline one\n  line two")
}

pub fn render_nested_lists_arbitrary_depth_bullets_test() {
  let great = item.new() |> item.item("great")
  let grand = item.new() |> item.nested("grandchild", great)
  let children = item.new() |> item.nested("child", grand)

  item.new()
  |> item.nested("parent", children)
  |> item.render(spruce.no_color(), _)
  |> should.equal("- parent\n  - child\n    - grandchild\n      - great")
}

pub fn render_nested_lists_arbitrary_depth_ordered_test() {
  let grandchildren =
    item.new()
    |> item.item("grand one")
    |> item.item("grand two")
  let children =
    item.new()
    |> item.nested("child one", grandchildren)
    |> item.item("child two")

  item.new()
  |> item.kind(item.Ordered)
  |> item.nested("parent one", children)
  |> item.item("parent two")
  |> item.render(spruce.no_color(), _)
  |> should.equal(
    "1. parent one\n"
    <> "  1. child one\n"
    <> "    1. grand one\n"
    <> "    2. grand two\n"
    <> "  2. child two\n"
    <> "2. parent two",
  )
}

pub fn render_child_default_behavior_unchanged_test() {
  item.new()
  |> item.kind(item.Ordered)
  |> item.child("parent", ["child one", "child two"])
  |> item.item("sibling")
  |> item.render(spruce.no_color(), _)
  |> should.equal("1. parent\n  1. child one\n  2. child two\n2. sibling")
}
