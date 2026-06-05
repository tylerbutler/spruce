//// Pure bullet and ordered list rendering.
////
//// Lists are rendered with an explicit `Spruce` context. Bullet lists use a
//// Unicode bullet when color is supported and a deterministic ASCII marker when
//// it is not. Ordered lists count from one at each nesting depth.

import gleam/int
import gleam/list as gleam_list
import gleam/string
import spruce.{type Spruce}
import spruce/align

type Enumerator {
  Auto
  Custom(fn(Int, Int) -> String)
}

type Items {
  Empty
  Cons(Item, Items)
}

type Item {
  Item(label: String, children: Items)
}

/// The marker style used by the default enumerator.
pub type Kind {
  Bullet
  Ordered
}

/// A list of labelled items.
pub opaque type List {
  List(items: Items, kind: Kind, enumerator: Enumerator)
}

/// Build an empty bullet list.
pub fn new() -> List {
  List(items: Empty, kind: Bullet, enumerator: Auto)
}

/// Add a top-level item, preserving insertion order.
pub fn item(list_: List, label: String) -> List {
  List(
    ..list_,
    items: append_item(list_.items, Item(label: label, children: Empty)),
  )
}

/// Add a top-level item with one level of child labels.
pub fn child(list_: List, label: String, children) -> List {
  List(
    ..list_,
    items: append_item(
      list_.items,
      Item(label: label, children: labels_to_items(children)),
    ),
  )
}

/// Add a top-level item whose children come from another list.
///
/// The nested list's item tree is preserved, while the parent list's kind and
/// enumerator control rendering at every depth.
pub fn nested(list_: List, label: String, children: List) -> List {
  List(
    ..list_,
    items: append_item(
      list_.items,
      Item(label: label, children: children.items),
    ),
  )
}

/// Set the default marker style for the list.
pub fn kind(list_: List, kind_: Kind) -> List {
  List(..list_, kind: kind_)
}

/// Set a custom enumerator.
///
/// The function receives the one-based item index within the current depth and
/// the one-based depth of the item being rendered. It should return the complete
/// marker to place before that item's first label line.
pub fn enumerator(list_: List, enumerate: fn(Int, Int) -> String) -> List {
  List(..list_, enumerator: Custom(enumerate))
}

/// Render a list to a string.
pub fn render(sp: Spruce, list_: List) -> String {
  let base = string.repeat("  ", spruce.depth(sp))

  render_items(sp, list_.items, list_.kind, list_.enumerator, base, 1, 1)
  |> string.join("\n")
}

fn render_items(
  sp: Spruce,
  items: Items,
  kind: Kind,
  enumerator: Enumerator,
  base: String,
  depth: Int,
  index: Int,
) {
  case items {
    Empty -> []
    Cons(first, rest) ->
      render_item(sp, first, kind, enumerator, base, depth, index)
      |> gleam_list.append(render_items(
        sp,
        rest,
        kind,
        enumerator,
        base,
        depth,
        index + 1,
      ))
  }
}

fn render_item(
  sp: Spruce,
  item: Item,
  kind: Kind,
  enumerator: Enumerator,
  base: String,
  depth: Int,
  index: Int,
) {
  let prefix =
    base
    <> string.repeat("  ", depth - 1)
    <> marker(sp, kind, enumerator, index, depth)
  let follow = string.repeat(" ", align.visual_length(prefix))

  render_label(prefix, follow, item.label)
  |> gleam_list.append(render_items(
    sp,
    item.children,
    kind,
    enumerator,
    base,
    depth + 1,
    1,
  ))
}

fn render_label(prefix: String, follow: String, label: String) {
  case string.split(label, "\n") {
    [] -> [prefix]
    [first, ..rest] -> [
      prefix <> first,
      ..gleam_list.map(rest, fn(line) { follow <> line })
    ]
  }
}

fn append_item(items: Items, item: Item) -> Items {
  case items {
    Empty -> Cons(item, Empty)
    Cons(first, rest) -> Cons(first, append_item(rest, item))
  }
}

fn labels_to_items(labels) -> Items {
  case labels {
    [] -> Empty
    [first, ..rest] ->
      Cons(Item(label: first, children: Empty), labels_to_items(rest))
  }
}

fn marker(
  sp: Spruce,
  kind: Kind,
  enumerator: Enumerator,
  index: Int,
  depth: Int,
) -> String {
  case enumerator {
    Custom(enumerate) -> enumerate(index, depth)
    Auto ->
      case kind {
        Bullet -> bullet_marker(sp)
        Ordered -> int.to_string(index) <> ". "
      }
  }
}

fn bullet_marker(sp: Spruce) -> String {
  case spruce.supports_color(sp) {
    True -> "• "
    False -> "- "
  }
}
