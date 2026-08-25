import assert from "node:assert/strict";

import { toList } from "./build/dev/javascript/spruce_workbench/gleam.mjs";
import * as workbench from "./build/dev/javascript/spruce_workbench/spruce_workbench.mjs";
import * as box from "./build/dev/javascript/spruce/spruce/box.mjs";
import * as style from "./build/dev/javascript/spruce/spruce/style.mjs";
import * as table from "./build/dev/javascript/spruce/spruce/table.mjs";

const completeColor = style.complete(
  style.Color$Red(),
  style.Color$Ansi256(200),
  style.Color$Hex(0x874bfd),
);
const colorStyle = style.fg(style.new$(), completeColor);

assert.equal(
  workbench.render_style(workbench.Capability$NoColor(), colorStyle, "x"),
  "x",
);
assert.equal(
  workbench.render_style(workbench.Capability$Basic(), colorStyle, "x"),
  "\u001b[31mx\u001b[39m",
);
assert.equal(
  workbench.render_style(workbench.Capability$Ansi256(), colorStyle, "x"),
  "\u001b[38;5;200mx\u001b[39m",
);
assert.equal(
  workbench.render_style(workbench.Capability$TrueColor(), colorStyle, "x"),
  "\u001b[38;2;135;75;253mx\u001b[39m",
);

assert.equal(
  workbench.render_message(
    workbench.Capability$NoColor(),
    workbench.Message$Success(),
    "ready",
  ),
  "✔ success ready",
);
assert.equal(
  workbench.render_box(
    workbench.Capability$NoColor(),
    "hi",
    box.new$(),
  ),
  "╭────╮\n│ hi │\n╰────╯",
);
assert.equal(
  workbench.render_table(
    workbench.Capability$NoColor(),
    table.rows(
      table.headers(table.new$(), toList(["A"])),
      toList([toList(["x"])]),
    ),
  ),
  "┌───┐\n│ A │\n├───┤\n│ x │\n└───┘",
);

console.log("workbench check passed");
