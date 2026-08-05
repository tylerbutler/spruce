import { useEffect, useState } from "react";
import {
  motion,
  useReducedMotion,
  type HTMLMotionProps,
} from "motion/react";
import { CopyIcon, CheckIcon, MoonIcon, SunIcon } from "../icons";

/* Scroll reveal. Content stays visible by default; motion only enhances entry. */
export function Reveal({
  children,
  delay = 0,
  className,
  ...rest
}: { delay?: number } & HTMLMotionProps<"div">) {
  const reduce = useReducedMotion();
  return (
    <motion.div
      className={className}
      initial={reduce ? false : { y: 18 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, amount: 0.18, margin: "0px 0px -8% 0px" }}
      transition={{ duration: 0.7, delay, ease: [0.16, 1, 0.3, 1] }}
      {...rest}
    >
      {children}
    </motion.div>
  );
}

/* The three-dot title bar shared by every terminal-style panel. */
export function TermBar({ title }: { title: string }) {
  return (
    <div className="term-bar">
      <span className="dot r" />
      <span className="dot m" />
      <span className="dot m" />
      <span className="term-title">{title}</span>
    </div>
  );
}

/* A terminal panel. `html` is real spruce output, injected verbatim. */
export function Terminal({
  title,
  html,
  caret = false,
}: {
  title: string;
  html: string;
  caret?: boolean;
}) {
  return (
    <div className="term">
      <TermBar title={title} />
      <pre className="term-body">
        <span dangerouslySetInnerHTML={{ __html: html }} />
        {caret && <span className="caret" />}
      </pre>
    </div>
  );
}

export function CopyButton({ text }: { text: string }) {
  const [copyState, setCopyState] = useState<"idle" | "copied" | "failed">(
    "idle",
  );

  useEffect(() => {
    if (copyState === "idle") return;
    const t = setTimeout(() => setCopyState("idle"), 1800);
    return () => clearTimeout(t);
  }, [copyState]);

  async function onCopy() {
    let ok = false;
    try {
      await navigator.clipboard.writeText(text);
      ok = true;
    } catch {
      const ta = document.createElement("textarea");
      ta.value = text;
      ta.setAttribute("readonly", "");
      ta.style.position = "fixed";
      ta.style.opacity = "0";
      document.body.appendChild(ta);
      ta.select();
      try {
        ok = document.execCommand("copy");
      } catch {
        ok = false;
      }
      document.body.removeChild(ta);
    }
    setCopyState(ok ? "copied" : "failed");
  }

  const copied = copyState === "copied";
  const failed = copyState === "failed";

  return (
    <button
      className={"copy" + (copied ? " copied" : "") + (failed ? " failed" : "")}
      onClick={onCopy}
      aria-label={`Copy: ${text}`}
    >
      <span>
        <span className="prompt">$</span> {text}
      </span>
      <span className="ico">{copied ? <CheckIcon /> : <CopyIcon />}</span>
      <span className="sr-only" aria-live="polite">
        {copied ? "Copied install command" : failed ? "Copy failed" : ""}
      </span>
    </button>
  );
}

export function ThemeToggle() {
  const [light, setLight] = useState(() =>
    document.documentElement.classList.contains("light"),
  );

  function toggle() {
    const el = document.documentElement;
    const next = !el.classList.contains("light");
    el.classList.toggle("light", next);
    el.classList.toggle("dark", !next);
    try {
      localStorage.setItem("spruce-theme", next ? "light" : "dark");
    } catch {
      /* ignore */
    }
    setLight(next);
  }

  return (
    <button
      className="icon-btn"
      onClick={toggle}
      aria-label={light ? "Switch to dark theme" : "Switch to light theme"}
      aria-pressed={light}
    >
      {light ? <SunIcon /> : <MoonIcon />}
    </button>
  );
}
