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

## Social previews

The home and workbench pages share `public/og-image.png`, a 1200 x 630 social
preview. Both pages include Open Graph and Twitter card metadata, with absolute
image and canonical URLs for `https://spruce.tylerbutler.com`.

To update the image, open `tools/social-preview.html` in a browser and capture
the `article` element at 1200 x 630 pixels with a device scale factor of 1.
Save the PNG as `public/og-image.png`. The source uses the site's logo, colors,
and system fonts and needs no image-generation service.

## Syntax-highlighted code

Source samples in `code-samples/` are rendered at build time with Expressive
Code and Shiki's bundled Gleam grammar. `npm run generate:code` writes static
HTML and CSS under `src/data/`; `npm run dev` and `npm run build` regenerate them automatically.

## Cloudflare Workers

Connect `tylerbutler/spruce` to a Worker in the Cloudflare dashboard with these
Workers Builds settings:

| Setting | Value |
| --- | --- |
| Worker name | `spruce-website` (must match `wrangler.jsonc`) |
| Production branch | `main` |
| Root directory | `website` |
| Build command | `npm run build` |
| Deploy command | `npm run deploy` |
| Build variable | `NODE_VERSION=22.22.3` |

Local tools use the repository's `.mise.toml`. Do not commit a `.tool-versions`
file: Workers Builds detects it at the repository root and attempts to install
its tools before `npm run build` runs. The failed build stopped at this stage,
so the build script's Gleam installer could not run. The root `.tool-versions`
path is ignored to prevent a local file from being committed again.

Keep automatic dependency installation enabled. Cloudflare installs npm
dependencies, then `scripts/build.sh` installs Gleam 1.16.0 when
needed, generates code samples, compiles the workbench, and builds `dist/`.
Cloudflare serves those files as Worker static assets; no Worker entry point
or server-side rendering is needed. The default HTML handling keeps
`/workbench/` as a separate page.

Workers Builds does not include Erlang. `npm run build` uses the committed terminal
snapshots. GitHub CI checks those
snapshots against both Erlang and JavaScript output. Run `npm run generate:terminal`
and commit the updated snapshots when terminal output changes.

For a manual deployment from `website/`, run `npm run build`,
`npx wrangler login`, and `npm run deploy`.
After you verify the Cloudflare deployment, add the existing site domain under
the Worker's **Settings > Domains & Routes** and disable Netlify deployments.
Keep Netlify active until you confirm that the domain serves the Cloudflare site.

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
The root `just build` recipe regenerates it. Website builds use the committed file.
