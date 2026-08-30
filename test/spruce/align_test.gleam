import gleam/list
import gleam/string
import gleam_community/ansi
import gleeunit/should
import spruce/align

pub fn visual_length_plain_test() {
  align.visual_length("hello")
  |> should.equal(5)
}

pub fn visual_length_ignores_ansi_test() {
  let styled = ansi.red("hello")
  should.be_true(string.length(styled) > 5)
  align.visual_length(styled)
  |> should.equal(5)
}

pub fn visual_length_counts_cjk_as_two_columns_test() {
  align.visual_length("日本")
  |> should.equal(4)
}

pub fn visual_length_counts_zero_width_graphemes_as_zero_test() {
  align.visual_length("e\u{0301}\u{200b}\u{0301}")
  |> should.equal(1)
}

pub fn visual_length_terminates_non_sgr_csi_escape_test() {
  align.visual_length("\u{001b}[2Jabc")
  |> should.equal(3)
}

pub fn visual_length_large_ascii_string_does_not_overflow_test() {
  let text = string.repeat("a", 200_000)
  align.visual_length(text)
  |> should.equal(200_000)
}

pub fn visual_length_ignores_osc_bel_sequence_test() {
  align.visual_length("\u{001b}]0;window title\u{0007}abc")
  |> should.equal(3)
}

pub fn visual_length_ignores_osc_st_sequence_test() {
  let open = "\u{001b}]8;;https://example.com\u{001b}\\"
  let close = "\u{001b}]8;;\u{001b}\\"

  align.visual_length(open <> "link" <> close)
  |> should.equal(4)
}

pub fn pad_right_extends_to_width_test() {
  align.pad_right("ab", 5)
  |> should.equal("ab   ")
}

pub fn pad_right_uses_wide_character_width_test() {
  align.pad_right("日", 4)
  |> should.equal("日  ")
}

pub fn pad_right_uses_visual_length_test() {
  let styled = ansi.red("ab")
  align.visual_length(align.pad_right(styled, 5))
  |> should.equal(5)
}

pub fn pad_right_no_truncation_test() {
  align.pad_right("abcdef", 3)
  |> should.equal("abcdef")
}

pub fn pad_left_extends_to_width_test() {
  align.pad_left("ab", 5)
  |> should.equal("   ab")
}

pub fn pad_center_extends_even_padding_test() {
  align.pad_center("ab", 6)
  |> should.equal("  ab  ")
}

pub fn pad_center_extends_odd_padding_test() {
  align.pad_center("ab", 5)
  |> should.equal(" ab  ")
}

pub fn pad_center_uses_visual_length_test() {
  let styled = ansi.red("ab")
  align.visual_length(align.pad_center(styled, 6))
  |> should.equal(6)
}

pub fn height_counts_lines_test() {
  align.height("one\ntwo\nthree")
  |> should.equal(3)
}

pub fn height_of_empty_string_is_one_test() {
  align.height("")
  |> should.equal(1)
}

pub fn size_returns_widest_visual_line_and_height_test() {
  let styled = ansi.red("wide")
  align.size("a\n" <> styled <> "\nmid")
  |> should.equal(#(4, 3))
}

pub fn truncate_plain_text_with_ellipsis_test() {
  align.truncate("abcdef", width: 4, ellipsis: "…")
  |> should.equal("abc…")
}

pub fn truncate_plain_text_without_truncation_test() {
  align.truncate("abc", width: 5, ellipsis: "…")
  |> should.equal("abc")
}

pub fn truncate_width_zero_is_empty_test() {
  align.truncate("abcdef", width: 0, ellipsis: "…")
  |> should.equal("")
}

pub fn truncate_trims_wide_ellipsis_to_fit_test() {
  align.truncate("abcdef", width: 2, ellipsis: "...")
  |> should.equal("..")
}

pub fn truncate_ansi_text_counts_visible_columns_test() {
  let text = "\u{001b}[31mred\u{001b}[0m blue"
  let result = align.truncate(text, width: 5, ellipsis: "…")

  should.be_true(string.contains(result, "\u{001b}[31m"))
  align.visual_length(result)
  |> should.equal(5)
}

pub fn truncate_closes_unclosed_sgr_before_ellipsis_test() {
  let opening = "\u{001b}[31m"

  align.truncate(opening <> "abcdef", width: 4, ellipsis: "…")
  |> should.equal(opening <> "abc\u{001b}[0m…")
}

pub fn truncate_osc_hyperlink_counts_only_visible_text_test() {
  let open = "\u{001b}]8;;https://example.com\u{001b}\\"
  let close = "\u{001b}]8;;\u{001b}\\"
  let result =
    align.truncate(open <> "abcdef" <> close, width: 4, ellipsis: "…")

  should.be_true(string.contains(result, open))
  should.be_true(string.contains(result, close))
  align.visual_length(result)
  |> should.equal(4)
  strip_terminal_escapes(result)
  |> should.equal("abc…")
}

pub fn wrap_words_test() {
  align.wrap("hello world from spruce", 11)
  |> should.equal("hello world\nfrom spruce")
}

pub fn wrap_preserves_spaces_when_no_wrap_is_needed_test() {
  align.wrap("  hello  world", 20)
  |> should.equal("  hello  world")
}

pub fn wrap_hard_wraps_long_words_test() {
  align.wrap("abcdefgh", 3)
  |> should.equal("abc\ndef\ngh")
}

pub fn wrap_keeps_wide_character_when_width_is_narrower_than_character_test() {
  align.wrap("日本", 1)
  |> should.equal("日\n本")
}

pub fn wrap_closes_unclosed_sgr_before_inserted_newline_test() {
  let opening = "\u{001b}[31m"

  align.wrap(opening <> "abcdef", 3)
  |> should.equal(opening <> "abc\u{001b}[0m\ndef")
}

pub fn wrap_preserves_ansi_escape_sequences_test() {
  let red = "\u{001b}[31mred\u{001b}[0m"

  align.wrap(red <> " blue", 4)
  |> should.equal(red <> "\nblue")
}

pub fn wrap_osc_hyperlink_counts_only_visible_text_test() {
  let open = "\u{001b}]8;;https://example.com\u{001b}\\"
  let close = "\u{001b}]8;;\u{001b}\\"
  let wrapped = align.wrap(open <> "abcdef" <> close, 3)

  should.be_true(string.contains(wrapped, open))
  should.be_true(string.contains(wrapped, close))
  strip_terminal_escapes(wrapped)
  |> should.equal("abc\ndef")

  string.split(wrapped, "\n")
  |> list.each(fn(line) { should.be_true(align.visual_length(line) <= 3) })
}

pub fn wrap_width_zero_returns_input_test() {
  align.wrap("hello world", 0)
  |> should.equal("hello world")
}

// Hard-wrapping a single styled token that is longer than the width (as happens
// when a width-constrained block contains highlighted code or long inline-styled
// text) must never split an ANSI escape sequence across a line break, and must
// preserve all visible characters.
pub fn wrap_hard_wrap_styled_word_keeps_escapes_intact_test() {
  // One green truecolor token wrapping a 26-letter body — longer than width 8.
  let opening = "\u{001b}[38;2;134;239;172m"
  let reset = "\u{001b}[39m"
  let styled = opening <> "abcdefghijklmnopqrstuvwxyz" <> reset

  let wrapped = align.wrap(styled, 8)

  // Every escape sequence remains well-formed: no ESC is left unterminated
  // before a newline or the end of the string.
  should.be_true(escapes_well_formed(string.to_graphemes(wrapped), False))

  // No information is lost: stripping ANSI and removing the inserted newlines
  // reconstructs exactly the original visible text.
  strip_terminal_escapes(wrapped)
  |> string.replace("\n", "")
  |> should.equal("abcdefghijklmnopqrstuvwxyz")

  // Each visible line respects the width.
  string.split(wrapped, "\n")
  |> list.each(fn(line) { should.be_true(align.visual_length(line) <= 8) })
}

fn escapes_well_formed(chars: List(String), in_escape: Bool) -> Bool {
  case chars, in_escape {
    [], False -> True
    // An escape that never reached its `m` terminator is malformed.
    [], True -> False
    // A newline (or a new ESC) before the terminator means the sequence was
    // split — the bug this test guards against.
    ["\n", ..], True -> False
    ["\u{001b}", ..], True -> False
    ["m", ..rest], True -> escapes_well_formed(rest, False)
    [_, ..rest], True -> escapes_well_formed(rest, True)
    ["\u{001b}", ..rest], False -> escapes_well_formed(rest, True)
    [_, ..rest], False -> escapes_well_formed(rest, False)
  }
}

type EscapeState {
  NormalText
  EscapeStart
  CsiEscape
  OscEscape
  OscEscapeAfterEsc
}

fn strip_terminal_escapes(text: String) -> String {
  strip_terminal_escapes_loop(string.to_graphemes(text), NormalText, "")
}

fn strip_terminal_escapes_loop(
  chars: List(String),
  state: EscapeState,
  acc: String,
) -> String {
  case chars {
    [] -> acc
    [char, ..rest] ->
      case state {
        NormalText ->
          case char {
            "\u{001b}" -> strip_terminal_escapes_loop(rest, EscapeStart, acc)
            _ -> strip_terminal_escapes_loop(rest, NormalText, acc <> char)
          }

        EscapeStart ->
          case char {
            "[" -> strip_terminal_escapes_loop(rest, CsiEscape, acc)
            "]" -> strip_terminal_escapes_loop(rest, OscEscape, acc)
            "\u{001b}" -> strip_terminal_escapes_loop(rest, EscapeStart, acc)
            _ -> strip_terminal_escapes_loop(rest, NormalText, acc)
          }

        CsiEscape ->
          case is_csi_final(char) {
            True -> strip_terminal_escapes_loop(rest, NormalText, acc)
            False -> strip_terminal_escapes_loop(rest, CsiEscape, acc)
          }

        OscEscape ->
          case char {
            "\u{0007}" -> strip_terminal_escapes_loop(rest, NormalText, acc)
            "\u{001b}" ->
              strip_terminal_escapes_loop(rest, OscEscapeAfterEsc, acc)
            _ -> strip_terminal_escapes_loop(rest, OscEscape, acc)
          }

        OscEscapeAfterEsc ->
          case char {
            "\\" -> strip_terminal_escapes_loop(rest, NormalText, acc)
            "\u{0007}" -> strip_terminal_escapes_loop(rest, NormalText, acc)
            "\u{001b}" ->
              strip_terminal_escapes_loop(rest, OscEscapeAfterEsc, acc)
            _ -> strip_terminal_escapes_loop(rest, OscEscape, acc)
          }
      }
  }
}

fn is_csi_final(grapheme: String) -> Bool {
  case string.to_utf_codepoints(grapheme) {
    [] -> False
    [codepoint, ..] -> {
      let codepoint = string.utf_codepoint_to_int(codepoint)
      codepoint >= 0x40 && codepoint <= 0x7e
    }
  }
}

pub fn join_vertical_start_pads_each_line_to_widest_block_test() {
  align.join_vertical(align.Start, ["a\nbb", "ccc"])
  |> should.equal("a  \nbb \nccc")
}

pub fn join_vertical_center_uses_visual_width_test() {
  let red = "\u{001b}[31mR\u{001b}[0m"

  align.join_vertical(align.Center, [red, "abc"])
  |> should.equal(" " <> red <> " \nabc")
}

pub fn join_horizontal_start_pads_lines_to_each_block_width_test() {
  align.join_horizontal(align.Start, ["a\nbbb", "x\ny"])
  |> should.equal("a  x\nbbby")
}

pub fn join_horizontal_end_places_shorter_blocks_at_bottom_test() {
  align.join_horizontal(align.End, ["a\nb", "XX"])
  |> should.equal("a  \nbXX")
}

pub fn join_horizontal_center_places_shorter_blocks_in_middle_test() {
  align.join_horizontal(align.Center, ["1\n2\n3", "XX"])
  |> should.equal("1  \n2XX\n3  ")
}

pub fn place_centers_content_horizontally_and_places_at_bottom_test() {
  align.place(
    width: 5,
    height: 3,
    horizontal: align.Center,
    vertical: align.End,
    content: "ab\ncde",
  )
  |> should.equal("     \n ab  \n cde ")
}

pub fn place_preserves_content_larger_than_region_test() {
  align.place(
    width: 2,
    height: 1,
    horizontal: align.End,
    vertical: align.End,
    content: "abcd\nef",
  )
  |> should.equal("abcd\n  ef")
}

pub fn layout_handles_large_flattened_and_repeated_lines_test() {
  let count = 20_000
  let blocks = list.repeat("x", times: count)

  align.join_vertical(align.Start, blocks)
  |> string.split("\n")
  |> list.length
  |> should.equal(count)

  let tall_block =
    list.repeat("y", times: count)
    |> string.join("\n")

  align.join_horizontal(align.End, ["x", tall_block])
  |> string.split("\n")
  |> list.length
  |> should.equal(count)
}
