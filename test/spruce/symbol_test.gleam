import spruce/symbol
import startest/expect

pub fn unicode_status_glyphs_test() {
  symbol.status(symbol.Unicode, symbol.Info)
  |> expect.to_equal("ℹ︎")
  symbol.status(symbol.Unicode, symbol.Success)
  |> expect.to_equal("✔")
  symbol.status(symbol.Unicode, symbol.Error)
  |> expect.to_equal("✖")
  symbol.status(symbol.Unicode, symbol.Warn)
  |> expect.to_equal("⚠")
  symbol.status(symbol.Unicode, symbol.Arrow)
  |> expect.to_equal("▸")
}

pub fn ascii_status_glyphs_test() {
  symbol.status(symbol.Ascii, symbol.Success)
  |> expect.to_equal("+")
  symbol.status(symbol.Ascii, symbol.Error)
  |> expect.to_equal("x")
  symbol.status(symbol.Ascii, symbol.Warn)
  |> expect.to_equal("!")
  symbol.status(symbol.Ascii, symbol.Bullet)
  |> expect.to_equal("-")
}
