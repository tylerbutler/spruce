import gleam/int
import gleam/string
import spruce
import spruce/list as slist
import startest/expect
import tty

pub fn render_no_color_bullets_use_ascii_fallback_test() {
  slist.new()
  |> slist.item("first")
  |> slist.item("second")
  |> slist.render(spruce.no_color(), _)
  |> expect.to_equal("- first\n- second")
}

pub fn render_color_bullets_use_unicode_marker_test() {
  slist.new()
  |> slist.item("first")
  |> slist.item("second")
  |> slist.render(spruce.with_color_level(tty.TrueColor), _)
  |> expect.to_equal("• first\n• second")
}

pub fn render_ordered_list_numbers_top_level_items_test() {
  slist.new()
  |> slist.kind(slist.Ordered)
  |> slist.item("alpha")
  |> slist.item("beta")
  |> slist.render(spruce.no_color(), _)
  |> expect.to_equal("1. alpha\n2. beta")
}

pub fn render_nested_ordered_children_restart_at_one_test() {
  slist.new()
  |> slist.kind(slist.Ordered)
  |> slist.child("parent", ["child one", "child two"])
  |> slist.item("sibling")
  |> slist.render(spruce.no_color(), _)
  |> expect.to_equal("1. parent\n  1. child one\n  2. child two\n2. sibling")
}

pub fn render_preserves_item_insertion_order_test() {
  slist.new()
  |> slist.item("first")
  |> slist.item("second")
  |> slist.item("third")
  |> slist.render(spruce.no_color(), _)
  |> expect.to_equal("- first\n- second\n- third")
}

pub fn render_multiline_labels_indent_subsequent_lines_test() {
  slist.new()
  |> slist.child("line one\nline two", ["child line one\nchild line two"])
  |> slist.render(spruce.no_color(), _)
  |> expect.to_equal(
    "- line one\n  line two\n  - child line one\n    child line two",
  )
}

pub fn custom_enumerator_receives_one_based_index_and_depth_test() {
  slist.new()
  |> slist.item("first")
  |> slist.child("second", ["nested"])
  |> slist.enumerator(fn(index, depth) {
    string.repeat("#", depth) <> int.to_string(index) <> " "
  })
  |> slist.render(spruce.no_color(), _)
  |> expect.to_equal("#1 first\n#2 second\n  ##1 nested")
}

pub fn custom_ansi_enumerator_uses_visual_width_for_continuation_test() {
  slist.new()
  |> slist.item("line one\nline two")
  |> slist.enumerator(fn(_index, _depth) { "\u{001b}[31m# \u{001b}[0m" })
  |> slist.render(spruce.no_color(), _)
  |> expect.to_equal("\u{001b}[31m# \u{001b}[0mline one\n  line two")
}

pub fn render_nested_lists_arbitrary_depth_bullets_test() {
  let great = slist.new() |> slist.item("great")
  let grand = slist.new() |> slist.nested("grandchild", great)
  let children = slist.new() |> slist.nested("child", grand)

  slist.new()
  |> slist.nested("parent", children)
  |> slist.render(spruce.no_color(), _)
  |> expect.to_equal("- parent\n  - child\n    - grandchild\n      - great")
}

pub fn render_nested_lists_arbitrary_depth_ordered_test() {
  let grandchildren =
    slist.new()
    |> slist.item("grand one")
    |> slist.item("grand two")
  let children =
    slist.new()
    |> slist.nested("child one", grandchildren)
    |> slist.item("child two")

  slist.new()
  |> slist.kind(slist.Ordered)
  |> slist.nested("parent one", children)
  |> slist.item("parent two")
  |> slist.render(spruce.no_color(), _)
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
  slist.new()
  |> slist.kind(slist.Ordered)
  |> slist.child("parent", ["child one", "child two"])
  |> slist.item("sibling")
  |> slist.render(spruce.no_color(), _)
  |> expect.to_equal("1. parent\n  1. child one\n  2. child two\n2. sibling")
}
