#!/bin/zsh

# fzf registers zle widgets, so skip it outside real interactive terminals.
if [[ ! -o interactive || ! -t 0 || ! -t 1 ]]; then
  return 0 2>/dev/null || exit 0
fi

# Setup fzf
# ---------
if [[ -d "/opt/homebrew/opt/fzf/bin" ]]; then
  FZF_BIN="/opt/homebrew/opt/fzf/bin"
elif [[ -d "/usr/local/opt/fzf/bin" ]]; then
  FZF_BIN="/usr/local/opt/fzf/bin"
fi
if [[ -n "${FZF_BIN:-}" && ":$PATH:" != *":$FZF_BIN:"* ]]; then
  PATH="${PATH:+${PATH}:}$FZF_BIN"
fi
unset FZF_BIN

if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi
