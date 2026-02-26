#!/bin/bash

# Post-installation setup script for additional tools and configurations

set -euo pipefail
IFS=$'\n\t'

echo "🔧 Running post-installation setup..."

# Setup Zinit (Zsh plugin manager)
echo "📥 Setting up Zinit..."
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME" ]]; then
  echo "Installing Zinit..."
  mkdir -p "$(dirname "$ZINIT_HOME")"
  if command -v git > /dev/null 2>&1; then
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
  else
    echo "git not found; skipping Zinit install"
  fi
else
  echo "Zinit already installed"
fi

# Setup fzf integration
echo "🔍 Setting up fzf integration..."
if command -v fzf > /dev/null 2>&1; then
  if [[ ! -f ~/.fzf.zsh && ! -f ~/.fzf.bash ]]; then
    if command -v brew > /dev/null 2>&1; then
      FZF_PREFIX="$(brew --prefix)"
      "$FZF_PREFIX/opt/fzf/install" --all --no-update-rc
    else
      echo "Homebrew not found; skipping fzf install script"
    fi
  fi
fi

# Setup pyenv
echo "🐍 Setting up pyenv..."
if command -v pyenv > /dev/null 2>&1; then
  echo "Installing latest Python..."
  LATEST_PYTHON=$(pyenv install --list | grep -E "^\s*3\.[0-9]+\.[0-9]+$" | tail -n 1 | tr -d ' ')
  if [[ -n "$LATEST_PYTHON" ]]; then
    pyenv install -s "$LATEST_PYTHON"
    pyenv global "$LATEST_PYTHON"
    echo "Python $LATEST_PYTHON installed and set as global"
  fi
fi

# Setup Node.js with latest LTS
echo "📦 Setting up Node.js..."
if command -v node > /dev/null 2>&1; then
  echo "Node.js already available via Homebrew"
else
  echo "Node.js not found - you may want to install it"
fi

# Setup tmux plugin manager
echo "🖥️  Setting up tmux plugin manager..."
if [[ ! -d ~/.tmux/plugins/tpm ]]; then
  echo "Installing TPM (Tmux Plugin Manager)..."
  if command -v git > /dev/null 2>&1; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    echo "TPM installed. Press prefix + I in tmux to install plugins."
  else
    echo "git not found; skipping TPM install"
  fi
fi

# Initialize zoxide database
echo "📂 Initializing zoxide..."
if command -v zoxide > /dev/null 2>&1; then
  # Just initialize it, it will build the database as you use it
  echo "Zoxide ready"
fi

# Rebuild bat themes cache (for Catppuccin)
echo "🎨 Rebuilding bat theme cache..."
if command -v bat > /dev/null 2>&1; then
  if [[ -d "${XDG_CONFIG_HOME:-$HOME/.config}/bat/themes" ]]; then
    bat cache --build
  fi
fi

echo "✅ Post-installation setup complete!"
echo ""
echo "🎯 Next steps:"
echo "   1. Restart your terminal or run: source ~/.zshrc"
echo "   2. Open tmux and press Ctrl+Space + I to install tmux plugins"
echo "   3. Open nvim and let LazyVim install plugins automatically"
echo ""
echo "🚀 Your development environment is ready!"
