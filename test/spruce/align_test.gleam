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

pub fn visual_length_counts_bmp_wide_emoji_as_two_columns_test() {
  ["✅", "❌", "✨", "⭐", "⚡", "☕"]
  |> list.each(fn(emoji) {
    align.visual_length(emoji) |> should.equal(2)
    align.visual_length(ansi.red(emoji)) |> should.equal(2)
  })
}

pub fn visual_length_bmp_emoji_range_boundaries_test() {
  let ranges = [
    #(0x231a, 0x231b),
    #(0x23e9, 0x23ec),
    #(0x23f0, 0x23f0),
    #(0x23f3, 0x23f3),
    #(0x25fd, 0x25fe),
    #(0x2614, 0x2615),
    #(0x2648, 0x2653),
    #(0x267f, 0x267f),
    #(0x2693, 0x2693),
    #(0x26a1, 0x26a1),
    #(0x26aa, 0x26ab),
    #(0x26bd, 0x26be),
    #(0x26c4, 0x26c5),
    #(0x26ce, 0x26ce),
    #(0x26d4, 0x26d4),
    #(0x26ea, 0x26ea),
    #(0x26f2, 0x26f3),
    #(0x26f5, 0x26f5),
    #(0x26fa, 0x26fa),
    #(0x26fd, 0x26fd),
    #(0x2705, 0x2705),
    #(0x270a, 0x270b),
    #(0x2728, 0x2728),
    #(0x274c, 0x274c),
    #(0x274e, 0x274e),
    #(0x2753, 0x2755),
    #(0x2757, 0x2757),
    #(0x2795, 0x2797),
    #(0x27b0, 0x27b0),
    #(0x27bf, 0x27bf),
    #(0x2b1b, 0x2b1c),
    #(0x2b50, 0x2b50),
    #(0x2b55, 0x2b55),
  ]

  list.each(ranges, fn(range) {
    let #(first, last) = range
    list.each([first, last, first - 1, last + 1], fn(value) {
      let assert Ok(codepoint) = string.utf_codepoint(value)
      let expected = case value >= first && value <= last {
        True -> 2
        False -> 1
      }
      string.from_utf_codepoints([codepoint])
      |> align.visual_length
      |> should.equal(expected)
    })
  })
}

pub fn visual_length_counts_zero_width_graphemes_as_zero_test() {
  align.visual_length("e\u{0301}\u{200b}\u{0301}")
  |> should.equal(1)
}

pub fn visual_length_counts_flag_pair_as_two_columns_test() {
  align.visual_length("🇺🇸")
  |> should.equal(2)
}

pub fn visual_length_counts_emoji_presentation_as_two_columns_test() {
  align.visual_length("☺️")
  |> should.equal(2)
}

pub fn visual_length_terminates_non_sgr_csi_escape_test() {
  align.visual_length("\u{001b}[2Jabc")
  |> should.equal(3)
}

pub fn visual_length_ignores_general_escape_sequence_test() {
  align.visual_length("\u{001b}(Babc")
  |> should.equal(3)
}

pub fn visual_length_ignores_st_control_string_test() {
  align.visual_length("\u{001b}Pignored\u{001b}\\abc")
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

pub fn padding_uses_bmp_emoji_width_test() {
  align.pad_right("✅", 4) |> should.equal("✅  ")
  align.pad_left("❌", 4) |> should.equal("  ❌")
  align.pad_center("⭐", 5) |> should.equal(" ⭐  ")
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

pub fn truncate_uses_bmp_emoji_width_test() {
  align.truncate("✅done", width: 3, ellipsis: "…")
  |> should.equal("✅…")
  align.truncate("✅done", width: 1, ellipsis: "")
  |> should.equal("")
  align.truncate("abcdef", width: 3, ellipsis: "⭐")
  |> should.equal("a⭐")
  align.truncate("abcdef", width: 1, ellipsis: "⭐")
  |> should.equal("")
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

pub fn truncate_does_not_treat_truecolor_zero_as_reset_test() {
  let opening = "\u{001b}[38;2;0;0;0m"

  align.truncate(opening <> "abcdef", width: 4, ellipsis: "…")
  |> should.equal(opening <> "abc\u{001b}[0m…")
}

pub fn truncate_preserves_partial_sgr_reset_test() {
  let bold_red = "\u{001b}[1;31m"
  let foreground_reset = "\u{001b}[39m"

  align.truncate(
    bold_red <> "ab" <> foreground_reset <> "cdef",
    width: 4,
    ellipsis: "…",
  )
  |> should.equal(bold_red <> "ab" <> foreground_reset <> "c\u{001b}[0m…")
}

pub fn truncate_preserves_explicit_trailing_foreground_reset_test() {
  let opening = "\u{001b}[31m"
  let foreground_reset = "\u{001b}[39m"

  align.truncate(
    opening <> "abcdef" <> foreground_reset,
    width: 4,
    ellipsis: "…",
  )
  |> should.equal(opening <> "abc" <> foreground_reset <> "…")
}

pub fn truncate_closes_unclosed_osc_hyperlink_test() {
  let open = "\u{001b}]8;;https://example.com\u{001b}\\"
  let close = "\u{001b}]8;;\u{001b}\\"

  align.truncate(open <> "abcdef", width: 4, ellipsis: "…")
  |> should.equal(open <> "abc" <> close <> "…")
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

  align.wrap("\u{001b}[31m  hi  \u{001b}[0m", 8)
  |> should.equal("\u{001b}[31m  hi  \u{001b}[0m")
}

pub fn wrap_preserves_trailing_spaces_at_physical_line_end_test() {
  align.wrap("a  \n   ", 80)
  |> should.equal("a  \n   ")
}

pub fn wrap_drops_overflow_trailing_spaces_without_an_extra_line_test() {
  let opening = "\u{001b}[31m"

  align.wrap(opening <> "hello     ", 5)
  |> should_equal_with_foreground_close(fn(close) {
    opening <> "hello" <> close
  })
}

pub fn wrap_drops_space_only_prefix_before_a_word_that_needs_wrapping_test() {
  [" ", "   ", "      "]
  |> list.each(fn(prefix) {
    align.wrap(prefix <> "abcdefghij", 5)
    |> should.equal("abcde\nfghij")

    align.wrap(prefix <> "abcde", 5)
    |> should.equal("abcde")
  })
}

pub fn wrap_keeps_controls_when_dropping_an_oversized_word_prefix_test() {
  let opening = "\u{001b}[31m"
  let cursor = "\u{001b}[2K"

  align.wrap(" " <> opening <> " " <> cursor <> "abcdefghij", 5)
  |> should_equal_with_foreground_close(fn(close) {
    opening <> cursor <> "abcde" <> close <> "\n" <> opening <> "fghij" <> close
  })
}

pub fn wrap_overflow_spaces_still_separate_the_next_word_test() {
  align.wrap("ab      c", 5)
  |> should.equal("ab\nc")
}

pub fn wrap_preserves_physical_blank_lines_and_trailing_newlines_test() {
  let opening = "\u{001b}[31m"

  align.wrap(opening <> "hello     \n\n   \nworld\n", 5)
  |> should_equal_with_foreground_close(fn(close) {
    string.join(
      [
        opening <> "hello" <> close,
        opening <> close,
        opening <> "   " <> close,
        opening <> "world" <> close,
        opening <> close,
      ],
      "\n",
    )
  })

  align.wrap("\n      \n\n", 5)
  |> should.equal("\n     \n\n")

  align.wrap(opening <> "      \n\nx", 5)
  |> should_equal_with_foreground_close(fn(close) {
    string.join(
      [opening <> "     " <> close, opening <> close, opening <> "x" <> close],
      "\n",
    )
  })
}

pub fn wrap_keeps_control_only_suffix_effects_and_state_test() {
  let opening = "\u{001b}[31m"
  let green = "\u{001b}[32m"
  let reset = "\u{001b}[0m"
  let cursor = "\u{001b}[2K"
  let open = "\u{001b}]8;;https://example.com\u{001b}\\"
  let close = "\u{001b}]8;;\u{001b}\\"

  align.wrap(opening <> "hello     " <> reset <> cursor, 5)
  |> should.equal(opening <> "hello" <> reset <> cursor)

  align.wrap(open <> "hello     " <> close <> cursor, 5)
  |> should.equal(open <> "hello" <> close <> cursor)

  align.wrap(open <> "hello     \n\nx" <> close, 5)
  |> should.equal(string.join(
    [open <> "hello" <> close, open <> close, open <> "x" <> close],
    "\n",
  ))

  align.wrap(open <> "      " <> close <> cursor <> green <> "\n\nx", 5)
  |> should_equal_with_foreground_close(fn(synthetic_close) {
    string.join(
      [
        open <> "     " <> close <> cursor <> green <> synthetic_close,
        green <> synthetic_close,
        green <> "x" <> synthetic_close,
      ],
      "\n",
    )
  })

  align.wrap(opening <> "hello     " <> green <> "\n\nx", 5)
  |> should_equal_with_foreground_close(fn(close) {
    string.join(
      [
        opening <> "hello" <> green <> close,
        green <> close,
        green <> "x" <> close,
      ],
      "\n",
    )
  })
}

fn should_equal_with_foreground_close(
  actual: String,
  expected: fn(String) -> String,
) -> Nil {
  // Both full and foreground-only synthetic resets close these foreground styles.
  list.contains([expected("\u{001b}[0m"), expected("\u{001b}[39m")], actual)
  |> should.be_true
}

pub fn wrap_hard_wraps_long_words_test() {
  align.wrap("abcdefgh", 3)
  |> should.equal("abc\ndef\ngh")
}

pub fn wrap_keeps_wide_character_when_width_is_narrower_than_character_test() {
  align.wrap("日本", 1)
  |> should.equal("日\n本")
}

pub fn wrap_uses_bmp_emoji_width_test() {
  align.wrap("✅ ok ⭐", 4) |> should.equal("✅\nok\n⭐")
  align.wrap("✅❌✨⭐", 4) |> should.equal("✅❌\n✨⭐")
  align.wrap("✅❌", 1) |> should.equal("✅\n❌")
}

pub fn wrap_closes_unclosed_sgr_before_inserted_newline_test() {
  let opening = "\u{001b}[31m"

  align.wrap(opening <> "abcdef", 3)
  |> should.equal(opening <> "abc\u{001b}[0m\n" <> opening <> "def\u{001b}[0m")
}

pub fn wrap_reopens_sgr_after_hard_wrap_test() {
  let opening = "\u{001b}[31m"
  let reset = "\u{001b}[0m"

  align.wrap(opening <> "abcdef" <> reset, 3)
  |> should.equal(
    opening <> "abc" <> reset <> "\n" <> opening <> "def" <> reset,
  )
}

pub fn wrap_reopens_sgr_after_word_wrap_test() {
  let opening = "\u{001b}[31m"
  let reset = "\u{001b}[0m"

  align.wrap(opening <> "abc def" <> reset, 3)
  |> should.equal(
    opening <> "abc" <> reset <> "\n" <> opening <> "def" <> reset,
  )
}

pub fn wrap_reopens_bold_and_dim_in_input_order_test() {
  let bold = "\u{001b}[1m"
  let dim = "\u{001b}[2m"
  let reset = "\u{001b}[0m"

  list.each([bold <> dim, dim <> bold], fn(opening) {
    list.each(["abc def", "abcdef", "abc\ndef"], fn(text) {
      let assert [first, second] =
        align.wrap(opening <> text <> reset, 3) |> string.split("\n")
      should.be_true(string.starts_with(first, opening <> "abc"))
      second |> should.equal(opening <> "def" <> reset)
    })
  })
}

pub fn wrap_reopens_combined_bold_and_dim_parameters_test() {
  let reset = "\u{001b}[0m"

  list.each(
    [
      #("\u{001b}[1;2m", "\u{001b}[1m\u{001b}[2m"),
      #("\u{001b}[2;1m", "\u{001b}[2m\u{001b}[1m"),
    ],
    fn(pair) {
      let #(opening, reopening) = pair
      list.each(["abc def", "abcdef", "abc\ndef"], fn(text) {
        let assert [first, second] =
          align.wrap(opening <> text <> reset, 3) |> string.split("\n")
        should.be_true(string.starts_with(first, opening <> "abc"))
        second |> should.equal(reopening <> "def" <> reset)
      })
    },
  )
}

pub fn wrap_intensity_reset_clears_bold_and_dim_but_keeps_other_styles_test() {
  let red = "\u{001b}[31m"
  let italic = "\u{001b}[3m"
  let reset = "\u{001b}[0m"

  list.each(["1;2", "2;1"], fn(parameters) {
    let opening = "\u{001b}[" <> parameters <> "m"
    let assert [first, second] =
      align.wrap(red <> opening <> italic <> "abc\u{001b}[22m\ndef" <> reset, 3)
      |> string.split("\n")
    should.be_true(string.starts_with(
      first,
      red <> opening <> italic <> "abc\u{001b}[22m",
    ))
    second |> should.equal(red <> italic <> "def" <> reset)
  })
}

pub fn wrap_full_reset_clears_bold_and_dim_test() {
  list.each(["\u{001b}[0m", "\u{001b}[m", "\u{001b}[22m"], fn(reset) {
    align.wrap("\u{001b}[1;2mabc" <> reset <> "\ndef", 3)
    |> should.equal("\u{001b}[1;2mabc" <> reset <> "\ndef")
  })
}

pub fn wrap_can_enable_either_attribute_after_intensity_reset_test() {
  list.each(["1", "2"], fn(parameter) {
    let opening = "\u{001b}[" <> parameter <> "m"
    let assert [first, second] =
      align.wrap("\u{001b}[1;2;22;" <> parameter <> "mabc\ndef", 3)
      |> string.split("\n")
    should.be_true(string.starts_with(
      first,
      "\u{001b}[1;2;22;" <> parameter <> "mabc",
    ))
    should.be_true(string.starts_with(second, opening <> "def"))
  })
}

pub fn wrap_word_boundary_preserves_reset_after_space_test() {
  let opening = "\u{001b}[31m"
  let reset = "\u{001b}[0m"

  align.wrap(opening <> "abc " <> reset <> "def", 3)
  |> should.equal(opening <> "abc" <> reset <> "\ndef")
}

pub fn wrap_carries_sgr_across_physical_newline_test() {
  let opening = "\u{001b}[31m"
  let reset = "\u{001b}[39m"

  align.wrap(opening <> "abc\ndef" <> reset <> "\nplain", 80)
  |> should.equal(
    opening <> "abc\u{001b}[0m\n" <> opening <> "def" <> reset <> "\nplain",
  )
}

pub fn wrap_carries_osc_hyperlink_across_physical_newline_test() {
  let open = "\u{001b}]8;;https://example.com\u{001b}\\"
  let close = "\u{001b}]8;;\u{001b}\\"

  align.wrap(open <> "abc\ndef" <> close <> "\nplain", 80)
  |> should.equal(
    open <> "abc" <> close <> "\n" <> open <> "def" <> close <> "\nplain",
  )
}

pub fn wrap_carries_sgr_across_empty_physical_line_test() {
  let opening = "\u{001b}[31m"
  let reset = "\u{001b}[39m"

  align.wrap(opening <> "a\n\nb" <> reset, 80)
  |> should.equal(
    opening
    <> "a\u{001b}[0m\n"
    <> opening
    <> "\u{001b}[0m\n"
    <> opening
    <> "b"
    <> reset,
  )
}

pub fn wrap_carries_sgr_across_physical_and_inserted_wraps_test() {
  let opening = "\u{001b}[31m"
  let reset = "\u{001b}[39m"

  align.wrap(opening <> "abcd\nef" <> reset <> "\nplain", 2)
  |> should.equal(
    opening
    <> "ab\u{001b}[0m\n"
    <> opening
    <> "cd\u{001b}[0m\n"
    <> opening
    <> "ef"
    <> reset
    <> "\npl\nai\nn",
  )
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

  wrapped
  |> should.equal(open <> "abc" <> close <> "\n" <> open <> "def" <> close)
  strip_terminal_escapes(wrapped)
  |> should.equal("abc\ndef")

  string.split(wrapped, "\n")
  |> list.each(fn(line) { should.be_true(align.visual_length(line) <= 3) })
}

pub fn wrap_width_zero_returns_input_test() {
  align.wrap("hello world", 0)
  |> should.equal("hello world")
}

pub fn wrap_large_unbroken_word_in_one_pass_test() {
  let text = string.repeat("a", 40_000)
  let wrapped = align.wrap(text, 80)

  wrapped
  |> string.replace("\n", "")
  |> should.equal(text)
  wrapped
  |> string.split("\n")
  |> list.length
  |> should.equal(500)
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
  EscapeIntermediate
  CsiEscape
  OscEscape
  OscEscapeAfterEsc
  StEscape
  StEscapeAfterEsc
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
            "P" | "X" | "^" | "_" ->
              strip_terminal_escapes_loop(rest, StEscape, acc)
            "\u{001b}" -> strip_terminal_escapes_loop(rest, EscapeStart, acc)
            _ ->
              case is_escape_intermediate(char) {
                True ->
                  strip_terminal_escapes_loop(rest, EscapeIntermediate, acc)
                False -> strip_terminal_escapes_loop(rest, NormalText, acc)
              }
          }

        EscapeIntermediate ->
          case is_escape_final_byte(char) {
            True -> strip_terminal_escapes_loop(rest, NormalText, acc)
            False -> strip_terminal_escapes_loop(rest, EscapeIntermediate, acc)
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

        StEscape ->
          case char {
            "\u{001b}" ->
              strip_terminal_escapes_loop(rest, StEscapeAfterEsc, acc)
            _ -> strip_terminal_escapes_loop(rest, StEscape, acc)
          }

        StEscapeAfterEsc ->
          case char {
            "\\" -> strip_terminal_escapes_loop(rest, NormalText, acc)
            "\u{001b}" ->
              strip_terminal_escapes_loop(rest, StEscapeAfterEsc, acc)
            _ -> strip_terminal_escapes_loop(rest, StEscape, acc)
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

fn is_escape_intermediate(grapheme: String) -> Bool {
  codepoint_in_range(grapheme, 0x20, 0x2f)
}

fn is_escape_final_byte(grapheme: String) -> Bool {
  codepoint_in_range(grapheme, 0x30, 0x7e)
}

fn codepoint_in_range(grapheme: String, first: Int, last: Int) -> Bool {
  case string.to_utf_codepoints(grapheme) {
    [] -> False
    [codepoint, ..] -> {
      let codepoint = string.utf_codepoint_to_int(codepoint)
      codepoint >= first && codepoint <= last
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
