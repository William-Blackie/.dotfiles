# Smart PATH discovery
# This file handles machine-independent PATH logic.

typeset -U path PATH

path_prepend() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    path=("$dir" $path)
  fi
}

# 1. Homebrew discovery
if [[ -z "$HOMEBREW_PREFIX" ]]; then
  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# 2. Native user tooling
path_prepend "$HOME/.local/bin"
path_prepend "$HOME/.local/share/nvim/mason/bin"
path_prepend "$HOME/bin"
path_prepend "$HOME/.cargo/bin"
path_prepend "$HOME/.go/bin"

# 3. NVM / Node
export NVM_DIR="$HOME/.nvm"
if [[ -d "$NVM_DIR/versions/node" ]]; then
  local_node_bin=""
  if [[ -r "$NVM_DIR/alias/default" ]]; then
    local_node_version="$(<"$NVM_DIR/alias/default")"
    if [[ -d "$NVM_DIR/versions/node/$local_node_version/bin" ]]; then
      local_node_bin="$NVM_DIR/versions/node/$local_node_version/bin"
    fi
  fi

  if [[ -z "$local_node_bin" ]]; then
    local_node_bin="$(command ls -1dt "$NVM_DIR"/versions/node/*/bin 2>/dev/null | head -n 1)"
  fi

  if [[ -n "$local_node_bin" ]]; then
    path_prepend "$local_node_bin"
  fi
fi

# 4. Pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PYENV_DISABLE_AUTO_REHASH=1
if [[ -d "$PYENV_ROOT" ]]; then
  path_prepend "$PYENV_ROOT/shims"
  path_prepend "$PYENV_ROOT/bin"
fi
