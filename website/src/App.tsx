import { lazy, Suspense, useState } from "react";
import {
  Reveal,
  Terminal,
  Tabs,
  CopyButton,
  ThemeToggle,
} from "./components/ui";
import { GitHubIcon, ArrowIcon, BookIcon } from "./icons";
import { terminalBlocks as T } from "./data/terminalBlocks";
import type { WorkbenchColorCapability } from "./workbench";

const Workbench = lazy(async () => {
  const module = await import("./components/Workbench");
  return { default: module.Workbench };
});

const REPO = "https://github.com/tylerbutler/spruce";
const CI = `${REPO}/actions`;
const DOCS = "https://hexdocs.pm/spruce/";
const HEX = "https://hex.pm/packages/spruce";
const INSTALL = "gleam add spruce";

const heroModes = [
  { id: "truecolor", label: "TrueColor", block: "hero" },
  { id: "ansi256", label: "256 color", block: "hero_ansi256" },
  { id: "basic", label: "Basic", block: "hero_basic" },
  { id: "no_color", label: "No color", block: "hero_plain" },
] as const;

const moduleGroups: Array<{
  title: string;
  summary: string;
  modules: Array<[string, string]>;
}> = [
  {
    title: "Render context",
    summary: "Detect once, then thread pure render state everywhere.",
    modules: [
      ["spruce", "Color level, background, and indent depth."],
      ["spruce/output", "Pipeable, buffered composition and grouping."],
    ],
  },
  {
    title: "Style and symbols",
    summary: "Build reusable color, emphasis, and terminal glyphs.",
    modules: [
      ["spruce/style", "Named, RGB, hex, 256, adaptive, and hashed colors."],
      ["spruce/symbol", "Named glyphs with automatic ASCII fallbacks."],
    ],
  },
  {
    title: "Layout primitives",
    summary: "Control width, alignment, borders, and framed blocks.",
    modules: [
      ["spruce/align", "ANSI-aware length, padding, and block composition."],
      ["spruce/border", "Border styles and glyphs shared by boxes and tables."],
      ["spruce/box", "Titles, padding, margin, sizing, alignment, borders."],
    ],
  },
  {
    title: "Structured content",
    summary: "Render data and hierarchy without hand-built spacing.",
    modules: [
      ["spruce/table", "Widths, borders, separators, and cell wrapping."],
      ["spruce/item", "Bulleted and ordered lists with arbitrary nesting."],
      ["spruce/tree", "Tree-structured output with Unicode or ASCII."],
    ],
  },
  {
    title: "Status and diagnostics",
    summary: "Give developer-facing lines consistent meaning and detail.",
    modules: [
      ["spruce/severity", "RFC 5424 severity labels, badges, and formatters."],
      ["spruce/message", "Semantic one-liners: success, fail, start, and more."],
      ["spruce/line", "Compact severity, scope, and key/value detail."],
      ["spruce/detail", "Key and value detail rendering."],
    ],
  },
  {
    title: "Rich text",
    summary: "Bring source code and Markdown into terminal output.",
    modules: [
      ["spruce/highlight", "Syntax highlighting for fenced code blocks."],
      ["spruce/markdown", "Markdown to ANSI, in the style of Glamour."],
    ],
  },
];

function Nav() {
  return (
    <header className="nav">
      <div className="wrap nav-inner">
        <a className="brand" href="#top">
          <img src="./spruce.webp" alt="spruce logo" />
          <span>spruce</span>
        </a>
        <div className="nav-spacer" />
        <nav className="nav-links">
          <a className="text nav-hide-sm" href="#workbench">
            Workbench
          </a>
          <a className="text nav-hide-sm" href="#modules">
            Modules
          </a>
          <a className="text" href={DOCS}>
            Docs
          </a>
          <a className="icon-btn" href={REPO} aria-label="GitHub repository">
            <GitHubIcon />
          </a>
          <ThemeToggle />
        </nav>
      </div>
    </header>
  );
}

function Hero({
  capability,
  onCapabilityChange,
}: {
  capability: WorkbenchColorCapability;
  onCapabilityChange: (capability: WorkbenchColorCapability) => void;
}) {
  const activeMode =
    heroModes.find((item) => item.id === capability) ?? heroModes[0];
  return (
    <section className="hero" id="top">
      <div className="wrap hero-grid">
        <div>
          <h1>
            One render path.{" "}
            <span className="solid-emphasis">Every terminal.</span>
          </h1>
          <p className="lead">
            spruce gives Gleam apps pure, testable terminal UI that adapts from
            TrueColor to plain text without branches in your code.
          </p>
          <div className="hero-cta">
            <CopyButton text={INSTALL} />
            <a className="docs-link" href={DOCS}>
              Read the docs <ArrowIcon />
            </a>
          </div>
        </div>
        <div className="hero-demo">
          <Tabs
            name="hero-color"
            label="Terminal color support"
            options={heroModes.map((item) => ({
              value: item.id,
              label: item.label,
            }))}
            value={capability}
            onChange={onCapabilityChange}
          >
            <Terminal
              title={`$ gleam run · ${activeMode.label}`}
              html={T[activeMode.block]}
              caret
            />
          </Tabs>
          <p className="hero-proof">
            Same Gleam code. The nearest supported color, automatically.
          </p>
        </div>
      </div>
    </section>
  );
}

function Runtimes() {
  return (
    <section className="runtimes" aria-labelledby="runtimes-title">
      <div className="wrap runtime-proof">
        <div className="runtime-proof-copy">
          <h2 id="runtimes-title">Same render. Both runtimes.</h2>
          <p>
            No native extensions. The same pure Gleam path produces the same
            output on Erlang and JavaScript.
          </p>
          <a className="runtime-ci" href={CI}>
            See the test matrix <ArrowIcon />
          </a>
        </div>
        <div className="runtime-outputs">
          <Terminal
            title="$ gleam run --target erlang"
            html={T.parity}
          />
          <Terminal
            title="$ gleam run --target javascript"
            html={T.parity}
          />
        </div>
      </div>
    </section>
  );
}

function Modules() {
  return (
    <section className="section" id="modules" style={{ paddingTop: 0 }}>
      <div className="wrap">
        <Reveal className="section-head">
          <h2>Focused modules for every terminal job.</h2>
          <p className="lead">
            Start with <code>message</code> for status lines, <code>box</code>{" "}
            for framed blocks, or <code>output</code> to compose a complete
            render.
          </p>
        </Reveal>
        <div className="mods">
          {moduleGroups.map((group) => (
            <Reveal
              className="module-group"
              key={group.title}
            >
              <div className="module-group-head">
                <h3>{group.title}</h3>
                <p>{group.summary}</p>
              </div>
              <div className="module-list">
                {group.modules.map(([name, desc]) => (
                  <a
                    className="mod"
                    href={`${DOCS}${name}.html`}
                    key={name}
                  >
                    <code>{name}</code>
                    <span>{desc}</span>
                    <ArrowIcon />
                  </a>
                ))}
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}

function Cta() {
  return (
    <section className="section" style={{ paddingTop: 0 }}>
      <div className="wrap">
        <Reveal className="cta-band">
          <h2>Add spruce to your project.</h2>
          <p>
            It is on Hex, dual-licensed under MIT and Apache-2.0, and ready on
            both runtimes.
          </p>
          <div className="cta-actions">
            <CopyButton text={INSTALL} />
            <a className="btn btn-primary" href={DOCS}>
              <BookIcon /> Read the docs
            </a>
            <a className="btn btn-ghost" href={REPO}>
              <GitHubIcon /> View on GitHub
            </a>
          </div>
        </Reveal>
      </div>
    </section>
  );
}

function Footer() {
  return (
    <footer className="footer">
      <div className="wrap footer-inner">
        <a className="brand" href="#top">
          <img src="./spruce.webp" alt="" width={22} height={22} />
          <span>spruce</span>
        </a>
        <span className="dotsep">/</span>
        <a href={HEX}>Hex</a>
        <a href={DOCS}>HexDocs</a>
        <a href={REPO}>GitHub</a>
        <div className="nav-spacer" />
        <span>MIT / Apache-2.0</span>
        <span className="dotsep">/</span>
        <span>Built with Gleam, {new Date().getFullYear()}</span>
      </div>
    </footer>
  );
}

export default function App() {
  const [capability, setCapability] =
    useState<WorkbenchColorCapability>("truecolor");

  return (
    <>
      <Nav />
      <main>
        <Hero
          capability={capability}
          onCapabilityChange={setCapability}
        />
        <Runtimes />
        <Suspense fallback={null}>
          <Workbench
            capability={capability}
            onCapabilityChange={setCapability}
          />
        </Suspense>
        <Modules />
        <Cta />
      </main>
      <Footer />
    </>
  );
}
