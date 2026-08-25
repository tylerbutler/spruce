#!/usr/bin/env bash
# Netlify installs npm dependencies before this script runs. Its build image
# does not include Gleam, which the website prebuild hook requires.
set -euo pipefail

GLEAM_VERSION="${GLEAM_VERSION:-1.16.0}"

if ! command -v gleam >/dev/null 2>&1; then
  echo "Installing gleam v${GLEAM_VERSION}..."
  install_dir="${HOME}/.gleam-bin"
  mkdir -p "${install_dir}"
  curl -fsSL "https://github.com/gleam-lang/gleam/releases/download/v${GLEAM_VERSION}/gleam-v${GLEAM_VERSION}-x86_64-unknown-linux-musl.tar.gz" \
    | tar -xz -C "${install_dir}"
  export PATH="${install_dir}:${PATH}"
fi

gleam --version
npm run build
