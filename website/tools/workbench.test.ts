import assert from "node:assert/strict";
import test from "node:test";

import { terminalBlocks } from "../src/data/terminalBlocks.ts";
import { convertAnsiToHtml } from "../src/lib/ansi2html.js";
import { getWorkbenchPreset } from "../src/workbench/index.ts";
import { workbenchPresets } from "../src/workbench/registry.ts";
import { loadWorkbenchAdapter } from "../src/workbench/loadAdapter.ts";
import { renderWorkbenchSource } from "../src/workbench/source.ts";
import {
  detectSourceOverflow,
  sourceOverflowCue,
  sourceOverflowHint,
} from "../src/components/sourceOverflow.ts";

test("workbench presets stay mapped to source and rendered output", async () => {
  const adapter = await loadWorkbenchAdapter();

  for (const preset of workbenchPresets) {
    assert.ok(terminalBlocks[preset.fallbackBlock], `${preset.id} fallback exists`);
    assert.deepEqual(
      Object.keys(preset.controlMetadata).sort(),
      preset.supportedControls
        .filter((control) => control in preset.controlMetadata)
        .sort(),
      `${preset.id} metadata covers the bounded controls`,
    );

    const source = preset.createSource();
    const result = adapter.render(preset.defaultExample);

    assert.equal(source, renderWorkbenchSource(preset.defaultExample));
    assert.equal(result.html, convertAnsiToHtml(result.ansi));
    assert.ok(result.html.length > 0, `${preset.id} renders html`);
    assert.doesNotMatch(source, /spruce_workbench/);
    assert.match(source, /import gleam\/io/);
    assert.match(source, /import spruce/);
    assert.match(source, /io\.println/);

    switch (preset.id) {
      case "message":
        assert.match(source, /import spruce\/message/);
        assert.match(source, /message\.success/);
        assert.match(source, /Deploy complete/);
        assert.match(result.html, /Deploy complete/);
        break;
      case "style":
        assert.match(source, /import spruce\/style/);
        assert.match(source, /style\.fg/);
        assert.match(source, /style\.bg/);
        assert.equal(
          preset.controlMetadata.foreground.kind,
          "choice",
        );
        assert.ok(
          preset.controlMetadata.foreground.options.some(
            (option) => option.label === "Spruce aqua",
          ),
          "style colors include the shared complete color option",
        );
        assert.match(result.ansi, /\u001b\[/);
        assert.match(result.html, /facade/);
        break;
      case "box":
        assert.deepEqual(preset.supportedControls, [
          "capability",
          "content",
          "title",
          "padding",
          "width",
          "alignment",
          "border",
        ]);
        assert.match(source, /import spruce\/box/);
        assert.match(source, /import spruce\/align/);
        assert.match(source, /import spruce\/border/);
        assert.match(source, /box\.title/);
        assert.match(source, /box\.align/);
        assert.deepEqual(preset.controlMetadata.padding, {
          kind: "padding",
          min: 0,
          max: 4,
          step: 1,
        });
        assert.equal(preset.controlMetadata.alignment.kind, "choice");
        assert.deepEqual(
          preset.controlMetadata.alignment.options.map((option) => option.value),
          ["start", "center", "end"],
        );
        assert.doesNotMatch(source, /box\.(plain|height|border_color)/);
        assert.match(result.html, /spruce/);
        assert.match(result.html, /ready/);
        break;
      case "table":
        assert.match(source, /import spruce\/table/);
        assert.match(source, /table\.headers/);
        assert.equal(preset.controlMetadata.width.kind, "table_width");
        assert.deepEqual(
          preset.controlMetadata.width.modes.map((mode) => mode.value),
          ["auto", "table", "columns"],
        );
        assert.match(result.html, /Module/);
        assert.match(result.html, /spruce\/table/);
        break;
    }
  }
});

test("box alignment stays synchronized across preset, source, and runtime", async () => {
  const adapter = await loadWorkbenchAdapter();
  const preset = getWorkbenchPreset("box");
  const centered = {
    ...preset.defaultExample,
    width: 16,
    alignment: "center" as const,
  };
  const source = renderWorkbenchSource(centered);
  const result = adapter.render(centered);

  assert.match(source, /import spruce\/align/);
  assert.match(
    source,
    /\|> box\.align\(horizontal: align\.Center, vertical: align\.Start\)/,
  );
  assert.doesNotMatch(source, /box\.(plain|height|border_color)/);
  assert.match(stripAnsi(result.ansi), /│\s+ready\s+│/);
});

test("source overflow announces the active scroll axis", () => {
  assert.deepEqual(
    detectSourceOverflow({
      scrollWidth: 100,
      clientWidth: 100,
      scrollHeight: 120,
      clientHeight: 100,
    } as HTMLElement),
    { horizontal: false, vertical: true },
  );
  assert.equal(
    sourceOverflowCue({ horizontal: false, vertical: true }),
    "Scroll ↓",
  );
  assert.equal(
    sourceOverflowHint({ horizontal: false, vertical: true }),
    "This source code scrolls vertically.",
  );
  assert.equal(
    sourceOverflowCue({ horizontal: true, vertical: true }),
    "Scroll ↘",
  );
  assert.equal(
    sourceOverflowHint({ horizontal: true, vertical: false }),
    "This source code scrolls horizontally.",
  );
});

function stripAnsi(value: string): string {
  return value.replace(/\u001b\[[0-9;]*m/g, "");
}
