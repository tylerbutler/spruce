import gleam/string
import spruce
import spruce/tree
import startest/expect
import tty

pub fn render_no_color_uses_ascii_fallback_test() {
  tree.root("app")
  |> tree.child(tree.root("src") |> tree.child(tree.root("main.gleam")))
  |> tree.child(tree.root("test"))
  |> tree.render(spruce.no_color(), _)
  |> expect.to_equal("app\n|- src\n|  `- main.gleam\n`- test")
}

pub fn render_color_uses_unicode_branches_test() {
  tree.root("app")
  |> tree.child(tree.root("src") |> tree.child(tree.root("main.gleam")))
  |> tree.child(tree.root("test"))
  |> tree.render(spruce.with_color_level(tty.TrueColor), _)
  |> expect.to_equal("app\n├─ src\n│  └─ main.gleam\n└─ test")
}

pub fn render_preserves_child_insertion_order_test() {
  tree.root("root")
  |> tree.child(tree.root("first"))
  |> tree.child(tree.root("second"))
  |> tree.child(tree.root("third"))
  |> tree.render(spruce.no_color(), _)
  |> expect.to_equal("root\n|- first\n|- second\n`- third")
}

pub fn render_multiline_labels_indent_subsequent_lines_test() {
  tree.root("root")
  |> tree.child(tree.root("line one\nline two"))
  |> tree.render(spruce.no_color(), _)
  |> expect.to_equal("root\n`- line one\n   line two")
}

pub fn render_multiline_non_last_label_keeps_unicode_guide_test() {
  tree.root("root")
  |> tree.child(tree.root("line one\nline two"))
  |> tree.child(tree.root("sibling"))
  |> tree.render(spruce.with_color_level(tty.TrueColor), _)
  |> expect.to_equal("root\n├─ line one\n│  line two\n└─ sibling")
}

pub fn render_multiline_non_last_label_keeps_ascii_guide_test() {
  tree.root("root")
  |> tree.child(tree.root("line one\nline two"))
  |> tree.child(tree.root("sibling"))
  |> tree.ascii()
  |> tree.render(spruce.with_color_level(tty.TrueColor), _)
  |> expect.to_equal("root\n|- line one\n|  line two\n`- sibling")
}

pub fn custom_enumerator_renders_current_branch_test() {
  tree.root("root")
  |> tree.child(tree.root("child"))
  |> tree.enumerator(fn(depth, last) {
    case last {
      True -> string.repeat(".", depth) <> "L "
      False -> string.repeat(".", depth) <> "M "
    }
  })
  |> tree.render(spruce.no_color(), _)
  |> expect.to_equal("root\n.L child")
}

pub fn custom_ansi_enumerator_uses_visual_width_for_continuation_test() {
  tree.root("root")
  |> tree.child(tree.root("line one\nline two"))
  |> tree.enumerator(fn(_depth, _last) { "\u{001b}[31m# \u{001b}[0m" })
  |> tree.render(spruce.no_color(), _)
  |> expect.to_equal("root\n\u{001b}[31m# \u{001b}[0mline one\n  line two")
}
