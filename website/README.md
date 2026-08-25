# spruce website

Marketing site for [spruce](https://hex.pm/packages/spruce), built with Vite +
React + TypeScript, Tailwind v4, and Motion.

```sh
npm install
npm run dev      # local dev server
npm run build    # static build to dist/
npm run preview  # serve the built site
```

The output is a static site in `dist/`, deployable to GitHub Pages or any static
host. `base` is relative, so it works from a subpath.

## Syntax-highlighted code

Source samples in `code-samples/` are rendered at build time with Expressive
Code and Shiki's bundled Gleam grammar. `npm run generate:code` writes static
HTML and CSS under `src/data/`; `npm run dev` and `npm run build` regenerate them automatically.

## Real terminal output

Every terminal panel on the page is **genuine spruce output**, not a mockup.
`npm run generate:terminal` runs `dev/spruce_landing_demo.gleam` on both targets,
checks that their output matches, and converts the ANSI output span-for-span
into `src/data/terminalBlocks.ts`. Run it locally after output changes and
commit the result; deployment builds use the checked-in snapshot and do not
require Gleam.
