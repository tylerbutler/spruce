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
    summary: "Build reusable terminal styling without leaking IO.",
    modules: [
      ["spruce/style", "Named, RGB, hex, 256, adaptive, and hashed colors."],
      ["spruce/symbol", "Named glyphs with automatic ASCII fallbacks."],
      ["spruce/severity", "RFC 5424 severity labels, badges, and formatters."],
    ],
  },
  {
    title: "Structure and layout",
    summary: "Keep multiline output aligned, nested, and readable.",
    modules: [
      ["spruce/align", "ANSI-aware length, padding, and block composition."],
      ["spruce/border", "Border styles and glyphs shared by boxes and tables."],
      ["spruce/box", "Titles, padding, margin, sizing, alignment, borders."],
      ["spruce/table", "Widths, borders, separators, and cell wrapping."],
      ["spruce/item", "Bulleted and ordered lists with arbitrary nesting."],
      ["spruce/tree", "Tree-structured output with Unicode or ASCII."],
    ],
  },
  {
    title: "Semantic output",
    summary: "Turn raw strings into meaningful developer-facing lines.",
    modules: [
      ["spruce/message", "Semantic one-liners: success, fail, start, and more."],
      ["spruce/line", "Compact severity, scope, and key/value detail."],
      ["spruce/detail", "Key and value detail rendering."],
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
            Make the terminal <span className="solid-emphasis">look good.</span>
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
              <span className="k">import</span>{" "}
              <span className="m">gleam/io</span>
              {"\n"}
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
              <span className="k">let</span> context ={" "}
              <span className="m">spruce</span>.
              <span className="f">detect</span>()
              {"\n  "}
              <span className="m">box</span>.<span className="f">print</span>(context,{" "}
              <span className="s">"spruce"</span>)
              {"\n  "}
              <span className="m">io</span>.<span className="f">println</span>(
              <span className="m">message</span>.
              <span className="f">success</span>(context,{" "}
              <span className="s">"ready"</span>))
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
          {moduleGroups.map((group, groupIndex) => (
            <Reveal
              className="module-group"
              key={group.title}
              delay={groupIndex * 0.04}
            >
              <div className="module-group-head">
                <h3>{group.title}</h3>
                <p>{group.summary}</p>
              </div>
              <div className="module-list">
                {group.modules.map(([name, desc]) => (
                  <div className="mod" key={name}>
                    <code>{name}</code>
                    <span>{desc}</span>
                  </div>
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
