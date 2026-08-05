---
name: spruce
description: Terminal-native marketing system for a Gleam terminal-UI kit.
colors:
  spruce-night: "#0c100e"
  spruce-night-2: "#101613"
  panel-green: "#121a16"
  panel-green-raised: "#16201b"
  terminal-black: "#090d0b"
  mist-text: "#e7ede9"
  muted-mint: "#95a59c"
  faint-sage: "#74877d"
  terminal-title: "#7c8a81"
  terminal-dot-muted: "#3a443e"
  spruce: "#3f9a6e"
  spruce-bright: "#4cb782"
  output-teal: "#56b3a4"
  output-green: "#58c98c"
  output-yellow: "#e6c46a"
  output-red: "#ff7a7a"
  output-red-soft: "#ff9a9a"
  output-teal-soft: "#7fccc0"
  code-blue: "#6aa9e9"
  spruce-ink: "#061009"
  signal-coral: "#ec6a82"
  paper-bg: "#f2f5f3"
  paper-white: "#ffffff"
  paper-text: "#14201a"
  paper-muted: "#56655c"
  paper-faint: "#607066"
typography:
  display:
    fontFamily: "ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Helvetica Neue, Arial, sans-serif"
    fontSize: "clamp(2.4rem, 4.6vw, 3.45rem)"
    fontWeight: 660
    lineHeight: 1.05
    letterSpacing: "-0.02em"
  headline:
    fontFamily: "ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Helvetica Neue, Arial, sans-serif"
    fontSize: "clamp(1.8rem, 3.4vw, 2.5rem)"
    fontWeight: 650
    lineHeight: 1.05
    letterSpacing: "-0.02em"
  body:
    fontFamily: "ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Helvetica Neue, Arial, sans-serif"
    fontSize: "16px"
    lineHeight: 1.6
  label:
    fontFamily: "ui-monospace, SF Mono, JetBrains Mono, Cascadia Code, Fira Code, Menlo, Consolas, monospace"
    fontSize: "0.72rem"
    letterSpacing: "0.18em"
  code:
    fontFamily: "ui-monospace, SF Mono, JetBrains Mono, Cascadia Code, Fira Code, Menlo, Consolas, monospace"
    fontSize: "0.82rem"
    lineHeight: 1.62
rounded:
  xs: "6px"
  icon: "9px"
  sm: "10px"
  md: "14px"
  terminal: "12px"
  pill: "999px"
spacing:
  xs: "8px"
  sm: "12px"
  md: "18px"
  lg: "24px"
  xl: "48px"
components:
  button-primary:
    backgroundColor: "{colors.spruce}"
    textColor: "{colors.spruce-ink}"
    rounded: "{rounded.pill}"
    padding: "12px 20px"
  button-ghost:
    backgroundColor: "transparent"
    textColor: "{colors.mist-text}"
    rounded: "{rounded.pill}"
    padding: "12px 20px"
  command-copy:
    backgroundColor: "{colors.panel-green}"
    textColor: "{colors.mist-text}"
    rounded: "{rounded.pill}"
    padding: "11px 12px 11px 20px"
  card:
    backgroundColor: "{colors.panel-green}"
    textColor: "{colors.mist-text}"
    rounded: "{rounded.md}"
    padding: "22px"
  terminal:
    backgroundColor: "{colors.terminal-black}"
    textColor: "{colors.mist-text}"
    rounded: "{rounded.terminal}"
---

# Design System: spruce

## 1. Overview

**Creative North Star: "The Quiet Terminal Bench"**

The spruce site feels like a carefully kept workbench for terminal output: dark green-black surfaces, precise controls, real rendered examples, and enough ambient glow to make the page feel alive without becoming spectacle. The system is calm and craft-forward; it demonstrates polish by showing actual spruce output rather than decorating around it.

The visual language rejects generic SaaS landing-page tropes, gradient-text gloss, noisy hacker neon, and fake terminal mocks. It should stay terminal-native, but never cosplay as a cyberpunk dashboard. The examples are the imagery, the install command is the primary action, and the surrounding interface should keep attention on readability, adaptivity, and composable Gleam code.

**Key Characteristics:**
- Deep spruce-black surfaces with green signal accents.
- Rounded but grounded panels: 10-14px for surfaces, full-pill only for controls.
- Real terminal panels are the signature image system.
- Dark mode is the default atmosphere; light mode preserves the same structure, not a separate brand.
- Motion is restrained and purposeful: scroll reveal, button feedback, caret blink, and no content hidden under reduced motion.

## 2. Colors

The palette is a dark spruce workbench: green-black surfaces, mint text, a functional spruce primary, and coral reserved for status contrast and small signal moments.

### Primary
- **Spruce Signal**: the primary brand/action color used for install affordances, icon backgrounds, inline code accents, and emphasis.
- **Bright Spruce**: the stronger hover/highlight version used when an element needs a readable green accent on dark surfaces.

### Secondary
- **Signal Coral**: a sparing contrast color for status output, terminal dots, and small moments that need warmth against the green system.
- **Runtime Output Colors**: the terminal and code example colors are documented tokens because they come from actual spruce output and syntax highlighting, not page decoration. They may include teal, green, yellow, red, soft red, soft teal, and code blue.

### Neutral
- **Spruce Night**: the default dark page background. It should feel like a terminal-adjacent environment, not generic black.
- **Panel Green**: the resting surface for cards, navigation controls, and command buttons.
- **Terminal Black**: the deepest surface, reserved for terminal/code panels so real output gets visual gravity.
- **Mist Text**: the primary foreground on dark surfaces.
- **Muted Mint**: supporting prose and secondary navigation. Use only where the size and contrast remain comfortable.
- **Paper Background / Paper Text**: the light-theme pair. Light mode stays slightly green-neutral, but it must not become cream, beige, or paper-warm by reflex.

### Named Rules

**The Real Output Rule.** Terminal colors should come from actual spruce output whenever possible; do not recolor terminal panels just to match a decorative page palette.

**The Coral Rarity Rule.** Coral is a signal, not a brand wash. Use it in small doses for contrast, status, and focus moments.

## 3. Typography

**Display Font:** System sans stack (`ui-sans-serif`, system UI, Segoe UI, Roboto, Arial).
**Body Font:** System sans stack.
**Label/Mono Font:** System monospace stack (`ui-monospace`, SF Mono, JetBrains Mono, Cascadia Code, Fira Code, Menlo, Consolas).

**Character:** The type system is single-sans with a functional mono layer. Sans carries calm clarity; mono appears where the content is genuinely terminal, code, command, or compact metadata. Mono is not a decorative shorthand for "developer."

### Hierarchy
- **Display** (660, `clamp(2.4rem, 4.6vw, 3.45rem)`, 1.05): hero headline only. Keep letter-spacing at `-0.02em`; do not tighten past `-0.04em`.
- **Headline** (650, `clamp(1.8rem, 3.4vw, 2.5rem)`, 1.05): section headings and CTA headline.
- **Title** (650, ~1.08rem, 1.05): card and module titles where dense hierarchy matters.
- **Body** (16px, 1.6): normal copy. Keep marketing prose around 60ch and never exceed 75ch.
- **Label** (mono, 0.72rem, 0.18em, uppercase only for the single hero kicker): use sparingly. Repeated section eyebrows are prohibited.

### Named Rules

**The Earned Mono Rule.** Use monospace only for commands, code, terminal panel chrome, or compact technical labels. If the text is marketing copy, it stays sans.

## 4. Elevation

The system uses a hybrid of tonal layering and ambient shadows. Flat panels carry most structure through background, border, and spacing; terminal/code panels get a soft shadow to separate them from the page and make the real output feel physical.

### Shadow Vocabulary
- **Terminal Ambient** (`0 24px 60px -28px rgba(0, 0, 0, 0.7), 0 8px 24px -16px rgba(20, 60, 42, 0.35)`): use for terminal panels and code examples only.
- **Light Ambient** (`0 24px 50px -30px rgba(20, 50, 36, 0.4), 0 6px 18px -14px rgba(20, 50, 36, 0.2)`): light-theme equivalent for elevated terminal/code panels.

### Named Rules

**The Terminal Gets Depth Rule.** Cards are bordered and tonal; terminal/code panels may cast a shadow. Do not put the full ambient shadow on every marketing card.

## 5. Components

### Buttons
- **Shape:** full-pill controls (`999px`) with tight vertical rhythm and no oversized card-radius carryover.
- **Primary:** Spruce Signal background with Spruce Ink text, 12px/20px padding, icon gap around 9px.
- **Hover / Focus:** hover shifts to Bright Spruce; focus should use an explicit visible outline or border treatment that preserves contrast in both themes.
- **Ghost:** transparent fill with a quiet border; on hover, lift through tonal background, not a large shadow.

### Cards / Containers
- **Corner Style:** gently curved surfaces (`14px` for cards, `10px` for compact modules).
- **Background:** Panel Green or Panel Green Raised on dark; Paper White or green-tinted paper on light.
- **Shadow Strategy:** no default card shadow. Use border and tonal contrast; reserve ambient shadow for terminal/code panels.
- **Border:** 1px low-contrast border. Never use a colored side stripe.
- **Internal Padding:** 22px for feature cards, 16-18px for compact module rows.

### Navigation
- **Style:** sticky top bar with a translucent background, 12px blur, and a single bottom border. Links are small sans text with muted resting color and text-color hover.
- **Controls:** icon buttons use compact square proportions (`38px`) with `10px` radius, a quiet border, and no decorative glow.

### Terminal Panel
- **Role:** the signature component and primary imagery system.
- **Shape:** 12px radius with overflow clipped, a dark terminal body, a 40px title bar, and compact mono text.
- **Behavior:** terminal content may scroll horizontally; never wrap real terminal output in a way that corrupts alignment.
- **Integrity:** panels must use real spruce output or clearly authored code examples. Fake terminal copy is forbidden.

### Command Copy
- **Role:** primary install CTA.
- **Style:** monospace pill with a Spruce Signal prompt, quiet border, and a small icon well that changes state after copy.
- **Behavior:** copied state should be clear without relying only on color; the icon swap is part of the pattern.

### Feature Grid
- **Role:** bento-style explanation of modules and capabilities.
- **Style:** varied spans on desktop, collapsing to two columns and then one column. Cards use icon chips, concise copy, and embedded terminal panels when the feature benefits from proof.

### Module Groups
- **Role:** compact API taxonomy that teaches how the library is organized before exposing individual import paths.
- **Style:** four grouped panels, each with a short category summary and compact module rows. Use grouping to reduce recall load; do not return to one undifferentiated list.

## 6. Do's and Don'ts

### Do:
- **Do** preserve the Quiet Terminal Bench: deep green-black surfaces, calm spacing, and real output as the visual proof.
- **Do** keep terminal examples readable without color; the page promise is adaptive output all the way down to plain text.
- **Do** use full-pill controls for actions and 10-14px radii for panels. Anything larger on cards starts to feel toy-like.
- **Do** keep motion visible but nonessential: content must be present by default and static under reduced-motion settings.
- **Do** treat light mode as the same brand in a brighter room, not a separate cream-paper aesthetic.

### Don't:
- **Don't** use generic SaaS landing-page tropes, gradient-text gloss, noisy hacker neon, or fake terminal mocks.
- **Don't** use repeated tiny uppercase section eyebrows. One hero kicker is enough.
- **Don't** pair a 1px border with a wide decorative shadow on normal cards. Pick border/tonal layering for cards; reserve shadow for terminal/code panels.
- **Don't** add colored side-stripe borders to cards, callouts, or alerts.
- **Don't** make coral a broad gradient or page wash. Coral is a signal color.
