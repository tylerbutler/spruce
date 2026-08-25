import test from "node:test";
import assert from "node:assert/strict";

import {
  convertAnsiToHtml,
  convertCapturedBlocks,
  escapeHtml,
} from "./ansi2html.js";

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
      '<span style="font-weight:700;opacity:.6;font-style:italic;text-decoration-line:underline line-through;filter:invert(100%)">attrs</span>',
  );
});

test("splits captured blocks", () => {
  const raw = "\u0001hero\n\u001b[32mok\u001b[39m\n\u0001end\n";
  assert.deepEqual(convertCapturedBlocks(raw), {
    hero: '<span style="color:#58c98c">ok</span>',
  });
});
