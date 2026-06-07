//// ANSI-aware layout helpers for composing multiline text blocks.

import gleam/int
import gleam/list
import gleam/string
import spruce/align

/// A position used for horizontal or vertical alignment.
pub type Pos {
  Start
  Center
  End
}

type Block {
  Block(width: Int, height: Int, lines: List(String))
}

/// Stack blocks vertically, padding every line to the widest visual width.
pub fn join_vertical(pos: Pos, blocks: List(String)) -> String {
  let lines = flatten_lines(blocks)
  let width = max_visual_width(lines)

  lines
  |> list.map(fn(line) { pad(line, width, pos) })
  |> string.join("\n")
}

/// Join blocks horizontally, aligning shorter blocks within the tallest block.
pub fn join_horizontal(pos: Pos, blocks: List(String)) -> String {
  case blocks {
    [] -> ""
    _ -> {
      let block_infos = list.map(blocks, block_info)
      let target_height = max_block_height(block_infos)

      block_infos
      |> list.map(fn(block) { normalize_block(block, target_height, pos) })
      |> join_normalized_blocks([])
    }
  }
}

/// Place content in a region, preserving content larger than the requested size.
pub fn place(
  width width: Int,
  height height: Int,
  horizontal h: Pos,
  vertical v: Pos,
  content content: String,
) -> String {
  let #(content_width, content_height) = align.size(content)
  let region_width = int.max(width, content_width)
  let region_height = int.max(height, content_height)
  let lines =
    content
    |> string.split("\n")
    |> list.map(fn(line) { pad(line, region_width, h) })

  position_lines(lines, content_height, region_width, region_height, v)
  |> string.join("\n")
}

fn block_info(block: String) -> Block {
  let #(width, _) = align.size(block)
  let height = align.height(block)
  Block(width: width, height: height, lines: string.split(block, "\n"))
}

fn normalize_block(block: Block, target_height: Int, pos: Pos) -> List(String) {
  let padded_lines =
    list.map(block.lines, fn(line) { pad(line, block.width, Start) })

  position_lines(padded_lines, block.height, block.width, target_height, pos)
}

fn position_lines(
  lines: List(String),
  content_height: Int,
  width: Int,
  target_height: Int,
  pos: Pos,
) -> List(String) {
  let extra = target_height - content_height

  case extra <= 0 {
    True -> lines
    False -> {
      let #(before, after) = padding_counts(extra, pos)
      let blank = string.repeat(" ", width)

      repeat_line(blank, before)
      |> list.append(lines)
      |> list.append(repeat_line(blank, after))
    }
  }
}

fn padding_counts(extra: Int, pos: Pos) -> #(Int, Int) {
  case pos {
    Start -> #(0, extra)
    Center -> {
      let before = extra / 2
      #(before, extra - before)
    }
    End -> #(extra, 0)
  }
}

fn pad(text: String, width: Int, pos: Pos) -> String {
  case pos {
    Start -> align.pad_right(text, width)
    Center -> align.pad_center(text, width)
    End -> align.pad_left(text, width)
  }
}

fn flatten_lines(blocks: List(String)) -> List(String) {
  flatten_lines_loop(blocks, [])
  |> list.reverse
}

fn flatten_lines_loop(blocks: List(String), acc: List(String)) -> List(String) {
  case blocks {
    [] -> acc
    [block, ..rest] ->
      flatten_lines_loop(rest, prepend_reversed(string.split(block, "\n"), acc))
  }
}

fn prepend_reversed(lines: List(String), acc: List(String)) -> List(String) {
  case lines {
    [] -> acc
    [line, ..rest] -> prepend_reversed(rest, [line, ..acc])
  }
}

fn max_visual_width(lines: List(String)) -> Int {
  lines
  |> list.map(align.visual_length)
  |> list.fold(0, int.max)
}

fn max_block_height(blocks: List(Block)) -> Int {
  max_block_height_loop(blocks, 0)
}

fn max_block_height_loop(blocks: List(Block), acc: Int) -> Int {
  case blocks {
    [] -> acc
    [Block(height: height, ..), ..rest] ->
      max_block_height_loop(rest, int.max(acc, height))
  }
}

fn repeat_line(line: String, times: Int) -> List(String) {
  repeat_line_loop(line, times, [])
  |> list.reverse
}

// nolint: prefer_guard_clause -- a guard closure breaks tail-call optimization here, overflowing the JS stack on large inputs
fn repeat_line_loop(
  line: String,
  times: Int,
  acc: List(String),
) -> List(String) {
  case times <= 0 {
    True -> acc
    False -> repeat_line_loop(line, times - 1, [line, ..acc])
  }
}

fn join_normalized_blocks(
  blocks: List(List(String)),
  rows: List(String),
) -> String {
  case collect_row(blocks, "", []) {
    Error(Nil) -> rows |> list.reverse |> string.join("\n")
    Ok(#(row, tails)) -> join_normalized_blocks(tails, [row, ..rows])
  }
}

fn collect_row(
  blocks: List(List(String)),
  row: String,
  tails: List(List(String)),
) -> Result(#(String, List(List(String))), Nil) {
  case blocks {
    [] -> Ok(#(row, list.reverse(tails)))
    [[], ..] -> Error(Nil)
    [[line, ..rest], ..remaining] ->
      collect_row(remaining, row <> line, [rest, ..tails])
  }
}
