// Converts captured spruce ANSI output into HTML spans, split by \u0001 markers.
// Reads from the file named in argv[2], or from stdin; writes block JSON to stdout.
const fs = require("fs");
const raw = fs.readFileSync(process.argv[2] ?? 0, "utf8");

const PAL = {
  30: "#3b403b", 31: "#ff7a7a", 32: "#58c98c", 33: "#e6c46a",
  34: "#6aa9e9", 35: "#ec6a82", 36: "#56b3a4", 37: "#d7dcd7",
  90: "#6b726b", 91: "#ff9a9a", 92: "#7fdca7", 93: "#f0d489",
  94: "#90c2f2", 95: "#f59ab0", 96: "#7fccc0", 97: "#f2f5f2",
};

function esc(s) {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

function convert(text) {
  let i = 0;
  let out = "";
  const st = { fg: null, bold: false, dim: false, italic: false };
  let openStyle = null;

  function styleStr() {
    const parts = [];
    if (st.fg) parts.push(`color:${st.fg}`);
    if (st.bold) parts.push("font-weight:700");
    if (st.dim) parts.push("opacity:.6");
    if (st.italic) parts.push("font-style:italic");
    return parts.join(";");
  }
  // Open/close spans lazily, only when text is actually emitted, so SGR
  // changes with nothing between them never produce empty spans.
  function emit(str) {
    const want = styleStr() || null;
    if (want !== openStyle) {
      if (openStyle !== null) out += "</span>";
      openStyle = want;
      if (openStyle !== null) out += `<span style="${openStyle}">`;
    }
    out += str;
  }

  while (i < text.length) {
    const c = text[i];
    if (c === "\x1b" && text[i + 1] === "[") {
      const m = /^\x1b\[([0-9;]*)m/.exec(text.slice(i));
      if (m) {
        const codes = m[1].split(";").map(Number);
        for (let k = 0; k < codes.length; k++) {
          const code = codes[k];
          if (code === 0) { st.fg = null; st.bold = false; st.dim = false; st.italic = false; }
          else if (code === 1) st.bold = true;
          else if (code === 2) st.dim = true;
          else if (code === 3) st.italic = true;
          else if (code === 22) { st.bold = false; st.dim = false; }
          else if (code === 23) st.italic = false;
          else if (code === 39) st.fg = null;
          else if (code === 38 && codes[k + 1] === 2) {
            st.fg = `rgb(${codes[k + 2]},${codes[k + 3]},${codes[k + 4]})`; k += 4;
          } else if (code === 38 && codes[k + 1] === 5) {
            st.fg = "#cccccc"; k += 2;
          } else if (PAL[code]) st.fg = PAL[code];
        }
        i += m[0].length;
        continue;
      }
    }
    emit(esc(c));
    i++;
  }
  if (openStyle !== null) out += "</span>";
  return out;
}

// Split by markers
const blocks = {};
const segs = raw.split("\x01");
for (const seg of segs) {
  if (!seg.trim()) continue;
  const nl = seg.indexOf("\n");
  const name = seg.slice(0, nl).trim();
  let body = seg.slice(nl + 1);
  body = body.replace(/\n+$/,"");
  if (name === "end") continue;
  blocks[name] = convert(body);
}

process.stdout.write(JSON.stringify(blocks, null, 2) + "\n");
console.error("blocks:", Object.keys(blocks).join(", "));
