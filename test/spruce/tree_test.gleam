import gleam/bool
import gleam/int
import gleeunit/should
import spruce
import spruce/tree

pub fn render_no_color_uses_unicode_branches_test() {
  tree.root("app")
  |> tree.child(
    child: tree.root("src") |> tree.child(child: tree.root("main.gleam")),
  )
  |> tree.child(child: tree.root("test"))
  |> tree.render(spruce.no_color(), _)
  |> should.equal("app\n├─ src\n│  └─ main.gleam\n└─ test")
}

pub fn render_color_uses_unicode_branches_test() {
  tree.root("app")
  |> tree.child(
    child: tree.root("src") |> tree.child(child: tree.root("main.gleam")),
  )
  |> tree.child(child: tree.root("test"))
  |> tree.render(spruce.with_color_level(spruce.TrueColor), _)
  |> should.equal("app\n├─ src\n│  └─ main.gleam\n└─ test")
}

pub fn render_preserves_child_insertion_order_test() {
  tree.root("root")
  |> tree.child(child: tree.root("first"))
  |> tree.child(child: tree.root("second"))
  |> tree.child(child: tree.root("third"))
  |> tree.render(spruce.no_color(), _)
  |> should.equal("root\n├─ first\n├─ second\n└─ third")
}

pub fn render_multiline_labels_indent_subsequent_lines_test() {
  tree.root("root")
  |> tree.child(child: tree.root("line one\nline two"))
  |> tree.render(spruce.no_color(), _)
  |> should.equal("root\n└─ line one\n   line two")
}

pub fn render_multiline_non_last_label_keeps_unicode_guide_test() {
  tree.root("root")
  |> tree.child(child: tree.root("line one\nline two"))
  |> tree.child(child: tree.root("sibling"))
  |> tree.render(spruce.with_color_level(spruce.TrueColor), _)
  |> should.equal("root\n├─ line one\n│  line two\n└─ sibling")
}

pub fn render_multiline_non_last_label_keeps_ascii_guide_test() {
  tree.root("root")
  |> tree.child(child: tree.root("line one\nline two"))
  |> tree.child(child: tree.root("sibling"))
  |> tree.ascii()
  |> tree.render(spruce.with_color_level(spruce.TrueColor), _)
  |> should.equal("root\n|- line one\n|  line two\n`- sibling")
}

pub fn unicode_overrides_ascii_branches_test() {
  tree.root("root")
  |> tree.child(child: tree.root("child"))
  |> tree.ascii()
  |> tree.unicode()
  |> tree.render(spruce.no_color(), _)
  |> should.equal("root\n└─ child")
}

pub fn custom_branches_preserve_ancestor_guides_test() {
  tree.root("root")
  |> tree.child(
    child: tree.root("first")
    |> tree.child(child: tree.root("nested")),
  )
  |> tree.child(child: tree.root("last"))
  |> tree.branches(tree.BranchChars(
    branch_mid: "+- ",
    branch_last: "\\- ",
    pipe: ":  ",
    blank: "   ",
  ))
  |> tree.render(spruce.no_color(), _)
  |> should.equal("root\n+- first\n:  \\- nested\n\\- last")
}

pub fn render_with_receives_layout_information_test() {
  tree.root("root")
  |> tree.child(child: tree.root("first"))
  |> tree.child(child: tree.root("last"))
  |> tree.render_with(spruce.no_color(), _, fn(label, width, depth, last) {
    int.to_string(width)
    <> ":"
    <> int.to_string(depth)
    <> ":"
    <> bool.to_string(last)
    <> " "
    <> label
  })
  |> should.equal("0:0:True root\n├─ 3:1:False first\n└─ 3:1:True last")
}

pub fn render_table_aligns_tree_labels_and_columns_test() {
  tree.root("PACKAGE")
  |> tree.columns(["VERSION", "LICENCE"])
  |> tree.child(
    child: tree.root("gleam_stdlib")
    |> tree.columns(["1.0.0", "Apache-2.0"])
    |> tree.child(
      child: tree.root("gleam_otp")
      |> tree.columns(["0.10.0", "Apache-2.0"]),
    ),
  )
  |> tree.child(child: tree.root("glint") |> tree.columns(["1.3.0", "MIT"]))
  |> tree.render_table(spruce.no_color(), _)
  |> should.equal(
    "PACKAGE          VERSION  LICENCE\n"
    <> "├─ gleam_stdlib  1.0.0    Apache-2.0\n"
    <> "│  └─ gleam_otp  0.10.0   Apache-2.0\n"
    <> "└─ glint         1.3.0    MIT",
  )
}

pub fn render_default_uses_context_ascii_mode_test() {
  tree.root("app")
  |> tree.child(child: tree.root("src"))
  |> tree.child(child: tree.root("test"))
  |> tree.render(spruce.no_color() |> spruce.with_symbol_mode(spruce.Ascii), _)
  |> should.equal("app\n|- src\n`- test")
}

pub fn render_unicode_override_ignores_ascii_context_test() {
  tree.root("app")
  |> tree.child(child: tree.root("src"))
  |> tree.unicode()
  |> tree.render(spruce.no_color() |> spruce.with_symbol_mode(spruce.Ascii), _)
  |> should.equal("app\n└─ src")
}
