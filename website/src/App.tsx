import { Reveal, Terminal, TermBar, CopyButton, ThemeToggle } from "./components/ui";
import {
  GitHubIcon,
  ArrowIcon,
  BookIcon,
  MessageIcon,
  PaletteIcon,
  TerminalIcon,
  TableIcon,
  TreeIcon,
  ShieldIcon,
} from "./icons";
import { terminalBlocks as T } from "./data/terminalBlocks";

const REPO = "https://github.com/tylerbutler/spruce";
const DOCS = "https://hexdocs.pm/spruce/";
const HEX = "https://hex.pm/packages/spruce";
const INSTALL = "gleam add spruce";

const runtimes = ["gleam", "erlang", "javascript", "nodedotjs"];
const runtimeAlt: Record<string, string> = {
  gleam: "Gleam",
  erlang: "Erlang",
  javascript: "JavaScript",
  nodedotjs: "Node.js",
};

const modules: Array<[string, string]> = [
  ["spruce", "The render context: color level, background, indent depth."],
  ["spruce/align", "ANSI-aware visual length and padding."],
  ["spruce/block", "Padding, margin, sizing, alignment, per-side borders."],
  ["spruce/box", "Boxed output with per-side borders and colors."],
  ["spruce/details", "Key and value detail rendering."],
  ["spruce/group", "Depth-in-context grouping and indentation."],
  ["spruce/highlight", "Syntax highlighting for fenced code blocks."],
  ["spruce/layout", "Compose multi-line text blocks together."],
  ["spruce/line", "Compact, single-line terminal log composition."],
  ["spruce/list", "Bulleted and ordered lists with arbitrary nesting."],
  ["spruce/markdown", "Markdown to ANSI, in the style of Glamour."],
  ["spruce/message", "Semantic one-liners with label, badge, or simple style."],
  ["spruce/output", "Pipeable, buffered output composition."],
  ["spruce/palette", "Deterministic hash colors from any string."],
  ["spruce/severity", "Generic severity and status labels and badges."],
  ["spruce/style", "Composable text styling: named, RGB, hex, 256, adaptive."],
  ["spruce/symbol", "Named glyphs with automatic ASCII fallbacks."],
  ["spruce/table", "Widths, borders, separators, and cell wrapping."],
  ["spruce/tree", "Tree-structured output with Unicode or ASCII."],
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
          <a className="text nav-hide-sm" href="#features">
            Features
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

function Hero() {
  return (
    <section className="hero" id="top">
      <div className="wrap hero-grid">
        <div>
          <p className="eyebrow">Terminal UI kit for Gleam</p>
          <h1>
            Make the terminal <span className="grad">look good.</span>
          </h1>
          <p className="lead">
            spruce renders styled text, boxes, tables, and semantic messages
            that adapt to whatever color the terminal supports.
          </p>
          <div className="hero-cta">
            <CopyButton text={INSTALL} />
            <a className="docs-link" href={DOCS}>
              Read the docs <ArrowIcon />
            </a>
          </div>
        </div>
        <div>
          <Terminal title="$ gleam run" html={T.hero} caret />
        </div>
      </div>
    </section>
  );
}

function Runtimes() {
  return (
    <section className="runtimes">
      <div className="wrap runtimes-inner">
        <p>Compiles to Erlang and JavaScript. No native extensions required.</p>
        <div className="logos">
          {runtimes.map((slug) => (
            <span key={slug}>
              <img
                className="only-dark"
                src={`https://cdn.simpleicons.org/${slug}/b8c2bc`}
                alt={runtimeAlt[slug]}
                height={26}
              />
              <img
                className="only-light"
                src={`https://cdn.simpleicons.org/${slug}/4a574f`}
                alt={runtimeAlt[slug]}
                height={26}
              />
            </span>
          ))}
        </div>
      </div>
    </section>
  );
}

function Features() {
  return (
    <section className="section" id="features">
      <div className="wrap">
        <Reveal className="section-head">
          <h2>Everything you print, composed.</h2>
          <p className="lead">
            One set of pure string builders for the whole surface of your CLI.
            Compose them, test them, then print them.
          </p>
        </Reveal>
        <div className="bento">
          <Reveal className="cell c-4">
            <div className="cell-head">
              <span className="cell-ico">
                <MessageIcon />
              </span>
              <h3>Semantic messages</h3>
            </div>
            <p>
              success, fail, start, ready, info, warn, and error lines, with
              label, badge, or simple prefixes.
            </p>
            <Terminal title="messages" html={T.messages} />
          </Reveal>

          <Reveal className="cell c-2" delay={0.05}>
            <div className="cell-head">
              <span className="cell-ico">
                <PaletteIcon />
              </span>
              <h3>Adaptive color</h3>
            </div>
            <p>Named, RGB, hex, 256, and light or dark adaptive colors.</p>
            <Terminal title="style" html={T.style} />
          </Reveal>

          <Reveal className="cell c-2">
            <div className="cell-head">
              <span className="cell-ico">
                <TableIcon />
              </span>
              <h3>Tables that align</h3>
            </div>
            <p>
              ANSI-aware column widths, per-column sizing, borders, separators,
              and wrapping.
            </p>
            <Terminal title="table" html={T.table} />
          </Reveal>

          <Reveal className="cell c-4" delay={0.05}>
            <div className="cell-head">
              <span className="cell-ico">
                <TerminalIcon />
              </span>
              <h3>Compact lines</h3>
            </div>
            <p>Severity, scope, and key/value details on one tidy line.</p>
            <Terminal title="line" html={T.line} />
          </Reveal>

          <Reveal className="cell c-3">
            <div className="cell-head">
              <span className="cell-ico">
                <TreeIcon />
              </span>
              <h3>Trees and lists</h3>
            </div>
            <p>Nest structure with Unicode branches or ASCII fallbacks.</p>
            <Terminal title="tree" html={T.tree} />
          </Reveal>

          <Reveal className="cell c-3" delay={0.05}>
            <div className="cell-head">
              <span className="cell-ico">
                <ShieldIcon />
              </span>
              <h3>Built for both runtimes</h3>
            </div>
            <p>
              Pure string builders that behave identically on Erlang and
              JavaScript.
            </p>
            <Terminal title="list" html={T.list} />
          </Reveal>
        </div>
      </div>
    </section>
  );
}

function ColorAware() {
  return (
    <section className="section" style={{ paddingTop: 0 }}>
      <div className="wrap">
        <Reveal className="section-head">
          <h2>One render path. Every terminal.</h2>
          <p className="lead">
            spruce detects the color level once. TrueColor, 256, basic, or none.
            The same code downgrades to the nearest representable color, all the
            way down to clean plain text.
          </p>
        </Reveal>
        <div className="compare">
          <Reveal>
            <Terminal title="TrueColor" html={T.hero} />
          </Reveal>
          <Reveal delay={0.05}>
            <Terminal title="NO_COLOR=1" html={T.hero_plain} />
          </Reveal>
        </div>
        <Reveal>
          <p className="compare-note">
            No branching in your code. Pipe the same output to a file or a CI
            log and it stays readable.
          </p>
        </Reveal>
      </div>
    </section>
  );
}

function Example() {
  return (
    <section className="section" style={{ paddingTop: 0 }}>
      <div className="wrap">
        <Reveal className="section-head">
          <h2>A few lines in, styled output out.</h2>
          <p className="lead">
            Detect the context once, thread it through, and every render
            function stays a plain, testable function from <code>Spruce</code>{" "}
            to <code>String</code>.
          </p>
        </Reveal>
        <div className="example-grid">
          <Reveal className="code">
            <TermBar title="main.gleam" />
            <pre>
              <span className="k">import</span> <span className="m">spruce</span>
              {"\n"}
              <span className="k">import</span>{" "}
              <span className="m">spruce/box</span>
              {"\n"}
              <span className="k">import</span>{" "}
              <span className="m">spruce/message</span>
              {"\n\n"}
              <span className="k">pub fn</span> <span className="f">main</span>
              () {"{"}
              {"\n  "}
              <span className="k">let</span> sp ={" "}
              <span className="m">spruce</span>.
              <span className="f">detect</span>()
              {"\n  "}
              <span className="m">box</span>.<span className="f">print</span>(sp,{" "}
              <span className="s">"spruce"</span>)
              {"\n  "}
              <span className="m">message</span>.
              <span className="f">print_success</span>(sp,{" "}
              <span className="s">"ready"</span>)
              {"\n"}
              {"}"}
            </pre>
          </Reveal>
          <Reveal delay={0.05}>
            <Terminal title="$ gleam run" html={T.example} />
          </Reveal>
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
            Import only what you print. Each module owns one job and nothing
            more.
          </p>
        </Reveal>
        <div className="mods">
          {modules.map(([name, desc], i) => (
            <Reveal
              className="mod"
              key={name}
              delay={Math.min(i, 8) * 0.02}
            >
              <code>{name}</code>
              <span>{desc}</span>
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
  return (
    <>
      <Nav />
      <main>
        <Hero />
        <Runtimes />
        <Features />
        <ColorAware />
        <Example />
        <Modules />
        <Cta />
      </main>
      <Footer />
    </>
  );
}
