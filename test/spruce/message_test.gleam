import gleam/string
import spruce
import spruce/details
import spruce/message
import spruce/symbol
import startest/expect
import tty

pub fn success_no_color_test() {
  spruce.no_color()
  |> message.success("done")
  |> expect.to_equal("✔ success done")
}

pub fn fail_no_color_test() {
  spruce.no_color()
  |> message.fail("nope")
  |> expect.to_equal("✖ fail nope")
}

pub fn warn_indented_test() {
  spruce.no_color()
  |> spruce.indented
  |> message.warn("careful")
  |> expect.to_equal("  ⚠ warn careful")
}

pub fn info_no_color_test() {
  spruce.no_color()
  |> message.info("noted")
  |> expect.to_equal("ℹ info noted")
}

pub fn success_color_has_escapes_test() {
  let out = message.success(spruce.with_color_level(tty.TrueColor), "done")
  expect.to_be_true(string.contains(out, "\u{001b}"))
}

pub fn message_with_details_test() {
  let details =
    details.new()
    |> details.add(key: "duration", value: "42ms")

  let options =
    message.default_options()
    |> message.with_details(details)

  message.line_with(spruce.no_color(), message.Success, "done", options)
  |> expect.to_equal("✔ success done duration=42ms")
}

pub fn message_with_ascii_glyphs_test() {
  let options =
    message.default_options()
    |> message.with_symbol_mode(symbol.Ascii)

  message.line_with(spruce.no_color(), message.Warn, "careful", options)
  |> expect.to_equal("! warn careful")
}

pub fn existing_message_helpers_stay_unchanged_test() {
  message.success(spruce.no_color(), "done")
  |> expect.to_equal("✔ success done")
}

pub fn message_with_badge_formatter_test() {
  let options =
    message.default_options()
    |> message.with_formatter(message.badge())

  message.line_with(spruce.no_color(), message.Success, "done", options)
  |> expect.to_equal("[SUCCESS] done")
}

pub fn message_with_simple_formatter_test() {
  let options =
    message.default_options()
    |> message.with_formatter(message.simple())

  message.line_with(spruce.no_color(), message.Fail, "nope", options)
  |> expect.to_equal("FAIL nope")
}

pub fn message_formatter_keeps_symbol_mode_authoritative_test() {
  let options =
    message.default_options()
    |> message.with_symbol_mode(symbol.Ascii)
    |> message.with_formatter(message.label())

  message.line_with(spruce.no_color(), message.Warn, "careful", options)
  |> expect.to_equal("! warn careful")
}

pub fn message_formatter_with_details_test() {
  let details =
    details.new()
    |> details.add(key: "duration", value: "42ms")

  let options =
    message.default_options()
    |> message.with_formatter(message.badge())
    |> message.with_details(details)

  message.line_with(spruce.no_color(), message.Ready, "listening", options)
  |> expect.to_equal("[READY] listening duration=42ms")
}

pub fn message_with_custom_formatter_test() {
  let options =
    message.default_options()
    |> message.with_formatter(
      message.custom(fn(kind, _sp) {
        case kind {
          message.Start -> "BEGIN"
          _ -> "OTHER"
        }
      }),
    )

  message.line_with(spruce.no_color(), message.Start, "build", options)
  |> expect.to_equal("BEGIN build")
}

pub fn semantic_with_helpers_use_options_test() {
  let options =
    message.default_options()
    |> message.with_formatter(message.badge())

  expect.to_equal(
    message.success_with(spruce.no_color(), "done", options),
    "[SUCCESS] done",
  )
  expect.to_equal(
    message.fail_with(spruce.no_color(), "nope", options),
    "[FAIL] nope",
  )
  expect.to_equal(
    message.start_with(spruce.no_color(), "build", options),
    "[START] build",
  )
  expect.to_equal(
    message.ready_with(spruce.no_color(), "listening", options),
    "[READY] listening",
  )
  expect.to_equal(
    message.info_with(spruce.no_color(), "noted", options),
    "[INFO] noted",
  )
  expect.to_equal(
    message.warn_with(spruce.no_color(), "careful", options),
    "[WARN] careful",
  )
  expect.to_equal(
    message.error_with(spruce.no_color(), "broken", options),
    "[ERROR] broken",
  )
}
