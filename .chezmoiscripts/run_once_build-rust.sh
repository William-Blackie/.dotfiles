#!/usr/bin/env bash
set -euo pipefail

if command -v rustup >/dev/null 2>&1 || command -v rustc >/dev/null 2>&1; then
    echo "Skipping Rust install, already installed"
    exit 0
fi

# https://rust-lang.org/learn/get-started/
installer="$(mktemp)"
trap 'rm -f "$installer"' EXIT

curl --proto '=https' --tlsv1.2 --fail --show-error --location \
    --output "$installer" \
    https://sh.rustup.rs

sh "$installer" -y --no-modify-path
