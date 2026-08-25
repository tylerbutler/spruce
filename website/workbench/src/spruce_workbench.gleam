import spruce.{type Spruce}
import spruce/box
import spruce/message as messages
import spruce/style
import spruce/table

/// Browser-facing color capability choices for pre-rendering ANSI strings.
pub type Capability {
  NoColor
  Basic
  Ansi256
  TrueColor
}

/// The supported semantic message variants.
pub type Message {
  Success
  Fail
  Start
  Ready
  Info
  Warn
  Error
}

/// Render a semantic message line for the chosen browser capability.
pub fn render_message(
  capability: Capability,
  message: Message,
  text: String,
) -> String {
  let context = context(capability)

  case message {
    Success -> messages.success(context, text)
    Fail -> messages.fail(context, text)
    Start -> messages.start(context, text)
    Ready -> messages.ready(context, text)
    Info -> messages.info(context, text)
    Warn -> messages.warn(context, text)
    Error -> messages.error(context, text)
  }
}

/// Render styled text for the chosen browser capability.
pub fn render_style(
  capability: Capability,
  text_style: style.Style,
  text: String,
) -> String {
  style.render(context(capability), text_style, text)
}

/// Render a box for the chosen browser capability.
pub fn render_box(
  capability: Capability,
  content: String,
  options: box.Box,
) -> String {
  box.render(context(capability), content, options)
}

/// Render a table for the chosen browser capability.
pub fn render_table(capability: Capability, data: table.Table) -> String {
  table.render(context(capability), data)
}

fn context(capability: Capability) -> Spruce {
  case capability {
    NoColor -> spruce.no_color()
    Basic -> spruce.with_color_level(spruce.Basic)
    Ansi256 -> spruce.with_color_level(spruce.Ansi256)
    TrueColor -> spruce.with_color_level(spruce.TrueColor)
  }
}
