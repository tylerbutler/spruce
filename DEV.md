# Development

## Prerequisites

- Gleam 1.11 or newer for package compatibility; CI uses Gleam 1.16.0
- Erlang/OTP 26 or newer for the Erlang target
- Node.js 20.19 or newer for the JavaScript target

## Common commands

- `just build` — compile the package
- `just test` — run the Erlang and JavaScript test suites
- `just format` — format the source and test files
- `just lint` — check formatting
- `just docs` — build the Hex documentation
- `just ci` — run the full validation workflow

## Release workflow

1. Add a changelog fragment under `.changes/unreleased/` using the project’s Changie setup.
2. Keep `gleam.toml` at the last released version until the release PR merges; the release PR is what bumps the package to the next version.
3. Run `just ci` before opening a pull request.
4. Ensure repository secrets are configured for automation:
   - `HEX_API_KEY`
   - `RELEASE_APP_ID`
   - `RELEASE_APP_PRIVATE_KEY`
5. Merge the release PR to `main`.
6. When the release PR closes, the auto-tag workflow creates a tag and GitHub release.
7. The `Publish` workflow runs on tag push and publishes the package to Hex.

## Public API expectations

- Keep the documented public API in `src/spruce.gleam` stable across minor releases.
- `ColorLevel` is a closed 1.x API contract (`NoColor`, `Basic`, `Ansi256`, `TrueColor`).
- Prefer additive changes over breaking changes for 1.x.
- If a behavior change is necessary, document it in the changelog and update the README examples when needed.
