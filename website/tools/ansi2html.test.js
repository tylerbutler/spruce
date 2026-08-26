import test from "node:test";
import assert from "node:assert/strict";
import path from "node:path";
import { pathToFileURL } from "node:url";

import {
  convertAnsiToHtml,
  convertCapturedBlocks,
  escapeHtml,
} from "../src/lib/ansi2html.js";

test("escapes html text", () => {
  assert.equal(escapeHtml(`<&>"'`), "&lt;&amp;&gt;&quot;&#39;");
});

test("renders fg bg attrs and resets", () => {
  const input =
    "\u001b[31;41mred\u001b[39;49m " +
    "\u001b[38;5;196;48;5;24mansi256\u001b[0m " +
    "\u001b[38;2;1;2;3;48;2;4;5;6mtruecolor\u001b[0m " +
    "\u001b[1;2;3;4;7;9mattrs\u001b[22;23;24;27;29m";

  assert.equal(
    convertAnsiToHtml(input),
    '<span style="color:#ff7a7a;background-color:#ff7a7a">red</span> ' +
      '<span style="color:rgb(255,0,0);background-color:rgb(0,95,135)">ansi256</span> ' +
      '<span style="color:rgb(1,2,3);background-color:rgb(4,5,6)">truecolor</span> ' +
      '<span style="color:var(--term-bg);background-color:var(--terminal-body);font-weight:700;opacity:.6;font-style:italic;text-decoration-line:underline line-through">attrs</span>',
  );
});

test("renders reverse with terminal defaults and explicit colors", () => {
  assert.equal(
    convertAnsiToHtml("\u001b[7mplain\u001b[27m"),
    '<span style="color:var(--term-bg);background-color:var(--terminal-body)">plain</span>',
  );
  assert.equal(
    convertAnsiToHtml("\u001b[31;7mfg-only\u001b[27m"),
    '<span style="color:var(--term-bg);background-color:#ff7a7a">fg-only</span>',
  );
  assert.equal(
    convertAnsiToHtml("\u001b[44;7mbg-only\u001b[27m"),
    '<span style="color:#6aa9e9;background-color:var(--terminal-body)">bg-only</span>',
  );
  assert.equal(
    convertAnsiToHtml("\u001b[31;44;7mboth\u001b[27m"),
    '<span style="color:#6aa9e9;background-color:#ff7a7a">both</span>',
  );
});

test("splits captured blocks", () => {
  const raw = "\u0001hero\n\u001b[32mok\u001b[39m\n\u0001end\n";
  assert.deepEqual(convertCapturedBlocks(raw), {
    hero: '<span style="color:#58c98c">ok</span>',
  });
});

test("converts ansi emitted by the generated workbench facade", async () => {
  const workbenchRoot = path.join(
    process.cwd(),
    "workbench/build/dev/javascript/spruce_workbench",
  );
  const gleam = await import(
    pathToFileURL(path.join(workbenchRoot, "gleam.mjs")).href
  );
  const workbench = await import(
    pathToFileURL(path.join(workbenchRoot, "spruce_workbench.mjs")).href
  );

  const styled = workbench.render_style(
    workbench.Capability$Basic(),
    workbench.style_underline(
      workbench.style_bold(
        workbench.style_bg(
          workbench.style_fg(
            workbench.new_style(),
            workbench.Color$BrightWhite(),
          ),
          workbench.Color$Blue(),
        ),
      ),
    ),
    "facade",
  );

  assert.equal(
    styled,
    "\u001b[4m\u001b[1m\u001b[44m\u001b[97mfacade\u001b[39m\u001b[49m\u001b[22m\u001b[24m",
  );
  assert.equal(
    convertAnsiToHtml(styled),
    '<span style="color:#f2f5f2;background-color:#6aa9e9;font-weight:700;text-decoration-line:underline">facade</span>',
  );

  const renderedTable = workbench.render_table(
    workbench.Capability$NoColor(),
    workbench.table_border(
      workbench.table_rows(
        workbench.table_headers(workbench.new_table(), gleam.toList(["A"])),
        gleam.toList([gleam.toList(["x"])]),
      ),
      workbench.BorderStyle$Rounded(),
    ),
  );
  assert.match(renderedTable, /╭───╮/);
});
