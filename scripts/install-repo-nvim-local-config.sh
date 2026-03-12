#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 /path/to/repo [django|generic]"
  exit 1
fi

REPO_ROOT="$1"
PROFILE="${2:-django}"
DOTFILES_ROOT="${DOTFILES_ROOT:-$HOME/.dotfiles}"
TEMPLATE="$DOTFILES_ROOT/nvim/.config/nvim/templates/repo-tools/.nvim.lua.example"

[[ -f "$TEMPLATE" ]] || {
  echo "Template not found: $TEMPLATE"
  exit 1
}
[[ -d "$REPO_ROOT" ]] || {
  echo "Repo not found: $REPO_ROOT"
  exit 1
}

TARGET="$REPO_ROOT/.nvim.lua"

if [[ -e "$TARGET" ]]; then
  echo "Already exists: $TARGET"
  exit 0
fi

cp "$TEMPLATE" "$TARGET"

if [[ "$PROFILE" == "generic" ]]; then
  perl -0pi -e 's/repo_type = "django"/repo_type = "generic"/g' "$TARGET"
fi

echo "Created $TARGET"
echo "Open Neovim in that repo and approve the local config when prompted."
