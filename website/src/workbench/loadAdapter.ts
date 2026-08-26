import type { WorkbenchAdapter } from "./domain.ts";

// Real dynamic import boundary for the generated Gleam facade and renderer.
export async function loadWorkbenchAdapter(): Promise<WorkbenchAdapter> {
  const module = await import("./runtime.ts");
  return module.createWorkbenchAdapter();
}
