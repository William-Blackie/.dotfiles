# Deterministic PATH setup.
# Order matters; duplicates do not.

typeset -U path

path_add() {
  local dir="$1"
  [[ -n "$dir" && -d "$dir" ]] || return 0
  path=("$dir" "${path[@]}")
}

# Start from the current shell PATH, then normalize it.
path=("${(@s/:/)PATH}")

# Homebrew first so native packages win over system binaries.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

path=("${(@s/:/)PATH}")

# User tooling.
path_add "$HOME/.local/bin"
path_add "$HOME/.local/share/nvim/mason/bin"
path_add "$HOME/bin"
path_add "$HOME/.cargo/bin"
path_add "$HOME/.go/bin"

# Node via nvm.
export NVM_DIR="$HOME/.nvm"
if [[ -d "$NVM_DIR/versions/node" ]]; then
  node_bin=""
  if [[ -r "$NVM_DIR/alias/default" ]]; then
    node_version="$(<"$NVM_DIR/alias/default")"
    if [[ -d "$NVM_DIR/versions/node/$node_version/bin" ]]; then
      node_bin="$NVM_DIR/versions/node/$node_version/bin"
    fi
  fi
  if [[ -z "$node_bin" ]]; then
    node_bin="$(command ls -1dt "$NVM_DIR"/versions/node/*/bin 2>/dev/null | head -n 1)"
  fi
  path_add "$node_bin"
fi

# Pyenv.
export PYENV_ROOT="$HOME/.pyenv"
export PYENV_DISABLE_AUTO_REHASH=1
path_add "$PYENV_ROOT/shims"
path_add "$PYENV_ROOT/bin"

export PATH="${(j/:/)path}"
