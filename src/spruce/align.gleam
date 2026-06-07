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

type EscapeState {
  NormalText
  EscapeStart
  CsiEscape
  OscEscape
  OscEscapeAfterEsc
}

/// The visual length of a string, excluding ANSI escape codes.
pub fn visual_length(text: String) -> Int {
  case string.contains(text, "\u{001b}") || !is_ascii(text) {
    True -> count_visible(string.to_graphemes(text), NormalText, 0)
    False -> string.length(text)
  }
}

fn count_visible(chars: List(String), state: EscapeState, count: Int) -> Int {
  case chars {
    [] -> count
    [char, ..rest] ->
      case state {
        NormalText ->
          case char {
            "\u{001b}" ->
              count_visible(rest, step_escape_state(NormalText, char), count)
            _ -> count_visible(rest, NormalText, count + display_width(char))
          }
        _ -> count_visible(rest, step_escape_state(state, char), count)
      }
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
  string.to_utf_codepoints(text)
  |> list.fold(True, fn(all_ascii, codepoint) {
    all_ascii && string.utf_codepoint_to_int(codepoint) < 0x80
  })
}

fn is_escape_final(grapheme: String) -> Bool {
  case string.to_utf_codepoints(grapheme) {
    [] -> False
    [codepoint, ..] ->
      in_range(string.utf_codepoint_to_int(codepoint), 0x40, 0x7e)
  }
}

fn step_escape_state(state: EscapeState, char: String) -> EscapeState {
  case state {
    NormalText ->
      case char {
        "\u{001b}" -> EscapeStart
        _ -> NormalText
      }

    EscapeStart ->
      case char {
        "[" -> CsiEscape
        "]" -> OscEscape
        "\u{001b}" -> EscapeStart
        _ -> NormalText
      }

    CsiEscape ->
      case is_escape_final(char) {
        True -> NormalText
        False -> CsiEscape
      }

    OscEscape ->
      case char {
        "\u{0007}" -> NormalText
        "\u{001b}" -> OscEscapeAfterEsc
        _ -> OscEscape
      }

    OscEscapeAfterEsc ->
      case char {
        "\\" -> NormalText
        "\u{0007}" -> NormalText
        "\u{001b}" -> OscEscapeAfterEsc
        _ -> OscEscape
      }
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
  split_pieces_loop(string.to_graphemes(text), NormalText, "", NoPiece, [])
}

fn split_pieces_loop(
  chars: List(String),
  state: EscapeState,
  current: String,
  kind: PieceKind,
  pieces: List(Piece),
) -> List(Piece) {
  case chars {
    [] -> list.reverse(push_piece(kind, current, pieces))

    [char, ..rest] -> {
      case state {
        NormalText ->
          case char {
            "\u{001b}" -> {
              let kind = case kind {
                NoPiece -> WordPiece
                _ -> kind
              }

              split_pieces_loop(
                rest,
                step_escape_state(NormalText, char),
                current <> char,
                kind,
                pieces,
              )
            }

            " " -> {
              let #(current, kind, pieces) =
                add_piece_grapheme(" ", SpacePiece, current, kind, pieces)

              split_pieces_loop(rest, NormalText, current, kind, pieces)
            }

            _ -> {
              let #(current, kind, pieces) =
                add_piece_grapheme(char, WordPiece, current, kind, pieces)

              split_pieces_loop(rest, NormalText, current, kind, pieces)
            }
          }

        _ ->
          split_pieces_loop(
            rest,
            step_escape_state(state, char),
            current <> char,
            kind,
            pieces,
          )
      }
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
  has_open_sgr_loop(string.to_graphemes(text), NormalText, "", False)
}

fn has_open_sgr_loop(
  chars: List(String),
  state: EscapeState,
  escape: String,
  active: Bool,
) -> Bool {
  case chars {
    [] -> active

    [char, ..rest] ->
      case state {
        NormalText ->
          case char {
            "\u{001b}" ->
              has_open_sgr_loop(
                rest,
                step_escape_state(NormalText, char),
                char,
                active,
              )
            _ -> has_open_sgr_loop(rest, NormalText, "", active)
          }

        EscapeStart ->
          case char {
            "[" -> has_open_sgr_loop(rest, CsiEscape, escape <> char, active)
            "]" -> has_open_sgr_loop(rest, OscEscape, "", active)
            _ ->
              has_open_sgr_loop(
                rest,
                step_escape_state(EscapeStart, char),
                "",
                active,
              )
          }

        CsiEscape -> {
          let escape = escape <> char
          let active = case is_escape_final(char) {
            True -> update_sgr_active(escape, char, active)
            False -> active
          }

          has_open_sgr_loop(
            rest,
            step_escape_state(CsiEscape, char),
            escape,
            active,
          )
        }

        OscEscape | OscEscapeAfterEsc ->
          has_open_sgr_loop(rest, step_escape_state(state, char), "", active)
      }
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
  first_positive_width_loop(string.to_graphemes(text), NormalText)
}

fn first_positive_width_loop(chars: List(String), state: EscapeState) -> Int {
  case chars {
    [] -> 0
    [char, ..rest] -> {
      case state {
        NormalText ->
          case char {
            "\u{001b}" ->
              first_positive_width_loop(
                rest,
                step_escape_state(NormalText, char),
              )
            _ -> {
              let width = display_width(char)

              case width {
                0 -> first_positive_width_loop(rest, NormalText)
                _ -> width
              }
            }
          }

        _ -> first_positive_width_loop(rest, step_escape_state(state, char))
      }
    }
  }
}

fn take_visible(text: String, width: Int) -> String {
  case width <= 0 {
    True -> take_visible_loop(string.to_graphemes(text), 0, NormalText, [])
    False -> take_visible_loop(string.to_graphemes(text), width, NormalText, [])
  }
}

fn take_visible_loop(
  chars: List(String),
  remaining: Int,
  state: EscapeState,
  acc: List(String),
) -> String {
  case chars {
    [] -> chars_to_string(list.reverse(acc))

    [char, ..rest] -> {
      case state {
        NormalText ->
          case char {
            "\u{001b}" ->
              take_visible_loop(
                rest,
                remaining,
                step_escape_state(NormalText, char),
                [char, ..acc],
              )
            _ -> {
              let char_width = display_width(char)

              case char_width == 0 || char_width <= remaining {
                True ->
                  take_visible_loop(rest, remaining - char_width, NormalText, [
                    char,
                    ..acc
                  ])
                False -> take_visible_loop(rest, 0, NormalText, acc)
              }
            }
          }

        _ ->
          take_visible_loop(rest, remaining, step_escape_state(state, char), [
            char,
            ..acc
          ])
      }
    }
  }
}

fn drop_visible(text: String, width: Int) -> String {
  drop_visible_loop(string.to_graphemes(text), width, NormalText)
}

fn drop_visible_loop(
  chars: List(String),
  remaining: Int,
  state: EscapeState,
) -> String {
  case chars {
    [] -> ""

    [char, ..rest] -> {
      case state {
        NormalText ->
          case remaining <= 0 {
            True -> chars_to_string(chars)
            False ->
              case char {
                "\u{001b}" ->
                  drop_visible_loop(
                    rest,
                    remaining,
                    step_escape_state(NormalText, char),
                  )

                _ -> {
                  let char_width = display_width(char)

                  case char_width > remaining {
                    True -> chars_to_string(chars)
                    False ->
                      drop_visible_loop(
                        rest,
                        remaining - char_width,
                        NormalText,
                      )
                  }
                }
              }
          }

        _ -> drop_visible_loop(rest, remaining, step_escape_state(state, char))
      }
    }
  }
}

fn chars_to_string(chars: List(String)) -> String {
  string.join(chars, "")
}
