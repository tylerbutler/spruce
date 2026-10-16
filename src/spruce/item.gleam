//// Pure bullet and ordered list rendering.
////
//// An `Items` value is a list of labelled entries rendered with an explicit
//// `Spruce` context. Bullet lists use a Unicode bullet (`•`) when the context
//// symbol mode is `Unicode` and a plain ASCII marker (`-`) when it is `Ascii`.
//// Ordered lists count from one at each nesting depth.
////
//// ```gleam
//// item.new()
//// |> item.kind(item.Ordered)
//// |> item.item("setup")
//// |> item.nested("build", item.new() |> item.item("erlang"))
//// |> item.render(context, _)
//// ```

import gleam/int
import gleam/list
import gleam/string
import spruce.{type Spruce}
import spruce/align

type Enumerator {
  Auto
  Custom(fn(Int, Int) -> String)
}

type Entry {
  Entry(label: String, children: List(Entry))
}

/// The marker style used by the default enumerator.
pub type Kind {
  Bullet
  Ordered
}

/// A list of labelled items.
pub opaque type Items {
  Items(entries: List(Entry), kind: Kind, enumerator: Enumerator)
}

/// Build an empty bullet list.
pub fn new() -> Items {
  Items(entries: [], kind: Bullet, enumerator: Auto)
}

/// Add a top-level item, preserving insertion order.
pub fn item(items: Items, label: String) -> Items {
  Items(..items, entries: [Entry(label: label, children: []), ..items.entries])
}

/// Add a top-level item with one level of child labels.
pub fn child(items: Items, label: String, children: List(String)) -> Items {
  Items(..items, entries: [
    Entry(label: label, children: labels_to_entries(children)),
    ..items.entries
  ])
}

/// Add a top-level item whose children come from another list.
///
/// The nested list's item tree is preserved, while the parent list's kind and
/// enumerator control rendering at every depth.
pub fn nested(items: Items, label: String, children: Items) -> Items {
  Items(..items, entries: [
    Entry(label: label, children: children.entries),
    ..items.entries
  ])
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
pub fn render(context: Spruce, items: Items) -> String {
  let base = spruce.indent_prefix(context)

  render_entries(context, items.entries, items.kind, items.enumerator, base, 1)
  |> string.join("\n")
}

fn render_entries(
  context: Spruce,
  entries: List(Entry),
  kind: Kind,
  enumerator: Enumerator,
  base: String,
  depth: Int,
) -> List(String) {
  render_ordered_entries(
    context,
    list.reverse(entries),
    kind,
    enumerator,
    base,
    depth,
    1,
  )
}

fn render_ordered_entries(
  context: Spruce,
  entries: List(Entry),
  kind: Kind,
  enumerator: Enumerator,
  base: String,
  depth: Int,
  index: Int,
) -> List(String) {
  case entries {
    [] -> []
    [first, ..rest] ->
      render_entry(context, first, kind, enumerator, base, depth, index)
      |> list.append(render_ordered_entries(
        context,
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
  context: Spruce,
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
    <> marker(context, kind, enumerator, index, depth)
  let follow = string.repeat(" ", align.visual_length(prefix))

  render_label(prefix, follow, entry.label)
  |> list.append(render_entries(
    context,
    entry.children,
    kind,
    enumerator,
    base,
    depth + 1,
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

fn labels_to_entries(labels: List(String)) -> List(Entry) {
  list.fold(labels, [], fn(entries, label) {
    [Entry(label: label, children: []), ..entries]
  })
}

fn marker(
  context: Spruce,
  kind: Kind,
  enumerator: Enumerator,
  index: Int,
  depth: Int,
) -> String {
  case enumerator {
    Custom(enumerate) -> enumerate(index, depth)
    Auto ->
      case kind {
        Bullet -> bullet_marker(context)
        Ordered -> int.to_string(index) <> ". "
      }
  }
}

fn bullet_marker(context: Spruce) -> String {
  case spruce.symbol_mode(context) {
    spruce.Ascii -> "- "
    spruce.Unicode -> "• "
  }
}
