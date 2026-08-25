import type {
  BoxWorkbenchExample,
  MessageWorkbenchExample,
  StyleWorkbenchExample,
  TableWorkbenchExample,
  WorkbenchKind,
  WorkbenchPreset,
} from "./domain.ts";
import { WORKBENCH_DOCS_ROOT } from "./domain.ts";
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

export const workbenchPresets = [
  {
    id: "message",
    label: "Semantic messages",
    summary: "Render one semantic line with the bounded message constructors.",
    docsHref: `${WORKBENCH_DOCS_ROOT}spruce/message.html`,
    supportedControls: ["capability", "message", "text"],
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
