if [[ -x "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x "/usr/local/bin/brew" ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Re-inject custom managers to ensure they win over Homebrew in login shells
if [[ -n "$NVM_DIR" && -d "$NVM_DIR/versions/node" ]]; then
  DEFAULT_NODE_BIN=$(find "$NVM_DIR/versions/node" -maxdepth 2 -type d -path "*/bin" | head -n 1)
  if [[ -n "$DEFAULT_NODE_BIN" ]]; then
    export PATH="$DEFAULT_NODE_BIN:$PATH"
  fi
fi

if [[ -n "$PYENV_ROOT" ]]; then
  [[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
  [[ -d "$PYENV_ROOT/shims" ]] && export PATH="$PYENV_ROOT/shims:$PATH"
fi

# Machine-local login environment (not tracked in dotfiles repo).
[[ -f ~/.zprofile.local ]] && source ~/.zprofile.local
