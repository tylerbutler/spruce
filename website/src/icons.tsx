import type { JSX, SVGProps } from "react";

type IconProps = SVGProps<SVGSVGElement>;

const stroke = {
  fill: "none",
  stroke: "currentColor",
  strokeWidth: 2,
  strokeLinecap: "round" as const,
  strokeLinejoin: "round" as const,
};

export const GitHubIcon = (p: IconProps): JSX.Element => (
  <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true" {...p}>
    <path d="M12 .5C5.7.5.6 5.6.6 11.9c0 5 3.3 9.3 7.8 10.8.6.1.8-.2.8-.5v-2c-3.2.7-3.9-1.4-3.9-1.4-.5-1.3-1.3-1.7-1.3-1.7-1-.7.1-.7.1-.7 1.2.1 1.8 1.2 1.8 1.2 1 1.8 2.8 1.3 3.5 1 .1-.8.4-1.3.7-1.6-2.6-.3-5.3-1.3-5.3-5.7 0-1.3.5-2.3 1.2-3.1-.1-.3-.5-1.5.1-3.1 0 0 1-.3 3.3 1.2a11.5 11.5 0 0 1 6 0C17.3 4.6 18.3 5 18.3 5c.6 1.6.2 2.8.1 3.1.8.8 1.2 1.8 1.2 3.1 0 4.4-2.7 5.4-5.3 5.7.4.4.8 1.1.8 2.2v3.3c0 .3.2.6.8.5 4.5-1.5 7.8-5.8 7.8-10.8C23.4 5.6 18.3.5 12 .5Z" />
  </svg>
);

export const ArrowIcon = (p: IconProps): JSX.Element => (
  <svg viewBox="0 0 24 24" {...stroke} {...p}>
    <path d="M5 12h14M13 6l6 6-6 6" />
  </svg>
);

export const CopyIcon = (p: IconProps): JSX.Element => (
  <svg viewBox="0 0 24 24" {...stroke} {...p}>
    <rect x="9" y="9" width="11" height="11" rx="2" />
    <path d="M5 15V5a2 2 0 0 1 2-2h10" />
  </svg>
);

export const CheckIcon = (p: IconProps): JSX.Element => (
  <svg viewBox="0 0 24 24" {...stroke} strokeWidth={2.2} {...p}>
    <path d="M20 6 9 17l-5-5" />
  </svg>
);

export const MoonIcon = (p: IconProps): JSX.Element => (
  <svg viewBox="0 0 24 24" {...stroke} {...p}>
    <path d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8Z" />
  </svg>
);

export const SunIcon = (p: IconProps): JSX.Element => (
  <svg viewBox="0 0 24 24" {...stroke} {...p}>
    <circle cx="12" cy="12" r="4" />
    <path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4" />
  </svg>
);

export const BookIcon = (p: IconProps): JSX.Element => (
  <svg viewBox="0 0 24 24" {...stroke} {...p}>
    <path d="M4 5a2 2 0 0 1 2-2h9v16H6a2 2 0 0 0-2 2V5Z" />
    <path d="M15 3h3a2 2 0 0 1 2 2v14a2 2 0 0 0-2-2h-3" />
  </svg>
);

export const MessageIcon = (p: IconProps): JSX.Element => (
  <svg viewBox="0 0 24 24" {...stroke} {...p}>
    <path d="M21 15a2 2 0 0 1-2 2H8l-4 4V5a2 2 0 0 1 2-2h13a2 2 0 0 1 2 2v10Z" />
  </svg>
);

export const PaletteIcon = (p: IconProps): JSX.Element => (
  <svg viewBox="0 0 24 24" {...stroke} {...p}>
    <path d="M12 21a9 9 0 1 1 9-9c0 1.7-1.3 3-3 3h-1.5a1.5 1.5 0 0 0-1 2.6c.3.3.5.7.5 1.1A2.3 2.3 0 0 1 12 21Z" />
    <circle cx="7.5" cy="11.5" r="1" />
    <circle cx="10" cy="7.5" r="1" />
    <circle cx="15" cy="8" r="1" />
  </svg>
);

export const TerminalIcon = (p: IconProps): JSX.Element => (
  <svg viewBox="0 0 24 24" {...stroke} {...p}>
    <rect x="3" y="4" width="18" height="16" rx="2" />
    <path d="M7 9l3 3-3 3M13 15h4" />
  </svg>
);

export const TableIcon = (p: IconProps): JSX.Element => (
  <svg viewBox="0 0 24 24" {...stroke} {...p}>
    <rect x="3" y="4" width="18" height="16" rx="2" />
    <path d="M3 10h18M9 10v10" />
  </svg>
);

export const TreeIcon = (p: IconProps): JSX.Element => (
  <svg viewBox="0 0 24 24" {...stroke} {...p}>
    <rect x="9" y="3" width="6" height="5" rx="1" />
    <rect x="3" y="16" width="6" height="5" rx="1" />
    <rect x="15" y="16" width="6" height="5" rx="1" />
    <path d="M12 8v4M6 16v-2h12v2" />
  </svg>
);

export const ShieldIcon = (p: IconProps): JSX.Element => (
  <svg viewBox="0 0 24 24" {...stroke} {...p}>
    <path d="M12 2 4 5v6c0 5 3.4 8.5 8 11 4.6-2.5 8-6 8-11V5l-8-3Z" />
    <path d="M9 12l2 2 4-4" />
  </svg>
);
