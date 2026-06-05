//// Syntax highlighting for source code using spruce styles.

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
pub opaque type Theme {
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
  case string.lowercase(name) {
    "bash" | "sh" | "shell" | "zsh" -> ok("bash", lang_bash.grammar())
    "c" -> ok("c", lang_c.grammar())
    "cpp" | "c++" -> ok("cpp", lang_cpp.grammar())
    "csharp" | "c#" | "cs" -> ok("csharp", lang_csharp.grammar())
    "css" -> ok("css", lang_css.grammar())
    "dart" -> ok("dart", lang_dart.grammar())
    "dockerfile" | "docker" -> ok("dockerfile", lang_dockerfile.grammar())
    "elixir" -> ok("elixir", lang_elixir.grammar())
    "erlang" -> ok("erlang", lang_erlang.grammar())
    "fsharp" -> ok("fsharp", lang_fsharp.grammar())
    "gleam" -> ok("gleam", lang_gleam.grammar())
    "go" | "golang" -> ok("go", lang_go.grammar())
    "haskell" -> ok("haskell", lang_haskell.grammar())
    "html" -> ok("html", lang_html.grammar())
    "java" -> ok("java", lang_java.grammar())
    "javascript" | "js" -> ok("javascript", lang_javascript.grammar())
    "json" -> ok("json", lang_json.grammar())
    "kotlin" | "kt" -> ok("kotlin", lang_kotlin.grammar())
    "lua" -> ok("lua", lang_lua.grammar())
    "markdown" | "md" -> ok("markdown", lang_markdown.grammar())
    "nginx" -> ok("nginx", lang_nginx.grammar())
    "php" -> ok("php", lang_php.grammar())
    "python" | "py" -> ok("python", lang_python.grammar())
    "razor" -> ok("razor", lang_razor.grammar())
    "reactjsx" | "jsx" -> ok("reactjsx", lang_reactjsx.grammar())
    "reacttsx" | "tsx" -> ok("reacttsx", lang_reacttsx.grammar())
    "ruby" | "rb" -> ok("ruby", lang_ruby.grammar())
    "rust" | "rs" -> ok("rust", lang_rust.grammar())
    "scala" -> ok("scala", lang_scala.grammar())
    "sql" -> ok("sql", lang_sql.grammar())
    "swift" -> ok("swift", lang_swift.grammar())
    "toml" -> ok("toml", lang_toml.grammar())
    "typescript" | "ts" -> ok("typescript", lang_typescript.grammar())
    "xml" -> ok("xml", lang_xml.grammar())
    "yaml" | "yml" -> ok("yaml", lang_yaml.grammar())
    "zig" -> ok("zig", lang_zig.grammar())
    _ -> Error(Nil)
  }
}

/// Highlight code with the default adaptive theme, or return code unchanged for
/// unknown languages.
pub fn highlight(sp: Spruce, code: String, name: String) -> String {
  highlight_named_with(sp, code, name, adaptive_theme())
}

/// Highlight code with a string language name and explicit theme.
pub fn highlight_named_with(
  sp: Spruce,
  code: String,
  name: String,
  theme: Theme,
) -> String {
  case language(name) {
    Ok(language) -> highlight_with(sp, code, language, theme)
    Error(Nil) -> code
  }
}

/// Highlight code with a resolved language and explicit theme.
pub fn highlight_with(
  sp: Spruce,
  code: String,
  language: Language,
  theme: Theme,
) -> String {
  smalto.to_tokens(code, language.grammar)
  |> list.map(render_token(sp, _, theme))
  |> string.join("")
}

fn ok(name: String, grammar: Grammar) -> Result(Language, Nil) {
  Ok(Language(name:, grammar:))
}

fn render_token(sp: Spruce, token: Token, theme: Theme) -> String {
  case token {
    token.Keyword(value) -> style.render(sp, theme.keyword, value)
    token.String(value) -> style.render(sp, theme.string, value)
    token.Number(value) -> style.render(sp, theme.number, value)
    token.Comment(value) -> style.render(sp, theme.comment, value)
    token.Function(value) -> style.render(sp, theme.function, value)
    token.Operator(value) -> style.render(sp, theme.operator, value)
    token.Punctuation(value) -> style.render(sp, theme.punctuation, value)
    token.Type(value) -> style.render(sp, theme.type_, value)
    token.Module(value) -> style.render(sp, theme.module_, value)
    token.Variable(value) -> style.render(sp, theme.variable, value)
    token.Constant(value) -> style.render(sp, theme.constant, value)
    token.Builtin(value) -> style.render(sp, theme.builtin, value)
    token.Tag(value) -> style.render(sp, theme.tag, value)
    token.Attribute(value) -> style.render(sp, theme.attribute, value)
    token.Selector(value) -> style.render(sp, theme.selector, value)
    token.Property(value) -> style.render(sp, theme.property, value)
    token.Regex(value) -> style.render(sp, theme.regex, value)
    token.Whitespace(value) | token.Other(value) | token.Custom(_, value) ->
      value
  }
}
