//// ANSI-aware text alignment helpers.

import gleam/bool
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
  case string.contains(text, "\u{001b}") || !is_ascii(text) {
    True -> count_visible(string.to_graphemes(text), False, 0)
    False -> string.length(text)
  }
}

fn count_visible(chars: List(String), in_escape: Bool, count: Int) -> Int {
  case chars {
    [] -> count
    ["\u{001b}", ..rest] -> count_visible(rest, True, count)
    ["[", ..rest] if in_escape -> count_visible(rest, True, count)
    [char, ..rest] if in_escape ->
      case is_escape_final(char) {
        True -> count_visible(rest, False, count)
        False -> count_visible(rest, True, count)
      }
    [char, ..rest] -> count_visible(rest, False, count + display_width(char))
  }
}

fn display_width(grapheme: String) -> Int {
  case string.to_utf_codepoints(grapheme) {
    [] -> 0
    [codepoint, ..] -> {
      let codepoint = string.utf_codepoint_to_int(codepoint)

      case is_zero_width(codepoint) {
        True -> 0
        False ->
          case is_wide(codepoint) {
            True -> 2
            False -> 1
          }
      }
    }
  }
}

fn is_ascii(text: String) -> Bool {
  is_ascii_codepoints(string.to_utf_codepoints(text))
}

fn is_ascii_codepoints(codepoints: List(UtfCodepoint)) -> Bool {
  case codepoints {
    [] -> True
    [codepoint, ..rest] ->
      string.utf_codepoint_to_int(codepoint) < 0x80 && is_ascii_codepoints(rest)
  }
}

fn is_escape_final(grapheme: String) -> Bool {
  case string.to_utf_codepoints(grapheme) {
    [] -> False
    [codepoint, ..] ->
      in_range(string.utf_codepoint_to_int(codepoint), 0x40, 0x7e)
  }
}

fn is_zero_width(codepoint: Int) -> Bool {
  in_range(codepoint, 0x0300, 0x036f)
  || codepoint == 0x0489
  || in_range(codepoint, 0x200b, 0x200f)
  || codepoint == 0x200d
  || in_range(codepoint, 0xfe00, 0xfe0f)
  || codepoint == 0xfeff
}

fn is_wide(codepoint: Int) -> Bool {
  in_range(codepoint, 0x1100, 0x115f)
  || in_range(codepoint, 0x2e80, 0x303e)
  || in_range(codepoint, 0x3041, 0x33ff)
  || in_range(codepoint, 0x3400, 0x4dbf)
  || in_range(codepoint, 0x4e00, 0x9fff)
  || in_range(codepoint, 0xa000, 0xa4cf)
  || in_range(codepoint, 0xac00, 0xd7a3)
  || in_range(codepoint, 0xf900, 0xfaff)
  || in_range(codepoint, 0xfe10, 0xfe19)
  || in_range(codepoint, 0xfe30, 0xfe6f)
  || in_range(codepoint, 0xff00, 0xff60)
  || in_range(codepoint, 0xffe0, 0xffe6)
  || in_range(codepoint, 0x1f300, 0x1faff)
  || in_range(codepoint, 0x20000, 0x3fffd)
}

fn in_range(value: Int, first: Int, last: Int) -> Bool {
  value >= first && value <= last
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
pub fn truncate(
  text: String,
  width width: Int,
  ellipsis ellipsis: String,
) -> String {
  use <- bool.guard(when: width <= 0, return: "")
  use <- bool.guard(when: visual_length(text) <= width, return: text)
  let ellipsis_width = visual_length(ellipsis)

  case ellipsis_width >= width {
    True -> take_visible(ellipsis, width)
    False ->
      close_open_sgr(take_visible(text, width - ellipsis_width)) <> ellipsis
  }
}

/// Wrap `text` to `width` visual columns.
///
/// ANSI escape sequences do not count toward the width and are never split.
/// Words longer than `width` are hard-wrapped at visible column boundaries.
/// Widths less than or equal to zero return the input unchanged.
pub fn wrap(text: String, width: Int) -> String {
  use <- bool.guard(when: width <= 0, return: text)
  text
  |> string.split("\n")
  |> list.map(wrap_line(_, width))
  |> string.join("\n")
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
    trimmed -> [close_open_sgr(trimmed), ..lines]
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

    ["[", ..rest] if in_escape ->
      split_pieces_loop(rest, True, current <> "[", kind, pieces)

    [char, ..rest] if in_escape ->
      case is_escape_final(char) {
        True -> split_pieces_loop(rest, False, current <> char, kind, pieces)
        False -> split_pieces_loop(rest, True, current <> char, kind, pieces)
      }

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
    [chunk, ..rest] ->
      add_wrapped_chunks(rest, [close_open_sgr(chunk), ..lines])
  }
}

fn close_open_sgr(text: String) -> String {
  use <- bool.guard(when: !has_open_sgr(text), return: text)
  text <> "\u{001b}[0m"
}

fn has_open_sgr(text: String) -> Bool {
  has_open_sgr_loop(string.to_graphemes(text), False, "", False)
}

fn has_open_sgr_loop(
  chars: List(String),
  in_escape: Bool,
  escape: String,
  active: Bool,
) -> Bool {
  case chars {
    [] -> active

    ["\u{001b}", ..rest] -> has_open_sgr_loop(rest, True, "\u{001b}", active)

    ["[", ..rest] if in_escape ->
      has_open_sgr_loop(rest, True, escape <> "[", active)

    [char, ..rest] if in_escape -> {
      let escape = escape <> char
      let active = case is_escape_final(char) {
        True -> update_sgr_active(escape, char, active)
        False -> active
      }

      has_open_sgr_loop(rest, !is_escape_final(char), escape, active)
    }

    [_, ..rest] -> has_open_sgr_loop(rest, False, "", active)
  }
}

fn update_sgr_active(escape: String, final: String, active: Bool) -> Bool {
  case final {
    "m" -> !is_sgr_reset(escape)
    _ -> active
  }
}

fn is_sgr_reset(escape: String) -> Bool {
  string.contains(escape, "[m")
  || sgr_has_param(escape, "0")
  || sgr_has_param(escape, "39")
  || sgr_has_param(escape, "49")
}

fn sgr_has_param(escape: String, param: String) -> Bool {
  string.contains(escape, "[" <> param <> "m")
  || string.contains(escape, "[" <> param <> ";")
  || string.contains(escape, ";" <> param <> "m")
  || string.contains(escape, ";" <> param <> ";")
}

fn wrap_long_word(word: String, width: Int) -> List(String) {
  case visual_length(word) <= width {
    True -> [word]
    False -> {
      let chunk = take_visible(word, width)

      case visual_length(chunk) == 0 {
        True -> {
          let first_width = first_positive_width(word)

          case first_width {
            0 -> [word]
            _ -> [
              take_visible(word, first_width),
              ..wrap_long_word(drop_visible(word, first_width), width)
            ]
          }
        }

        False -> [chunk, ..wrap_long_word(drop_visible(word, width), width)]
      }
    }
  }
}

fn first_positive_width(text: String) -> Int {
  first_positive_width_loop(string.to_graphemes(text), False)
}

fn first_positive_width_loop(chars: List(String), in_escape: Bool) -> Int {
  case chars {
    [] -> 0
    ["\u{001b}", ..rest] -> first_positive_width_loop(rest, True)
    ["[", ..rest] if in_escape -> first_positive_width_loop(rest, True)
    [char, ..rest] if in_escape ->
      case is_escape_final(char) {
        True -> first_positive_width_loop(rest, False)
        False -> first_positive_width_loop(rest, True)
      }
    [char, ..rest] -> {
      let width = display_width(char)

      case width {
        0 -> first_positive_width_loop(rest, False)
        _ -> width
      }
    }
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

    ["[", ..rest] if in_escape ->
      take_visible_loop(rest, remaining, True, ["[", ..acc])

    [char, ..rest] if in_escape ->
      case is_escape_final(char) {
        True -> take_visible_loop(rest, remaining, False, [char, ..acc])
        False -> take_visible_loop(rest, remaining, True, [char, ..acc])
      }

    [char, ..rest] -> {
      let char_width = display_width(char)

      case char_width == 0 || char_width <= remaining {
        True ->
          take_visible_loop(rest, remaining - char_width, False, [char, ..acc])
        False -> take_visible_loop(rest, 0, False, acc)
      }
    }
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

    ["[", ..rest] if in_escape -> drop_visible_loop(rest, remaining, True)

    [char, ..rest] if in_escape ->
      case is_escape_final(char) {
        True -> drop_visible_loop(rest, remaining, False)
        False -> drop_visible_loop(rest, remaining, True)
      }

    _ if remaining <= 0 -> chars_to_string(chars)

    [char, ..rest] -> {
      let char_width = display_width(char)

      case char_width > remaining {
        True -> chars_to_string(chars)
        False -> drop_visible_loop(rest, remaining - char_width, False)
      }
    }
  }
}

fn chars_to_string(chars: List(String)) -> String {
  string.join(chars, "")
}
