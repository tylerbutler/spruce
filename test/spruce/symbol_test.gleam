import spruce/symbol
import startest/expect

pub fn info_glyph_test() {
  symbol.info
  |> expect.to_equal("ℹ")
}

pub fn success_glyph_test() {
  symbol.success
  |> expect.to_equal("✔")
}

pub fn error_glyph_test() {
  symbol.error
  |> expect.to_equal("✖")
}

pub fn ascii_fallback_test() {
  symbol.error_ascii
  |> expect.to_equal("x")
}

pub fn resolve_unicode_mode_test() {
  symbol.resolve(
    symbol.Unicode,
    unicode: symbol.success,
    ascii: symbol.success_ascii,
  )
  |> expect.to_equal("✔")
}

pub fn resolve_ascii_mode_test() {
  symbol.resolve(
    symbol.Ascii,
    unicode: symbol.success,
    ascii: symbol.success_ascii,
  )
  |> expect.to_equal("+")
}

pub fn resolve_named_status_glyphs_test() {
  symbol.status(symbol.Ascii, symbol.Success)
  |> expect.to_equal("+")

  symbol.status(symbol.Unicode, symbol.Warn)
  |> expect.to_equal("⚠")
}
