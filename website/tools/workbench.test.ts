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

    const source = preset.createSource();
    const result = adapter.render(preset.defaultExample);

    assert.equal(source, renderWorkbenchSource(preset.defaultExample));
    assert.equal(result.html, convertAnsiToHtml(result.ansi));
    assert.ok(result.html.length > 0, `${preset.id} renders html`);
    assert.match(source, new RegExp(`render_${preset.id}`));

    switch (preset.id) {
      case "message":
        assert.match(source, /Deploy complete/);
        assert.match(result.html, /Deploy complete/);
        break;
      case "style":
        assert.match(source, /style_fg/);
        assert.match(source, /style_bg/);
        assert.match(result.ansi, /\u001b\[/);
        assert.match(result.html, /facade/);
        break;
      case "box":
        assert.match(source, /box_title/);
        assert.match(result.html, /spruce/);
        assert.match(result.html, /ready/);
        break;
      case "table":
        assert.match(source, /table_headers/);
        assert.match(result.html, /Module/);
        assert.match(result.html, /spruce\/table/);
        break;
    }
  }
});
