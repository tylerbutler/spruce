# spruce — a terminal-UI kit for Gleam

# === ALIASES ===
alias b := build
alias t := test
alias f := format
alias l := lint
alias c := clean
alias cl := change

# Default recipe
default:
    @just --list

# === DEPENDENCIES ===

# Download project dependencies
deps:
    trellis run deps

# === BUILD ===

# Compile the project
build:
    trellis run build
    npm --prefix website run generate:terminal

# Build with warnings as errors (both targets)
build-strict:
    trellis run build --target all --strict

# === TESTING ===

# Run tests on both targets
test:
    trellis run test --target all

# === CODE QUALITY ===

# Format code
format:
    trellis run format

# Check formatting without changes
format-check:
    trellis run format --check

# Type check without building
check:
    trellis run check

# Run linter (format check + glinter)
lint: format-check
    trellis run lint

# === DOCUMENTATION ===

# Build API documentation
docs:
    trellis run docs

# Verify checked-in website terminal examples
terminal-check:
    npm --prefix website run check:terminal

# === DEMO ===

# Run the feature showcase demo (TARGET defaults to erlang)
demo target="erlang":
    gleam run -m demo --target {{target}}

# === CHANGELOG ===

# Create a new changelog entry
change kind body:
    trellis changelog new --kind "{{kind}}" --body "{{body}}"

# Preview the next release
changelog-preview:
    trellis version plan

# Apply the planned version and changelog updates
changelog:
    trellis version apply

# === SBOM ===

# Generate a CycloneDX SBOM (requires licence_audit from mise)
sbom output="dist/spruce.cdx.json":
    mkdir -p $(dirname {{output}})
    licence_audit sbom --output={{output}}

# Build the full release artifact set into dist/ (source archive, SBOM,
# checksums) using the version from gleam.toml — parity with the publish
# workflow. Requires licence_audit from mise.
dist version=`grep '^version' gleam.toml | sed -E 's/.*"(.*)".*/\1/'`:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p dist
    git archive --format=tar.gz --prefix="spruce-{{version}}/" \
        -o "dist/spruce-{{version}}.tar.gz" HEAD
    licence_audit sbom --output="dist/spruce-{{version}}.cdx.json"
    # Run from dist/ so the checksums file records bare names and excludes itself.
    cd dist
    sha256sum \
        "spruce-{{version}}.tar.gz" \
        "spruce-{{version}}.cdx.json" \
        > "spruce-{{version}}.sha256sum"
    echo "Wrote dist/spruce-{{version}}.{tar.gz,cdx.json,sha256sum}"

# === MAINTENANCE ===

# Remove build artifacts
clean:
    trellis run clean

# === CI ===

# Full validation workflow (no file mutation)
ci: lint check build-strict test docs terminal-check

alias pr := ci
