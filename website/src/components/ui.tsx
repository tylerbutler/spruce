import {
  useEffect,
  useId,
  useRef,
  useState,
  type HTMLAttributes,
  type KeyboardEvent,
  type ReactNode,
} from "react";
import { CopyIcon, CheckIcon, MoonIcon, SunIcon } from "../icons";

/* Shared section wrapper retained for consistent page composition. */
export function Reveal({
  children,
  className,
  ...rest
}: HTMLAttributes<HTMLDivElement>) {
  return (
    <div className={className} {...rest}>
      {children}
    </div>
  );
}

export function Tabs<TValue extends string>({
  name,
  label,
  options,
  value,
  onChange,
  children,
  className = "color-tabs",
  panelClassName,
}: {
  name: string;
  label: string;
  options: readonly { value: TValue; label: string }[];
  value: TValue;
  onChange: (value: TValue) => void;
  children: ReactNode;
  className?: string;
  panelClassName?: string;
}) {
  const instanceId = useId().replace(/:/g, "");
  const baseId = `${name}-${instanceId}`;
  const tabRefs = useRef<Array<HTMLButtonElement | null>>([]);

  function onKeyDown(
    event: KeyboardEvent<HTMLButtonElement>,
    index: number,
  ) {
    let nextIndex: number | undefined;
    if (event.key === "ArrowRight" || event.key === "ArrowDown") {
      nextIndex = (index + 1) % options.length;
    }
    if (event.key === "ArrowLeft" || event.key === "ArrowUp") {
      nextIndex = (index - 1 + options.length) % options.length;
    }
    if (event.key === "Home") nextIndex = 0;
    if (event.key === "End") nextIndex = options.length - 1;
    if (nextIndex === undefined) return;

    event.preventDefault();
    onChange(options[nextIndex].value);
    tabRefs.current[nextIndex]?.focus();
  }

  return (
    <>
      <div className={className} role="tablist" aria-label={label}>
        {options.map((option, index) => {
          const selected = option.value === value;
          return (
            <button
              key={option.value}
              id={`${baseId}-tab-${option.value}`}
              type="button"
              role="tab"
              aria-selected={selected}
              aria-controls={`${baseId}-panel`}
              tabIndex={selected ? 0 : -1}
              className={selected ? "active" : ""}
              onClick={() => onChange(option.value)}
              onKeyDown={(event) => onKeyDown(event, index)}
              ref={(element) => {
                tabRefs.current[index] = element;
              }}
            >
              {option.label}
            </button>
          );
        })}
      </div>
      <div
        id={`${baseId}-panel`}
        className={panelClassName}
        role="tabpanel"
        aria-labelledby={`${baseId}-tab-${value}`}
      >
        {children}
      </div>
    </>
  );
}

/* The three-dot title bar shared by every terminal-style panel. */
export function TermBar({
  title,
  action,
}: {
  title: string;
  action?: ReactNode;
}) {
  return (
    <div className="term-bar">
      <span className="dot r" />
      <span className="dot m" />
      <span className="dot m" />
      <span className="term-title">{title}</span>
      {action && <span className="term-action">{action}</span>}
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
  const bodyRef = useRef<HTMLPreElement>(null);
  const hintId = useId();
  const [hasOverflow, setHasOverflow] = useState(false);

  useEffect(() => {
    const body = bodyRef.current;
    if (!body) return;

    const updateOverflow = () => {
      setHasOverflow(body.scrollWidth > body.clientWidth + 1);
    };
    updateOverflow();

    const observer = new ResizeObserver(updateOverflow);
    observer.observe(body);
    return () => observer.disconnect();
  }, [html]);

  return (
    <div className="term">
      <TermBar title={title} />
      <div className="term-content">
        <pre
          ref={bodyRef}
          className="term-body"
          tabIndex={hasOverflow ? 0 : undefined}
          role="region"
          aria-label={`${title} terminal output`}
          aria-describedby={hasOverflow ? hintId : undefined}
        >
          <span dangerouslySetInnerHTML={{ __html: html }} />
          {caret && <span className="caret" />}
        </pre>
        {hasOverflow && (
          <>
            <span className="term-scroll-cue" aria-hidden="true">
              Scroll →
            </span>
            <span className="sr-only" id={hintId}>
              This terminal output scrolls horizontally.
            </span>
          </>
        )}
      </div>
    </div>
  );
}

export function CodeBlock({
  title,
  html,
}: {
  title: string;
  html: string;
}) {
  const bodyRef = useRef<HTMLDivElement>(null);
  const hintId = useId();
  const [hasOverflow, setHasOverflow] = useState(false);

  useEffect(() => {
    const body = bodyRef.current;
    if (!body) return;

    const updateOverflow = () => {
      setHasOverflow(body.scrollWidth > body.clientWidth + 1);
    };
    updateOverflow();

    const observer = new ResizeObserver(updateOverflow);
    observer.observe(body);
    return () => observer.disconnect();
  }, [html]);

  return (
    <div className="code-panel">
      <TermBar title={title} />
      <div className="code-content">
        <div
          ref={bodyRef}
          className="code-scroll"
          tabIndex={hasOverflow ? 0 : undefined}
          role="region"
          aria-label={`${title} source code`}
          aria-describedby={hasOverflow ? hintId : undefined}
          dangerouslySetInnerHTML={{ __html: html }}
        />
        {hasOverflow && (
          <>
            <span className="term-scroll-cue" aria-hidden="true">
              Scroll →
            </span>
            <span className="sr-only" id={hintId}>
              This source code scrolls horizontally.
            </span>
          </>
        )}
      </div>
    </div>
  );
}

export function CopyButton({ text }: { text: string }) {
  const [copyState, onCopy] = useCopy(text);

  const copied = copyState === "copied";
  const failed = copyState === "failed";

  return (
    <span className="copy-wrap">
      <button
        type="button"
        className={"copy" + (copied ? " copied" : "") + (failed ? " failed" : "")}
        onClick={onCopy}
        aria-label={`Copy: ${text}`}
      >
        <span>
          <span className="prompt">$</span> {text}
        </span>
        <span className="ico">{copied ? <CheckIcon /> : <CopyIcon />}</span>
      </button>
      <span className="sr-only" aria-live="polite">
        {copied ? "Copied install command" : failed ? "Copy failed" : ""}
      </span>
      {failed && (
        <span className="copy-error" role="status">
          Copy failed. Select the command and copy it manually.
        </span>
      )}
    </span>
  );
}

export function CopyTextButton({
  text,
  label,
}: {
  text: string;
  label: string;
}) {
  const [copyState, onCopy] = useCopy(text);
  const copied = copyState === "copied";
  const failed = copyState === "failed";

  return (
    <span className="text-copy-wrap">
      <button
        type="button"
        className={`text-copy${copied ? " copied" : ""}${failed ? " failed" : ""}`}
        onClick={onCopy}
      >
        {copied ? <CheckIcon /> : <CopyIcon />}
        {copied ? "Copied" : failed ? "Copy failed" : label}
      </button>
      <span className="sr-only" aria-live="polite">
        {copied ? `${label} copied` : failed ? `${label} copy failed` : ""}
      </span>
    </span>
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
    >
      {light ? <MoonIcon /> : <SunIcon />}
    </button>
  );
}

function useCopy(text: string) {
  const [copyState, setCopyState] = useState<"idle" | "copied" | "failed">(
    "idle",
  );

  useEffect(() => {
    if (copyState === "idle") return;
    const timeout = setTimeout(() => setCopyState("idle"), 1800);
    return () => clearTimeout(timeout);
  }, [copyState]);

  async function onCopy() {
    let ok = false;
    try {
      await navigator.clipboard.writeText(text);
      ok = true;
    } catch {
      const textarea = document.createElement("textarea");
      textarea.value = text;
      textarea.setAttribute("readonly", "");
      textarea.style.position = "fixed";
      textarea.style.opacity = "0";
      document.body.appendChild(textarea);
      textarea.select();
      try {
        ok = document.execCommand("copy");
      } catch {
        ok = false;
      }
      document.body.removeChild(textarea);
    }
    setCopyState(ok ? "copied" : "failed");
  }

  return [copyState, onCopy] as const;
}
