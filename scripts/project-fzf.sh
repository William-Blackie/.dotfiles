#!/usr/bin/env bash
set -euo pipefail

# Fuzzy Session Manager
# Searches ~/Projects for directories and opens them in a tmux session.

PROJECTS_DIR="$HOME/Projects"
[[ -d "$PROJECTS_DIR" ]] || { echo "Projects directory not found at $PROJECTS_DIR"; exit 1; }

# Find projects (depth 1 or 2 depending on structure)
selected=$(find "$PROJECTS_DIR" -maxdepth 2 -not -path '*/.*' -type d | fzf --header "Select Project" --reverse)

[[ -z "$selected" ]] && exit 0

session_name=$(basename "$selected" | tr ' .:' '-')

# Use our existing tmux-session.sh to handle the heavy lifting
~/.dotfiles/scripts/tmux-session.sh attach "$session_name" "$selected"
