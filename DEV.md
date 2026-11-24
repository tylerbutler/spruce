# Development

## Prerequisites

- Gleam 1.16 or newer for package compatibility; CI uses Gleam 1.16.0
- Erlang/OTP 26 or newer for the Erlang target
- Node.js 20.19 or newer for the JavaScript target

Use [mise](https://mise.jdx.dev/) to install the local tools from `.mise.toml`:

```sh
mise trust
mise install
```

Activate mise in your shell, or use `mise exec -- just ci`. Local development
uses Erlang/OTP 28. The shared CI setup keeps Erlang/OTP 27.2.1 and Gleam
1.16.0 as defaults; the test matrix checks Erlang/OTP 26, 27, and 28.

## Common commands

- `just build` — compile the package
- `just test` — run the Erlang and JavaScript test suites
- `just format` — format the source and test files
- `just lint` — check formatting and run glinter
- `just audit` — check root Gleam dependency licences and known vulnerabilities
- `just docs` — build the Hex documentation
- `just ci` — run the full validation workflow
- `npm run build --prefix website` — regenerate examples and build the website

## Dependency audits

`just audit` runs `licence_audit check --checks=all` with the policy in `gleam.toml`.
It checks the root lockfile, including production and development dependencies.
It does not scan the browser workbench or npm dependencies.

The command verifies licence declarations from the locked Hex archives against
the checksums in `manifest.toml`. It requires network access to Hex and OSV.dev.
Licence policy violations and high or critical advisories fail the check. Lower and unknown
severities appear in the report but do not fail it. Missing or invalid package
metadata and OSV request or advisory-detail failures also fail the check.
Review findings before changing the policy or adding an exception.

CI runs the audit once in the checks job. Both CI and local development use
mise to install the self-contained licence_audit executable pinned in
`.mise.toml`. CI installs only the audit tool and keeps its existing build
toolchain. `just sbom` and `just dist` use the same pin for the existing
CycloneDX SBOM artifacts.

## Output snapshots

Birdie snapshots in `test/birdie_snapshots/` cover a small set of composed
Markdown documents, tables, boxes, and layouts. They supplement the exact-output
and semantic tests; keep explicit assertions for widths, physical blank lines,
Unicode, and ANSI state.

Run `gleam test --target erlang` and `gleam test --target javascript`. Both
targets use the same accepted snapshots, fixed widths, and explicit color levels.
Tests fail for new or changed output; they do not accept it.

Snapshots show ESC as `\x1b` and every space as `·`, including trailing spaces.
Literal backslashes are doubled. Line breaks remain unchanged. The test-local
`visible_output` helper preserves ANSI sequences rather than stripping them;
Birdie accepts strings without a built-in output formatter.

After an intentional output change, run `gleam run -m birdie` to review each
new snapshot. Accept only the expected changes, then run both targets again.
Commit the `.accepted` files with the tests. Do not edit baselines by hand or
run `gleam run -m birdie accept` in CI. CI runs only the test commands and never
accepts snapshots. Unreviewed `.new` files are ignored by Git.

## Release workflow

1. Add a changelog fragment with `just change <kind> "<text>"`.
2. Keep `gleam.toml` at the last released version until the release PR merges; the release PR is what bumps the package to the next version.
3. Run `just ci` before opening a pull request.
4. Ensure repository secrets are configured for automation:
   - `HEX_API_KEY`
   - `RELEASE_APP_ID`
   - `RELEASE_APP_PRIVATE_KEY`
5. Merge the release PR to `main`.
6. When the `release/pending` PR closes, Trellis creates the tag and GitHub release.
7. The `Publish` workflow runs on tag push and publishes the package to Hex.

After publication, the artifact job associates the dependency SBOM with the
source archive and adds build provenance attestations for the archive, SBOM
document, and checksums. It uploads these files to the existing GitHub release.

Both release workflows use the release app token for Git authentication and
GitHub API calls. Keep that token in the checkout step: GitHub does not start
the tag-triggered `Publish` workflow for pushes made with `GITHUB_TOKEN`.

The website workbench uses Trellis's `workspace` lifecycle. It remains part of
the workspace but does not receive version bumps, tags, GitHub releases, or
Hex publications.

## Public API expectations

- Keep the README-documented public modules (`spruce` and `spruce/*`) stable across minor releases.
- `ColorLevel` is a closed API contract (`NoColor`, `Basic`, `Ansi256`, `TrueColor`).
- Prefer additive changes over breaking changes within a major version; module
  layout changes are recorded as ADRs under `docs/adr/`.
- If a behavior change is necessary, document it in the changelog and update the README examples when needed.
