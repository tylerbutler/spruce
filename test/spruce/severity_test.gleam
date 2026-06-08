import gleam/list
import gleam/string
import spruce
import spruce/severity
import spruce/symbol
import startest/expect
import tty

pub fn label_formatter_no_color_test() {
  severity.render(spruce.no_color(), severity.label(), severity.Info)
  |> expect.to_equal("ℹ info")
}

pub fn label_formatter_ascii_no_color_test() {
  let formatter = severity.label() |> severity.mode(symbol.Ascii)

  severity.render(spruce.no_color(), formatter, severity.Warn)
  |> expect.to_equal("! warn")
}

pub fn label_formatter_without_icons_test() {
  let formatter = severity.label() |> severity.icons(False)

  severity.render(spruce.no_color(), formatter, severity.Critical)
  |> expect.to_equal("critical")
}

pub fn label_formatter_without_icons_target_width_test() {
  severity.label()
  |> severity.icons(False)
  |> severity.target_width
  |> expect.to_equal(8)
}

pub fn badge_formatter_no_color_test() {
  severity.render(spruce.no_color(), severity.badge(), severity.Warn)
  |> expect.to_equal("[WARN]")
}

pub fn simple_formatter_no_color_test() {
  severity.render(spruce.no_color(), severity.simple(), severity.Debug)
  |> expect.to_equal("DEBUG")
}

pub fn padded_label_formatter_uses_visual_width_test() {
  severity.render_padded(spruce.no_color(), severity.label(), severity.Info)
  |> expect.to_equal("ℹ info    ")
}

pub fn color_formatter_emits_escapes_test() {
  let out =
    severity.render(
      spruce.with_color_level(tty.TrueColor),
      severity.label(),
      severity.Err,
    )

  expect.to_be_true(string.contains(out, "\u{001b}"))
  expect.to_be_true(string.contains(out, "error"))
}

pub fn notice_label_uses_cyan_test() {
  let out =
    severity.render(
      spruce.with_color_level(tty.Basic),
      severity.label(),
      severity.Notice,
    )

  expect.to_be_true(string.contains(out, "\u{001b}[36m"))
  expect.to_be_false(string.contains(out, "\u{001b}[34m"))
}

pub fn alert_label_uses_bright_red_test() {
  let out =
    severity.render(
      spruce.with_color_level(tty.Basic),
      severity.label(),
      severity.Alert,
    )

  expect.to_be_true(string.contains(out, "\u{001b}[91m"))
  expect.to_be_false(string.contains(out, "\u{001b}[35m"))
}

pub fn colored_badge_is_bold_test() {
  let out =
    severity.render(
      spruce.with_color_level(tty.Basic),
      severity.badge(),
      severity.Warn,
    )

  expect.to_be_true(string.contains(out, "\u{001b}[1m"))
  expect.to_be_true(string.contains(out, "[WARN]"))
}

pub fn all_rfc5424_levels_are_retained_test() {
  [
    severity.Trace,
    severity.Debug,
    severity.Info,
    severity.Notice,
    severity.Warn,
    severity.Err,
    severity.Critical,
    severity.Alert,
    severity.Fatal,
  ]
  |> list.map(severity.to_string)
  |> expect.to_equal([
    "TRACE",
    "DEBUG",
    "INFO",
    "NOTICE",
    "WARN",
    "ERROR",
    "CRITICAL",
    "ALERT",
    "FATAL",
  ])
}

pub fn rfc5424_level_order_is_retained_test() {
  severity.to_int(severity.Trace)
  |> expect.to_equal(0)
  severity.to_int(severity.Err)
  |> expect.to_equal(5)
  severity.to_int(severity.Fatal)
  |> expect.to_equal(8)
}

pub fn custom_formatter_test() {
  let formatter =
    severity.custom(
      fn(sev, _sp) {
        case sev {
          severity.Warn -> "heads-up"
          _ -> "status"
        }
      },
      target_width: 8,
    )

  severity.render_padded(spruce.no_color(), formatter, severity.Warn)
  |> expect.to_equal("heads-up")
}
