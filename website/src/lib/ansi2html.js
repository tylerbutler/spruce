const PAL = {
  30: "#3b403b",
  31: "#ff7a7a",
  32: "#58c98c",
  33: "#e6c46a",
  34: "#6aa9e9",
  35: "#ec6a82",
  36: "#56b3a4",
  37: "#d7dcd7",
  90: "#7c857d",
  91: "#ff9a9a",
  92: "#7fdca7",
  93: "#f0d489",
  94: "#90c2f2",
  95: "#f59ab0",
  96: "#7fccc0",
  97: "#f2f5f2",
};

const FG_BASIC = {
  30: PAL[30],
  31: PAL[31],
  32: PAL[32],
  33: PAL[33],
  34: PAL[34],
  35: PAL[35],
  36: PAL[36],
  37: PAL[37],
  90: PAL[90],
  91: PAL[91],
  92: PAL[92],
  93: PAL[93],
  94: PAL[94],
  95: PAL[95],
  96: PAL[96],
  97: PAL[97],
};

const BG_BASIC = {
  40: PAL[30],
  41: PAL[31],
  42: PAL[32],
  43: PAL[33],
  44: PAL[34],
  45: PAL[35],
  46: PAL[36],
  47: PAL[37],
  100: PAL[90],
  101: PAL[91],
  102: PAL[92],
  103: PAL[93],
  104: PAL[94],
  105: PAL[95],
  106: PAL[96],
  107: PAL[97],
};

const DEFAULT_TERMINAL_FG = "var(--terminal-body)";
const DEFAULT_TERMINAL_BG = "var(--term-bg)";

export function escapeHtml(value) {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

export function ansi256ToCssColor(index) {
  const value = clamp(index, 0, 255);
  if (value < 16) {
    const code = value < 8 ? 30 + value : 82 + value;
    return FG_BASIC[code] ?? "#cccccc";
  }
  if (value < 232) {
    const levels = [0, 95, 135, 175, 215, 255];
    const offset = value - 16;
    const r = levels[Math.floor(offset / 36)];
    const g = levels[Math.floor((offset % 36) / 6)];
    const b = levels[offset % 6];
    return `rgb(${r},${g},${b})`;
  }
  const gray = 8 + (value - 232) * 10;
  return `rgb(${gray},${gray},${gray})`;
}

export function convertAnsiToHtml(text) {
  let out = "";
  const state = {
    fg: null,
    bg: null,
    bold: false,
    dim: false,
    italic: false,
    underline: false,
    strikethrough: false,
    reverse: false,
  };
  let openStyle = null;
  const emit = (chunk) => {
    if (!chunk) return;
    const style = buildStyle(state) || null;
    if (style !== openStyle) {
      if (openStyle !== null) out += "</span>";
      openStyle = style;
      if (openStyle !== null) out += `<span style="${openStyle}">`;
    }
    out += escapeHtml(chunk);
  };

  let lastIndex = 0;
  const pattern = /\x1b\[([0-9;]*)m/g;
  for (
    let match = pattern.exec(text);
    match !== null;
    match = pattern.exec(text)
  ) {
    emit(text.slice(lastIndex, match.index));
    applyCodes(state, match[1]);
    lastIndex = match.index + match[0].length;
  }

  emit(text.slice(lastIndex));

  if (openStyle !== null) out += "</span>";
  return out;
}

export function convertCapturedBlocks(raw) {
  const blocks = {};
  for (const segment of raw.split("\x01")) {
    if (!segment.trim()) continue;
    const nl = segment.indexOf("\n");
    const name = segment.slice(0, nl).trim();
    if (name === "end") continue;
    const body = segment.slice(nl + 1).replace(/\n+$/, "");
    blocks[name] = convertAnsiToHtml(body);
  }
  return blocks;
}

function applyCodes(state, rawCodes) {
  const codes = rawCodes === "" ? [0] : rawCodes.split(";").map(Number);
  for (let i = 0; i < codes.length; i += 1) {
    const code = codes[i];
    if (code === 0) {
      state.fg = null;
      state.bg = null;
      state.bold = false;
      state.dim = false;
      state.italic = false;
      state.underline = false;
      state.strikethrough = false;
      state.reverse = false;
    } else if (code === 1) state.bold = true;
    else if (code === 2) state.dim = true;
    else if (code === 3) state.italic = true;
    else if (code === 4) state.underline = true;
    else if (code === 7) state.reverse = true;
    else if (code === 9) state.strikethrough = true;
    else if (code === 22) {
      state.bold = false;
      state.dim = false;
    } else if (code === 23) state.italic = false;
    else if (code === 24) state.underline = false;
    else if (code === 27) state.reverse = false;
    else if (code === 29) state.strikethrough = false;
    else if (code === 39) state.fg = null;
    else if (code === 49) state.bg = null;
    else if (code === 38 && codes[i + 1] === 2) {
      state.fg = `rgb(${clamp(codes[i + 2], 0, 255)},${clamp(codes[i + 3], 0, 255)},${clamp(codes[i + 4], 0, 255)})`;
      i += 4;
    } else if (code === 48 && codes[i + 1] === 2) {
      state.bg = `rgb(${clamp(codes[i + 2], 0, 255)},${clamp(codes[i + 3], 0, 255)},${clamp(codes[i + 4], 0, 255)})`;
      i += 4;
    } else if (code === 38 && codes[i + 1] === 5) {
      state.fg = ansi256ToCssColor(codes[i + 2]);
      i += 2;
    } else if (code === 48 && codes[i + 1] === 5) {
      state.bg = ansi256ToCssColor(codes[i + 2]);
      i += 2;
    } else if (FG_BASIC[code]) {
      state.fg = FG_BASIC[code];
    } else if (BG_BASIC[code]) {
      state.bg = BG_BASIC[code];
    }
  }
}

function buildStyle(state) {
  const parts = [];
  const { fg, bg } = resolveEffectiveColors(state);
  if (fg) parts.push(`color:${fg}`);
  if (bg) parts.push(`background-color:${bg}`);
  if (state.bold) parts.push("font-weight:700");
  if (state.dim) parts.push("opacity:.6");
  if (state.italic) parts.push("font-style:italic");
  const decorations = [];
  if (state.underline) decorations.push("underline");
  if (state.strikethrough) decorations.push("line-through");
  if (decorations.length) {
    parts.push(`text-decoration-line:${decorations.join(" ")}`);
  }
  return parts.join(";");
}

function resolveEffectiveColors(state) {
  if (!state.reverse) {
    return { fg: state.fg, bg: state.bg };
  }

  return {
    fg: state.bg ?? DEFAULT_TERMINAL_BG,
    bg: state.fg ?? DEFAULT_TERMINAL_FG,
  };
}

function clamp(value, min, max) {
  return Math.max(min, Math.min(max, Number(value) || 0));
}
