import { convertAnsiToHtml } from "../lib/ansi2html.js";
import * as gleam from "../../workbench/build/dev/javascript/spruce_workbench/gleam.mjs";
import * as facade from "../../workbench/build/dev/javascript/spruce_workbench/spruce_workbench.mjs";
import type {
  BoxWorkbenchExample,
  TableWorkbenchExample,
  WorkbenchAdapter,
  WorkbenchBorderStyle,
  WorkbenchColor,
  WorkbenchColorCapability,
  WorkbenchExample,
  WorkbenchMessageKind,
  WorkbenchRenderResult,
} from "./domain.ts";

export function createWorkbenchAdapter(): WorkbenchAdapter {
  return {
    render(example) {
      const ansi = renderAnsi(example);
      return {
        ansi,
        html: convertAnsiToHtml(ansi),
      };
    },
  };
}

function renderAnsi(example: WorkbenchExample): string {
  switch (example.kind) {
    case "message":
      return facade.render_message(
        toCapability(example.capability),
        toMessage(example.message),
        example.text,
      );
    case "style": {
      let config = facade.new_style();
      if (example.foreground) {
        config = facade.style_fg(config, toColor(example.foreground));
      }
      if (example.background) {
        config = facade.style_bg(config, toColor(example.background));
      }
      if (example.bold) config = facade.style_bold(config);
      if (example.italic) config = facade.style_italic(config);
      if (example.underline) config = facade.style_underline(config);

      return facade.render_style(toCapability(example.capability), config, example.text);
    }
    case "box":
      return facade.render_box(
        toCapability(example.capability),
        example.content,
        toBoxConfig(example),
      );
    case "table":
      return facade.render_table(
        toCapability(example.capability),
        toTableConfig(example),
      );
  }
}

function toCapability(capability: WorkbenchColorCapability): facade.Capability$ {
  switch (capability) {
    case "no_color":
      return facade.Capability$NoColor();
    case "basic":
      return facade.Capability$Basic();
    case "ansi256":
      return facade.Capability$Ansi256();
    case "truecolor":
      return facade.Capability$TrueColor();
  }
}

function toMessage(message: WorkbenchMessageKind): facade.Message$ {
  switch (message) {
    case "success":
      return facade.Message$Success();
    case "fail":
      return facade.Message$Fail();
    case "start":
      return facade.Message$Start();
    case "ready":
      return facade.Message$Ready();
    case "info":
      return facade.Message$Info();
    case "warn":
      return facade.Message$Warn();
    case "error":
      return facade.Message$Error();
  }
}

function toBoxConfig(example: BoxWorkbenchExample): facade.BoxConfig$ {
  let config =
    example.box === "plain" ? facade.plain_box() : facade.new_box();

  if (example.title) {
    config = facade.box_title(config, example.title);
  }

  config = facade.box_padding(
    config,
    example.padding.top,
    example.padding.right,
    example.padding.bottom,
    example.padding.left,
  );
  config = facade.box_border(config, toBorder(example.border));

  if (example.width !== null) {
    config = facade.box_width(config, example.width);
  }
  if (example.height !== null) {
    config = facade.box_height(config, example.height);
  }
  if (example.borderColor) {
    config = facade.box_border_color(config, toColor(example.borderColor));
  }

  return config;
}

function toTableConfig(example: TableWorkbenchExample): facade.TableConfig$ {
  let config = facade.new_table();
  config = facade.table_headers(config, toList(example.headers));
  config = facade.table_rows(config, toRowList(example.rows));

  switch (example.width.kind) {
    case "auto":
      break;
    case "table":
      config = facade.table_width(config, example.width.value);
      break;
    case "columns":
      config = facade.table_column_widths(config, toList(example.width.values));
      break;
  }

  config = facade.table_border(config, toBorder(example.border));

  if (example.rowSeparators) {
    config = facade.table_row_separators(config, true);
  }

  return config;
}

function toBorder(border: WorkbenchBorderStyle): facade.BorderStyle$ {
  switch (border) {
    case "normal":
      return facade.BorderStyle$Normal();
    case "rounded":
      return facade.BorderStyle$Rounded();
    case "thick":
      return facade.BorderStyle$Thick();
    case "double":
      return facade.BorderStyle$Double();
    case "hidden":
      return facade.BorderStyle$Hidden();
    case "block":
      return facade.BorderStyle$Block();
  }
}

function toColor(color: WorkbenchColor): facade.Color$ {
  switch (color.kind) {
    case "named":
      return toNamedColor(color.value);
    case "hex":
      return facade.Color$Hex(color.value);
    case "ansi256":
      return facade.Color$Color256(color.value);
    case "complete":
      return facade.complete_color(
        toColor(color.ansi),
        toColor(color.ansi256),
        toColor(color.truecolor),
      );
  }
}

function toNamedColor(
  color: Extract<WorkbenchColor, { kind: "named" }>["value"],
): facade.Color$ {
  switch (color) {
    case "black":
      return facade.Color$Black();
    case "red":
      return facade.Color$Red();
    case "green":
      return facade.Color$Green();
    case "yellow":
      return facade.Color$Yellow();
    case "blue":
      return facade.Color$Blue();
    case "magenta":
      return facade.Color$Magenta();
    case "cyan":
      return facade.Color$Cyan();
    case "white":
      return facade.Color$White();
    case "gray":
      return facade.Color$Gray();
    case "bright_red":
      return facade.Color$BrightRed();
    case "bright_green":
      return facade.Color$BrightGreen();
    case "bright_yellow":
      return facade.Color$BrightYellow();
    case "bright_blue":
      return facade.Color$BrightBlue();
    case "bright_magenta":
      return facade.Color$BrightMagenta();
    case "bright_cyan":
      return facade.Color$BrightCyan();
    case "bright_white":
      return facade.Color$BrightWhite();
  }
}

function toList<T>(values: readonly T[]) {
  return gleam.toList(Array.from(values));
}

function toRowList(values: readonly (readonly string[])[]) {
  return toList(values.map((row) => toList(row)));
}

export function renderWorkbenchExample(
  example: WorkbenchExample,
): WorkbenchRenderResult {
  return createWorkbenchAdapter().render(example);
}
