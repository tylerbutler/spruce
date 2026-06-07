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

## Real terminal output

Every terminal panel on the page is **genuine spruce output**, not a mockup. The
strings in `src/data/terminalBlocks.ts` are captured from a live `gleam run` at
TrueColor and converted span-for-span to HTML.

To regenerate after changing spruce:

1. Copy `tools/spruce_landing_demo.gleam` into the repo `src/` directory.
2. From the repo root, pipe the captured output through the converter:
   ```sh
   FORCE_COLOR=3 gleam run -m spruce_landing_demo --target javascript \
     | node website/tools/ansi2html.cjs > /tmp/spruce_blocks.json
   ```
3. Rebuild `src/data/terminalBlocks.ts` from that JSON, then delete the demo
   module from `src/` (it must not ship in the published package).
