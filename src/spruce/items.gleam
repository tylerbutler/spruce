//// Pure bullet and ordered list rendering.
////
//// An `Items` value is a list of labelled entries rendered with an explicit
//// `Spruce` context. Bullet lists use a Unicode bullet when color is supported
//// and a deterministic ASCII marker when it is not. Ordered lists count from
//// one at each nesting depth.
////
//// ```gleam
//// items.new()
//// |> items.kind(items.Ordered)
//// |> items.item("setup")
//// |> items.nested("build", items.new() |> items.item("erlang"))
//// |> items.render(sp, _)
//// ```

import gleam/bool
import gleam/int
import gleam/list
import gleam/string
import spruce.{type Spruce}
import spruce/align

type Enumerator {
  Auto
  Custom(fn(Int, Int) -> String)
}

type Entries {
  Empty
  Cons(Entry, Entries)
}

type Entry {
  Entry(label: String, children: Entries)
}

/// The marker style used by the default enumerator.
pub type Kind {
  Bullet
  Ordered
}

/// A list of labelled items.
pub opaque type Items {
  Items(entries: Entries, kind: Kind, enumerator: Enumerator)
}

/// Build an empty bullet list.
pub fn new() -> Items {
  Items(entries: Empty, kind: Bullet, enumerator: Auto)
}

/// Add a top-level item, preserving insertion order.
pub fn item(items: Items, label: String) -> Items {
  Items(
    ..items,
    entries: append_entry(items.entries, Entry(label: label, children: Empty)),
  )
}

/// Add a top-level item with one level of child labels.
pub fn child(items: Items, label: String, children: List(String)) -> Items {
  Items(
    ..items,
    entries: append_entry(
      items.entries,
      Entry(label: label, children: labels_to_entries(children)),
    ),
  )
}

/// Add a top-level item whose children come from another list.
///
/// The nested list's item tree is preserved, while the parent list's kind and
/// enumerator control rendering at every depth.
pub fn nested(items: Items, label: String, children: Items) -> Items {
  Items(
    ..items,
    entries: append_entry(
      items.entries,
      Entry(label: label, children: children.entries),
    ),
  )
}

/// Set the default marker style for the list.
pub fn kind(items: Items, kind: Kind) -> Items {
  Items(..items, kind: kind)
}

/// Set a custom enumerator.
///
/// The function receives the one-based item index within the current depth and
/// the one-based depth of the item being rendered. It should return the complete
/// marker to place before that item's first label line.
pub fn enumerator(items: Items, enumerate: fn(Int, Int) -> String) -> Items {
  Items(..items, enumerator: Custom(enumerate))
}

/// Render a list to a string.
pub fn render(sp: Spruce, items: Items) -> String {
  let base = spruce.indent_prefix(sp)

  render_entries(sp, items.entries, items.kind, items.enumerator, base, 1, 1)
  |> string.join("\n")
}

fn render_entries(
  sp: Spruce,
  entries: Entries,
  kind: Kind,
  enumerator: Enumerator,
  base: String,
  depth: Int,
  index: Int,
) -> List(String) {
  case entries {
    Empty -> []
    Cons(first, rest) ->
      render_entry(sp, first, kind, enumerator, base, depth, index)
      |> list.append(render_entries(
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

fn render_entry(
  sp: Spruce,
  entry: Entry,
  kind: Kind,
  enumerator: Enumerator,
  base: String,
  depth: Int,
  index: Int,
) -> List(String) {
  let prefix =
    base
    <> string.repeat("  ", depth - 1)
    <> marker(sp, kind, enumerator, index, depth)
  let follow = string.repeat(" ", align.visual_length(prefix))

  render_label(prefix, follow, entry.label)
  |> list.append(render_entries(
    sp,
    entry.children,
    kind,
    enumerator,
    base,
    depth + 1,
    1,
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

fn append_entry(entries: Entries, entry: Entry) -> Entries {
  case entries {
    Empty -> Cons(entry, Empty)
    Cons(first, rest) -> Cons(first, append_entry(rest, entry))
  }
}

fn labels_to_entries(labels: List(String)) -> Entries {
  case labels {
    [] -> Empty
    [first, ..rest] ->
      Cons(Entry(label: first, children: Empty), labels_to_entries(rest))
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
  use <- bool.guard(when: !spruce.supports_color(sp), return: "- ")
  "• "
}
