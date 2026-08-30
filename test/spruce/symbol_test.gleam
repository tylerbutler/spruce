import gleeunit/should
import spruce
import spruce/symbol

pub fn unicode_status_glyphs_test() {
  symbol.status(spruce.Unicode, symbol.Info)
  |> should.equal("ℹ︎")
  symbol.status(spruce.Unicode, symbol.Success)
  |> should.equal("✔")
  symbol.status(spruce.Unicode, symbol.Error)
  |> should.equal("✖")
  symbol.status(spruce.Unicode, symbol.Warn)
  |> should.equal("⚠")
  symbol.status(spruce.Unicode, symbol.Arrow)
  |> should.equal("▸")
}

pub fn ascii_status_glyphs_test() {
  symbol.status(spruce.Ascii, symbol.Success)
  |> should.equal("+")
  symbol.status(spruce.Ascii, symbol.Error)
  |> should.equal("x")
  symbol.status(spruce.Ascii, symbol.Warn)
  |> should.equal("!")
  symbol.status(spruce.Ascii, symbol.Bullet)
  |> should.equal("-")
}
