export { loadWorkbenchAdapter } from "./loadAdapter.ts";
export { getWorkbenchPreset, workbenchPresets } from "./registry.ts";
export { renderWorkbenchSource } from "./source.ts";
export {
  WORKBENCH_DOCS_ROOT,
  borderStyles,
  boxKinds,
  colorCapabilities,
  messageKinds,
  namedColors,
  workbenchKinds,
} from "./domain.ts";
export type {
  BoxWorkbenchExample,
  MessageWorkbenchExample,
  StyleWorkbenchExample,
  TableWorkbenchExample,
  WorkbenchAdapter,
  WorkbenchBorderStyle,
  WorkbenchColor,
  WorkbenchColorCapability,
  WorkbenchControl,
  WorkbenchExample,
  WorkbenchFallbackBlock,
  WorkbenchKind,
  WorkbenchMessageKind,
  WorkbenchPreset,
  WorkbenchRenderResult,
} from "./domain.ts";
