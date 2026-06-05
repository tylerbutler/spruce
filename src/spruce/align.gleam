//// ANSI-aware text alignment helpers.

import gleam/int
import gleam/list
import gleam/string

type Piece {
  Word(String)
  Spaces(String)
}

type PieceKind {
  NoPiece
  WordPiece
  SpacePiece
}

/// The visual length of a string, excluding ANSI escape codes.
pub fn visual_length(text: String) -> Int {
  case string.contains(text, "\u{001b}") {
    True -> count_visible(string.to_graphemes(text), False, 0)
    False -> string.length(text)
  }
}

fn count_visible(chars: List(String), in_escape: Bool, count: Int) -> Int {
  case chars {
    [] -> count
    ["\u{001b}", ..rest] -> count_visible(rest, True, count)
    ["m", ..rest] if in_escape -> count_visible(rest, False, count)
    [_, ..rest] if in_escape -> count_visible(rest, True, count)
    [_, ..rest] -> count_visible(rest, False, count + 1)
  }
}

/// Pad `text` on the right with spaces until it reaches `width` visual columns.
/// Text already at or beyond `width` is returned unchanged.
pub fn pad_right(text: String, width: Int) -> String {
  let padding = width - visual_length(text)
  case padding > 0 {
    True -> text <> string.repeat(" ", padding)
    False -> text
  }
}

/// Pad `text` on the left with spaces until it reaches `width` visual columns.
/// Text already at or beyond `width` is returned unchanged.
pub fn pad_left(text: String, width: Int) -> String {
  let padding = width - visual_length(text)
  case padding > 0 {
    True -> string.repeat(" ", padding) <> text
    False -> text
  }
}

/// Pad `text` on both sides with spaces until it reaches `width` visual columns.
/// When an odd number of spaces is needed, the extra space is placed on the
/// right. Text already at or beyond `width` is returned unchanged.
pub fn pad_center(text: String, width: Int) -> String {
  let padding = width - visual_length(text)
  case padding > 0 {
    True -> {
      let left = padding / 2
      let right = padding - left
      string.repeat(" ", left) <> text <> string.repeat(" ", right)
    }
    False -> text
  }
}

/// Count the number of lines in `text`.
pub fn height(text: String) -> Int {
  text
  |> string.split("\n")
  |> list.length
}

/// Return the widest visual line and the number of lines in `text`.
pub fn size(text: String) -> #(Int, Int) {
  let lines = string.split(text, "\n")
  let width =
    lines
    |> list.map(visual_length)
    |> list.fold(0, int.max)

  #(width, list.length(lines))
}

/// Truncate `text` to at most `width` visual columns, appending `ellipsis` when
/// truncation is needed.
///
/// ANSI escape sequences do not count toward the width and are never split.
/// If `ellipsis` is wider than `width`, the ellipsis itself is visibly
/// truncated to fit. Widths less than or equal to zero return an empty string.
pub fn truncate(text: String, width: Int, ellipsis: String) -> String {
  case width <= 0 {
    True -> ""
    False ->
      case visual_length(text) <= width {
        True -> text
        False -> {
          let ellipsis_width = visual_length(ellipsis)

          case ellipsis_width >= width {
            True -> take_visible(ellipsis, width)
            False -> take_visible(text, width - ellipsis_width) <> ellipsis
          }
        }
      }
  }
}

/// Wrap `text` to `width` visual columns.
///
/// ANSI escape sequences do not count toward the width and are never split.
/// Words longer than `width` are hard-wrapped at visible column boundaries.
/// Widths less than or equal to zero return the input unchanged.
pub fn wrap(text: String, width: Int) -> String {
  case width <= 0 {
    True -> text
    False ->
      text
      |> string.split("\n")
      |> list.map(wrap_line(_, width))
      |> string.join("\n")
  }
}

fn wrap_line(line: String, width: Int) -> String {
  line
  |> split_pieces
  |> wrap_pieces(width, "", 0, [])
  |> string.join("\n")
}

fn wrap_pieces(
  pieces: List(Piece),
  width: Int,
  current: String,
  current_width: Int,
  lines: List(String),
) -> List(String) {
  case pieces {
    [] ->
      case current {
        "" -> list.reverse(lines)
        _ -> list.reverse([current, ..lines])
      }

    [Spaces(spaces), ..rest] -> {
      let spaces_width = visual_length(spaces)

      case current_width + spaces_width <= width {
        True ->
          wrap_pieces(
            rest,
            width,
            current <> spaces,
            current_width + spaces_width,
            lines,
          )

        False ->
          case current_width {
            0 -> {
              let #(next_current, next_width, next_lines) =
                add_wrapped_chunks(wrap_long_word(spaces, width), lines)

              wrap_pieces(rest, width, next_current, next_width, next_lines)
            }

            _ ->
              wrap_pieces(rest, width, "", 0, push_wrapped_line(current, lines))
          }
      }
    }

    [Word(word), ..rest] -> {
      let word_width = visual_length(word)

      case word_width > width {
        True ->
          case current_width {
            0 -> {
              let #(next_current, next_width, next_lines) =
                add_wrapped_chunks(wrap_long_word(word, width), lines)

              wrap_pieces(rest, width, next_current, next_width, next_lines)
            }

            _ ->
              wrap_pieces(
                pieces,
                width,
                "",
                0,
                push_wrapped_line(current, lines),
              )
          }

        False ->
          case current_width + word_width <= width {
            True ->
              wrap_pieces(
                rest,
                width,
                current <> word,
                current_width + word_width,
                lines,
              )

            False ->
              wrap_pieces(
                pieces,
                width,
                "",
                0,
                push_wrapped_line(current, lines),
              )
          }
      }
    }
  }
}

fn push_wrapped_line(line: String, lines: List(String)) -> List(String) {
  case trim_trailing_spaces(line) {
    "" -> lines
    trimmed -> [trimmed, ..lines]
  }
}

fn trim_trailing_spaces(text: String) -> String {
  text
  |> string.to_graphemes
  |> list.reverse
  |> drop_spaces
  |> list.reverse
  |> chars_to_string
}

fn drop_spaces(chars: List(String)) -> List(String) {
  case chars {
    [" ", ..rest] -> drop_spaces(rest)
    _ -> chars
  }
}

fn split_pieces(text: String) -> List(Piece) {
  split_pieces_loop(string.to_graphemes(text), False, "", NoPiece, [])
}

fn split_pieces_loop(
  chars: List(String),
  in_escape: Bool,
  current: String,
  kind: PieceKind,
  pieces: List(Piece),
) -> List(Piece) {
  case chars {
    [] -> list.reverse(push_piece(kind, current, pieces))

    ["\u{001b}", ..rest] -> {
      let kind = case kind {
        NoPiece -> WordPiece
        _ -> kind
      }
      split_pieces_loop(rest, True, current <> "\u{001b}", kind, pieces)
    }

    ["m", ..rest] if in_escape ->
      split_pieces_loop(rest, False, current <> "m", kind, pieces)

    [char, ..rest] if in_escape ->
      split_pieces_loop(rest, True, current <> char, kind, pieces)

    [" ", ..rest] -> {
      let #(current, kind, pieces) =
        add_piece_grapheme(" ", SpacePiece, current, kind, pieces)

      split_pieces_loop(rest, False, current, kind, pieces)
    }

    [char, ..rest] -> {
      let #(current, kind, pieces) =
        add_piece_grapheme(char, WordPiece, current, kind, pieces)

      split_pieces_loop(rest, False, current, kind, pieces)
    }
  }
}

fn add_piece_grapheme(
  char: String,
  char_kind: PieceKind,
  current: String,
  kind: PieceKind,
  pieces: List(Piece),
) -> #(String, PieceKind, List(Piece)) {
  case kind, char_kind {
    NoPiece, _ -> #(char, char_kind, pieces)
    SpacePiece, SpacePiece -> #(current <> char, kind, pieces)
    WordPiece, WordPiece -> #(current <> char, kind, pieces)
    _, _ -> #(char, char_kind, push_piece(kind, current, pieces))
  }
}

fn push_piece(
  kind: PieceKind,
  current: String,
  pieces: List(Piece),
) -> List(Piece) {
  case current {
    "" -> pieces
    _ ->
      case kind {
        SpacePiece -> [Spaces(current), ..pieces]
        _ -> [Word(current), ..pieces]
      }
  }
}

fn add_wrapped_chunks(
  chunks: List(String),
  lines: List(String),
) -> #(String, Int, List(String)) {
  case chunks {
    [] -> #("", 0, lines)
    [chunk] -> #(chunk, visual_length(chunk), lines)
    [chunk, ..rest] -> add_wrapped_chunks(rest, [chunk, ..lines])
  }
}

fn wrap_long_word(word: String, width: Int) -> List(String) {
  case visual_length(word) <= width {
    True -> [word]
    False -> [
      take_visible(word, width),
      ..wrap_long_word(drop_visible(word, width), width)
    ]
  }
}

fn take_visible(text: String, width: Int) -> String {
  case width <= 0 {
    True -> take_visible_loop(string.to_graphemes(text), 0, False, [])
    False -> take_visible_loop(string.to_graphemes(text), width, False, [])
  }
}

fn take_visible_loop(
  chars: List(String),
  remaining: Int,
  in_escape: Bool,
  acc: List(String),
) -> String {
  case chars {
    [] -> chars_to_string(list.reverse(acc))

    ["\u{001b}", ..rest] ->
      take_visible_loop(rest, remaining, True, ["\u{001b}", ..acc])

    ["m", ..rest] if in_escape ->
      take_visible_loop(rest, remaining, False, ["m", ..acc])

    [char, ..rest] if in_escape ->
      take_visible_loop(rest, remaining, True, [char, ..acc])

    [_, ..rest] if remaining <= 0 ->
      take_visible_loop(rest, remaining, False, acc)

    [char, ..rest] ->
      take_visible_loop(rest, remaining - 1, False, [char, ..acc])
  }
}

fn drop_visible(text: String, width: Int) -> String {
  drop_visible_loop(string.to_graphemes(text), width, False)
}

fn drop_visible_loop(
  chars: List(String),
  remaining: Int,
  in_escape: Bool,
) -> String {
  case chars {
    [] -> ""

    ["\u{001b}", ..rest] -> drop_visible_loop(rest, remaining, True)

    ["m", ..rest] if in_escape -> drop_visible_loop(rest, remaining, False)

    [_, ..rest] if in_escape -> drop_visible_loop(rest, remaining, True)

    _ if remaining <= 0 -> chars_to_string(chars)

    [_, ..rest] -> drop_visible_loop(rest, remaining - 1, False)
  }
}

fn chars_to_string(chars: List(String)) -> String {
  string.join(chars, "")
}
