# spruce website

Marketing site for [spruce](https://hex.pm/packages/spruce), built with Vite,
React, TypeScript, and Tailwind v4.

```sh
npm install
npm run build:gleam  # compile the nested Gleam workbench facade
npm run check:gleam  # smoke-test the generated JavaScript facade
npm test         # ANSI and workbench adapter checks
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

## Netlify

The root `netlify.toml` builds from `website/` and publishes `website/dist/`.
Netlify installs npm dependencies, then `scripts/netlify-build.sh` provides
Gleam 1.16.0 when needed and runs the normal `npm run build` command.

## Interactive workbench

The standalone workbench at `/workbench/` is driven by the nested Gleam package in
`website/workbench/`. `npm run build:gleam` compiles that facade to the
generated JavaScript checked into the untracked `workbench/build/` boundary,
which Vite and TypeScript consume from `src/workbench/runtime.ts`.

The React workbench UI and its generated Gleam runtime lazy-load on the
standalone page. Its changing Gleam source is syntax-highlighted in the browser
with Expressive Code.
Its native controls update real ANSI output and runnable public Gleam source
from the same typed state.

`npm run dev`, `npm test`, and `npm run build` all compile the browser facade in
`workbench/` before running their website checks.

## Real terminal output

Every terminal panel on the page is **genuine spruce output**, not a mockup.
`npm run generate:terminal` runs `dev/spruce_landing_demo.gleam` on both targets,
checks that their output matches, and converts the ANSI output span-for-span
into `src/data/terminalBlocks.ts`. It writes the file only when the output
changes. Run it locally after output changes and commit the result.
`npm run check:terminal` makes CI fail when the checked-in snapshot is stale.
The root `just build` recipe and website deployment builds regenerate it.
