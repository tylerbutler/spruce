# ADR 0002: Keep Markdown and highlighting in spruce

- **Status:** Accepted
- **Date:** 2026-08-30
- **Scope:** `spruce/markdown`, `spruce/highlight`, and package dependencies
- **Breaking:** No

## Context

`spruce/markdown` uses `mork` and `spruce/highlight`. `spruce/highlight` uses
`smalto` and imports 36 bundled language grammar modules. Because `mork` and
`smalto` are package dependencies, Gleam fetches and compiles them even when an
application imports only a core module such as `spruce/box`.

Issue #33 proposed moving both modules to a companion package before spruce
2.0. The main expected benefit was a smaller JavaScript bundle for core-only
applications.

## Measurements

Measurements used repository commit `232f2c5703d0` on Linux with Gleam 1.16.0,
Node.js 22.22.3, and Rolldown 1.0.3. The package versions came from the generated
`manifest.toml`: `mork` 1.12.1 and `smalto` 3.0.0.

### Dependency and build weight

The current package resolves 12 dependency records for a minimal application.
A simulated core package, made by removing `spruce/markdown`,
`spruce/highlight`, `mork`, and `smalto`, resolves 7. The five additional
packages are:

- `mork`
- `smalto`
- `casefold`
- `houdini`
- `splitter`

Their downloaded source directories total 2,932 KiB according to:

```sh
du -sk build/packages/{mork,smalto,casefold,houdini,splitter}
```

Three clean JavaScript builds of each fixture, after the packages were cached
locally, had these wall-clock times:

| Package shape | Runs (seconds) | Median |
|---|---:|---:|
| Current package | 1.89, 1.87, 1.59 | 1.87 s |
| Simulated core package | 0.67, 0.63, 0.64 | 0.64 s |

The command for each run was:

```sh
gleam clean
/usr/bin/time -f '%e' gleam build --target javascript
```

These local timings show real dependency and clean-build overhead. They are not
a CI benchmark and should not be treated as a release target.

### JavaScript bundle size

The core fixture calls `spruce/box.render` with `spruce.no_color`. The Markdown
fixture calls `spruce/markdown.render` on a document with a Gleam code fence.
Both were compiled with Gleam and bundled with:

```sh
rolldown build/dev/javascript/issue_33_measure/core_only.mjs \
  --format esm --platform node --minify --file out/core.mjs
rolldown build/dev/javascript/issue_33_measure/markdown_case.mjs \
  --format esm --platform node --minify --file out/markdown.mjs
wc -c out/core.mjs out/markdown.mjs
gzip -9 -c out/core.mjs | wc -c
gzip -9 -c out/markdown.mjs | wc -c
```

The simulated core package contained the same core source modules but omitted
the two optional modules and their dependencies.

| Fixture | Minified | Gzip |
|---|---:|---:|
| Core-only use, current package | 25,086 B | 7,186 B |
| Core-only use, simulated split | 25,086 B | 7,186 B |
| Markdown use, current package | 547,426 B | 72,064 B |

The two core bundles had the same SHA-256 digest:
`ba5d0a4da16c6ad59b50bfb7b6a2c7abf493b7c3d937a17bfeb3edb447d4040f`.
Therefore, the measured production bundle saving from a package split is
**0 B** with a tree-shaking bundler. Using Markdown adds 522,340 B minified or
64,878 B gzip, but that cost is already absent from a core-only bundle.

## API and release assessment

No implementation change is required in the core modules. A companion package
would depend on spruce because both optional modules use `Spruce`,
`style.Style`, and several core renderers.

`markdown.Theme` contains `highlight.Theme`, but both types would move
together. This does not create a dependency from core spruce to the companion
package. `highlight.Theme` contains core `style.Style` values, so the
dependency remains one-way from the companion package to spruce.

The public module move is still a breaking change. A new package could keep the
old `spruce/markdown` and `spruce/highlight` module names, but package ownership
would be less clear and old spruce versions would conflict with those modules.
Using `spruce_md/markdown` and `spruce_md/highlight` avoids that conflict but
requires import changes.

Exact release lockstep would require two coordinated package publications and
would prevent fixes in one package from shipping independently. A broad
companion constraint such as `spruce >= 2.0.0 and < 3.0.0` is lower friction,
but compatibility would still need tests across supported spruce versions.
Either model adds a second Hex package, changelog, documentation site, release
workflow, and dependency update for every Markdown user.

## Decision

Do not split Markdown and syntax highlighting before spruce 2.0.

The split would reduce five resolved packages, about 2.9 MiB of downloaded
source, and local clean-build time. It does not reduce the measured core-only
JavaScript bundle. That does not justify a breaking module move and permanent
two-package release overhead during the 2.0 stabilization work.

Reopen this decision when a representative production core-only application
shows either:

1. at least 25 KiB gzip or 10% bundle savings from the split with its normal
   bundler and settings; or
2. at least 20% repeatable CI time or dependency-cache savings, measured over
   ten clean runs, where dependency installation or compilation is a material
   part of the job.

If either threshold is met, prefer one companion package for both modules, a
one-way `spruce_md -> spruce` dependency with a major-version range, and
`spruce_md/markdown` plus `spruce_md/highlight` module names. Publish it with
the next spruce major release and provide direct import replacements.

## Consequences

- Existing imports and release automation remain unchanged for 2.0.
- Core-only JavaScript applications rely on normal bundler tree shaking.
- All consumers continue to fetch and compile the five optional dependency
  records.
- The measured thresholds make a later split evidence-based instead of
  speculative.
