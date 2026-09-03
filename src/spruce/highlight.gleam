//// Syntax highlighting for source code using spruce styles.
////
//// Use `language` to resolve a canonical name or alias, `language_name` to
//// inspect the result, and `languages` to discover all supported names.

import gleam/list
import gleam/string
import smalto
import smalto/grammar.{type Grammar}
import smalto/languages/bash as lang_bash
import smalto/languages/c as lang_c
import smalto/languages/cpp as lang_cpp
import smalto/languages/csharp as lang_csharp
import smalto/languages/css as lang_css
import smalto/languages/dart as lang_dart
import smalto/languages/dockerfile as lang_dockerfile
import smalto/languages/elixir as lang_elixir
import smalto/languages/erlang as lang_erlang
import smalto/languages/fsharp as lang_fsharp
import smalto/languages/gleam as lang_gleam
import smalto/languages/go as lang_go
import smalto/languages/haskell as lang_haskell
import smalto/languages/html as lang_html
import smalto/languages/java as lang_java
import smalto/languages/javascript as lang_javascript
import smalto/languages/json as lang_json
import smalto/languages/kotlin as lang_kotlin
import smalto/languages/lua as lang_lua
import smalto/languages/markdown as lang_markdown
import smalto/languages/nginx as lang_nginx
import smalto/languages/php as lang_php
import smalto/languages/python as lang_python
import smalto/languages/razor as lang_razor
import smalto/languages/reactjsx as lang_reactjsx
import smalto/languages/reacttsx as lang_reacttsx
import smalto/languages/ruby as lang_ruby
import smalto/languages/rust as lang_rust
import smalto/languages/scala as lang_scala
import smalto/languages/sql as lang_sql
import smalto/languages/swift as lang_swift
import smalto/languages/toml as lang_toml
import smalto/languages/typescript as lang_typescript
import smalto/languages/xml as lang_xml
import smalto/languages/yaml as lang_yaml
import smalto/languages/zig as lang_zig
import smalto/token.{type Token}
import spruce.{type Spruce}
import spruce/style

/// A syntax highlighting theme for styled smalto token kinds.
///
/// Use a built-in theme as a base and replace selected fields:
///
/// ```gleam
/// highlight.Theme(
///   ..highlight.dark_theme(),
///   keyword: style.new() |> style.bold |> style.fg(style.Hex(0xff6b6b)),
/// )
/// ```
///
/// The public constructor also supports defining every style from scratch.
pub type Theme {
  Theme(
    keyword: style.Style,
    string: style.Style,
    number: style.Style,
    comment: style.Style,
    function: style.Style,
    operator: style.Style,
    punctuation: style.Style,
    type_: style.Style,
    module_: style.Style,
    variable: style.Style,
    constant: style.Style,
    builtin: style.Style,
    tag: style.Style,
    attribute: style.Style,
    selector: style.Style,
    property: style.Style,
    regex: style.Style,
  )
}

/// A resolved syntax language backed by a smalto grammar.
pub opaque type Language {
  Language(name: String, grammar: Grammar)
}

/// Build a syntax highlighting theme for dark terminal backgrounds.
pub fn dark_theme() -> Theme {
  Theme(
    keyword: style.new() |> style.bold |> style.fg(style.Hex(0xc4b5fd)),
    string: style.new() |> style.fg(style.Hex(0x86efac)),
    number: style.new() |> style.fg(style.Hex(0xfbbf24)),
    comment: style.new() |> style.dim |> style.fg(style.Hex(0x94a3b8)),
    function: style.new() |> style.fg(style.Hex(0x7dd3fc)),
    operator: style.new() |> style.fg(style.Hex(0xf0abfc)),
    punctuation: style.new() |> style.fg(style.Hex(0xcbd5e1)),
    type_: style.new() |> style.fg(style.Hex(0x67e8f9)),
    module_: style.new() |> style.fg(style.Hex(0x93c5fd)),
    variable: style.new() |> style.fg(style.Hex(0xe2e8f0)),
    constant: style.new() |> style.fg(style.Hex(0xfca5a5)),
    builtin: style.new() |> style.fg(style.Hex(0xf9a8d4)),
    tag: style.new() |> style.fg(style.Hex(0x60a5fa)),
    attribute: style.new() |> style.fg(style.Hex(0xfcd34d)),
    selector: style.new() |> style.fg(style.Hex(0xa7f3d0)),
    property: style.new() |> style.fg(style.Hex(0x93c5fd)),
    regex: style.new() |> style.fg(style.Hex(0xfda4af)),
  )
}

/// Build a syntax highlighting theme for light terminal backgrounds.
pub fn light_theme() -> Theme {
  Theme(
    keyword: style.new() |> style.bold |> style.fg(style.Hex(0x6d28d9)),
    string: style.new() |> style.fg(style.Hex(0x15803d)),
    number: style.new() |> style.fg(style.Hex(0x92400e)),
    comment: style.new() |> style.dim |> style.fg(style.Hex(0x64748b)),
    function: style.new() |> style.fg(style.Hex(0x0369a1)),
    operator: style.new() |> style.fg(style.Hex(0xa21caf)),
    punctuation: style.new() |> style.fg(style.Hex(0x475569)),
    type_: style.new() |> style.fg(style.Hex(0x0e7490)),
    module_: style.new() |> style.fg(style.Hex(0x1d4ed8)),
    variable: style.new() |> style.fg(style.Hex(0x334155)),
    constant: style.new() |> style.fg(style.Hex(0xbe123c)),
    builtin: style.new() |> style.fg(style.Hex(0xbe185d)),
    tag: style.new() |> style.fg(style.Hex(0x2563eb)),
    attribute: style.new() |> style.fg(style.Hex(0xb45309)),
    selector: style.new() |> style.fg(style.Hex(0x047857)),
    property: style.new() |> style.fg(style.Hex(0x1d4ed8)),
    regex: style.new() |> style.fg(style.Hex(0xbe123c)),
  )
}

/// Build the default syntax highlighting theme with adaptive light/dark colors.
pub fn adaptive_theme() -> Theme {
  let adapt = fn(light: Int, dark: Int) {
    style.adaptive(light: style.Hex(light), dark: style.Hex(dark))
  }
  Theme(
    keyword: style.new() |> style.bold |> style.fg(adapt(0x6d28d9, 0xc4b5fd)),
    string: style.new() |> style.fg(adapt(0x15803d, 0x86efac)),
    number: style.new() |> style.fg(adapt(0x92400e, 0xfbbf24)),
    comment: style.new() |> style.dim |> style.fg(adapt(0x64748b, 0x94a3b8)),
    function: style.new() |> style.fg(adapt(0x0369a1, 0x7dd3fc)),
    operator: style.new() |> style.fg(adapt(0xa21caf, 0xf0abfc)),
    punctuation: style.new() |> style.fg(adapt(0x475569, 0xcbd5e1)),
    type_: style.new() |> style.fg(adapt(0x0e7490, 0x67e8f9)),
    module_: style.new() |> style.fg(adapt(0x1d4ed8, 0x93c5fd)),
    variable: style.new() |> style.fg(adapt(0x334155, 0xe2e8f0)),
    constant: style.new() |> style.fg(adapt(0xbe123c, 0xfca5a5)),
    builtin: style.new() |> style.fg(adapt(0xbe185d, 0xf9a8d4)),
    tag: style.new() |> style.fg(adapt(0x2563eb, 0x60a5fa)),
    attribute: style.new() |> style.fg(adapt(0xb45309, 0xfcd34d)),
    selector: style.new() |> style.fg(adapt(0x047857, 0xa7f3d0)),
    property: style.new() |> style.fg(adapt(0x1d4ed8, 0x93c5fd)),
    regex: style.new() |> style.fg(adapt(0xbe123c, 0xfda4af)),
  )
}

/// Resolve a language name or alias to a smalto-backed language.
pub fn language(name: String) -> Result(Language, Nil) {
  let name = string.lowercase(name)
  case
    language_definitions()
    |> list.find(fn(definition) {
      name == definition.name || list.contains(definition.aliases, name)
    })
  {
    Ok(definition) -> ok(definition.name, definition.grammar())
    Error(Nil) -> Error(Nil)
  }
}

/// Return the canonical name for a resolved language.
pub fn language_name(language: Language) -> String {
  language.name
}

/// Return all supported canonical language names and their aliases.
///
/// Canonical names and aliases are in deterministic alphabetical order.
pub fn languages() -> List(#(String, List(String))) {
  language_definitions()
  |> list.map(fn(definition) { #(definition.name, definition.aliases) })
}

/// Highlight code with the default adaptive theme, or return code unchanged for
/// unknown languages.
pub fn highlight(
  context: Spruce,
  code code: String,
  name name: String,
) -> String {
  highlight_named_with(context, code:, name:, theme: adaptive_theme())
}

/// Highlight code with a string language name and explicit theme.
pub fn highlight_named_with(
  context: Spruce,
  code code: String,
  name name: String,
  theme theme: Theme,
) -> String {
  case language(name) {
    Ok(language) -> highlight_with(context, code, language, theme)
    Error(Nil) -> code
  }
}

/// Highlight code with a resolved language and explicit theme.
pub fn highlight_with(
  context: Spruce,
  code: String,
  language: Language,
  theme: Theme,
) -> String {
  smalto.to_tokens(code, language.grammar)
  |> list.map(render_token(context, _, theme))
  |> string.join("")
}

fn ok(name: String, grammar: Grammar) -> Result(Language, Nil) {
  Ok(Language(name:, grammar:))
}

type LanguageDefinition {
  LanguageDefinition(
    name: String,
    aliases: List(String),
    grammar: fn() -> Grammar,
  )
}

fn language_definitions() -> List(LanguageDefinition) {
  [
    LanguageDefinition("bash", ["sh", "shell", "zsh"], lang_bash.grammar),
    LanguageDefinition("c", [], lang_c.grammar),
    LanguageDefinition("cpp", ["c++"], lang_cpp.grammar),
    LanguageDefinition("csharp", ["c#", "cs"], lang_csharp.grammar),
    LanguageDefinition("css", [], lang_css.grammar),
    LanguageDefinition("dart", [], lang_dart.grammar),
    LanguageDefinition("dockerfile", ["docker"], lang_dockerfile.grammar),
    LanguageDefinition("elixir", [], lang_elixir.grammar),
    LanguageDefinition("erlang", [], lang_erlang.grammar),
    LanguageDefinition("fsharp", [], lang_fsharp.grammar),
    LanguageDefinition("gleam", [], lang_gleam.grammar),
    LanguageDefinition("go", ["golang"], lang_go.grammar),
    LanguageDefinition("haskell", [], lang_haskell.grammar),
    LanguageDefinition("html", [], lang_html.grammar),
    LanguageDefinition("java", [], lang_java.grammar),
    LanguageDefinition("javascript", ["js"], lang_javascript.grammar),
    LanguageDefinition("json", [], lang_json.grammar),
    LanguageDefinition("kotlin", ["kt"], lang_kotlin.grammar),
    LanguageDefinition("lua", [], lang_lua.grammar),
    LanguageDefinition("markdown", ["md"], lang_markdown.grammar),
    LanguageDefinition("nginx", [], lang_nginx.grammar),
    LanguageDefinition("php", [], lang_php.grammar),
    LanguageDefinition("python", ["py"], lang_python.grammar),
    LanguageDefinition("razor", [], lang_razor.grammar),
    LanguageDefinition("reactjsx", ["jsx"], lang_reactjsx.grammar),
    LanguageDefinition("reacttsx", ["tsx"], lang_reacttsx.grammar),
    LanguageDefinition("ruby", ["rb"], lang_ruby.grammar),
    LanguageDefinition("rust", ["rs"], lang_rust.grammar),
    LanguageDefinition("scala", [], lang_scala.grammar),
    LanguageDefinition("sql", [], lang_sql.grammar),
    LanguageDefinition("swift", [], lang_swift.grammar),
    LanguageDefinition("toml", [], lang_toml.grammar),
    LanguageDefinition("typescript", ["ts"], lang_typescript.grammar),
    LanguageDefinition("xml", [], lang_xml.grammar),
    LanguageDefinition("yaml", ["yml"], lang_yaml.grammar),
    LanguageDefinition("zig", [], lang_zig.grammar),
  ]
}

fn render_token(context: Spruce, token: Token, theme: Theme) -> String {
  case token {
    token.Keyword(value) -> style.render(context, theme.keyword, value)
    token.String(value) -> style.render(context, theme.string, value)
    token.Number(value) -> style.render(context, theme.number, value)
    token.Comment(value) -> style.render(context, theme.comment, value)
    token.Function(value) -> style.render(context, theme.function, value)
    token.Operator(value) -> style.render(context, theme.operator, value)
    token.Punctuation(value) -> style.render(context, theme.punctuation, value)
    token.Type(value) -> style.render(context, theme.type_, value)
    token.Module(value) -> style.render(context, theme.module_, value)
    token.Variable(value) -> style.render(context, theme.variable, value)
    token.Constant(value) -> style.render(context, theme.constant, value)
    token.Builtin(value) -> style.render(context, theme.builtin, value)
    token.Tag(value) -> style.render(context, theme.tag, value)
    token.Attribute(value) -> style.render(context, theme.attribute, value)
    token.Selector(value) -> style.render(context, theme.selector, value)
    token.Property(value) -> style.render(context, theme.property, value)
    token.Regex(value) -> style.render(context, theme.regex, value)
    token.Whitespace(value) | token.Other(value) | token.Custom(_, value) ->
      value
  }
}
