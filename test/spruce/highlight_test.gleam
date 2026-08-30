import gleam/string
import gleeunit/should
import spruce
import spruce/highlight
import spruce/style

pub fn no_color_round_trips_gleam_test() {
  let code = "pub fn main() {}"

  highlight.highlight(spruce.no_color(), code: code, name: "gleam")
  |> should.equal(code)
}

pub fn colored_output_contains_escape_and_source_test() {
  let code = "pub fn main() {}"
  let rendered =
    highlight.highlight(
      spruce.with_color_level(spruce.TrueColor),
      code: code,
      name: "gleam",
    )

  should.be_true(string.contains(rendered, "\u{001b}"))
  should.be_true(string.contains(rendered, "main"))
}

pub fn unknown_language_falls_back_to_plain_code_test() {
  highlight.highlight(spruce.no_color(), code: "whatever", name: "not-a-lang")
  |> should.equal("whatever")
}

pub fn language_aliases_resolve_test() {
  should.be_true(result_is_ok(highlight.language("js")))
  should.be_true(result_is_ok(highlight.language("PY")))
  should.be_true(result_is_ok(highlight.language("c++")))
  should.be_true(result_is_ok(highlight.language("rs")))
  should.equal(highlight.language("bogus"), Error(Nil))
}

pub fn no_color_preserves_multiline_whitespace_test() {
  let code = "pub fn main() {\n  let x = 1\n  x\n}\n"

  highlight.highlight(spruce.no_color(), code: code, name: "gleam")
  |> should.equal(code)
}

pub fn theme_constructors_work_with_language_test() {
  let code = "pub fn main() {}"
  let assert_theme = fn(theme) {
    let assert Ok(lang) = highlight.language("gleam")

    highlight.highlight_with(spruce.no_color(), code, lang, theme)
    |> should.equal(code)
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
  |> should.equal(code)
}

pub fn theme_fields_can_be_overridden_test() {
  let theme =
    highlight.Theme(
      ..highlight.dark_theme(),
      keyword: style.new() |> style.fg(style.Red),
    )
  let rendered =
    highlight.highlight_named_with(
      spruce.with_color_level(spruce.Basic),
      code: "pub",
      name: "gleam",
      theme:,
    )

  should.equal(rendered, "\u{001b}[31mpub\u{001b}[39m")
}

pub fn custom_theme_can_be_constructed_test() {
  let plain = style.new()
  let theme =
    highlight.Theme(
      keyword: plain,
      string: plain,
      number: plain,
      comment: plain,
      function: plain,
      operator: plain,
      punctuation: plain,
      type_: plain,
      module_: plain,
      variable: plain,
      constant: plain,
      builtin: plain,
      tag: plain,
      attribute: plain,
      selector: plain,
      property: plain,
      regex: plain,
    )

  highlight.highlight_named_with(
    spruce.with_color_level(spruce.TrueColor),
    code: "pub fn main() {}",
    name: "gleam",
    theme:,
  )
  |> should.equal("pub fn main() {}")
}

fn result_is_ok(result: Result(a, b)) -> Bool {
  case result {
    Ok(_) -> True
    // nolint: thrown_away_error -- predicate intentionally ignores the error
    Error(_) -> False
  }
}
