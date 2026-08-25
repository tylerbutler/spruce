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
HTML and CSS under `src/data/`; `npm run dev` and `npm run build` regenerate
them automatically.

## Netlify

The root `netlify.toml` builds from `website/` and publishes `website/dist/`.
Netlify installs npm dependencies, then `scripts/netlify-build.sh` provides
Gleam 1.16.0 when needed and runs the normal `npm run build` command.

## Interactive workbench

The homepage workbench is driven by the nested Gleam package in
`website/workbench/`. `npm run build:gleam` compiles that facade to the
generated JavaScript checked into the untracked `workbench/build/` boundary,
which Vite and TypeScript consume from `src/workbench/runtime.ts`.

The React workbench UI lazy-loads separately from the landing-page shell, and
its generated Gleam runtime remains a second lazy chunk behind that boundary.
Its native controls update real ANSI output and runnable public Gleam source
from the same typed state.

`npm run dev`, `npm test`, and `npm run build` all compile the browser facade in
`workbench/` before running their website checks.

## Real terminal output

Every terminal panel on the page is **genuine spruce output**, not a mockup. The
strings in `src/data/terminalBlocks.ts` are captured from a live `gleam run` at
each advertised color level and converted span-for-span to HTML by the shared
module in `src/lib/ansi2html.js`.

To regenerate after changing spruce:

1. Copy `tools/spruce_landing_demo.gleam` into the repo `src/` directory.
2. From the repo root, capture both targets and verify that their output matches:
   ```sh
   FORCE_COLOR=3 gleam run -m spruce_landing_demo --target erlang > /tmp/spruce_erlang.ansi
   FORCE_COLOR=3 gleam run -m spruce_landing_demo --target javascript > /tmp/spruce_javascript.ansi
   diff /tmp/spruce_erlang.ansi /tmp/spruce_javascript.ansi
   node website/tools/ansi2html.cjs /tmp/spruce_erlang.ansi > website/spruce_blocks.json
   ```
3. Rebuild `src/data/terminalBlocks.ts` from that JSON, then delete the demo
   module from `src/` (it must not ship in the published package).

After regenerating fixtures, rerun `npm test` to verify the ANSI converter and
workbench adapter still agree with the captured output.
