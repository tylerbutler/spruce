import {
  useCallback,
  useEffect,
  useId,
  useRef,
  useState,
  type ComponentType,
  type SVGProps,
} from "react";
import {
  ArrowIcon,
  MessageIcon,
  PaletteIcon,
  TableIcon,
  TerminalIcon,
} from "../icons";
import { terminalBlocks } from "../data/terminalBlocks";
import {
  getWorkbenchPreset,
  loadWorkbenchAdapter,
  renderWorkbenchSource,
  workbenchPresets,
  type BoxWorkbenchExample,
  type MessageWorkbenchExample,
  type StyleWorkbenchExample,
  type TableWorkbenchExample,
  type WorkbenchAdapter,
  type WorkbenchColor,
  type WorkbenchColorCapability,
  type WorkbenchExample,
  type WorkbenchKind,
  type WorkbenchNumberControlMetadata,
} from "../workbench";
import { CopyTextButton, Tabs, TermBar, Terminal } from "./ui";

type ExamplesByKind = {
  message: MessageWorkbenchExample;
  style: StyleWorkbenchExample;
  box: BoxWorkbenchExample;
  table: TableWorkbenchExample;
};

type AdapterState =
  | { status: "loading" }
  | { status: "ready"; adapter: WorkbenchAdapter }
  | { status: "error"; message: string };

const kindIcons: Record<
  WorkbenchKind,
  ComponentType<SVGProps<SVGSVGElement>>
> = {
  message: MessageIcon,
  style: PaletteIcon,
  box: TerminalIcon,
  table: TableIcon,
};

const kindOptions = workbenchPresets.map((preset) => ({
  value: preset.id,
  label: preset.label,
}));

const colorOptions =
  getWorkbenchPreset("message").controlMetadata.capability.options;

const tableDatasets = [
  {
    id: "timings",
    label: "Build timings",
    headers: ["Module", "Target", "Time"],
    rows: [
      ["spruce/box", "erlang", "1.2ms"],
      ["spruce/table", "javascript", "0.8ms"],
    ],
  },
  {
    id: "releases",
    label: "Release checks",
    headers: ["Check", "Status", "Target"],
    rows: [
      ["format", "pass", "both"],
      ["tests", "pass", "erlang"],
      ["docs", "pass", "javascript"],
    ],
  },
] as const;

export function Workbench({
  capability,
  onCapabilityChange,
}: {
  capability: WorkbenchColorCapability;
  onCapabilityChange: (capability: WorkbenchColorCapability) => void;
}) {
  const [kind, setKind] = useState<WorkbenchKind>("message");
  const [examples, setExamples] = useState<ExamplesByKind>(() =>
    createDefaultExamples(capability),
  );
  const [adapterState, setAdapterState] = useState<AdapterState>({
    status: "loading",
  });
  const loadRequest = useRef(0);

  const loadAdapter = useCallback(() => {
    const request = ++loadRequest.current;
    setAdapterState({ status: "loading" });
    void loadWorkbenchAdapter().then(
      (adapter) => {
        if (loadRequest.current === request) {
          setAdapterState({ status: "ready", adapter });
        }
      },
      (error: unknown) => {
        if (loadRequest.current === request) {
          setAdapterState({
            status: "error",
            message: errorMessage(error),
          });
        }
      },
    );
  }, []);

  useEffect(() => {
    loadAdapter();
    return () => {
      loadRequest.current += 1;
    };
  }, [loadAdapter]);

  const preset = getWorkbenchPreset(kind);
  const example = withCapability(examples[kind], capability);
  const Icon = kindIcons[kind];
  const source = renderWorkbenchSource(example);

  let renderedHtml: string | null = null;
  let renderError: string | null = null;
  if (adapterState.status === "ready") {
    try {
      renderedHtml = adapterState.adapter.render(example).html;
    } catch (error) {
      renderError = errorMessage(error);
    }
  }

  function updateExample(next: WorkbenchExample) {
    setExamples((current) => {
      switch (next.kind) {
        case "message":
          return { ...current, message: next };
        case "style":
          return { ...current, style: next };
        case "box":
          return { ...current, box: next };
        case "table":
          return { ...current, table: next };
      }
    });
  }

  function resetCurrent() {
    setExamples((current) => ({
      ...current,
      [kind]: createDefaultExample(kind, capability),
    }));
  }

  return (
    <section className="section" id="workbench">
      <div className="wrap">
        <div className="section-head">
          <h2>Shape the output, then take the code.</h2>
          <p className="lead">
            Choose one focused spruce capability. Every control updates real
            Gleam-rendered ANSI output and the public source beside it.
          </p>
        </div>
        <div className="workbench">
          <Tabs
            name="workbench-kind"
            label="Workbench capability"
            options={kindOptions}
            value={kind}
            onChange={setKind}
            className="workbench-kind-tabs"
            panelClassName="workbench-stage"
          >
            <div className="workbench-stage-head">
              <div className="workbench-title">
                <span className="workbench-icon">
                  <Icon />
                </span>
                <div>
                  <h3>{preset.label}</h3>
                  <p>{preset.summary}</p>
                </div>
              </div>
              <div className="workbench-actions">
                <button
                  className="btn btn-ghost workbench-reset"
                  type="button"
                  onClick={resetCurrent}
                >
                  Reset preset
                </button>
                <a className="workbench-docs" href={preset.docsHref}>
                  Open focused docs <ArrowIcon />
                </a>
              </div>
            </div>
            <Tabs
              name="workbench-color"
              label="Workbench terminal color support"
              options={colorOptions}
              value={capability}
              onChange={onCapabilityChange}
              className="color-tabs workbench-color-tabs"
              panelClassName="workbench-color-panel"
            >
              <div className="workbench-grid">
                <fieldset className="workbench-controls">
                  <legend>Adjust {preset.label.toLowerCase()}</legend>
                  <ControlFields
                    example={example}
                    updateExample={updateExample}
                  />
                </fieldset>
                <div className="workbench-results">
                  <div className="workbench-output" aria-live="polite">
                    {adapterState.status === "loading" && (
                      <div className="workbench-loading">
                        <p role="status">Loading the Gleam renderer…</p>
                        <Terminal
                          title="Real output preview"
                          html={terminalBlocks[preset.fallbackBlock]}
                        />
                      </div>
                    )}
                    {adapterState.status === "error" && (
                      <WorkbenchError
                        title="The renderer did not load."
                        message={adapterState.message}
                        actionLabel="Try loading again"
                        onAction={loadAdapter}
                      />
                    )}
                    {renderError && (
                      <WorkbenchError
                        title="This preset could not render."
                        message={renderError}
                        actionLabel="Reset preset"
                        onAction={resetCurrent}
                      />
                    )}
                    {renderedHtml !== null && !renderError && (
                      <Terminal
                        title={`$ gleam run · ${colorLabel(capability)}`}
                        html={renderedHtml}
                      />
                    )}
                  </div>
                  <div className="code source-panel">
                    <TermBar
                      title="main.gleam"
                      action={
                        <CopyTextButton text={source} label="Copy source" />
                      }
                    />
                    <pre tabIndex={0}>
                      <code>{source}</code>
                    </pre>
                  </div>
                </div>
              </div>
            </Tabs>
          </Tabs>
        </div>
      </div>
    </section>
  );
}

function ControlFields({
  example,
  updateExample,
}: {
  example: WorkbenchExample;
  updateExample: (example: WorkbenchExample) => void;
}) {
  switch (example.kind) {
    case "message":
      return (
        <MessageControls
          example={example}
          onChange={(next) => updateExample(next)}
        />
      );
    case "style":
      return (
        <StyleControls
          example={example}
          onChange={(next) => updateExample(next)}
        />
      );
    case "box":
      return (
        <BoxControls
          example={example}
          onChange={(next) => updateExample(next)}
        />
      );
    case "table":
      return (
        <TableControls
          example={example}
          onChange={(next) => updateExample(next)}
        />
      );
  }
}

function MessageControls({
  example,
  onChange,
}: {
  example: MessageWorkbenchExample;
  onChange: (example: MessageWorkbenchExample) => void;
}) {
  const metadata = getWorkbenchPreset("message").controlMetadata;
  return (
    <>
      <label className="control-field">
        <span>Message kind</span>
        <select
          value={example.message}
          onChange={(event) =>
            onChange({
              ...example,
              message: event.target.value as MessageWorkbenchExample["message"],
            })
          }
        >
          {metadata.message.options.map((option) => (
            <option key={option.value} value={option.value}>
              {option.label}
            </option>
          ))}
        </select>
      </label>
      <label className="control-field">
        <span>Text</span>
        <input
          type="text"
          value={example.text}
          onChange={(event) =>
            onChange({ ...example, text: event.target.value })
          }
        />
      </label>
    </>
  );
}

function StyleControls({
  example,
  onChange,
}: {
  example: StyleWorkbenchExample;
  onChange: (example: StyleWorkbenchExample) => void;
}) {
  const metadata = getWorkbenchPreset("style").controlMetadata;
  return (
    <>
      <label className="control-field">
        <span>Text</span>
        <input
          type="text"
          value={example.text}
          onChange={(event) =>
            onChange({ ...example, text: event.target.value })
          }
        />
      </label>
      <div className="control-pair">
        <ColorSelect
          label="Foreground"
          value={example.foreground}
          options={metadata.foreground.options}
          clearable={metadata.foreground.clearable}
          onChange={(foreground) => onChange({ ...example, foreground })}
        />
        <ColorSelect
          label="Background"
          value={example.background}
          options={metadata.background.options}
          clearable={metadata.background.clearable}
          onChange={(background) => onChange({ ...example, background })}
        />
      </div>
      <div className="control-field">
        <span>Text attributes</span>
        <div className="check-row">
          <CheckControl
            label="Bold"
            checked={example.bold}
            onChange={(bold) => onChange({ ...example, bold })}
          />
          <CheckControl
            label="Italic"
            checked={example.italic}
            onChange={(italic) => onChange({ ...example, italic })}
          />
          <CheckControl
            label="Underline"
            checked={example.underline}
            onChange={(underline) => onChange({ ...example, underline })}
          />
        </div>
      </div>
    </>
  );
}

function BoxControls({
  example,
  onChange,
}: {
  example: BoxWorkbenchExample;
  onChange: (example: BoxWorkbenchExample) => void;
}) {
  const metadata = getWorkbenchPreset("box").controlMetadata;
  return (
    <>
      <label className="control-field">
        <span>Content</span>
        <textarea
          rows={3}
          value={example.content}
          onChange={(event) =>
            onChange({ ...example, content: event.target.value })
          }
        />
      </label>
      <div className="control-pair">
        <label className="control-field">
          <span>Box base</span>
          <select
            value={example.box}
            onChange={(event) =>
              onChange({
                ...example,
                box: event.target.value as BoxWorkbenchExample["box"],
              })
            }
          >
            {metadata.box.options.map((option) => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
        </label>
        <label className="control-field">
          <span>Title</span>
          <input
            type="text"
            value={example.title}
            onChange={(event) =>
              onChange({ ...example, title: event.target.value })
            }
          />
        </label>
      </div>
      <div className="control-field">
        <span>Padding</span>
        <div className="padding-grid">
          {(["top", "right", "bottom", "left"] as const).map((side) => (
            <label key={side}>
              <span>{side}</span>
              <input
                type="number"
                min={metadata.padding.min}
                max={metadata.padding.max}
                step={metadata.padding.step}
                value={example.padding[side]}
                onChange={(event) =>
                  onChange({
                    ...example,
                    padding: {
                      ...example.padding,
                      [side]: clamp(
                        Number(event.target.value),
                        metadata.padding.min,
                        metadata.padding.max,
                      ),
                    },
                  })
                }
              />
            </label>
          ))}
        </div>
      </div>
      <RangeControl
        label="Width"
        value={example.width}
        metadata={metadata.width}
        onChange={(width) => onChange({ ...example, width })}
      />
      <RangeControl
        label="Height"
        value={example.height}
        metadata={metadata.height}
        onChange={(height) => onChange({ ...example, height })}
      />
      <div className="control-pair">
        <label className="control-field">
          <span>Border</span>
          <select
            value={example.border}
            onChange={(event) =>
              onChange({
                ...example,
                border: event.target.value as BoxWorkbenchExample["border"],
              })
            }
          >
            {metadata.border.options.map((option) => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
        </label>
        <ColorSelect
          label="Border color"
          value={example.borderColor}
          options={metadata.border_color.options}
          clearable={metadata.border_color.clearable}
          onChange={(borderColor) => onChange({ ...example, borderColor })}
        />
      </div>
    </>
  );
}

function TableControls({
  example,
  onChange,
}: {
  example: TableWorkbenchExample;
  onChange: (example: TableWorkbenchExample) => void;
}) {
  const metadata = getWorkbenchPreset("table").controlMetadata;
  const dataset =
    tableDatasets.find(
      (item) => JSON.stringify(item.headers) === JSON.stringify(example.headers),
    ) ?? tableDatasets[0];

  return (
    <>
      <label className="control-field">
        <span>Sample dataset</span>
        <select
          value={dataset.id}
          onChange={(event) => {
            const next =
              tableDatasets.find((item) => item.id === event.target.value) ??
              tableDatasets[0];
            const width =
              example.width.kind === "columns"
                ? {
                    kind: "columns" as const,
                    values: next.headers.map(() =>
                      clamp(
                        12,
                        metadata.width.column.min,
                        metadata.width.column.max,
                      ),
                    ),
                  }
                : example.width;
            onChange({
              ...example,
              headers: next.headers,
              rows: next.rows,
              width,
            });
          }}
        >
          {tableDatasets.map((item) => (
            <option key={item.id} value={item.id}>
              {item.label}
            </option>
          ))}
        </select>
      </label>
      <label className="control-field">
        <span>Width mode</span>
        <select
          value={example.width.kind}
          onChange={(event) => {
            const mode = event.target
              .value as TableWorkbenchExample["width"]["kind"];
            if (mode === "auto") {
              onChange({ ...example, width: { kind: "auto" } });
            } else if (mode === "table") {
              onChange({
                ...example,
                width: { kind: "table", value: metadata.width.table.min },
              });
            } else {
              onChange({
                ...example,
                width: {
                  kind: "columns",
                  values: example.headers.map(() =>
                    clamp(
                      12,
                      metadata.width.column.min,
                      metadata.width.column.max,
                    ),
                  ),
                },
              });
            }
          }}
        >
          {metadata.width.modes.map((mode) => (
            <option key={mode.value} value={mode.value}>
              {mode.label}
            </option>
          ))}
        </select>
      </label>
      {example.width.kind === "table" && (
        <RangeControl
          label="Table width"
          value={example.width.value}
          metadata={metadata.width.table}
          onChange={(value) =>
            onChange({
              ...example,
              width: {
                kind: "table",
                value: value ?? metadata.width.table.min,
              },
            })
          }
        />
      )}
      {example.width.kind === "columns" && (
        <div className="control-field">
          <span>Column widths</span>
          <div className="column-widths">
            {example.headers.map((header, index) => (
              <RangeControl
                key={header}
                label={header}
                value={
                  example.width.kind === "columns"
                    ? example.width.values[index]
                    : metadata.width.column.min
                }
                metadata={metadata.width.column}
                compact
                onChange={(value) => {
                  if (example.width.kind !== "columns") return;
                  const values = [...example.width.values];
                  values[index] = value ?? metadata.width.column.min;
                  onChange({
                    ...example,
                    width: { kind: "columns", values },
                  });
                }}
              />
            ))}
          </div>
        </div>
      )}
      <label className="control-field">
        <span>Border</span>
        <select
          value={example.border}
          onChange={(event) =>
            onChange({
              ...example,
              border: event.target.value as TableWorkbenchExample["border"],
            })
          }
        >
          {metadata.border.options.map((option) => (
            <option key={option.value} value={option.value}>
              {option.label}
            </option>
          ))}
        </select>
      </label>
      <CheckControl
        label="Show row separators"
        checked={example.rowSeparators}
        onChange={(rowSeparators) => onChange({ ...example, rowSeparators })}
      />
    </>
  );
}

function ColorSelect({
  label,
  value,
  options,
  clearable = false,
  onChange,
}: {
  label: string;
  value: WorkbenchColor | null;
  options: readonly { value: WorkbenchColor; label: string }[];
  clearable?: boolean;
  onChange: (value: WorkbenchColor | null) => void;
}) {
  const selectedIndex =
    value === null
      ? ""
      : String(
          options.findIndex(
            (option) => colorKey(option.value) === colorKey(value),
          ),
        );
  return (
    <label className="control-field">
      <span>{label}</span>
      <select
        value={selectedIndex}
        onChange={(event) =>
          onChange(
            event.target.value === ""
              ? null
              : options[Number(event.target.value)].value,
          )
        }
      >
        {clearable && <option value="">None</option>}
        {options.map((option, index) => (
          <option key={`${label}-${colorKey(option.value)}`} value={index}>
            {option.label}
          </option>
        ))}
      </select>
    </label>
  );
}

function CheckControl({
  label,
  checked,
  onChange,
}: {
  label: string;
  checked: boolean;
  onChange: (checked: boolean) => void;
}) {
  return (
    <label className="check-control">
      <input
        type="checkbox"
        checked={checked}
        onChange={(event) => onChange(event.target.checked)}
      />
      <span>{label}</span>
    </label>
  );
}

function RangeControl({
  label,
  value,
  metadata,
  onChange,
  compact = false,
}: {
  label: string;
  value: number | null | undefined;
  metadata: WorkbenchNumberControlMetadata | {
    min: number;
    max: number;
    step: number;
  };
  onChange: (value: number | null) => void;
  compact?: boolean;
}) {
  const inputId = useId();
  const nullable = "nullable" in metadata && metadata.nullable;
  const isAuto = Boolean(nullable && value === null);
  const current = value ?? metadata.min;

  return (
    <div className={`control-field range-control${compact ? " compact" : ""}`}>
      <div className="range-label">
        <label htmlFor={inputId}>{label}</label>
        <output>{isAuto ? "Auto" : current}</output>
      </div>
      <input
        id={inputId}
        type="range"
        min={metadata.min}
        max={metadata.max}
        step={metadata.step}
        value={current}
        disabled={isAuto}
        onChange={(event) => onChange(Number(event.target.value))}
      />
      {nullable && (
        <CheckControl
          label="Automatic"
          checked={isAuto}
          onChange={(checked) => onChange(checked ? null : metadata.min)}
        />
      )}
    </div>
  );
}

function WorkbenchError({
  title,
  message,
  actionLabel,
  onAction,
}: {
  title: string;
  message: string;
  actionLabel: string;
  onAction: () => void;
}) {
  return (
    <div className="workbench-error" role="alert">
      <h4>{title}</h4>
      <p>{message}</p>
      <button className="btn btn-ghost" type="button" onClick={onAction}>
        {actionLabel}
      </button>
    </div>
  );
}

function createDefaultExamples(
  capability: WorkbenchColorCapability,
): ExamplesByKind {
  return {
    message: createDefaultExample("message", capability),
    style: createDefaultExample("style", capability),
    box: createDefaultExample("box", capability),
    table: createDefaultExample("table", capability),
  };
}

function withCapability(
  example: WorkbenchExample,
  capability: WorkbenchColorCapability,
): WorkbenchExample {
  switch (example.kind) {
    case "message":
      return { ...example, capability };
    case "style":
      return { ...example, capability };
    case "box":
      return { ...example, capability };
    case "table":
      return { ...example, capability };
  }
}

function createDefaultExample(
  kind: "message",
  capability: WorkbenchColorCapability,
): MessageWorkbenchExample;
function createDefaultExample(
  kind: "style",
  capability: WorkbenchColorCapability,
): StyleWorkbenchExample;
function createDefaultExample(
  kind: "box",
  capability: WorkbenchColorCapability,
): BoxWorkbenchExample;
function createDefaultExample(
  kind: "table",
  capability: WorkbenchColorCapability,
): TableWorkbenchExample;
function createDefaultExample(
  kind: WorkbenchKind,
  capability: WorkbenchColorCapability,
): WorkbenchExample;
function createDefaultExample(
  kind: WorkbenchKind,
  capability: WorkbenchColorCapability,
): WorkbenchExample {
  switch (kind) {
    case "message":
      return {
        ...getWorkbenchPreset("message").defaultExample,
        capability,
      };
    case "style":
      return {
        ...getWorkbenchPreset("style").defaultExample,
        capability,
      };
    case "box": {
      const example = getWorkbenchPreset("box").defaultExample;
      return {
        ...example,
        capability,
        padding: { ...example.padding },
      };
    }
    case "table": {
      const example = getWorkbenchPreset("table").defaultExample;
      return {
        ...example,
        capability,
        headers: [...example.headers],
        rows: example.rows.map((row) => [...row]),
        width: cloneTableWidth(example.width),
      };
    }
  }
}

function cloneTableWidth(
  width: TableWorkbenchExample["width"],
): TableWorkbenchExample["width"] {
  return width.kind === "columns"
    ? { kind: "columns", values: [...width.values] }
    : { ...width };
}

function colorLabel(capability: WorkbenchColorCapability): string {
  return (
    colorOptions.find((option) => option.value === capability)?.label ??
    capability
  );
}

function colorKey(color: WorkbenchColor): string {
  return JSON.stringify(color);
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
}

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : "Unknown renderer error.";
}
