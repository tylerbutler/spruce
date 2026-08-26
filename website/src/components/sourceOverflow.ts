export type SourceOverflow = {
  horizontal: boolean;
  vertical: boolean;
};

export function detectSourceOverflow(
  element: Pick<
    HTMLElement,
    "scrollWidth" | "clientWidth" | "scrollHeight" | "clientHeight"
  >,
): SourceOverflow {
  return {
    horizontal: element.scrollWidth > element.clientWidth + 1,
    vertical: element.scrollHeight > element.clientHeight + 1,
  };
}

export function sourceOverflowCue(overflow: SourceOverflow) {
  if (overflow.horizontal) {
    return overflow.vertical ? "Scroll ↘" : "Scroll →";
  }
  return overflow.vertical ? "Scroll ↓" : "";
}

export function sourceOverflowHint(overflow: SourceOverflow) {
  if (overflow.horizontal) {
    return overflow.vertical
      ? "This source code scrolls horizontally and vertically."
      : "This source code scrolls horizontally.";
  }
  return overflow.vertical
    ? "This source code scrolls vertically."
    : "";
}
