#!/bin/bash

# Post-installation setup script for additional tools and configurations
# Version Pinned for E2E Stability via scripts/versions.sh

set -euo pipefail
IFS=$'\n\t'

# Load pinned versions
if [[ -f "$(dirname "$0")/scripts/versions.sh" ]]; then
  # shellcheck disable=SC1091
  source "$(dirname "$0")/scripts/versions.sh"
else
  echo "⚠️  scripts/versions.sh not found; using fallback versions"
  export ZINIT_VERSION="v3.14.0"
  export TPM_COMMIT="99469c4"
  export NVM_VERSION="v0.39.7"
  export NODE_VERSION="22.13.1"
  export PYTHON_VERSION="3.13.7"
fi

echo "🔧 Running post-installation setup..."

# Setup Zinit (Zsh plugin manager)
echo "📥 Setting up Zinit ($ZINIT_VERSION)..."
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME" ]]; then
  echo "Installing Zinit..."
  mkdir -p "$(dirname "$ZINIT_HOME")"
  if command -v git > /dev/null 2>&1; then
    git clone --branch "$ZINIT_VERSION" https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
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
      echo "Skipping fzf install script (not on macOS/Homebrew)"
    fi
  fi
fi

# Setup pyenv
echo "🐍 Setting up pyenv..."
export PYENV_ROOT="$HOME/.pyenv"
if [[ -d "$PYENV_ROOT" ]]; then
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
fi

if command -v pyenv > /dev/null 2>&1; then
  if [[ "${SKIP_PYENV_INSTALL:-0}" == "1" ]]; then
    echo "Skipping pyenv Python installation (SKIP_PYENV_INSTALL=1)"
  else
    echo "Installing Python $PYTHON_VERSION..."
    pyenv install -s "$PYTHON_VERSION"
    pyenv global "$PYTHON_VERSION"
    echo "Python $PYTHON_VERSION installed and set as global"
  fi
else
  echo "pyenv not found; skipping Python install"
fi

# Setup Node.js with nvm
echo "📦 Setting up Node.js (nvm $NVM_VERSION)..."
export NVM_DIR="$HOME/.nvm"
if [[ ! -d "$NVM_DIR" ]]; then
  echo "Installing nvm..."
  curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | bash
  # Load nvm for the rest of this script
  # shellcheck disable=SC1091
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
else
  echo "nvm already installed"
fi

if command -v nvm > /dev/null 2>&1; then
  echo "Installing Node.js $NODE_VERSION..."
  nvm install "$NODE_VERSION"
  nvm alias default "$NODE_VERSION"
  nvm use default
  echo "Node.js $NODE_VERSION installed and set as default"

  # Install Gemini CLI (Wow Factor 🌟)
  echo "Installing Gemini CLI..."
  npm install -g @google/gemini-cli
fi

# Setup tmux plugin manager
echo "🖥️  Setting up tmux plugin manager (TPM)..."
if [[ ! -d ~/.tmux/plugins/tpm ]]; then
  echo "Installing TPM..."
  if command -v git > /dev/null 2>&1; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    (cd ~/.tmux/plugins/tpm && git checkout "$TPM_COMMIT")
    echo "TPM installed."
  else
    echo "git not found; skipping TPM install"
  fi
fi

# Initialize zoxide database
echo "📂 Initializing zoxide..."
if command -v zoxide > /dev/null 2>&1; then
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
echo "🚀 Your development environment is ready!"
