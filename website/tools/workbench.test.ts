import assert from "node:assert/strict";
import test from "node:test";

import { terminalBlocks } from "../src/data/terminalBlocks.ts";
import { convertAnsiToHtml } from "../src/lib/ansi2html.js";
import { workbenchPresets } from "../src/workbench/registry.ts";
import { loadWorkbenchAdapter } from "../src/workbench/loadAdapter.ts";
import { renderWorkbenchSource } from "../src/workbench/source.ts";

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
        assert.match(source, /import spruce\/box/);
        assert.match(source, /import spruce\/border/);
        assert.match(source, /box\.title/);
        assert.deepEqual(preset.controlMetadata.padding, {
          kind: "padding",
          min: 0,
          max: 4,
          step: 1,
        });
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
