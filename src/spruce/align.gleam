//// ANSI-aware text geometry: visual length, padding, wrapping, truncation,
//// and multi-line block composition (`join_vertical`, `join_horizontal`,
//// `place`).

import gleam/bool
import gleam/int
import gleam/list
import gleam/result
import gleam/string

type Token {
  Visible(text: String, width: Int, space: Bool)
  Control(String)
}

type Piece {
  Word(tokens: List(Token), width: Int)
  Spaces(tokens: List(Token), width: Int)
}

type PieceKind {
  NoPiece
  WordPiece
  SpacePiece
}

type EscapeState {
  NormalText
  EscapeStart
  EscapeIntermediate
  CsiEscape
  OscEscape
  OscEscapeAfterEsc
  StEscape
  StEscapeAfterEsc
}

type SgrCategory {
  Foreground
  Background
  UnderlineColor
  Intensity
  Italic
  Underline
  Blink
  Inverse
  Conceal
  Strike
  Font
  Other(Int)
}

type SgrSetting {
  SgrSetting(category: SgrCategory, parameters: String)
}

type TerminalState {
  TerminalState(sgr: List(SgrSetting), hyperlink: String)
}

/// A position used for horizontal or vertical alignment.
pub type Pos {
  Start
  Center
  End
}

type Block {
  Block(width: Int, height: Int, lines: List(String))
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
        EscapeStart
        | EscapeIntermediate
        | CsiEscape
        | OscEscape
        | OscEscapeAfterEsc
        | StEscape
        | StEscapeAfterEsc ->
          count_visible(rest, step_escape_state(state, char), count)
      }
  }
}

fn display_width(grapheme: String) -> Int {
  let codepoints = string.to_utf_codepoints(grapheme)

  case codepoints {
    [] -> 0
    [codepoint, ..] -> {
      let codepoint = string.utf_codepoint_to_int(codepoint)

      case is_zero_width(codepoint) {
        True -> 0
        False ->
          case
            is_wide(codepoint)
            || has_codepoint(codepoints, 0xfe0f)
            || is_regional_indicator_pair(codepoints)
          {
            True -> 2
            False -> 1
          }
      }
    }
  }
}

fn has_codepoint(codepoints: List(UtfCodepoint), wanted: Int) -> Bool {
  case codepoints {
    [] -> False
    [codepoint, ..rest] ->
      string.utf_codepoint_to_int(codepoint) == wanted
      || has_codepoint(rest, wanted)
  }
}

fn is_regional_indicator_pair(codepoints: List(UtfCodepoint)) -> Bool {
  case codepoints {
    [first, second] ->
      is_regional_indicator(string.utf_codepoint_to_int(first))
      && is_regional_indicator(string.utf_codepoint_to_int(second))
    _ -> False
  }
}

fn is_regional_indicator(codepoint: Int) -> Bool {
  in_range(codepoint, 0x1f1e6, 0x1f1ff)
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
        "P" | "X" | "^" | "_" -> StEscape
        "\u{001b}" -> EscapeStart
        _ ->
          case is_escape_intermediate(char) {
            True -> EscapeIntermediate
            False -> NormalText
          }
      }

    EscapeIntermediate ->
      case is_escape_final_byte(char) {
        True -> NormalText
        False -> EscapeIntermediate
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

    StEscape ->
      case char {
        "\u{001b}" -> StEscapeAfterEsc
        _ -> StEscape
      }

    StEscapeAfterEsc ->
      case char {
        "\\" -> NormalText
        "\u{001b}" -> StEscapeAfterEsc
        _ -> StEscape
      }
  }
}

fn is_escape_intermediate(grapheme: String) -> Bool {
  case string.to_utf_codepoints(grapheme) {
    [] -> False
    [codepoint, ..] ->
      in_range(string.utf_codepoint_to_int(codepoint), 0x20, 0x2f)
  }
}

fn is_escape_final_byte(grapheme: String) -> Bool {
  case string.to_utf_codepoints(grapheme) {
    [] -> False
    [codepoint, ..] ->
      in_range(string.utf_codepoint_to_int(codepoint), 0x30, 0x7e)
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
/// Open SGR styles and OSC 8 hyperlinks are closed before the ellipsis.
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
    False -> {
      let #(cropped, state) =
        take_visible_with_state(text, width - ellipsis_width)
      cropped <> close_terminal(state) <> ellipsis
    }
  }
}

/// Wrap `text` to `width` visual columns.
///
/// ANSI escape sequences do not count toward the width and are never split.
/// Active SGR styles and OSC 8 hyperlinks are closed and reopened at output
/// line boundaries.
/// Words longer than `width` are hard-wrapped at visible column boundaries.
/// Widths less than or equal to zero return the input unchanged.
pub fn wrap(text: String, width: Int) -> String {
  use <- bool.guard(when: width <= 0, return: text)
  text
  |> string.split("\n")
  |> wrap_lines(width, TerminalState([], ""), [])
  |> string.join("\n")
}

fn wrap_lines(
  lines: List(String),
  width: Int,
  state: TerminalState,
  wrapped: List(String),
) -> List(String) {
  case lines {
    [] -> list.reverse(wrapped)
    [line, ..rest] -> {
      let #(line, state) = wrap_line(line, width, state)
      wrap_lines(rest, width, state, [line, ..wrapped])
    }
  }
}

fn wrap_line(
  line: String,
  width: Int,
  state: TerminalState,
) -> #(String, TerminalState) {
  let tokens = tokenize(line)
  let final_state = terminal_state_after(tokens, state)
  let wrapped =
    tokens
    |> split_pieces
    |> wrap_pieces(width, start_line(state), 0, state, [])
    |> string.join("\n")
  #(wrapped, final_state)
}

fn wrap_pieces(
  pieces: List(Piece),
  width: Int,
  current: List(String),
  current_width: Int,
  state: TerminalState,
  lines: List(String),
) -> List(String) {
  case pieces {
    [] ->
      case current {
        [] -> list.reverse(lines)
        _ -> list.reverse([finish_line(current, state, False), ..lines])
      }

    [Spaces(tokens, spaces_width), ..rest] -> {
      case current_width + spaces_width <= width {
        True -> {
          let #(current, state) = append_tokens(tokens, current, state)
          wrap_pieces(
            rest,
            width,
            current,
            current_width + spaces_width,
            state,
            lines,
          )
        }

        False ->
          case current_width {
            0 -> {
              let #(current, current_width, state, lines) =
                wrap_long_piece(tokens, width, current, state, lines)
              wrap_pieces(rest, width, current, current_width, state, lines)
            }

            _ -> {
              let #(current, state) = append_controls(tokens, current, state)
              let lines = [finish_line(current, state, True), ..lines]
              wrap_pieces(rest, width, start_line(state), 0, state, lines)
            }
          }
      }
    }

    [Word(tokens, word_width), ..rest] -> {
      case word_width > width {
        True ->
          case current_width {
            0 -> {
              let #(current, current_width, state, lines) =
                wrap_long_piece(tokens, width, current, state, lines)
              wrap_pieces(rest, width, current, current_width, state, lines)
            }

            _ -> {
              let lines = [finish_line(current, state, True), ..lines]
              wrap_pieces(pieces, width, start_line(state), 0, state, lines)
            }
          }

        False ->
          case current_width + word_width <= width {
            True -> {
              let #(current, state) = append_tokens(tokens, current, state)
              wrap_pieces(
                rest,
                width,
                current,
                current_width + word_width,
                state,
                lines,
              )
            }

            False -> {
              let lines = [finish_line(current, state, True), ..lines]
              wrap_pieces(pieces, width, start_line(state), 0, state, lines)
            }
          }
      }
    }
  }
}

fn wrap_long_piece(
  tokens: List(Token),
  width: Int,
  current: List(String),
  state: TerminalState,
  lines: List(String),
) -> #(List(String), Int, TerminalState, List(String)) {
  wrap_long_piece_loop(tokens, width, current, 0, state, lines)
}

fn wrap_long_piece_loop(
  tokens: List(Token),
  width: Int,
  current: List(String),
  current_width: Int,
  state: TerminalState,
  lines: List(String),
) -> #(List(String), Int, TerminalState, List(String)) {
  case tokens {
    [] -> #(current, current_width, state, lines)
    [Control(control), ..rest] ->
      wrap_long_piece_loop(
        rest,
        width,
        [control, ..current],
        current_width,
        update_terminal(state, control),
        lines,
      )
    [Visible(text, token_width, _), ..rest] ->
      case current_width > 0 && current_width + token_width > width {
        True -> {
          let lines = [finish_line(current, state, True), ..lines]
          wrap_long_piece_loop(
            tokens,
            width,
            start_line(state),
            0,
            state,
            lines,
          )
        }
        False ->
          wrap_long_piece_loop(
            rest,
            width,
            [text, ..current],
            current_width + token_width,
            state,
            lines,
          )
      }
  }
}

fn append_tokens(
  tokens: List(Token),
  current: List(String),
  state: TerminalState,
) -> #(List(String), TerminalState) {
  case tokens {
    [] -> #(current, state)
    [Visible(text, _, _), ..rest] ->
      append_tokens(rest, [text, ..current], state)
    [Control(control), ..rest] ->
      append_tokens(rest, [control, ..current], update_terminal(state, control))
  }
}

fn append_controls(
  tokens: List(Token),
  current: List(String),
  state: TerminalState,
) -> #(List(String), TerminalState) {
  case tokens {
    [] -> #(current, state)
    [Visible(_, _, _), ..rest] -> append_controls(rest, current, state)
    [Control(control), ..rest] ->
      append_controls(
        rest,
        [control, ..current],
        update_terminal(state, control),
      )
  }
}

fn finish_line(
  current: List(String),
  state: TerminalState,
  trim_spaces: Bool,
) -> String {
  let line = current |> list.reverse |> chars_to_string
  let line = case trim_spaces {
    True -> trim_trailing_spaces(line)
    False -> line
  }
  line <> close_terminal(state)
}

fn close_terminal(state: TerminalState) -> String {
  let TerminalState(sgr:, hyperlink:) = state
  let hyperlink_close = case hyperlink {
    "" -> ""
    _ -> "\u{001b}]8;;\u{001b}\\"
  }
  let sgr_close = case sgr {
    [] -> ""
    _ -> "\u{001b}[0m"
  }
  hyperlink_close <> sgr_close
}

fn reopen_terminal(state: TerminalState) -> String {
  let TerminalState(sgr:, hyperlink:) = state
  let sgr =
    sgr
    |> list.map(fn(setting) { "\u{001b}[" <> setting.parameters <> "m" })
    |> string.join("")
  sgr <> hyperlink
}

fn start_line(state: TerminalState) -> List(String) {
  case reopen_terminal(state) {
    "" -> []
    reopening -> [reopening]
  }
}

fn terminal_state_after(
  tokens: List(Token),
  state: TerminalState,
) -> TerminalState {
  case tokens {
    [] -> state
    [Visible(_, _, _), ..rest] -> terminal_state_after(rest, state)
    [Control(control), ..rest] ->
      terminal_state_after(rest, update_terminal(state, control))
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

fn split_pieces(tokens: List(Token)) -> List(Piece) {
  split_pieces_loop(tokens, [], 0, NoPiece, [])
}

fn split_pieces_loop(
  tokens: List(Token),
  current: List(Token),
  current_width: Int,
  kind: PieceKind,
  pieces: List(Piece),
) -> List(Piece) {
  case tokens {
    [] -> list.reverse(push_piece(kind, current, current_width, pieces))
    [token, ..rest] ->
      case token {
        Control(_) -> {
          let kind = case kind {
            NoPiece -> WordPiece
            WordPiece | SpacePiece -> kind
          }
          split_pieces_loop(
            rest,
            [token, ..current],
            current_width,
            kind,
            pieces,
          )
        }
        Visible(_, token_width, space) -> {
          let token_kind = case space {
            True -> SpacePiece
            False -> WordPiece
          }
          case kind == NoPiece || kind == token_kind {
            True ->
              split_pieces_loop(
                rest,
                [token, ..current],
                current_width + token_width,
                token_kind,
                pieces,
              )
            False ->
              split_pieces_loop(
                rest,
                [token],
                token_width,
                token_kind,
                push_piece(kind, current, current_width, pieces),
              )
          }
        }
      }
  }
}

fn push_piece(
  kind: PieceKind,
  current: List(Token),
  width: Int,
  pieces: List(Piece),
) -> List(Piece) {
  case current {
    [] -> pieces
    _ ->
      case kind {
        SpacePiece -> [Spaces(list.reverse(current), width), ..pieces]
        NoPiece | WordPiece -> [Word(list.reverse(current), width), ..pieces]
      }
  }
}

fn tokenize(text: String) -> List(Token) {
  tokenize_loop(string.to_graphemes(text), NormalText, [], [])
}

fn tokenize_loop(
  chars: List(String),
  state: EscapeState,
  escape: List(String),
  tokens: List(Token),
) -> List(Token) {
  case chars {
    [] -> {
      let tokens = case escape {
        [] -> tokens
        _ -> [Control(escape |> list.reverse |> chars_to_string), ..tokens]
      }
      list.reverse(tokens)
    }
    [char, ..rest] -> {
      case state {
        NormalText ->
          case char {
            "\u{001b}" -> tokenize_loop(rest, EscapeStart, [char], tokens)
            _ ->
              tokenize_loop(rest, NormalText, [], [
                Visible(char, display_width(char), char == " "),
                ..tokens
              ])
          }
        EscapeStart
        | EscapeIntermediate
        | CsiEscape
        | OscEscape
        | OscEscapeAfterEsc
        | StEscape
        | StEscapeAfterEsc -> {
          let escape = [char, ..escape]
          let next_state = step_escape_state(state, char)
          case next_state {
            NormalText ->
              tokenize_loop(rest, NormalText, [], [
                Control(escape |> list.reverse |> chars_to_string),
                ..tokens
              ])
            _ -> tokenize_loop(rest, next_state, escape, tokens)
          }
        }
      }
    }
  }
}

fn take_visible(text: String, width: Int) -> String {
  let #(taken, _) = take_visible_with_state(text, int.max(0, width))
  taken
}

fn take_visible_with_state(
  text: String,
  width: Int,
) -> #(String, TerminalState) {
  let #(taken, state) =
    take_visible_loop(
      tokenize(text),
      int.max(0, width),
      True,
      [],
      TerminalState([], ""),
    )
  #(taken |> list.reverse |> chars_to_string, state)
}

fn take_visible_loop(
  tokens: List(Token),
  remaining: Int,
  accepting: Bool,
  acc: List(String),
  state: TerminalState,
) -> #(List(String), TerminalState) {
  case tokens {
    [] -> #(acc, state)
    [Control(control), ..rest] ->
      take_visible_loop(
        rest,
        remaining,
        accepting,
        [control, ..acc],
        update_terminal(state, control),
      )
    [Visible(text, token_width, _), ..rest] ->
      case token_width == 0 || accepting && token_width <= remaining {
        True ->
          take_visible_loop(
            rest,
            remaining - token_width,
            accepting,
            [text, ..acc],
            state,
          )
        False -> take_visible_loop(rest, remaining, False, acc, state)
      }
  }
}

fn update_terminal(state: TerminalState, control: String) -> TerminalState {
  let TerminalState(sgr:, hyperlink:) = state
  case
    string.starts_with(control, "\u{001b}[") && string.ends_with(control, "m")
  {
    True -> {
      let parameters =
        control
        |> string.drop_start(2)
        |> string.drop_end(1)
        |> string.split(";")
      TerminalState(update_sgr(sgr, parameters), hyperlink)
    }
    False ->
      case string.starts_with(control, "\u{001b}]8;") {
        True ->
          case is_hyperlink_close(control) {
            True -> TerminalState(sgr, "")
            False -> TerminalState(sgr, control)
          }
        False -> state
      }
  }
}

fn is_hyperlink_close(control: String) -> Bool {
  control == "\u{001b}]8;;\u{001b}\\" || control == "\u{001b}]8;;\u{0007}"
}

fn update_sgr(
  settings: List(SgrSetting),
  parameters: List(String),
) -> List(SgrSetting) {
  case parameters {
    [] -> settings
    [""] -> []
    ["0", ..rest] -> update_sgr([], rest)
    ["38", mode, red, green, blue, ..rest] if mode == "2" ->
      update_sgr(
        set_sgr(
          settings,
          Foreground,
          "38;2;" <> red <> ";" <> green <> ";" <> blue,
        ),
        rest,
      )
    ["38", mode, color, ..rest] if mode == "5" ->
      update_sgr(set_sgr(settings, Foreground, "38;5;" <> color), rest)
    ["48", mode, red, green, blue, ..rest] if mode == "2" ->
      update_sgr(
        set_sgr(
          settings,
          Background,
          "48;2;" <> red <> ";" <> green <> ";" <> blue,
        ),
        rest,
      )
    ["48", mode, color, ..rest] if mode == "5" ->
      update_sgr(set_sgr(settings, Background, "48;5;" <> color), rest)
    ["58", mode, red, green, blue, ..rest] if mode == "2" ->
      update_sgr(
        set_sgr(
          settings,
          UnderlineColor,
          "58;2;" <> red <> ";" <> green <> ";" <> blue,
        ),
        rest,
      )
    ["58", mode, color, ..rest] if mode == "5" ->
      update_sgr(set_sgr(settings, UnderlineColor, "58;5;" <> color), rest)
    [parameter, ..rest] -> {
      let settings = update_sgr_parameter(settings, parameter)
      update_sgr(settings, rest)
    }
  }
}

fn update_sgr_parameter(
  settings: List(SgrSetting),
  parameter: String,
) -> List(SgrSetting) {
  let code = parameter |> int.parse |> result.unwrap(-1)
  case code {
    0 -> []
    22 -> remove_sgr(settings, Intensity)
    23 -> remove_sgr(settings, Italic)
    24 -> remove_sgr(settings, Underline)
    25 -> remove_sgr(settings, Blink)
    27 -> remove_sgr(settings, Inverse)
    28 -> remove_sgr(settings, Conceal)
    29 -> remove_sgr(settings, Strike)
    39 -> remove_sgr(settings, Foreground)
    49 -> remove_sgr(settings, Background)
    59 -> remove_sgr(settings, UnderlineColor)
    10 -> remove_sgr(settings, Font)
    _ if code > 0 -> set_sgr(settings, sgr_category(code), parameter)
    _ -> settings
  }
}

fn sgr_category(code: Int) -> SgrCategory {
  case code {
    1 | 2 -> Intensity
    3 -> Italic
    4 | 21 -> Underline
    5 | 6 -> Blink
    7 -> Inverse
    8 -> Conceal
    9 -> Strike
    _ ->
      case True {
        _ if code >= 11 && code <= 19 -> Font
        _ if code >= 30 && code <= 37 || code >= 90 && code <= 97 -> Foreground
        _ if code >= 40 && code <= 47 || code >= 100 && code <= 107 ->
          Background
        _ -> Other(code)
      }
  }
}

fn set_sgr(
  settings: List(SgrSetting),
  category: SgrCategory,
  parameters: String,
) -> List(SgrSetting) {
  remove_sgr(settings, category)
  |> list.append([SgrSetting(category:, parameters:)])
}

fn remove_sgr(
  settings: List(SgrSetting),
  category: SgrCategory,
) -> List(SgrSetting) {
  list.filter(settings, fn(setting) { setting.category != category })
}

fn chars_to_string(chars: List(String)) -> String {
  string.join(chars, "")
}

fn pad(text: String, width: Int, pos: Pos) -> String {
  case pos {
    Start -> pad_right(text, width)
    Center -> pad_center(text, width)
    End -> pad_left(text, width)
  }
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
  let #(content_width, content_height) = size(content)
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
  let #(width, block_height) = size(block)
  Block(width: width, height: block_height, lines: string.split(block, "\n"))
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

      list.repeat(blank, before)
      |> list.append(lines)
      |> list.append(list.repeat(blank, after))
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
  |> list.map(visual_length)
  |> list.fold(0, int.max)
}

fn max_block_height(blocks: List(Block)) -> Int {
  max_block_height_loop(blocks, 0)
}

fn max_block_height_loop(blocks: List(Block), acc: Int) -> Int {
  case blocks {
    [] -> acc
    [Block(height: block_height, ..), ..rest] ->
      max_block_height_loop(rest, int.max(acc, block_height))
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
