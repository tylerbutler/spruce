import type {
  BoxWorkbenchExample,
  NamedWorkbenchColor,
  StyleWorkbenchExample,
  TableWorkbenchExample,
  TableWidth,
  WorkbenchBorderStyle,
  WorkbenchColor,
  WorkbenchColorCapability,
  WorkbenchExample,
  WorkbenchHorizontalAlignment,
  WorkbenchMessageKind,
} from "./domain.ts";

export function renderWorkbenchSource(example: WorkbenchExample): string {
  switch (example.kind) {
    case "message":
      return renderMessageSource(example);
    case "style":
      return renderStyleSource(example);
    case "box":
      return renderBoxSource(example);
    case "table":
      return renderTableSource(example);
  }
}

function renderMessageSource(example: WorkbenchExample & { kind: "message" }): string {
  return [
    "import gleam/io",
    "import spruce",
    "import spruce/message",
    "",
    "pub fn main() {",
    `  let context = ${renderContext(example.capability)}`,
    `  io.println(message.${renderMessage(example.message)}(context, ${renderString(example.text)}))`,
    "}",
  ].join("\n");
}

function renderStyleSource(example: StyleWorkbenchExample): string {
  return [
    "import gleam/io",
    "import spruce",
    "import spruce/style",
    "",
    "pub fn main() {",
    `  let context = ${renderContext(example.capability)}`,
    "  let text_style =",
    indent(renderStyleBuilder(example), 4),
    "",
    `  io.println(style.render(context, text_style, ${renderString(example.text)}))`,
    "}",
  ].join("\n");
}

function renderBoxSource(example: BoxWorkbenchExample): string {
  return [
    "import gleam/io",
    "import spruce",
    "import spruce/align",
    "import spruce/border",
    "import spruce/box",
    "",
    "pub fn main() {",
    `  let context = ${renderContext(example.capability)}`,
    "  let config =",
    indent(renderBoxBuilder(example), 4),
    "",
    `  io.println(box.render(context, ${renderString(example.content)}, config))`,
    "}",
  ].join("\n");
}

function renderTableSource(example: TableWorkbenchExample): string {
  return [
    "import gleam/io",
    "import spruce",
    "import spruce/border",
    "import spruce/table",
    "",
    "pub fn main() {",
    `  let context = ${renderContext(example.capability)}`,
    "  let table_data =",
    indent(renderTableBuilder(example), 4),
    "",
    "  io.println(table.render(context, table_data))",
    "}",
  ].join("\n");
}

function renderStyleBuilder(example: StyleWorkbenchExample): string {
  const lines = ["style.new()"];

  if (example.foreground) {
    lines.push(`|> style.fg(${renderColor(example.foreground)})`);
  }
  if (example.background) {
    lines.push(`|> style.bg(${renderColor(example.background)})`);
  }
  if (example.bold) lines.push("|> style.bold");
  if (example.italic) lines.push("|> style.italic");
  if (example.underline) lines.push("|> style.underline");

  return lines.join("\n");
}

function renderBoxBuilder(example: BoxWorkbenchExample): string {
  const lines = ["box.new()"];

  if (example.title) {
    lines.push(`|> box.title(${renderString(example.title)})`);
  }

  lines.push(
    `|> box.padding(top: ${example.padding.top}, right: ${example.padding.right}, bottom: ${example.padding.bottom}, left: ${example.padding.left})`,
  );
  lines.push(
    `|> box.align(horizontal: align.${renderHorizontalAlignment(example.alignment)}, vertical: align.Start)`,
  );
  lines.push(`|> box.border(border.${renderBorder(example.border)})`);

  if (example.width !== null) {
    lines.push(`|> box.width(${example.width})`);
  }

  return lines.join("\n");
}

function renderTableBuilder(example: TableWorkbenchExample): string {
  const lines = [
    "table.new()",
    `|> table.headers(${renderStringList(example.headers)})`,
    `|> table.rows(${renderStringRows(example.rows)})`,
  ];

  lines.push(...renderTableWidth(example.width));
  lines.push(`|> table.border(border.${renderBorder(example.border)})`);

  if (example.rowSeparators) {
    lines.push("|> table.row_separators(True)");
  }

  return lines.join("\n");
}

function renderTableWidth(width: TableWidth): string[] {
  switch (width.kind) {
    case "auto":
      return [];
    case "table":
      return [`|> table.width(${width.value})`];
    case "columns":
      return [`|> table.column_widths(${renderIntList(width.values)})`];
  }
}

function renderContext(capability: WorkbenchColorCapability): string {
  switch (capability) {
    case "no_color":
      return "spruce.no_color()";
    case "basic":
      return "spruce.with_color_level(spruce.Basic)";
    case "ansi256":
      return "spruce.with_color_level(spruce.Ansi256)";
    case "truecolor":
      return "spruce.with_color_level(spruce.TrueColor)";
  }
}

function renderMessage(message: WorkbenchMessageKind): string {
  switch (message) {
    case "success":
      return "success";
    case "fail":
      return "fail";
    case "start":
      return "start";
    case "ready":
      return "ready";
    case "info":
      return "info";
    case "warn":
      return "warn";
    case "error":
      return "error";
  }
}

function renderBorder(border: WorkbenchBorderStyle): string {
  switch (border) {
    case "normal":
      return "Normal";
    case "rounded":
      return "Rounded";
    case "thick":
      return "Thick";
    case "double":
      return "Double";
    case "hidden":
      return "Hidden";
    case "block":
      return "Block";
  }
}

function renderHorizontalAlignment(
  alignment: WorkbenchHorizontalAlignment,
): string {
  switch (alignment) {
    case "start":
      return "Start";
    case "center":
      return "Center";
    case "end":
      return "End";
  }
}

function renderColor(color: WorkbenchColor): string {
  switch (color.kind) {
    case "named":
      return `style.${toColorConstructor(color.value)}`;
    case "hex":
      return `style.Hex(${color.value})`;
    case "ansi256":
      return `style.Ansi256(${color.value})`;
    case "complete":
      return [
        "style.complete(",
        `  ansi: ${renderColor(color.ansi)},`,
        `  ansi256: ${renderColor(color.ansi256)},`,
        `  truecolor: ${renderColor(color.truecolor)},`,
        ")",
      ].join("\n");
  }
}

function toColorConstructor(value: NamedWorkbenchColor): string {
  return value
    .split("_")
    .map((part) => part[0]!.toUpperCase() + part.slice(1))
    .join("");
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

function indent(value: string, spaces: number): string {
  const prefix = " ".repeat(spaces);
  return value
    .split("\n")
    .map((line) => `${prefix}${line}`)
    .join("\n");
}
