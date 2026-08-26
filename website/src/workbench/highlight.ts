import { ExpressiveCode, ExpressiveCodeTheme } from "expressive-code";
import { toHtml } from "expressive-code/hast";

const theme = new ExpressiveCodeTheme({
  name: "spruce",
  type: "dark",
  bg: "#090d0b",
  fg: "#cdd6d0",
  colors: {
    "editor.background": "#090d0b",
    "editor.foreground": "#cdd6d0",
    "editor.selectionBackground": "#3f9a6e55",
    "editorLineNumber.foreground": "#74877d",
    "focusBorder": "#4cb782",
    "scrollbarSlider.background": "#ffffff1f",
    "scrollbarSlider.hoverBackground": "#ffffff33",
  },
  tokenColors: [
    {
      scope: ["comment", "punctuation.definition.comment"],
      settings: { foreground: "#74877d", fontStyle: "italic" },
    },
    {
      scope: ["keyword", "storage.modifier", "storage.type"],
      settings: { foreground: "#ec6a82" },
    },
    {
      scope: ["string", "string.quoted"],
      settings: { foreground: "#58c98c" },
    },
    {
      scope: ["constant.numeric", "constant.language"],
      settings: { foreground: "#e6c46a" },
    },
    {
      scope: ["entity.name.function", "support.function"],
      settings: { foreground: "#6aa9e9" },
    },
    {
      scope: [
        "entity.name.namespace",
        "entity.name.type",
        "support.type",
        "variable.other.constant",
      ],
      settings: { foreground: "#56b3a4" },
    },
  ],
});

const highlighter = new ExpressiveCode({
  themes: [theme],
  frames: false,
  shiki: { engine: "javascript" },
  useDarkModeMediaQuery: false,
});

export async function highlightWorkbenchSource(source: string) {
  const result = await highlighter.render({
    code: source,
    language: "gleam",
    meta: "",
  });

  return toHtml(result.renderedGroupAst);
}
