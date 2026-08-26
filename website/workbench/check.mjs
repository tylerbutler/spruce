import assert from "node:assert/strict";

import { toList } from "./build/dev/javascript/spruce_workbench/gleam.mjs";
import * as workbench from "./build/dev/javascript/spruce_workbench/spruce_workbench.mjs";

const completeColor = workbench.complete_color(
  workbench.Color$Red(),
  workbench.Color$Color256(200),
  workbench.Color$Hex(0x874bfd),
);
const colorStyle = workbench.style_fg(workbench.new_style(), completeColor);

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
  workbench.render_style(
    workbench.Capability$Basic(),
    workbench.style_underline(workbench.style_bold(workbench.new_style())),
    "x",
  ),
  "\u001b[4m\u001b[1mx\u001b[22m\u001b[24m",
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
    workbench.box_border(
      workbench.box_padding(workbench.new_box(), 0, 1, 0, 1),
      workbench.BorderStyle$Rounded(),
    ),
  ),
  "╭────╮\n│ hi │\n╰────╯",
);
assert.equal(
  workbench.render_table(
    workbench.Capability$NoColor(),
    workbench.table_border(
      workbench.table_row_separators(
        workbench.table_rows(
          workbench.table_headers(workbench.new_table(), toList(["A"])),
          toList([toList(["x"]), toList(["y"])]),
        ),
        true,
      ),
      workbench.BorderStyle$Double(),
    ),
  ),
  "╔═══╗\n║ A ║\n╠═══╣\n║ x ║\n╠═══╣\n║ y ║\n╚═══╝",
);

console.log("workbench check passed");
