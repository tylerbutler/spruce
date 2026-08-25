import type {
  BoxWorkbenchExample,
  MessageWorkbenchExample,
  StyleWorkbenchExample,
  TableWorkbenchExample,
  WorkbenchColor,
  WorkbenchKind,
  WorkbenchPreset,
} from "./domain.ts";
import { WORKBENCH_DOCS_ROOT, namedColors } from "./domain.ts";
import { renderWorkbenchSource } from "./source.ts";

const messageDefault: MessageWorkbenchExample = {
  kind: "message",
  capability: "basic",
  message: "success",
  text: "Deploy complete",
};

const styleDefault: StyleWorkbenchExample = {
  kind: "style",
  capability: "truecolor",
  text: "facade",
  foreground: { kind: "named", value: "bright_white" },
  background: { kind: "named", value: "blue" },
  bold: true,
  italic: false,
  underline: true,
};

const boxDefault: BoxWorkbenchExample = {
  kind: "box",
  capability: "truecolor",
  content: "ready",
  box: "framed",
  title: "spruce",
  padding: { top: 0, right: 1, bottom: 0, left: 1 },
  width: null,
  height: null,
  border: "rounded",
  borderColor: { kind: "complete", ansi: { kind: "named", value: "cyan" }, ansi256: { kind: "ansi256", value: 116 }, truecolor: { kind: "hex", value: 0x56b3a4 } },
};

const tableDefault: TableWorkbenchExample = {
  kind: "table",
  capability: "no_color",
  headers: ["Module", "Target", "Time"],
  rows: [
    ["spruce/box", "erlang", "1.2ms"],
    ["spruce/table", "javascript", "0.8ms"],
  ],
  width: { kind: "auto" },
  border: "rounded",
  rowSeparators: true,
};

const colorCapabilityOptions = [
  { value: "no_color", label: "No color" },
  { value: "basic", label: "Basic ANSI" },
  { value: "ansi256", label: "ANSI 256" },
  { value: "truecolor", label: "Truecolor" },
] as const satisfies WorkbenchPreset<MessageWorkbenchExample>["controlMetadata"]["capability"]["options"];

const messageOptions = [
  { value: "success", label: "Success" },
  { value: "fail", label: "Fail" },
  { value: "start", label: "Start" },
  { value: "ready", label: "Ready" },
  { value: "info", label: "Info" },
  { value: "warn", label: "Warn" },
  { value: "error", label: "Error" },
] as const satisfies WorkbenchPreset<MessageWorkbenchExample>["controlMetadata"]["message"]["options"];

const booleanOptions = [
  { value: false, label: "Off" },
  { value: true, label: "On" },
] as const;

const boxKindOptions = [
  { value: "framed", label: "Framed" },
  { value: "plain", label: "Plain" },
] as const satisfies WorkbenchPreset<BoxWorkbenchExample>["controlMetadata"]["box"]["options"];

const borderOptions = [
  { value: "normal", label: "Normal" },
  { value: "rounded", label: "Rounded" },
  { value: "thick", label: "Thick" },
  { value: "double", label: "Double" },
  { value: "hidden", label: "Hidden" },
  { value: "block", label: "Block" },
] as const satisfies WorkbenchPreset<BoxWorkbenchExample>["controlMetadata"]["border"]["options"];

const namedColorOptions = namedColors.map((value) => ({
  value: { kind: "named", value } as const,
  label: humanizeToken(value),
})) as ReadonlyArray<{
  value: WorkbenchColor;
  label: string;
}>;

const workbenchColorOptions = [
  ...namedColorOptions,
  {
    value: {
      kind: "complete",
      ansi: { kind: "named", value: "cyan" },
      ansi256: { kind: "ansi256", value: 116 },
      truecolor: { kind: "hex", value: 0x56b3a4 },
    },
    label: "Spruce aqua",
  },
] as ReadonlyArray<{
  value: WorkbenchColor;
  label: string;
}>;

const tableWidthModes = [
  { value: "auto", label: "Auto" },
  { value: "table", label: "Table width" },
  { value: "columns", label: "Column widths" },
] as const;

export const workbenchPresets = [
  {
    id: "message",
    label: "Semantic messages",
    summary: "Render one semantic line with the bounded message constructors.",
    docsHref: `${WORKBENCH_DOCS_ROOT}spruce/message.html`,
    supportedControls: ["capability", "message", "text"],
    controlMetadata: {
      capability: { kind: "choice", options: colorCapabilityOptions },
      message: { kind: "choice", options: messageOptions },
    },
    defaultExample: messageDefault,
    fallbackBlock: "messages",
    createSource: (example = messageDefault) => renderWorkbenchSource(example),
  },
  {
    id: "style",
    label: "Styled text",
    summary: "Compose bounded foreground, background, and text attributes.",
    docsHref: `${WORKBENCH_DOCS_ROOT}spruce/style.html`,
    supportedControls: [
      "capability",
      "text",
      "foreground",
      "background",
      "bold",
      "italic",
      "underline",
    ],
    controlMetadata: {
      capability: { kind: "choice", options: colorCapabilityOptions },
      foreground: {
        kind: "choice",
        options: workbenchColorOptions,
        clearable: true,
      },
      background: {
        kind: "choice",
        options: workbenchColorOptions,
        clearable: true,
      },
      bold: { kind: "choice", options: booleanOptions },
      italic: { kind: "choice", options: booleanOptions },
      underline: { kind: "choice", options: booleanOptions },
    },
    defaultExample: styleDefault,
    fallbackBlock: "style",
    createSource: (example = styleDefault) => renderWorkbenchSource(example),
  },
  {
    id: "box",
    label: "Boxed blocks",
    summary: "Tune the bounded box builder without exposing the full API.",
    docsHref: `${WORKBENCH_DOCS_ROOT}spruce/box.html`,
    supportedControls: [
      "capability",
      "content",
      "box",
      "title",
      "padding",
      "width",
      "height",
      "border",
      "border_color",
    ],
    controlMetadata: {
      capability: { kind: "choice", options: colorCapabilityOptions },
      box: { kind: "choice", options: boxKindOptions },
      padding: { kind: "padding", min: 0, max: 4, step: 1 },
      width: { kind: "number", min: 12, max: 80, step: 1, nullable: true },
      height: { kind: "number", min: 1, max: 12, step: 1, nullable: true },
      border: { kind: "choice", options: borderOptions },
      border_color: {
        kind: "choice",
        options: workbenchColorOptions,
        clearable: true,
      },
    },
    defaultExample: boxDefault,
    fallbackBlock: "example",
    createSource: (example = boxDefault) => renderWorkbenchSource(example),
  },
  {
    id: "table",
    label: "Tables",
    summary: "Render headers, rows, borders, and width constraints from one preset.",
    docsHref: `${WORKBENCH_DOCS_ROOT}spruce/table.html`,
    supportedControls: [
      "capability",
      "headers",
      "rows",
      "width",
      "border",
      "row_separators",
    ],
    controlMetadata: {
      capability: { kind: "choice", options: colorCapabilityOptions },
      width: {
        kind: "table_width",
        modes: tableWidthModes,
        table: { min: 24, max: 96, step: 1 },
        column: { min: 4, max: 32, step: 1 },
      },
      border: { kind: "choice", options: borderOptions },
      row_separators: { kind: "choice", options: booleanOptions },
    },
    defaultExample: tableDefault,
    fallbackBlock: "table",
    createSource: (example = tableDefault) => renderWorkbenchSource(example),
  },
] as const satisfies readonly [
  WorkbenchPreset<MessageWorkbenchExample>,
  WorkbenchPreset<StyleWorkbenchExample>,
  WorkbenchPreset<BoxWorkbenchExample>,
  WorkbenchPreset<TableWorkbenchExample>,
];

export function getWorkbenchPreset<TKind extends WorkbenchKind>(id: TKind) {
  return workbenchPresets.find((preset) => preset.id === id) as Extract<
    (typeof workbenchPresets)[number],
    { id: TKind }
  >;
}

function humanizeToken(value: string): string {
  return value
    .split("_")
    .map((part) => part[0]!.toUpperCase() + part.slice(1))
    .join(" ");
}
