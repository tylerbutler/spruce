//// Pure nested tree rendering.
////
//// Trees are data structures rendered with an explicit `Spruce` context. The
//// default renderer uses Unicode branch glyphs when color is supported and a
//// deterministic ASCII fallback when it is not.

import gleam/list
import gleam/string
import spruce.{type Spruce}
import spruce/align

type Branches {
  Auto
  Ascii
  Custom(fn(Int, Bool) -> String)
}

/// A nested labelled tree.
pub opaque type Tree {
  Tree(label: String, children: List(Tree), branches: Branches)
}

/// Build a tree root with no children.
pub fn root(label: String) -> Tree {
  Tree(label: label, children: [], branches: Auto)
}

/// Add a child to `parent`, preserving insertion order.
pub fn child(parent: Tree, child: Tree) -> Tree {
  Tree(..parent, children: list.append(parent.children, [child]))
}

/// Force deterministic ASCII branch markers regardless of color support.
pub fn ascii(tree: Tree) -> Tree {
  Tree(..tree, branches: Ascii)
}

/// Set a custom branch enumerator for the rendered tree.
///
/// The function receives the one-based depth of the node being rendered and
/// whether it is the last child of its parent. It should return the complete
/// branch marker to place before that node's first label line.
pub fn enumerator(tree: Tree, branch: fn(Int, Bool) -> String) -> Tree {
  Tree(..tree, branches: Custom(branch))
}

/// Render a tree to a string.
pub fn render(sp: Spruce, tree: Tree) -> String {
  let base = string.repeat("  ", spruce.depth(sp))
  let lines =
    render_label(base, base, tree.label)
    |> list.append(render_children(
      sp,
      tree.children,
      tree.branches,
      1,
      [],
      base,
    ))

  string.join(lines, "\n")
}

fn render_children(
  sp: Spruce,
  children: List(Tree),
  branches: Branches,
  depth: Int,
  ancestors: List(Bool),
  base: String,
) -> List(String) {
  case children {
    [] -> []
    [last_child] ->
      render_node(sp, last_child, branches, depth, ancestors, base, True)
    [first, ..rest] ->
      render_node(sp, first, branches, depth, ancestors, base, False)
      |> list.append(render_children(sp, rest, branches, depth, ancestors, base))
  }
}

fn render_node(
  sp: Spruce,
  tree: Tree,
  branches: Branches,
  depth: Int,
  ancestors: List(Bool),
  base: String,
  last: Bool,
) -> List(String) {
  let ancestor = ancestor_prefix(sp, branches, ancestors, 1)
  let prefix = base <> ancestor <> branch_token(sp, branches, depth, last)
  let follow = base <> ancestor <> follow_token(sp, branches, depth, last)

  render_label(prefix, follow, tree.label)
  |> list.append(render_children(
    sp,
    tree.children,
    branches,
    depth + 1,
    list.append(ancestors, [last]),
    base,
  ))
}

fn render_label(prefix: String, follow: String, label: String) -> List(String) {
  case string.split(label, "\n") {
    [] -> [prefix]
    [first, ..rest] -> [
      prefix <> first,
      ..list.map(rest, fn(line) { follow <> line })
    ]
  }
}

fn ancestor_prefix(
  sp: Spruce,
  branches: Branches,
  ancestors: List(Bool),
  depth: Int,
) -> String {
  case ancestors {
    [] -> ""
    [last, ..rest] ->
      ancestor_token(sp, branches, depth, last)
      <> ancestor_prefix(sp, branches, rest, depth + 1)
  }
}

fn branch_token(
  sp: Spruce,
  branches: Branches,
  depth: Int,
  last: Bool,
) -> String {
  case branches {
    Auto ->
      case spruce.supports_color(sp) {
        True -> unicode_branch(last)
        False -> ascii_branch(last)
      }

    Ascii -> ascii_branch(last)
    Custom(branch) -> branch(depth, last)
  }
}

fn follow_token(
  sp: Spruce,
  branches: Branches,
  depth: Int,
  last: Bool,
) -> String {
  ancestor_token(sp, branches, depth, last)
}

fn ancestor_token(
  sp: Spruce,
  branches: Branches,
  depth: Int,
  last: Bool,
) -> String {
  case branches {
    Auto ->
      case spruce.supports_color(sp) {
        True -> unicode_ancestor(last)
        False -> ascii_ancestor(last)
      }

    Ascii -> ascii_ancestor(last)
    Custom(branch) -> spaces_like(branch(depth, last))
  }
}

fn unicode_branch(last: Bool) -> String {
  case last {
    True -> "└─ "
    False -> "├─ "
  }
}

fn ascii_branch(last: Bool) -> String {
  case last {
    True -> "`- "
    False -> "|- "
  }
}

fn unicode_ancestor(last: Bool) -> String {
  case last {
    True -> "   "
    False -> "│  "
  }
}

fn ascii_ancestor(last: Bool) -> String {
  case last {
    True -> "   "
    False -> "|  "
  }
}

fn spaces_like(text: String) -> String {
  string.repeat(" ", align.visual_length(text))
}
