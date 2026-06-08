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
    gleam deps download

# === BUILD ===

# Compile the project
build:
    gleam build

# Build with warnings as errors (both targets)
build-strict:
    gleam build --target erlang --warnings-as-errors
    gleam build --target javascript --warnings-as-errors

# === TESTING ===

# Run tests on both targets
test:
    gleam test --target erlang
    gleam test --target javascript

# === CODE QUALITY ===

# Format code
format:
    gleam format src test

# Check formatting without changes
format-check:
    gleam format --check src test

# Type check without building
check:
    gleam check

# Run linter (format check + glinter)
lint: format-check
    gleam run -m glinter

# === DOCUMENTATION ===

# Build API documentation
docs:
    gleam docs build

# === DEMO ===

# Run the feature showcase demo (TARGET defaults to erlang)
demo target="erlang":
    gleam run -m demo --target {{target}}

# === CHANGELOG ===

# Create a new changelog entry
change:
    changie new

# Preview unreleased changelog
changelog-preview:
    changie batch auto --dry-run

# Generate CHANGELOG.md
changelog:
    changie merge

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
    rm -rf build

# === CI ===

# Full validation workflow (no file mutation)
ci: lint check build-strict test docs

alias pr := ci
