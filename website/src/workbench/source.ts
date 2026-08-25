import type {
  BoxWorkbenchExample,
  NamedWorkbenchColor,
  StyleWorkbenchExample,
  TableWorkbenchExample,
  WorkbenchBorderStyle,
  WorkbenchColor,
  WorkbenchColorCapability,
  WorkbenchExample,
  WorkbenchMessageKind,
} from "./domain.ts";

export function renderWorkbenchSource(example: WorkbenchExample): string {
  const body = renderBody(example);
  return `import spruce_workbench

pub fn main() {
  ${body}
}`;
}

function renderBody(example: WorkbenchExample): string {
  switch (example.kind) {
    case "message":
      return [
        "spruce_workbench.render_message(",
        `  ${renderCapability(example.capability)},`,
        `  ${renderMessage(example.message)},`,
        `  ${renderString(example.text)},`,
        ")",
      ].join("\n  ");
    case "style":
      return [
        "spruce_workbench.render_style(",
        `  ${renderCapability(example.capability)},`,
        `  ${renderStyleConfig(example)},`,
        `  ${renderString(example.text)},`,
        ")",
      ].join("\n  ");
    case "box":
      return [
        "spruce_workbench.render_box(",
        `  ${renderCapability(example.capability)},`,
        `  ${renderString(example.content)},`,
        `  ${renderBoxConfig(example)},`,
        ")",
      ].join("\n  ");
    case "table":
      return [
        "spruce_workbench.render_table(",
        `  ${renderCapability(example.capability)},`,
        `  ${renderTableConfig(example)},`,
        ")",
      ].join("\n  ");
  }
}

function renderStyleConfig(example: StyleWorkbenchExample): string {
  const lines = ["spruce_workbench.new_style()"];
  if (example.foreground) {
    lines.push(
      `|> spruce_workbench.style_fg(${renderColor(example.foreground)})`,
    );
  }
  if (example.background) {
    lines.push(
      `|> spruce_workbench.style_bg(${renderColor(example.background)})`,
    );
  }
  if (example.bold) lines.push("|> spruce_workbench.style_bold");
  if (example.italic) lines.push("|> spruce_workbench.style_italic");
  if (example.underline) lines.push("|> spruce_workbench.style_underline");

  return lines.join("\n    ");
}

function renderBoxConfig(example: BoxWorkbenchExample): string {
  const lines = [
    example.box === "plain"
      ? "spruce_workbench.plain_box()"
      : "spruce_workbench.new_box()",
  ];

  if (example.title) {
    lines.push(`|> spruce_workbench.box_title(${renderString(example.title)})`);
  }

  lines.push(
    `|> spruce_workbench.box_padding(top: ${example.padding.top}, right: ${example.padding.right}, bottom: ${example.padding.bottom}, left: ${example.padding.left})`,
  );
  lines.push(`|> spruce_workbench.box_border(${renderBorder(example.border)})`);

  if (example.width !== null) {
    lines.push(`|> spruce_workbench.box_width(${example.width})`);
  }
  if (example.height !== null) {
    lines.push(`|> spruce_workbench.box_height(${example.height})`);
  }
  if (example.borderColor) {
    lines.push(
      `|> spruce_workbench.box_border_color(${renderColor(example.borderColor)})`,
    );
  }

  return lines.join("\n    ");
}

function renderTableConfig(example: TableWorkbenchExample): string {
  const lines = [
    "spruce_workbench.new_table()",
    `|> spruce_workbench.table_headers(${renderStringList(example.headers)})`,
    `|> spruce_workbench.table_rows(${renderStringRows(example.rows)})`,
  ];

  switch (example.width.kind) {
    case "auto":
      break;
    case "table":
      lines.push(`|> spruce_workbench.table_width(${example.width.value})`);
      break;
    case "columns":
      lines.push(
        `|> spruce_workbench.table_column_widths(${renderIntList(example.width.values)})`,
      );
      break;
  }

  lines.push(`|> spruce_workbench.table_border(${renderBorder(example.border)})`);

  if (example.rowSeparators) {
    lines.push("|> spruce_workbench.table_row_separators(True)");
  }

  return lines.join("\n    ");
}

function renderCapability(capability: WorkbenchColorCapability): string {
  switch (capability) {
    case "no_color":
      return "spruce_workbench.NoColor";
    case "basic":
      return "spruce_workbench.Basic";
    case "ansi256":
      return "spruce_workbench.Ansi256";
    case "truecolor":
      return "spruce_workbench.TrueColor";
  }
}

function renderMessage(message: WorkbenchMessageKind): string {
  switch (message) {
    case "success":
      return "spruce_workbench.Success";
    case "fail":
      return "spruce_workbench.Fail";
    case "start":
      return "spruce_workbench.Start";
    case "ready":
      return "spruce_workbench.Ready";
    case "info":
      return "spruce_workbench.Info";
    case "warn":
      return "spruce_workbench.Warn";
    case "error":
      return "spruce_workbench.Error";
  }
}

function renderBorder(border: WorkbenchBorderStyle): string {
  switch (border) {
    case "normal":
      return "spruce_workbench.Normal";
    case "rounded":
      return "spruce_workbench.Rounded";
    case "thick":
      return "spruce_workbench.Thick";
    case "double":
      return "spruce_workbench.Double";
    case "hidden":
      return "spruce_workbench.Hidden";
    case "block":
      return "spruce_workbench.Block";
  }
}

function renderColor(color: WorkbenchColor): string {
  switch (color.kind) {
    case "named":
      return `spruce_workbench.${toColorConstructor(color.value)}`;
    case "hex":
      return `spruce_workbench.Hex(${color.value})`;
    case "ansi256":
      return `spruce_workbench.Color256(${color.value})`;
    case "complete":
      return [
        "spruce_workbench.complete_color(",
        `      ansi: ${renderColor(color.ansi)},`,
        `      ansi256: ${renderColor(color.ansi256)},`,
        `      truecolor: ${renderColor(color.truecolor)},`,
        "    )",
      ].join("\n");
  }
}

function toColorConstructorName(value: string): string {
  return value
    .split("_")
    .map((part) => part[0]!.toUpperCase() + part.slice(1))
    .join("");
}

function toColorConstructor(value: NamedWorkbenchColor): string {
  return toColorConstructorName(value);
}

function renderString(value: string): string {
  return JSON.stringify(value);
}

function renderStringList(values: readonly string[]): string {
  return `[${values.map(renderString).join(", ")}]`;
}

function renderStringRows(values: readonly (readonly string[])[]): string {
  return `[${values.map(renderStringList).join(", ")}]`;
}

function renderIntList(values: readonly number[]): string {
  return `[${values.join(", ")}]`;
}
