#!/usr/bin/env bash
# Platform-aware package installer for dotfiles.
# Supports macOS (Homebrew) and Debian/Ubuntu (apt-get + manual installs).
# Version pinning sourced from scripts/versions.sh.

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load pinned versions
if [[ -f "$SCRIPT_DIR/versions.sh" ]]; then
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/versions.sh"
else
  echo "⚠️  scripts/versions.sh not found; cannot pin versions."
  exit 1
fi

echo "📦 Detecting OS and installing packages (Pinned)..."

if [[ "$(uname -s)" == "Darwin" ]]; then
  echo "🍎 macOS detected. Using Homebrew..."
  command -v brew > /dev/null 2>&1 || {
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  }
  brew install git curl neovim tmux stow fzf fd ripgrep eza bat zoxide \
    starship lazygit tree-sitter-cli delta gh k9s kubectl docker kind \
    blueutil switchaudio-osx lua luarocks pyenv uv shellcheck shfmt hadolint \
    1password-cli bitwarden-cli \
    --cask 1password bitwarden

elif [[ -f /etc/debian_version ]]; then
  echo "🐧 Debian/Ubuntu detected. Using apt-get..."
  sudo apt-get update && sudo apt-get install -y \
    git curl zsh tmux stow fzf ripgrep zoxide make build-essential \
    lua5.4 luarocks python3-pip python3-venv jq shellcheck shfmt \
    libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
    libffi-dev liblzma-dev

  echo "🔧 Installing additional development tools for Linux..."
  ARCH=$(dpkg --print-architecture)

  # Neovim
  if ! command -v nvim > /dev/null 2>&1; then
    if [[ "$ARCH" == "amd64" ]]; then
      curl -LO "https://github.com/neovim/neovim/releases/download/$NEOVIM_VERSION/nvim-linux-x86_64.tar.gz"
      sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
      sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
      rm nvim-linux-x86_64.tar.gz
    elif [[ "$ARCH" == "arm64" ]]; then
      curl -LO "https://github.com/neovim/neovim/releases/download/$NEOVIM_VERSION/nvim-linux-arm64.tar.gz"
      sudo tar -C /opt -xzf nvim-linux-arm64.tar.gz
      sudo ln -sf /opt/nvim-linux-arm64/bin/nvim /usr/local/bin/nvim
      rm nvim-linux-arm64.tar.gz
    fi
  fi

  # eza
  if ! command -v eza > /dev/null 2>&1; then
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc |
      sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" |
      sudo tee /etc/apt/sources.list.d/gierens.list
    sudo apt-get update && sudo apt-get install -y eza
  fi

  # fd
  if ! command -v fd > /dev/null 2>&1; then
    sudo apt-get install -y fd-find
    sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
  fi

  # Starship
  if ! command -v starship > /dev/null 2>&1; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
  fi

  # Delta
  if ! command -v delta > /dev/null 2>&1; then
    curl -LO "https://github.com/dandavison/delta/releases/download/$DELTA_VERSION/git-delta_${DELTA_VERSION}_${ARCH}.deb"
    sudo dpkg -i "git-delta_${DELTA_VERSION}_${ARCH}.deb"
    rm "git-delta_${DELTA_VERSION}_${ARCH}.deb"
  fi

  # Hadolint
  if ! command -v hadolint > /dev/null 2>&1; then
    HADOLINT_ARCH="$ARCH"
    [[ "$ARCH" == "amd64" ]] && HADOLINT_ARCH="x86_64"
    curl -Lo hadolint "https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-${HADOLINT_ARCH}"
    sudo install -m 0755 hadolint /usr/local/bin/hadolint
    rm hadolint
  fi

  # GitHub CLI
  if ! command -v gh > /dev/null 2>&1; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg |
      sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" |
      sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt-get update && sudo apt-get install -y gh
  fi

  # kubectl
  if ! command -v kubectl > /dev/null 2>&1; then
    curl -LO "https://dl.k8s.io/release/v$KUBECTL_VERSION/bin/linux/${ARCH}/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
  fi

  # pyenv
  if [[ ! -d "$HOME/.pyenv" ]]; then
    curl https://pyenv.run | bash || true
  fi

else
  echo "⚠️  Unsupported OS. Install packages manually."
  exit 1
fi

if command -v uv > /dev/null 2>&1; then
  echo "🐍 Installing Python CLI tools with uv..."
  uv tool install --upgrade pycodestyle > /dev/null
  uv tool install --upgrade pyflakes > /dev/null
fi

echo "✅ All packages installed!"
