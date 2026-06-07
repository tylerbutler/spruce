import gleam/string
import spruce
import spruce/highlight
import startest/expect
import tty

pub fn no_color_round_trips_gleam_test() {
  let code = "pub fn main() {}"

  highlight.highlight(spruce.no_color(), code: code, name: "gleam")
  |> expect.to_equal(code)
}

pub fn colored_output_contains_escape_and_source_test() {
  let code = "pub fn main() {}"
  let out =
    highlight.highlight(
      spruce.with_color_level(tty.TrueColor),
      code: code,
      name: "gleam",
    )

  expect.to_be_true(string.contains(out, "\u{001b}"))
  expect.to_be_true(string.contains(out, "main"))
}

pub fn unknown_language_falls_back_to_plain_code_test() {
  highlight.highlight(spruce.no_color(), code: "whatever", name: "not-a-lang")
  |> expect.to_equal("whatever")
}

pub fn language_aliases_resolve_test() {
  expect.to_be_true(result_is_ok(highlight.language("js")))
  expect.to_be_true(result_is_ok(highlight.language("PY")))
  expect.to_be_true(result_is_ok(highlight.language("c++")))
  expect.to_be_true(result_is_ok(highlight.language("rs")))
  expect.to_equal(highlight.language("bogus"), Error(Nil))
}

pub fn no_color_preserves_multiline_whitespace_test() {
  let code = "pub fn main() {\n  let x = 1\n  x\n}\n"

  highlight.highlight(spruce.no_color(), code: code, name: "gleam")
  |> expect.to_equal(code)
}

pub fn theme_constructors_work_with_language_test() {
  let code = "pub fn main() {}"
  let assert_theme = fn(theme) {
    let assert Ok(lang) = highlight.language("gleam")

    highlight.highlight_with(spruce.no_color(), code, lang, theme)
    |> expect.to_equal(code)
  }

  assert_theme(highlight.dark_theme())
  assert_theme(highlight.light_theme())
  assert_theme(highlight.adaptive_theme())
}

pub fn named_custom_theme_path_works_test() {
  let code = "let x = 1"

  highlight.highlight_named_with(
    spruce.no_color(),
    code: code,
    name: "gleam",
    theme: highlight.dark_theme(),
  )
  |> expect.to_equal(code)
}

fn result_is_ok(result: Result(a, b)) -> Bool {
  case result {
    Ok(_) -> True
    // nolint: thrown_away_error -- predicate intentionally ignores the error
    Error(_) -> False
  }
}
