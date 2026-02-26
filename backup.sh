#!/bin/bash

# Backup existing dotfiles before installation

set -euo pipefail
IFS=$'\n\t'

BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

echo "🛡️  Creating backup of existing dotfiles..."

# Create backup directory
mkdir -p "$BACKUP_DIR"

# List of files to backup
FILES_TO_BACKUP=(
  ".zshrc"
  ".tmux.conf"
  ".gitconfig"
  ".zprofile"
  ".fzf.zsh"
  ".config/kitty"
  ".config/nvim"
  ".config/starship.toml"
)

# Backup existing files
for file in "${FILES_TO_BACKUP[@]}"; do
  if [[ -e "$HOME/$file" ]] && [[ ! -L "$HOME/$file" ]]; then
    echo "📦 Backing up $file"
    mkdir -p "$BACKUP_DIR/$(dirname "$file")"
    cp -r "$HOME/$file" "$BACKUP_DIR/$file"
  fi
done

echo "✅ Backup created at: $BACKUP_DIR"
echo "$BACKUP_DIR" > ~/.dotfiles-last-backup
