export const WORKBENCH_DOCS_ROOT = "https://hexdocs.pm/spruce/";

export const workbenchKinds = ["message", "style", "box", "table"] as const;
export type WorkbenchKind = (typeof workbenchKinds)[number];

export const colorCapabilities = [
  "no_color",
  "basic",
  "ansi256",
  "truecolor",
] as const;
export type WorkbenchColorCapability = (typeof colorCapabilities)[number];

export const messageKinds = [
  "success",
  "fail",
  "start",
  "ready",
  "info",
  "warn",
  "error",
] as const;
export type WorkbenchMessageKind = (typeof messageKinds)[number];

export const namedColors = [
  "black",
  "red",
  "green",
  "yellow",
  "blue",
  "magenta",
  "cyan",
  "white",
  "gray",
  "bright_red",
  "bright_green",
  "bright_yellow",
  "bright_blue",
  "bright_magenta",
  "bright_cyan",
  "bright_white",
] as const;
export type NamedWorkbenchColor = (typeof namedColors)[number];

export type WorkbenchAtomicColor =
  | { kind: "named"; value: NamedWorkbenchColor }
  | { kind: "hex"; value: number }
  | { kind: "ansi256"; value: number };

export type WorkbenchColor =
  | WorkbenchAtomicColor
  | {
      kind: "complete";
      ansi: WorkbenchAtomicColor;
      ansi256: WorkbenchAtomicColor;
      truecolor: WorkbenchAtomicColor;
    };

export const borderStyles = [
  "normal",
  "rounded",
  "thick",
  "double",
  "hidden",
  "block",
] as const;
export type WorkbenchBorderStyle = (typeof borderStyles)[number];

export const horizontalAlignments = ["start", "center", "end"] as const;
export type WorkbenchHorizontalAlignment =
  (typeof horizontalAlignments)[number];

export type WorkbenchPadding = {
  top: number;
  right: number;
  bottom: number;
  left: number;
};

export type MessageWorkbenchExample = {
  kind: "message";
  capability: WorkbenchColorCapability;
  message: WorkbenchMessageKind;
  text: string;
};

export type StyleWorkbenchExample = {
  kind: "style";
  capability: WorkbenchColorCapability;
  text: string;
  foreground: WorkbenchColor | null;
  background: WorkbenchColor | null;
  bold: boolean;
  italic: boolean;
  underline: boolean;
};

export type BoxWorkbenchExample = {
  kind: "box";
  capability: WorkbenchColorCapability;
  content: string;
  title: string;
  padding: WorkbenchPadding;
  width: number | null;
  alignment: WorkbenchHorizontalAlignment;
  border: WorkbenchBorderStyle;
};

export type TableWidth =
  | { kind: "auto" }
  | { kind: "table"; value: number }
  | { kind: "columns"; values: readonly number[] };

export type TableWorkbenchExample = {
  kind: "table";
  capability: WorkbenchColorCapability;
  headers: readonly string[];
  rows: readonly (readonly string[])[];
  width: TableWidth;
  border: WorkbenchBorderStyle;
  rowSeparators: boolean;
};

export type WorkbenchExample =
  | MessageWorkbenchExample
  | StyleWorkbenchExample
  | BoxWorkbenchExample
  | TableWorkbenchExample;

export type MessageControl = "capability" | "message" | "text";
export type StyleControl =
  | "capability"
  | "text"
  | "foreground"
  | "background"
  | "bold"
  | "italic"
  | "underline";
export type BoxControl =
  | "capability"
  | "content"
  | "title"
  | "padding"
  | "width"
  | "alignment"
  | "border"
export type TableControl =
  | "capability"
  | "headers"
  | "rows"
  | "width"
  | "border"
  | "row_separators";

export type WorkbenchControl =
  | MessageControl
  | StyleControl
  | BoxControl
  | TableControl;

export type WorkbenchControlSetByKind = {
  message: MessageControl;
  style: StyleControl;
  box: BoxControl;
  table: TableControl;
};

export type WorkbenchControlOption<TValue> = {
  value: TValue;
  label: string;
};

export type WorkbenchChoiceControlMetadata<TValue> = {
  kind: "choice";
  options: readonly WorkbenchControlOption<TValue>[];
  clearable?: boolean;
};

export type WorkbenchNumberControlMetadata = {
  kind: "number";
  min: number;
  max: number;
  step: number;
  nullable?: boolean;
};

export type WorkbenchPaddingControlMetadata = {
  kind: "padding";
  min: number;
  max: number;
  step: number;
};

export type WorkbenchTableWidthControlMetadata = {
  kind: "table_width";
  modes: readonly WorkbenchControlOption<TableWidth["kind"]>[];
  table: {
    min: number;
    max: number;
    step: number;
  };
  column: {
    min: number;
    max: number;
    step: number;
  };
};

export type MessageControlMetadata = {
  capability: WorkbenchChoiceControlMetadata<WorkbenchColorCapability>;
  message: WorkbenchChoiceControlMetadata<WorkbenchMessageKind>;
};

export type StyleControlMetadata = {
  capability: WorkbenchChoiceControlMetadata<WorkbenchColorCapability>;
  foreground: WorkbenchChoiceControlMetadata<WorkbenchColor>;
  background: WorkbenchChoiceControlMetadata<WorkbenchColor>;
  bold: WorkbenchChoiceControlMetadata<boolean>;
  italic: WorkbenchChoiceControlMetadata<boolean>;
  underline: WorkbenchChoiceControlMetadata<boolean>;
};

export type BoxControlMetadata = {
  capability: WorkbenchChoiceControlMetadata<WorkbenchColorCapability>;
  padding: WorkbenchPaddingControlMetadata;
  width: WorkbenchNumberControlMetadata;
  alignment: WorkbenchChoiceControlMetadata<WorkbenchHorizontalAlignment>;
  border: WorkbenchChoiceControlMetadata<WorkbenchBorderStyle>;
};

export type TableControlMetadata = {
  capability: WorkbenchChoiceControlMetadata<WorkbenchColorCapability>;
  width: WorkbenchTableWidthControlMetadata;
  border: WorkbenchChoiceControlMetadata<WorkbenchBorderStyle>;
  row_separators: WorkbenchChoiceControlMetadata<boolean>;
};

export type WorkbenchControlMetadataByKind = {
  message: MessageControlMetadata;
  style: StyleControlMetadata;
  box: BoxControlMetadata;
  table: TableControlMetadata;
};

export type WorkbenchFallbackBlock =
  | "messages"
  | "style"
  | "example"
  | "table";

export type WorkbenchPreset<T extends WorkbenchExample> = {
  id: T["kind"];
  label: string;
  summary: string;
  docsHref: string;
  supportedControls: readonly WorkbenchControlSetByKind[T["kind"]][];
  controlMetadata: WorkbenchControlMetadataByKind[T["kind"]];
  defaultExample: T;
  fallbackBlock: WorkbenchFallbackBlock;
  createSource: (example?: T) => string;
};

export type WorkbenchRenderResult = {
  ansi: string;
  html: string;
};

export type WorkbenchAdapter = {
  render(example: WorkbenchExample): WorkbenchRenderResult;
};
