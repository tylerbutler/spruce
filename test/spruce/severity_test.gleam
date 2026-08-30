import gleam/list
import gleam/string
import gleeunit/should
import spruce
import spruce/align
import spruce/severity

pub fn label_formatter_no_color_test() {
  severity.render(spruce.no_color(), severity.label(), severity.Info)
  |> should.equal("ℹ︎ info")
}

pub fn label_formatter_ascii_no_color_test() {
  let formatter = severity.label() |> severity.mode(spruce.Ascii)

  severity.render(spruce.no_color(), formatter, severity.Warning)
  |> should.equal("! warning")
}

pub fn label_formatter_without_icons_test() {
  let formatter = severity.label() |> severity.icons(False)

  severity.render(spruce.no_color(), formatter, severity.Critical)
  |> should.equal("critical")
}

pub fn label_formatter_without_icons_target_width_test() {
  severity.label()
  |> severity.icons(False)
  |> severity.target_width
  |> should.equal(9)
}

pub fn badge_formatter_no_color_test() {
  severity.render(spruce.no_color(), severity.badge(), severity.Warning)
  |> should.equal("[WARNING]")
}

pub fn simple_formatter_no_color_test() {
  severity.render(spruce.no_color(), severity.simple(), severity.Debug)
  |> should.equal("DEBUG")
}

pub fn padded_label_formatter_uses_visual_width_test() {
  severity.render_padded(spruce.no_color(), severity.label(), severity.Info)
  |> should.equal("ℹ︎ info      ")
}

pub fn color_formatter_emits_escapes_test() {
  let rendered =
    severity.render(
      spruce.with_color_level(spruce.TrueColor),
      severity.label(),
      severity.Error,
    )

  should.be_true(string.contains(rendered, "\u{001b}"))
  should.be_true(string.contains(rendered, "error"))
}

pub fn notice_label_uses_cyan_test() {
  let rendered =
    severity.render(
      spruce.with_color_level(spruce.Basic),
      severity.label(),
      severity.Notice,
    )

  should.be_true(string.contains(rendered, "\u{001b}[36m"))
  should.be_false(string.contains(rendered, "\u{001b}[34m"))
}

pub fn alert_label_uses_bright_red_test() {
  let rendered =
    severity.render(
      spruce.with_color_level(spruce.Basic),
      severity.label(),
      severity.Alert,
    )

  should.be_true(string.contains(rendered, "\u{001b}[91m"))
  should.be_false(string.contains(rendered, "\u{001b}[35m"))
}

pub fn colored_badge_is_bold_test() {
  let rendered =
    severity.render(
      spruce.with_color_level(spruce.Basic),
      severity.badge(),
      severity.Warning,
    )

  should.be_true(string.contains(rendered, "\u{001b}[1m"))
  should.be_true(string.contains(rendered, "[WARNING]"))
}

pub fn all_rfc5424_levels_are_retained_test() {
  [
    severity.Emergency,
    severity.Alert,
    severity.Critical,
    severity.Error,
    severity.Warning,
    severity.Notice,
    severity.Info,
    severity.Debug,
  ]
  |> list.map(severity.to_string)
  |> should.equal([
    "EMERGENCY",
    "ALERT",
    "CRITICAL",
    "ERROR",
    "WARNING",
    "NOTICE",
    "INFO",
    "DEBUG",
  ])
}

pub fn rfc5424_level_order_is_retained_test() {
  severity.to_int(severity.Emergency)
  |> should.equal(0)
  severity.to_int(severity.Error)
  |> should.equal(3)
  severity.to_int(severity.Debug)
  |> should.equal(7)
}

pub fn custom_formatter_test() {
  let formatter =
    severity.custom(
      fn(severity_value, _sp) {
        case severity_value {
          severity.Warning -> "heads-up"
          _ -> "status"
        }
      },
      target_width: 8,
    )

  severity.render_padded(spruce.no_color(), formatter, severity.Warning)
  |> should.equal("heads-up")
}

pub fn label_uses_context_symbol_mode_test() {
  let ctx = spruce.no_color() |> spruce.with_symbol_mode(spruce.Ascii)

  severity.render(ctx, severity.label(), severity.Warning)
  |> should.equal("! warning")
}

pub fn label_mode_override_wins_over_context_test() {
  let ctx = spruce.no_color() |> spruce.with_symbol_mode(spruce.Ascii)
  let formatter = severity.label() |> severity.mode(spruce.Unicode)

  severity.render(ctx, formatter, severity.Warning)
  |> should.equal("⚠ warning")
}

const all_severities = [
  severity.Emergency,
  severity.Alert,
  severity.Critical,
  severity.Error,
  severity.Warning,
  severity.Notice,
  severity.Info,
  severity.Debug,
]

fn padded_widths(
  context: spruce.Spruce,
  formatter: severity.Formatter,
) -> List(Int) {
  all_severities
  |> list.map(fn(severity_value) {
    severity.render_padded(context, formatter, severity_value)
    |> align.visual_length
  })
}

fn assert_alignment(context: spruce.Spruce, formatter: severity.Formatter) {
  let width = severity.target_width(formatter)

  padded_widths(context, formatter)
  |> should.equal(list.repeat(width, list.length(all_severities)))
}

pub fn padded_label_aligns_in_unicode_mode_test() {
  assert_alignment(spruce.no_color(), severity.label())
}

pub fn padded_label_aligns_in_ascii_mode_test() {
  let context = spruce.no_color() |> spruce.with_symbol_mode(spruce.Ascii)

  assert_alignment(context, severity.label())
}

pub fn padded_label_without_icons_aligns_test() {
  assert_alignment(spruce.no_color(), severity.label() |> severity.icons(False))
}

pub fn padded_badge_aligns_test() {
  assert_alignment(spruce.no_color(), severity.badge())
}

pub fn padded_simple_aligns_test() {
  assert_alignment(spruce.no_color(), severity.simple())
}

pub fn padded_label_fits_ascii_emergency_test() {
  let context = spruce.no_color() |> spruce.with_symbol_mode(spruce.Ascii)

  severity.render_padded(context, severity.label(), severity.Emergency)
  |> should.equal("!! emergency")
}

pub fn padded_label_fits_unicode_emergency_test() {
  severity.render_padded(
    spruce.no_color(),
    severity.label(),
    severity.Emergency,
  )
  |> should.equal("‼ emergency ")
}

pub fn padded_label_without_icons_fits_emergency_test() {
  let formatter = severity.label() |> severity.icons(False)

  severity.render_padded(spruce.no_color(), formatter, severity.Emergency)
  |> should.equal("emergency")
}

pub fn padded_badge_fits_emergency_test() {
  severity.render_padded(
    spruce.no_color(),
    severity.badge(),
    severity.Emergency,
  )
  |> should.equal("[EMERGENCY]")
}

pub fn padded_simple_fits_emergency_test() {
  severity.render_padded(
    spruce.no_color(),
    severity.simple(),
    severity.Emergency,
  )
  |> should.equal("EMERGENCY")
}

pub fn formatter_target_widths_test() {
  severity.target_width(severity.label())
  |> should.equal(12)
  severity.target_width(severity.badge())
  |> should.equal(11)
  severity.target_width(severity.simple())
  |> should.equal(9)
}
