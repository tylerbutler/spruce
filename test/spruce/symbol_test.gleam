import gleeunit/should
import spruce/symbol

pub fn unicode_status_glyphs_test() {
  symbol.status(symbol.Unicode, symbol.Info)
  |> should.equal("ℹ︎")
  symbol.status(symbol.Unicode, symbol.Success)
  |> should.equal("✔")
  symbol.status(symbol.Unicode, symbol.Error)
  |> should.equal("✖")
  symbol.status(symbol.Unicode, symbol.Warn)
  |> should.equal("⚠")
  symbol.status(symbol.Unicode, symbol.Arrow)
  |> should.equal("▸")
}

pub fn ascii_status_glyphs_test() {
  symbol.status(symbol.Ascii, symbol.Success)
  |> should.equal("+")
  symbol.status(symbol.Ascii, symbol.Error)
  |> should.equal("x")
  symbol.status(symbol.Ascii, symbol.Warn)
  |> should.equal("!")
  symbol.status(symbol.Ascii, symbol.Bullet)
  |> should.equal("-")
}
