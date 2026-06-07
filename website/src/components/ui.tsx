import { useEffect, useState } from "react";
import {
  motion,
  useReducedMotion,
  type HTMLMotionProps,
} from "motion/react";
import { CopyIcon, CheckIcon, MoonIcon, SunIcon } from "../icons";

/* Scroll reveal. Motivated: section content enters as the reader reaches it.
   Collapses to a static render under prefers-reduced-motion. */
export function Reveal({
  children,
  delay = 0,
  mount = false,
  className,
  ...rest
}: { delay?: number; mount?: boolean } & HTMLMotionProps<"div">) {
  const reduce = useReducedMotion();
  const animateProps = mount
    ? { animate: { opacity: 1, y: 0 } }
    : {
        whileInView: { opacity: 1, y: 0 },
        viewport: {
          once: true,
          amount: 0.18,
          margin: "0px 0px -8% 0px",
        } as const,
      };
  return (
    <motion.div
      className={className}
      initial={reduce ? false : { opacity: 0, y: 22 }}
      {...animateProps}
      transition={{ duration: 0.7, delay, ease: [0.16, 1, 0.3, 1] }}
      {...rest}
    >
      {children}
    </motion.div>
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
      <div className="term-bar">
        <span className="dot r" />
        <span className="dot m" />
        <span className="dot m" />
        <span className="term-title">{title}</span>
      </div>
      <pre className="term-body">
        <span dangerouslySetInnerHTML={{ __html: html }} />
        {caret && <span className="caret" />}
      </pre>
    </div>
  );
}

export function CopyButton({ text }: { text: string }) {
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    if (!copied) return;
    const t = setTimeout(() => setCopied(false), 1600);
    return () => clearTimeout(t);
  }, [copied]);

  async function onCopy() {
    try {
      await navigator.clipboard.writeText(text);
    } catch {
      const ta = document.createElement("textarea");
      ta.value = text;
      document.body.appendChild(ta);
      ta.select();
      try {
        document.execCommand("copy");
      } catch {
        /* ignore */
      }
      document.body.removeChild(ta);
    }
    setCopied(true);
  }

  return (
    <button
      className={"copy" + (copied ? " copied" : "")}
      onClick={onCopy}
      aria-label={`Copy: ${text}`}
    >
      <span>
        <span className="prompt">$</span> {text}
      </span>
      <span className="ico">{copied ? <CheckIcon /> : <CopyIcon />}</span>
    </button>
  );
}

export function ThemeToggle() {
  const [light, setLight] = useState(false);

  useEffect(() => {
    setLight(document.documentElement.classList.contains("light"));
  }, []);

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
      aria-label="Toggle color theme"
    >
      {light ? <SunIcon /> : <MoonIcon />}
    </button>
  );
}
